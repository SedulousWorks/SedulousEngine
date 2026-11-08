using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.VFS;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// The cooked form a parcel is built from, stored in the content database.
[Serializable]
class ParcelSource
{
	public int32 Weight;
}

/// What a courier's reference resolves to.
class Parcel
{
	public int32 Weight;
}

/// Builds a Parcel from its stored source.
class ParcelFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Parcel>();
	public Type CookedType => typeof(ParcelSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;
		let parcel = new Parcel();
		parcel.Weight = ((ParcelSource)source).Weight;
		return parcel;
	}
}

/// Registers this namespace's [Serializable] types, so the database reads a ParcelSource back.
[SerializableRegistry]
static class GameplayTestSerializables
{
}

/// A scratch mount, a content database over it with a parcel factory, and a resource manager
/// on top: the whole stack a scene resolves against.
class ParcelFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;
	public ParcelFactory Parcels = new .() ~ delete _;
	private String mRoot = new .() ~ delete _;

	public this(StringView root)
	{
		GameplayTestSerializables.RegisterAll();
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);
		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset");
		Manager = new ResourceManager(Database);
		Manager.AddFactory(Parcels);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Stores a parcel's source and answers its identity.
	public Guid Author(StringView name, int32 weight)
	{
		let instance = Database.RootGroup.CreateInstance(name, "Sedulous.Engine.Gameplay.Tests.ParcelSource");
		let source = scope ParcelSource();
		source.Weight = weight;
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}
}

/// How a courier moves: a game enum with no [Reflect], held only as a list's elements.
enum CourierGait : int32
{
	Walk = 0,
	Trot = 4,
	Gallop = 9
}

/// A behaviour holding an asset reference, and a list of an unreflected enum.
[Behaviour("test.courier")]
class Courier : Behaviour
{
	public Ref<Parcel> Package = .(Guid());
	public List<CourierGait> Gaits = new .() ~ delete _;
}

/// A behaviour's Ref<T> fields bound as a component's are: by the resolve pass after a load,
/// and at once for what is read into a scene already resolved. An id that names nothing stays
/// unresolved, and is kept.
class BehaviourResourceTests
{
	private static void RoundTrip(Scene source, Scene target)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		}
		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Binary);
		Test.Assert(reader.IsOk);
	}

	[Test]
	public static void AReferenceIsBoundWhenTheLoadedSceneResolves()
	{
		let fixture = scope ParcelFixture("scratch_behaviour_refs_resolve");
		let parcelId = fixture.Author("parcel", 7);
		let missingId = Guid.Create();

		let source = scope Scene();
		let couriers = source.AddSystem<BehaviourManager<Courier>>();
		couriers.Add(source.CreateEntity("Carrier")).Package.SetId(parcelId);
		couriers.Add(source.CreateEntity("Stray")).Package.SetId(missingId);

		let target = scope Scene();
		let loaded = target.AddSystem<BehaviourManager<Courier>>();
		RoundTrip(source, target);

		let carried = loaded.Get(target.FindEntityByName("Carrier"));
		let lost = loaded.Get(target.FindEntityByName("Stray"));
		Test.Assert((carried != null) && (lost != null));
		Test.Assert(carried.Package.Id == parcelId, "the id was saved");
		Test.Assert(!carried.Package.IsBound, "a read before any resolve leaves it unbound");

		SceneResolve.ResolveSceneResources(target, fixture.Manager);
		Test.Assert(carried.Package.HasValue, "the resolve bound it");
		Test.Assert(carried.Package.Get.Weight == 7, "to the parcel the database holds");
		Test.Assert(lost.Package.Id == missingId, "an id that names nothing is kept");
		Test.Assert(!lost.Package.HasValue, "and stays unresolved");

		// Idempotent: a second pass is a cache hit, the same parcel.
		let first = carried.Package.Get;
		SceneResolve.ResolveSceneResources(target, fixture.Manager);
		Test.Assert(carried.Package.Get === first);
	}

	[Test]
	public static void WhatArrivesInAResolvedSceneIsBoundAtOnce()
	{
		let fixture = scope ParcelFixture("scratch_behaviour_refs_arrive");
		let parcelId = fixture.Author("parcel", 3);
		let otherId = fixture.Author("other", 11);

		let scene = scope Scene();
		let couriers = scene.AddSystem<BehaviourManager<Courier>>();
		let carrier = scene.CreateEntity("Carrier");
		SceneResolve.ResolveSceneResources(scene, fixture.Manager);

		// Added after the resolve: an id set in code waits for a bind.
		let added = couriers.Add(carrier);
		Test.Assert(!added.Package.HasValue);
		added.Package.SetId(parcelId);
		Test.Assert(!added.Package.HasValue, "setting the id binds nothing");

		// Read over it (a restore, an undo): the fresh instance is bound as it is read.
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			couriers.WriteComponent(writer, carrier);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(buffer, .Read);
			couriers.ReadComponent(reader, carrier);
			Test.Assert(reader.IsOk);
		}
		let reread = couriers.Get(carrier);
		Test.Assert(reread.Package.HasValue && (reread.Package.Get.Weight == 3), "a read into a resolved scene binds what it read");

		// One entity's pass: a subtree spawned into the scene.
		reread.Package.SetId(otherId);
		SceneResolve.ResolveEntityResources(scene, carrier, fixture.Manager);
		Test.Assert(reread.Package.Get.Weight == 11, "the entity's pass binds the id it now holds");
	}

	/// The enums a behaviour's fields hold are registered by its [Behaviour], so the tools name
	/// them though neither enum is reflected: a field's (MoverMood, on Mover) and a list's
	/// elements' (CourierGait, on Courier), each case with its own value.
	[Test]
	public static void ABehavioursEnumsAreNamedWithoutReflection()
	{
		Test.Assert(EnumCases.IsRegistered(typeof(MoverMood)), "a field's enum");
		Test.Assert(EnumCases.NameOf(typeof(MoverMood), 2, .. scope String()) == "Asleep");

		Test.Assert(EnumCases.IsRegistered(typeof(CourierGait)), "a list's elements' enum");
		let names = scope String();
		for (let (name, caseValue) in EnumCases.Of(typeof(CourierGait)))
			names.AppendF("{}={} ", name, caseValue);
		Test.Assert(names == "Walk=0 Trot=4 Gallop=9 ", names);
		Test.Assert(EnumCases.NameOf(typeof(CourierGait), 5, .. scope String()) == "5", "a value no case has is its number");
	}
}
