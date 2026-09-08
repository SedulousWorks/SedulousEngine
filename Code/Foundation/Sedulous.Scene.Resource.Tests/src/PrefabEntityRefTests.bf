using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// The reflected remap of entity references inside a component.
///
/// This is what [Component] and [SerializableComponent] buy: a component with a reference
/// field is covered without per type code, because the attribute forces the field
/// reflection that finds it. A component that could not be reflected would spawn with its
/// references still pointing at the template, which is the silent kind of wrong.
class PrefabEntityRefTests
{
	private static Guid Id(uint32 value) => .(value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// A reference pointing INSIDE the prefab becomes the instance's own copy.
	[Test]
	public static void AReferenceIntoThePrefabIsRemappedToTheInstance()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("member");

		let sourceId = Id(1);
		let liveId = Id(2);
		manager.Add(entity).Target = .(sourceId);

		let map = scope Dictionary<Guid, Guid>();
		map[sourceId] = liveId;

		PrefabEntityRefs.Remap(manager, entity, map);

		Test.Assert(manager.Get(entity).Target.Id == liveId,
			"the attribute's reflection found the field");
	}

	/// A reference resolving OUTSIDE the prefab is left exactly as it was: it names
	/// something in the wider scene, and rewriting it would redirect it to whichever
	/// member happened to share a guid.
	[Test]
	public static void AReferenceOutsideThePrefabIsLeftAlone()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("member");

		let outsider = Id(99);
		manager.Add(entity).Target = .(outsider);

		let map = scope Dictionary<Guid, Guid>();
		map[Id(1)] = Id(2);

		PrefabEntityRefs.Remap(manager, entity, map);

		Test.Assert(manager.Get(entity).Target.Id == outsider);
	}

	/// An unset reference stays unset rather than picking up whatever a nil guid happens
	/// to map to.
	[Test]
	public static void AnUnsetReferenceStaysUnset()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("member");
		manager.Add(entity);

		let map = scope Dictionary<Guid, Guid>();
		map[Guid()] = Id(7);

		PrefabEntityRefs.Remap(manager, entity, map);

		Test.Assert(manager.Get(entity).Target.IsNil);
	}

	/// A component that is absent, or an entity that is gone, is a no op rather than a
	/// read through a null pool address.
	[Test]
	public static void RemappingSomethingAbsentIsANoOp()
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("no component");

		let map = scope Dictionary<Guid, Guid>();
		map[Id(1)] = Id(2);

		PrefabEntityRefs.Remap(manager, entity, map);
		PrefabEntityRefs.Remap(manager, EntityHandle.Invalid, map);
	}
}
