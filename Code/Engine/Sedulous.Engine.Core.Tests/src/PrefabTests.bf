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

class PrefabTests
{
	/// Helper: find an entity by name (iterates all entities).
	private static EntityHandle FindByName(Scene scene, StringView name)
	{
		for (let entity in scene.Entities)
		{
			if (scene.GetEntityName(entity) == name)
				return entity;
		}
		return .Invalid;
	}

	private static ComponentTypeRegistry CreateRegistry()
	{
		let registry = new ComponentTypeRegistry();
		registry.Register("Test.HealthComponent", new () => new HealthManager());
		registry.Register("Test.TargetComponent", new () => new TargetManager());
		registry.Register("Test.NameTagComponent", new () => new NameTagManager());
		// PrefabInstanceTagManager has empty SerializationTypeId - not in registry
		return registry;
	}

	/// Round-trip a prefab: save scene as prefab, load back into new scene.
	private static bool PrefabRoundTrip(Scene sourceScene, Scene destScene,
		List<ExposedParameterDescriptor> sourceParams,
		List<ExposedParameterDescriptor> destParams,
		ComponentTypeRegistry registry)
	{
		let serializer = scope PrefabSerializer(registry);

		// Save
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		serializer.Save(sourceScene, sourceParams, writer);

		let output = scope String();
		writer.GetOutput(output);

		// Load
		let desc = scope SerializerDataDescription();
		if (desc.ProcessText(output) != .Ok)
			return false;

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;
		serializer.Load(destScene, destParams, reader);
		return true;
	}

	// ==================== Basic Serialization ====================

	[Test]
	public static void RoundTrip_EmptyPrefab()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);
		Test.Assert(dest.EntityCount == 0);
		Test.Assert(destParams.Count == 0);
	}

	[Test]
	public static void RoundTrip_SingleEntity()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		source.CreateEntity("Root");

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);
		Test.Assert(dest.EntityCount == 1);
	}

	[Test]
	public static void RoundTrip_EntityHierarchy()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		let root = source.CreateEntity("Root");
		let child1 = source.CreateEntity("Child1");
		let child2 = source.CreateEntity("Child2");
		source.SetParent(child1, root);
		source.SetParent(child2, root);

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);
		Test.Assert(dest.EntityCount == 3);

		// Check hierarchy preserved
		let destRoot = FindByName(dest,"Root");
		let destChild1 = FindByName(dest,"Child1");
		let destChild2 = FindByName(dest,"Child2");
		Test.Assert(destRoot.IsAssigned);
		Test.Assert(destChild1.IsAssigned);
		Test.Assert(destChild2.IsAssigned);
		Test.Assert(dest.GetParent(destChild1) == destRoot);
		Test.Assert(dest.GetParent(destChild2) == destRoot);
	}

	[Test]
	public static void RoundTrip_WithComponents()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		source.AddModule(new HealthManager());

		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		let entity = source.CreateEntity("Warrior");
		let healthMgr = source.GetModule<HealthManager>();
		let handle = healthMgr.CreateComponent(entity);
		if (let comp = healthMgr.Get(handle))
		{
			comp.Health = 250;
			comp.Armor = 10;
		}

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);

		let destEntity = FindByName(dest,"Warrior");
		Test.Assert(destEntity.IsAssigned);

		let destHealthMgr = dest.GetModule<HealthManager>();
		Test.Assert(destHealthMgr != null);
		let destComp = destHealthMgr.GetForEntity(destEntity);
		Test.Assert(destComp != null);
		Test.Assert(destComp.Health == 250);
		Test.Assert(destComp.Armor == 10);
	}

	[Test]
	public static void RoundTrip_WithTransform()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		let entity = source.CreateEntity("Positioned");
		source.SetLocalTransform(entity, .()
		{
			Position = .(10, 20, 30),
			Rotation = .Identity,
			Scale = .(2, 2, 2)
		});

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);

		let destEntity = FindByName(dest,"Positioned");
		Test.Assert(destEntity.IsAssigned);

		let t = dest.GetLocalTransform(destEntity);
		Test.Assert(Math.Abs(t.Position.X - 10) < 0.001f);
		Test.Assert(Math.Abs(t.Position.Y - 20) < 0.001f);
		Test.Assert(Math.Abs(t.Position.Z - 30) < 0.001f);
		Test.Assert(Math.Abs(t.Scale.X - 2) < 0.001f);
	}

	// ==================== Exposed Parameters ====================

	[Test]
	public static void RoundTrip_ExposedParameters()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		source.AddModule(new HealthManager());

		let entity = source.CreateEntity("Warrior");
		let entityId = source.GetEntityId(entity);

		let sourceParams = scope List<ExposedParameterDescriptor>();
		let param = scope ExposedParameterDescriptor();
		param.Name.Set("MaxHealth");
		param.EntityId = entityId;
		param.ComponentTypeId.Set("Test.HealthComponent");
		param.PropertyName.Set("Health");
		sourceParams.Add(param);

		let destParams = scope List<ExposedParameterDescriptor>();

		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);
		Test.Assert(destParams.Count == 1);
		Test.Assert(destParams[0].Name == "MaxHealth");
		Test.Assert(destParams[0].EntityId == entityId);
		Test.Assert(destParams[0].ComponentTypeId == "Test.HealthComponent");
		Test.Assert(destParams[0].PropertyName == "Health");

		// Clean up destParams (owned by scope list but items are heap)
		for (let p in destParams) delete p;
	}

	// ==================== Instantiation ====================

	[Test]
	public static void Instantiate_CreatesEntitiesUnderParent()
	{
		let registry = CreateRegistry();
		defer delete registry;

		// Build a prefab in a source scene
		let source = scope Scene();
		source.AddModule(new HealthManager());

		let root = source.CreateEntity("PrefabRoot");
		let child = source.CreateEntity("PrefabChild");
		source.SetParent(child, root);

		let healthMgr = source.GetModule<HealthManager>();
		let handle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(handle))
			comp.Health = 500;

		// Serialize to text
		let prefabSerializer = scope PrefabSerializer(registry);
		let sourceParams = scope List<ExposedParameterDescriptor>();

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		prefabSerializer.Save(source, sourceParams, writer);

		let output = scope String();
		writer.GetOutput(output);

		// Create target scene with a parent entity
		let targetScene = scope Scene();
		let parentEntity = targetScene.CreateEntity("InstanceParent");

		// Instantiate
		let desc = scope SerializerDataDescription();
		Test.Assert(desc.ProcessText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;

		let emptyParams = scope List<ExposedParameterDescriptor>();
		let result = prefabSerializer.Instantiate(targetScene, parentEntity, reader, emptyParams);
		Test.Assert(result case .Ok);

		let guidMap = result.Value;
		defer delete guidMap;

		// Should have 3 entities total: parent + 2 instantiated
		Test.Assert(targetScene.EntityCount == 3);

		// Instantiated root should be child of parentEntity
		let instRoot = FindByName(targetScene,"PrefabRoot");
		Test.Assert(instRoot.IsAssigned);
		Test.Assert(targetScene.GetParent(instRoot) == parentEntity);

		// Instantiated child should be child of instantiated root
		let instChild = FindByName(targetScene,"PrefabChild");
		Test.Assert(instChild.IsAssigned);
		Test.Assert(targetScene.GetParent(instChild) == instRoot);

		// Component data should be preserved
		let destHealthMgr = targetScene.GetModule<HealthManager>();
		Test.Assert(destHealthMgr != null);
		let destComp = destHealthMgr.GetForEntity(instRoot);
		Test.Assert(destComp != null);
		Test.Assert(destComp.Health == 500);
	}

	[Test]
	public static void Instantiate_CreatesNewGuids()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let entity = source.CreateEntity("Entity1");
		let sourceId = source.GetEntityId(entity);

		let prefabSerializer = scope PrefabSerializer(registry);
		let sourceParams = scope List<ExposedParameterDescriptor>();

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		prefabSerializer.Save(source, sourceParams, writer);

		let output = scope String();
		writer.GetOutput(output);

		let targetScene = scope Scene();
		let parent = targetScene.CreateEntity("Parent");

		let desc = scope SerializerDataDescription();
		Test.Assert(desc.ProcessText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;

		let emptyParams = scope List<ExposedParameterDescriptor>();
		let result = prefabSerializer.Instantiate(targetScene, parent, reader, emptyParams);
		Test.Assert(result case .Ok);

		let guidMap = result.Value;
		defer delete guidMap;

		// The instantiated entity should have a DIFFERENT guid than the source
		let instEntity = FindByName(targetScene,"Entity1");
		Test.Assert(instEntity.IsAssigned);
		let instId = targetScene.GetEntityId(instEntity);
		Test.Assert(instId != sourceId);

		// But the guidMap should map source -> instance
		Test.Assert(guidMap.ContainsKey(sourceId));
		Test.Assert(guidMap[sourceId] == instEntity);
	}

	// ==================== PrefabInstanceTag ====================

	[Test]
	public static void PrefabInstanceTag_NotSerialized()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		source.AddModule(new PrefabInstanceTagManager());

		let entity = source.CreateEntity("Tagged");
		let tagMgr = source.GetModule<PrefabInstanceTagManager>();
		let handle = tagMgr.CreateComponent(entity);
		if (let tag = tagMgr.Get(handle))
		{
			tag.PrefabId = Guid.Create();
			tag.SourceEntityId = Guid.Create();
		}

		let dest = scope Scene();
		let sourceParams = scope List<ExposedParameterDescriptor>();
		let destParams = scope List<ExposedParameterDescriptor>();

		// PrefabInstanceTag doesn't implement ISerializableComponent,
		// so it should be silently skipped during serialization.
		let ok = PrefabRoundTrip(source, dest, sourceParams, destParams, registry);
		Test.Assert(ok);
		Test.Assert(dest.EntityCount == 1);

		// Dest should NOT have a PrefabInstanceTagManager (empty TypeId = not serialized)
		let destTagMgr = dest.GetModule<PrefabInstanceTagManager>();
		Test.Assert(destTagMgr == null);
	}

	// ==================== Integration: PrefabComponentManager ====================

	/// Creates a .prefab file on disk, sets up ResourceSystem + PrefabComponentManager,
	/// and verifies end-to-end instantiation via the manager's update loop.
	///
	/// The callback receives the FileSystemMount over the temp dir and the
	/// locator within it. Tests should `resSys.Mount("test", mount)` to make
	/// the prefab loadable via the URI "test://<locator>".
	private static void WithTempPrefabFile(Scene prefabScene, List<ExposedParameterDescriptor> parameters,
		ComponentTypeRegistry registry, delegate void(Sedulous.VFS.Disk.FileSystemMount mount, StringView locator) testBody)
	{
		let provider = scope OpenDDLSerializerProvider();
		let prefabResMgr = scope PrefabResourceManager(registry, provider);

		// Save to temp file via a one-off FileSystemMount over the temp dir.
		let tempDir = scope String();
		System.IO.Path.GetTempPath(tempDir);

		let locator = scope String()..AppendF("test_prefab_{}.prefab", Guid.Create());
		let tempPath = scope String();
		System.IO.Path.InternalCombine(tempPath, tempDir, locator);

		defer System.IO.File.Delete(tempPath);

		let mount = scope Sedulous.VFS.Disk.FileSystemMount(tempDir);
		let saveResult = prefabResMgr.SavePrefab(prefabScene, parameters, mount, locator);
		Test.Assert(saveResult case .Ok);

		testBody(mount, locator);

		delete testBody;
	}

	[Test]
	public static void Manager_InstantiatesPrefabOnUpdate()
	{
		let registry = CreateRegistry();
		defer delete registry;

		// Build prefab content
		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("PrefabRoot");
		let child = prefabScene.CreateEntity("PrefabChild");
		prefabScene.SetParent(child, root);
		prefabScene.SetLocalTransform(root, .() { Position = .(1, 2, 3), Rotation = .Identity, Scale = .One });

		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
			comp.Health = 999;

		let parameters = scope List<ExposedParameterDescriptor>();

		WithTempPrefabFile(prefabScene, parameters, registry, new [&] (mount, locator) =>
		{
			let provider = scope OpenDDLSerializerProvider();

			// Set up ResourceSystem with the temp dir mounted under "test://".
			let logger = scope ConsoleLogger(.Trace);
			let resSys = scope ResourceSystem(logger);
			resSys.Startup();
			resSys.Mount("test", mount);
			let prefabResMgr = new PrefabResourceManager(registry, provider);
			defer {resSys.RemoveResourceManager(prefabResMgr);  delete prefabResMgr;}
			resSys.AddResourceManager(prefabResMgr);

			// Create live scene with PrefabComponentManager
			let scene = scope Scene();
			let prefabMgr = new PrefabComponentManager();
			prefabMgr.ResourceSystem = resSys;
			prefabMgr.SerializerProvider = provider;
			prefabMgr.TypeRegistry = registry;
			scene.AddModule(prefabMgr);

			// Create entity with PrefabReferenceComponent
			let instanceEntity = scene.CreateEntity("PrefabInstance");
			let refHandle = prefabMgr.CreateComponent(instanceEntity);
			if (let refComp = prefabMgr.Get(refHandle))
			{
				let uri = scope String()..AppendF("test://{}", locator);
				var prefabRef = ResourceRef(.Empty, uri);
				defer prefabRef.Dispose();
				refComp.SetPrefabRef(prefabRef);
			}

			// Run one update cycle (triggers resolve + instantiate)
			scene.Update(0.016f);

			// Verify instantiated entities
			let refComp2 = prefabMgr.GetForEntity(instanceEntity);
			Test.Assert(refComp2 != null);
			Test.Assert(refComp2.IsInstantiated);
			Test.Assert(refComp2.InstantiatedEntities.Count == 2); // root + child

			// Verify hierarchy: instantiated root is child of instanceEntity
			let instRoot = FindByName(scene, "PrefabRoot");
			Test.Assert(instRoot.IsAssigned);
			Test.Assert(scene.GetParent(instRoot) == instanceEntity);

			let instChild = FindByName(scene, "PrefabChild");
			Test.Assert(instChild.IsAssigned);
			Test.Assert(scene.GetParent(instChild) == instRoot);

			// Verify component data cloned
			let destHealthMgr = scene.GetModule<HealthManager>();
			Test.Assert(destHealthMgr != null);
			let destComp = destHealthMgr.GetForEntity(instRoot);
			Test.Assert(destComp != null);
			Test.Assert(destComp.Health == 999);

			// Verify PrefabInstanceTags
			let tagMgr = scene.GetModule<PrefabInstanceTagManager>();
			Test.Assert(tagMgr != null);
			let rootTag = tagMgr.GetForEntity(instRoot);
			Test.Assert(rootTag != null);
			Test.Assert(rootTag.ReferenceEntity == instanceEntity);

			// Total: 1 instance entity + 2 prefab entities = 3
			Test.Assert(scene.EntityCount == 3);
		});
	}

	[Test]
	public static void Manager_CleansUpOnEntityDestroy()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		let root = prefabScene.CreateEntity("Root");
		let parameters = scope List<ExposedParameterDescriptor>();

		WithTempPrefabFile(prefabScene, parameters, registry, new [&] (mount, locator) =>
		{
			let provider = scope OpenDDLSerializerProvider();
			let logger = scope ConsoleLogger(.Trace);
			let resSys = scope ResourceSystem(logger);
			resSys.Startup();
			resSys.Mount("test", mount);
			let prefabResMgr = new PrefabResourceManager(registry, provider);
			defer {resSys.RemoveResourceManager(prefabResMgr);  delete prefabResMgr;}
			resSys.AddResourceManager(prefabResMgr);

			let scene = scope Scene();
			let prefabMgr = new PrefabComponentManager();
			prefabMgr.ResourceSystem = resSys;
			prefabMgr.SerializerProvider = provider;
			prefabMgr.TypeRegistry = registry;
			scene.AddModule(prefabMgr);

			let instanceEntity = scene.CreateEntity("Instance");
			let refHandle = prefabMgr.CreateComponent(instanceEntity);
			if (let refComp = prefabMgr.Get(refHandle))
			{
				let uri = scope String()..AppendF("test://{}", locator);
				var prefabRef = ResourceRef(.Empty, uri);
				defer prefabRef.Dispose();
				refComp.SetPrefabRef(prefabRef);
			}

			// Instantiate
			scene.Update(0.016f);
			Test.Assert(scene.EntityCount == 2); // instance + 1 prefab entity

			// Destroy the instance entity - should clean up prefab entities
			scene.DestroyEntity(instanceEntity);
			scene.Update(0.016f); // process deferred destroys

			Test.Assert(scene.EntityCount == 0);
		});
	}

	// ==================== OverrideApplicator ====================

	[Test]
	public static void OverrideApplicator_Float()
	{
		let comp = scope HealthComponent();
		comp.Health = 100;

		let applicator = scope OverrideApplicator("Health", "250");
		comp.Serialize(applicator);

		Test.Assert(Math.Abs(comp.Health - 250) < 0.001f);
	}

	[Test]
	public static void OverrideApplicator_Int()
	{
		let comp = scope HealthComponent();
		comp.Armor = 5;

		let applicator = scope OverrideApplicator("Armor", "42");
		comp.Serialize(applicator);

		Test.Assert(comp.Armor == 42);
	}

	[Test]
	public static void OverrideApplicator_Bool()
	{
		let comp = scope HealthComponent();
		comp.IsInvulnerable = false;

		let applicator = scope OverrideApplicator("IsInvulnerable", "true");
		comp.Serialize(applicator);

		Test.Assert(comp.IsInvulnerable == true);
	}

	[Test]
	public static void OverrideApplicator_OnlyModifiesTarget()
	{
		let comp = scope HealthComponent();
		comp.Health = 100;
		comp.Armor = 5;
		comp.IsInvulnerable = false;

		let applicator = scope OverrideApplicator("Armor", "99");
		comp.Serialize(applicator);

		// Only Armor changed
		Test.Assert(comp.Armor == 99);
		// Others unchanged
		Test.Assert(Math.Abs(comp.Health - 100) < 0.001f);
		Test.Assert(comp.IsInvulnerable == false);
	}

	[Test]
	public static void OverrideApplicator_InvalidValue_NoChange()
	{
		let comp = scope HealthComponent();
		comp.Health = 100;

		let applicator = scope OverrideApplicator("Health", "notanumber");
		comp.Serialize(applicator);

		// Should not crash, value stays unchanged
		Test.Assert(Math.Abs(comp.Health - 100) < 0.001f);
	}

	[Test]
	public static void OverrideApplicator_NonexistentProperty_NoChange()
	{
		let comp = scope HealthComponent();
		comp.Health = 100;
		comp.Armor = 5;

		let applicator = scope OverrideApplicator("Mana", "999");
		comp.Serialize(applicator);

		// Nothing should change
		Test.Assert(Math.Abs(comp.Health - 100) < 0.001f);
		Test.Assert(comp.Armor == 5);
	}

	// ==================== Manager Override Application ====================

	[Test]
	public static void Manager_AppliesOverridesOnInstantiation()
	{
		let registry = CreateRegistry();
		defer delete registry;

		// Build prefab with HealthComponent (Health=100, Armor=5)
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

		// Expose Health as "MaxHealth" parameter
		let parameters = scope List<ExposedParameterDescriptor>();
		let param = scope ExposedParameterDescriptor();
		param.Name.Set("MaxHealth");
		param.EntityId = rootId;
		param.ComponentTypeId.Set("Test.HealthComponent");
		param.PropertyName.Set("Health");
		parameters.Add(param);

		WithTempPrefabFile(prefabScene, parameters, registry, new [&] (mount, locator) =>
		{
			let provider = scope OpenDDLSerializerProvider();
			let logger = scope ConsoleLogger(.Trace);
			let resSys = scope ResourceSystem(logger);
			resSys.Startup();
			resSys.Mount("test", mount);
			let prefabResMgr = new PrefabResourceManager(registry, provider);
			defer { resSys.RemoveResourceManager(prefabResMgr); delete prefabResMgr; }
			resSys.AddResourceManager(prefabResMgr);

			let scene = scope Scene();
			let prefabMgr = new PrefabComponentManager();
			prefabMgr.ResourceSystem = resSys;
			prefabMgr.SerializerProvider = provider;
			prefabMgr.TypeRegistry = registry;
			scene.AddModule(prefabMgr);

			let instanceEntity = scene.CreateEntity("PrefabInstance");
			let refHandle = prefabMgr.CreateComponent(instanceEntity);
			if (let refComp = prefabMgr.Get(refHandle))
			{
				let uri = scope String()..AppendF("test://{}", locator);
				var prefabRef = ResourceRef(.Empty, uri);
				defer prefabRef.Dispose();
				refComp.SetPrefabRef(prefabRef);

				// Set override: Health -> 500
				refComp.SetOverride("MaxHealth", "500");
			}

			// Update triggers instantiation + override application
			scene.Update(0.016f);

			// Verify Health was overridden to 500
			let instWarrior = FindByName(scene, "Warrior");
			Test.Assert(instWarrior.IsAssigned);

			let destHealthMgr = scene.GetModule<HealthManager>();
			Test.Assert(destHealthMgr != null);
			let destComp = destHealthMgr.GetForEntity(instWarrior);
			Test.Assert(destComp != null);
			Test.Assert(Math.Abs(destComp.Health - 500) < 0.001f);

			// Armor should be unchanged (no override for it)
			Test.Assert(destComp.Armor == 5);
		});
	}

	[Test]
	public static void Manager_OrphanedOverrideIgnored()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.AddModule(new HealthManager());
		let root = prefabScene.CreateEntity("Warrior");

		let healthMgr = prefabScene.GetModule<HealthManager>();
		let hHandle = healthMgr.CreateComponent(root);
		if (let comp = healthMgr.Get(hHandle))
			comp.Health = 100;

		// No exposed parameters — override will be orphaned
		let parameters = scope List<ExposedParameterDescriptor>();

		WithTempPrefabFile(prefabScene, parameters, registry, new [&] (mount, locator) =>
		{
			let provider = scope OpenDDLSerializerProvider();
			let logger = scope ConsoleLogger(.Trace);
			let resSys = scope ResourceSystem(logger);
			resSys.Startup();
			resSys.Mount("test", mount);
			let prefabResMgr = new PrefabResourceManager(registry, provider);
			defer { resSys.RemoveResourceManager(prefabResMgr); delete prefabResMgr; }
			resSys.AddResourceManager(prefabResMgr);

			let scene = scope Scene();
			let prefabMgr = new PrefabComponentManager();
			prefabMgr.ResourceSystem = resSys;
			prefabMgr.SerializerProvider = provider;
			prefabMgr.TypeRegistry = registry;
			scene.AddModule(prefabMgr);

			let instanceEntity = scene.CreateEntity("PrefabInstance");
			let refHandle = prefabMgr.CreateComponent(instanceEntity);
			if (let refComp = prefabMgr.Get(refHandle))
			{
				let uri = scope String()..AppendF("test://{}", locator);
				var prefabRef = ResourceRef(.Empty, uri);
				defer prefabRef.Dispose();
				refComp.SetPrefabRef(prefabRef);

				// Override for non-existent parameter — should be silently ignored
				refComp.SetOverride("NonExistent", "999");
			}

			// Should not crash
			scene.Update(0.016f);

			// Health should still be 100 (no valid override applied)
			let instWarrior = FindByName(scene, "Warrior");
			Test.Assert(instWarrior.IsAssigned);
			let destHealthMgr = scene.GetModule<HealthManager>();
			let destComp = destHealthMgr.GetForEntity(instWarrior);
			Test.Assert(destComp != null);
			Test.Assert(Math.Abs(destComp.Health - 100) < 0.001f);
		});
	}

	// ==================== Stability ====================

	[Test]
	public static void Manager_DoesNotReinstantiateIfUnchanged()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let prefabScene = scope Scene();
		prefabScene.CreateEntity("Root");
		let parameters = scope List<ExposedParameterDescriptor>();

		WithTempPrefabFile(prefabScene, parameters, registry, new [&] (mount, locator) =>
		{
			let provider = scope OpenDDLSerializerProvider();
			let logger = scope ConsoleLogger(.Trace);
			let resSys = scope ResourceSystem(logger);
			resSys.Startup();
			resSys.Mount("test", mount);
			let prefabResMgr = new PrefabResourceManager(registry, provider);
			defer {resSys.RemoveResourceManager(prefabResMgr);  delete prefabResMgr;}
			resSys.AddResourceManager(prefabResMgr);

			let scene = scope Scene();
			let prefabMgr = new PrefabComponentManager();
			prefabMgr.ResourceSystem = resSys;
			prefabMgr.SerializerProvider = provider;
			prefabMgr.TypeRegistry = registry;
			scene.AddModule(prefabMgr);

			let instanceEntity = scene.CreateEntity("Instance");
			let refHandle = prefabMgr.CreateComponent(instanceEntity);
			if (let refComp = prefabMgr.Get(refHandle))
			{
				let uri = scope String()..AppendF("test://{}", locator);
				var prefabRef = ResourceRef(.Empty, uri);
				defer prefabRef.Dispose();
				refComp.SetPrefabRef(prefabRef);
			}

			// First update - instantiates
			scene.Update(0.016f);
			let firstInstRoot = FindByName(scene, "Root");
			Test.Assert(firstInstRoot.IsAssigned);

			// Second update - should NOT re-instantiate (same resource)
			scene.Update(0.016f);
			let secondInstRoot = FindByName(scene, "Root");
			Test.Assert(secondInstRoot == firstInstRoot); // Same entity handle = no re-instantiation
		});
	}
}
