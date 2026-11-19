using System;
using System.Collections;
using System.IO;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Scene.Tests;

/// A product type for the references below.
class HeldProduct
{
}

/// Builds a HeldProduct for any record.
class HeldProductFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<HeldProduct>();
	public Type CookedType => typeof(Object);
	public Object Create(ResourceManager manager, Instance instance) => new HeldProduct();
}

/// A component holding a reference, as a real one does.
[Reflect(.NonStaticFields)]
struct Skin
{
	public Ref<HeldProduct> Texture;
	public List<Ref<HeldProduct>> Extras;

	public this()
	{
		Texture = .(Guid.Empty);
		Extras = null;
	}
}

class SkinManager : ComponentManager<Skin>
{
}

/// What a scene answers a resource manager's holder with: the ids its components reference, as
/// they are now (a reference re-pointed after binding included), for every live scene, and none
/// once the scene is gone.
class SceneResourceIdsTests
{
	[Test]
	public static void ALiveScenesComponentsNameTheirResourcesUntilTheSceneGoes()
	{
		let first = Guid.Create();
		let extra = Guid.Create();
		let repointed = Guid.Create();
		let scene = new Scene("held");
		let manager = scene.AddSystem<SkinManager>();
		let entity = scene.CreateEntity("a");
		let skin = manager.Add(entity);
		skin.Texture = .(first);
		let extras = scope List<Ref<HeldProduct>>();
		extras.Add(.(extra));
		skin.Extras = extras;

		let held = scope HashSet<Guid>();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(held.Contains(first) && held.Contains(extra));

		// Re-pointed by any path: the next answer has the new id, not the old.
		skin.Texture.SetId(repointed);
		held.Clear();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(held.Contains(repointed) && !held.Contains(first));

		skin.Extras = null; // the list is the test's
		delete scene;
		held.Clear();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(!held.Contains(repointed) && !held.Contains(extra), "a gone scene names nothing");
	}

	/// The live scenes as a manager's holder: what a loaded scene references stays loaded however
	/// long nothing else holds it, and is released once the scene is gone.
	[Test]
	public static void WhatALoadedSceneReferencesStaysUntilTheSceneGoes()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_scene_hold", .. scope .());
		RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		defer RemoveDirectoryRecursive(dir);
		let mount = scope NativeFileSystem(dir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "asset");
		let resources = scope ResourceManager(database);
		let factory = scope HeldProductFactory();
		resources.AddFactory(factory);
		resources.SetUnusedFrames(2);
		Scene.HoldResources(resources);
		let id = database.RootGroup.CreateInstance("skin", "Held").Id;

		let scene = new Scene("held");
		let manager = scene.AddSystem<SkinManager>();
		let skin = manager.Add(scene.CreateEntity("a"));
		skin.Texture = .(id);
		skin.Texture.Bind(resources);
		let handle = resources.FindHandle(id);
		let product = handle.Product;
		Test.Assert(product != null);

		for (int i < 5)
			resources.CollectGarbage();
		Test.Assert(handle.Product === product, "held while the scene is loaded");

		// The holders are asked each time it comes due, so it goes within its frames.
		delete scene;
		for (int i < 2)
			resources.CollectGarbage();
		Test.Assert(handle.Product == null, "released once the scene is gone");
	}
}
