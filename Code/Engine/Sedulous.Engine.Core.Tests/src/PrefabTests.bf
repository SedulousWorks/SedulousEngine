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
		ComponentTypeRegistry registry)
	{
		let serializer = scope PrefabSerializer(registry);

		// Save
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		serializer.Save(sourceScene, writer);

		let output = scope String();
		writer.GetOutput(output);

		// Load
		let desc = scope SerializerDataDescription();
		if (desc.ProcessText(output) != .Ok)
			return false;

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;
		serializer.Load(destScene, reader);
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
		let ok = PrefabRoundTrip(source, dest, registry);
		Test.Assert(ok);
		Test.Assert(dest.EntityCount == 0);
	}

	[Test]
	public static void RoundTrip_SingleEntity()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();
		source.CreateEntity("Root");

		let ok = PrefabRoundTrip(source, dest, registry);
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


		let root = source.CreateEntity("Root");
		let child1 = source.CreateEntity("Child1");
		let child2 = source.CreateEntity("Child2");
		source.SetParent(child1, root);
		source.SetParent(child2, root);

		let ok = PrefabRoundTrip(source, dest, registry);
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


		let entity = source.CreateEntity("Warrior");
		let healthMgr = source.GetModule<HealthManager>();
		let handle = healthMgr.CreateComponent(entity);
		if (let comp = healthMgr.Get(handle))
		{
			comp.Health = 250;
			comp.Armor = 10;
		}

		let ok = PrefabRoundTrip(source, dest, registry);
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


		let entity = source.CreateEntity("Positioned");
		source.SetLocalTransform(entity, .()
		{
			Position = .(10, 20, 30),
			Rotation = .Identity,
			Scale = .(2, 2, 2)
		});

		let ok = PrefabRoundTrip(source, dest, registry);
		Test.Assert(ok);

		let destEntity = FindByName(dest,"Positioned");
		Test.Assert(destEntity.IsAssigned);

		let t = dest.GetLocalTransform(destEntity);
		Test.Assert(Math.Abs(t.Position.X - 10) < 0.001f);
		Test.Assert(Math.Abs(t.Position.Y - 20) < 0.001f);
		Test.Assert(Math.Abs(t.Position.Z - 30) < 0.001f);
		Test.Assert(Math.Abs(t.Scale.X - 2) < 0.001f);
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
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		prefabSerializer.Save(source, writer);

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

		let result = prefabSerializer.Instantiate(targetScene, parentEntity, reader);
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
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		prefabSerializer.Save(source, writer);

		let output = scope String();
		writer.GetOutput(output);

		let targetScene = scope Scene();
		let parent = targetScene.CreateEntity("Parent");

		let desc = scope SerializerDataDescription();
		Test.Assert(desc.ProcessText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;

		let result = prefabSerializer.Instantiate(targetScene, parent, reader);
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

}
