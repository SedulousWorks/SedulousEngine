namespace Sedulous.Engine.Core.Tests;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.OpenDDL;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Core.Logging.Console;

class PrefabSpawnerTests
{
	private static ComponentTypeRegistry CreateRegistry()
	{
		let registry = new ComponentTypeRegistry();
		registry.Register("Test.HealthComponent", new () => new HealthManager());
		registry.Register("Test.TargetComponent", new () => new TargetManager());
		registry.Register("Test.NameTagComponent", new () => new NameTagManager());
		return registry;
	}

	private static EntityHandle FindByName(Scene scene, StringView name)
	{
		for (let entity in scene.Entities)
		{
			if (scene.GetEntityName(entity) == name)
				return entity;
		}
		return .Invalid;
	}

	/// Helper: create a prefab file on disk, set up ResourceSystem, run test.
	private static void WithTempPrefab(Scene prefabScene, ComponentTypeRegistry registry,
		delegate void(Sedulous.VFS.Disk.FileSystemMount mount, StringView locator,
			ResourceSystem resSys, ISerializerProvider provider) testBody)
	{
		let provider = scope OpenDDLSerializerProvider();
		let prefabResMgr = scope PrefabResourceManager(registry, provider);

		let tempDir = scope String();
		System.IO.Path.GetTempPath(tempDir);

		let locator = scope String()..AppendF("test_prefab_v2_{}.prefab", Guid.Create());
		let tempPath = scope String();
		System.IO.Path.InternalCombine(tempPath, tempDir, locator);
		defer System.IO.File.Delete(tempPath);

		let mount = scope Sedulous.VFS.Disk.FileSystemMount(tempDir);
		let saveResult = prefabResMgr.SavePrefab(prefabScene, mount, locator);
		Test.Assert(saveResult case .Ok);

		let logger = scope ConsoleLogger(.Trace);
		let resSys = scope ResourceSystem(logger);
		resSys.Startup();
		resSys.Mount("test", mount);
		let resMgr = new PrefabResourceManager(registry, provider);
		defer { resSys.RemoveResourceManager(resMgr); delete resMgr; }
		resSys.AddResourceManager(resMgr);

		testBody(mount, locator, resSys, provider);
		delete testBody;
	}

	/// Helper: save scene via SceneSerializer, load into new scene.
	private static bool SceneRoundTrip(Scene source, Scene dest,
		ComponentTypeRegistry registry, ISerializerProvider provider, ResourceSystem resSys)
	{
		// Save
		let serializer = scope SceneSerializer(registry, provider, resSys);
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		serializer.Save(source, writer);

		let output = scope String();
		writer.GetOutput(output);

		// Load
		let desc = scope SerializerDataDescription();
		if (desc.ProcessText(output) != .Ok)
			return false;

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;
		let loadSerializer = scope SceneSerializer(registry, provider, resSys);
		loadSerializer.Load(dest, reader);
		return true;
	}

	// ==================== Spawn ====================

	[Test]
	public static void Spawn_CreatesEntitiesWithTags()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("PrefabRoot");
		let child = prefabScene.CreateEntity("PrefabChild");
		prefabScene.SetParent(child, root);

		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
			comp.Health = 500;

		WithTempPrefab(prefabScene, registry, new [&] (mount, locator, resSys, provider) =>
		{
			let scene = scope Scene();
			let parentEntity = scene.CreateEntity("Parent");

			let uri = scope String()..AppendF("test://{}", locator);
			var prefabRef = ResourceRef(.Empty, uri);
			defer prefabRef.Dispose();
			let prefabId = Guid.Create();

			let result = PrefabSpawner.Spawn(scene, prefabRef, prefabId,
				parentEntity, registry, provider, resSys);
			Test.Assert(result case .Ok);

			let spawnResult = result.Value;
			defer delete spawnResult.GuidMap;

			// Should have 3 entities: parent + 2 prefab
			Test.Assert(scene.EntityCount == 3);

			// Root tagged
			let instRoot = FindByName(scene, "PrefabRoot");
			Test.Assert(instRoot.IsAssigned);

			let tagMgr = scene.GetModule<PrefabInstanceTagManager>();
			Test.Assert(tagMgr != null);

			let rootTag = tagMgr.GetForEntity(instRoot);
			Test.Assert(rootTag != null);
			Test.Assert(rootTag.PrefabId == prefabId);
			Test.Assert(rootTag.InstanceRoot == instRoot);

			// Child tagged with same PrefabId
			let instChild = FindByName(scene, "PrefabChild");
			Test.Assert(instChild.IsAssigned);
			let childTag = tagMgr.GetForEntity(instChild);
			Test.Assert(childTag != null);
			Test.Assert(childTag.PrefabId == prefabId);
			Test.Assert(childTag.InstanceRoot == instRoot);

			// Component data preserved
			let destHealthMgr = scene.GetModule<HealthManager>();
			Test.Assert(destHealthMgr != null);
			let destComp = destHealthMgr.GetForEntity(instRoot);
			Test.Assert(destComp != null);
			Test.Assert(Math.Abs(destComp.Health - 500) < 0.001f);
		});
	}

	// ==================== Scene Round-Trip ====================

	[Test]
	public static void RoundTrip_NormalEntities()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let provider = scope OpenDDLSerializerProvider();

		let source = scope Scene();
		source.AddModule(new HealthManager());
		let entity = source.CreateEntity("Warrior");
		let healthMgr = source.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(entity);
		if (let comp = healthMgr.Get(hHandle))
		{
			comp.Health = 250;
			comp.Armor = 10;
		}

		let dest = scope Scene();
		let ok = SceneRoundTrip(source, dest, registry, provider, null);
		Test.Assert(ok);

		let destEntity = FindByName(dest, "Warrior");
		Test.Assert(destEntity.IsAssigned);

		let destHealthMgr = dest.GetModule<HealthManager>();
		let destComp = destHealthMgr.GetForEntity(destEntity);
		Test.Assert(destComp != null);
		Test.Assert(Math.Abs(destComp.Health - 250) < 0.001f);
		Test.Assert(destComp.Armor == 10);
	}

	[Test]
	public static void RoundTrip_PrefabInstance_NoOverrides()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("Warrior");
		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
		{
			comp.Health = 100;
			comp.Armor = 5;
		}

		WithTempPrefab(prefabScene, registry, new [&] (mount, locator, resSys, provider) =>
		{
			// Source scene: spawn a prefab instance
			let source = scope Scene();
			let uri = scope String()..AppendF("test://{}", locator);
			var prefabRef = ResourceRef(.Empty, uri);
			defer prefabRef.Dispose();
			let prefabId = Guid.Create();

			let spawnResult = PrefabSpawner.Spawn(source, prefabRef, prefabId,
				.Invalid, registry, provider, resSys);
			Test.Assert(spawnResult case .Ok);
			let sr = spawnResult.Value;
			defer delete sr.GuidMap;

			// Save and load
			let dest = scope Scene();
			let ok = SceneRoundTrip(source, dest, registry, provider, resSys);
			Test.Assert(ok);

			// Prefab instance should be recreated from template
			let destWarrior = FindByName(dest, "Warrior");
			Test.Assert(destWarrior.IsAssigned);

			let destHealthMgr = dest.GetModule<HealthManager>();
			let destComp = destHealthMgr.GetForEntity(destWarrior);
			Test.Assert(destComp != null);
			Test.Assert(Math.Abs(destComp.Health - 100) < 0.001f);
			Test.Assert(destComp.Armor == 5);

			// Tags recreated
			let tagMgr = dest.GetModule<PrefabInstanceTagManager>();
			Test.Assert(tagMgr != null);
			let tag = tagMgr.GetForEntity(destWarrior);
			Test.Assert(tag != null);
			Test.Assert(tag.PrefabId == prefabId);
		});
	}

	[Test]
	public static void RoundTrip_PrefabInstance_WithOverrides()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("Warrior");
		let rootId = prefabScene.GetEntityId(root);
		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
		{
			comp.Health = 100;
			comp.Armor = 5;
		}

		WithTempPrefab(prefabScene, registry, new [&] (mount, locator, resSys, provider) =>
		{
			// Source scene: spawn and override Health
			let source = scope Scene();
			let uri = scope String()..AppendF("test://{}", locator);
			var prefabRef = ResourceRef(.Empty, uri);
			defer prefabRef.Dispose();
			let prefabId = Guid.Create();

			let spawnResult = PrefabSpawner.Spawn(source, prefabRef, prefabId,
				.Invalid, registry, provider, resSys);
			Test.Assert(spawnResult case .Ok);
			let sr = spawnResult.Value;
			defer delete sr.GuidMap;

			// Modify Health to 500 on the instantiated entity
			let instWarrior = FindByName(source, "Warrior");
			Test.Assert(instWarrior.IsAssigned);

			let srcHealthMgr = source.GetModule<HealthManager>();
			let srcComp = srcHealthMgr.GetForEntity(instWarrior);
			srcComp.Health = 500;

			// Mark as modified in LocalModifications
			source.LocalModifications.SetPropertyModified(
				instWarrior, "Test.HealthComponent", "Health");

			// Save and load
			let dest = scope Scene();
			let ok = SceneRoundTrip(source, dest, registry, provider, resSys);
			Test.Assert(ok);

			// Health should be 500 (overridden), Armor should be 5 (from template)
			let destWarrior = FindByName(dest, "Warrior");
			Test.Assert(destWarrior.IsAssigned);

			let destHealthMgr = dest.GetModule<HealthManager>();
			let destComp = destHealthMgr.GetForEntity(destWarrior);
			Test.Assert(destComp != null);
			Test.Assert(Math.Abs(destComp.Health - 500) < 0.001f);
			Test.Assert(destComp.Armor == 5);

			// LocalModifications should be restored
			Test.Assert(dest.LocalModifications.IsPropertyModified(
				destWarrior, "Test.HealthComponent", "Health"));
			Test.Assert(!dest.LocalModifications.IsPropertyModified(
				destWarrior, "Test.HealthComponent", "Armor"));
		});
	}

	[Test]
	public static void RoundTrip_Mixed_NormalAndPrefab()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("PrefabEntity");
		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
			comp.Health = 100;

		WithTempPrefab(prefabScene, registry, new [&] (mount, locator, resSys, provider) =>
		{
			let source = scope Scene();
			source.AddModule(new HealthManager());

			// Normal entity
			let normalEntity = source.CreateEntity("NormalEntity");
			let srcHealthMgr = source.GetModule<HealthManager>();
			let normalHandle = srcHealthMgr.CreateComponent(normalEntity);
			if (let comp = srcHealthMgr.Get(normalHandle))
				comp.Health = 999;

			// Prefab instance
			let uri = scope String()..AppendF("test://{}", locator);
			var prefabRef = ResourceRef(.Empty, uri);
			defer prefabRef.Dispose();

			let spawnResult = PrefabSpawner.Spawn(source, prefabRef, Guid.Create(),
				.Invalid, registry, provider, resSys);
			Test.Assert(spawnResult case .Ok);
			defer delete spawnResult.Value.GuidMap;

			// Save and load
			let dest = scope Scene();
			let ok = SceneRoundTrip(source, dest, registry, provider, resSys);
			Test.Assert(ok);

			// Both should exist
			let destNormal = FindByName(dest, "NormalEntity");
			Test.Assert(destNormal.IsAssigned);
			let destPrefab = FindByName(dest, "PrefabEntity");
			Test.Assert(destPrefab.IsAssigned);

			// Normal entity has its own Health
			let destHealthMgr = dest.GetModule<HealthManager>();
			let normalComp = destHealthMgr.GetForEntity(destNormal);
			Test.Assert(normalComp != null);
			Test.Assert(Math.Abs(normalComp.Health - 999) < 0.001f);

			// Prefab entity has template Health
			let prefabComp = destHealthMgr.GetForEntity(destPrefab);
			Test.Assert(prefabComp != null);
			Test.Assert(Math.Abs(prefabComp.Health - 100) < 0.001f);
		});
	}
}
