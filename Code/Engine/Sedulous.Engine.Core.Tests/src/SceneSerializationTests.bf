namespace Sedulous.Engine.Core.Tests;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.OpenDDL;

// ==================== Serializable test components ====================

class HealthComponent : Component, ISerializableComponent
{
	public float Health = 100;
	public int32 Armor = 0;
	public bool IsInvulnerable = false;

	public void Serialize(IComponentSerializer s)
	{
		s.Float("Health", ref Health);
		s.Int32("Armor", ref Armor);
		s.Bool("IsInvulnerable", ref IsInvulnerable);
	}

	public int32 SerializationVersion => 1;
}

class HealthManager : ComponentManager<HealthComponent>
{
	public override StringView SerializationTypeId => "Test.HealthComponent";
}

class TargetComponent : Component, ISerializableComponent
{
	public EntityRef Target = .();
	public float FollowDistance = 5.0f;

	public void Serialize(IComponentSerializer s)
	{
		s.EntityRef("Target", ref Target);
		s.Float("FollowDistance", ref FollowDistance);
	}

	public int32 SerializationVersion => 1;
}

class TargetManager : ComponentManager<TargetComponent>
{
	public override StringView SerializationTypeId => "Test.TargetComponent";
}

class NameTagComponent : Component, ISerializableComponent
{
	public String DisplayName = new .() ~ delete _;

	public void Serialize(IComponentSerializer s)
	{
		s.String("DisplayName", DisplayName);
	}

	public int32 SerializationVersion => 1;
}

class NameTagManager : ComponentManager<NameTagComponent>
{
	public override StringView SerializationTypeId => "Test.NameTagComponent";
}

struct Waypoint
{
	public float X, Y, Z;
	public float WaitTime;
}

class PatrolComponent : Component, ISerializableComponent
{
	public List<Waypoint> Waypoints = new .() ~ delete _;
	public float Speed = 5.0f;
	public bool Loop = true;

	public void Serialize(IComponentSerializer s)
	{
		s.Float("Speed", ref Speed);
		s.Bool("Loop", ref Loop);

		var count = (int32)Waypoints.Count;
		s.BeginArray("Waypoints", ref count);

		if (s.IsReading)
		{
			Waypoints.Clear();
			for (int32 i = 0; i < count; i++)
			{
				var wp = Waypoint();
				s.BeginObject("");
				s.Float("X", ref wp.X);
				s.Float("Y", ref wp.Y);
				s.Float("Z", ref wp.Z);
				s.Float("WaitTime", ref wp.WaitTime);
				s.EndObject();
				Waypoints.Add(wp);
			}
		}
		else
		{
			for (var wp in ref Waypoints)
			{
				s.BeginObject("");
				s.Float("X", ref wp.X);
				s.Float("Y", ref wp.Y);
				s.Float("Z", ref wp.Z);
				s.Float("WaitTime", ref wp.WaitTime);
				s.EndObject();
			}
		}

		s.EndArray();
	}

	public int32 SerializationVersion => 1;
}

class PatrolManager : ComponentManager<PatrolComponent>
{
	public override StringView SerializationTypeId => "Test.PatrolComponent";
}

// ==================== Tests ====================

class SceneSerializationTests
{
	private static ComponentTypeRegistry CreateRegistry()
	{
		let registry = new ComponentTypeRegistry();
		registry.Register("Test.HealthComponent", new () => new HealthManager());
		registry.Register("Test.TargetComponent", new () => new TargetManager());
		registry.Register("Test.NameTagComponent", new () => new NameTagManager());
		registry.Register("Test.PatrolComponent", new () => new PatrolManager());
		return registry;
	}

	private static bool RoundTrip(Scene sourceScene, Scene destScene, ComponentTypeRegistry registry)
	{
		let sceneSerializer = scope SceneSerializer(registry);

		// Save
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		sceneSerializer.Save(sourceScene, writer);

		let output = scope String();
		writer.GetOutput(output);

		// Load
		let desc = scope SerializerDataDescription();
		if (desc.ProcessText(output) != .Ok)
			return false;

		let reader = OpenDDLSerializer.CreateReader(desc);
		defer delete reader;
		sceneSerializer.Load(destScene, reader);
		return true;
	}

	// ---- Entity-only tests (no components) ----

	[Test]
	public static void RoundTrip_EmptyScene()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let dest = scope Scene();

		RoundTrip(source, dest, registry);
		Test.Assert(dest.EntityCount == 0);
	}

	[Test]
	public static void RoundTrip_SingleEntity()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let entity = source.CreateEntity("TestEntity");

		source.SetLocalTransform(entity, .()
		{
			Position = .(10, 20, 30),
			Rotation = .Identity,
			Scale = .(2, 2, 2)
		});

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		Test.Assert(dest.EntityCount == 1);

		EntityHandle found = .Invalid;
		for (let e in dest.Entities)
		{
			if (dest.GetEntityName(e) == "TestEntity")
				found = e;
		}
		Test.Assert(found.IsAssigned);

		dest.Update(0);
		let world = dest.GetWorldMatrix(found);
		Test.Assert(Math.Abs(world.M41 - 10) < 0.001f);
		Test.Assert(Math.Abs(world.M42 - 20) < 0.001f);
		Test.Assert(Math.Abs(world.M43 - 30) < 0.001f);
	}

	[Test]
	public static void RoundTrip_PreservesGuid()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let entity = source.CreateEntity("Player");
		let originalId = source.GetEntityId(entity);

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		let found = dest.FindEntity(originalId);
		Test.Assert(found.IsAssigned);
		Test.Assert(dest.GetEntityName(found) == "Player");
	}

	[Test]
	public static void RoundTrip_ParentChild()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let parent = source.CreateEntity("Parent");
		let child = source.CreateEntity("Child");
		source.SetParent(child, parent);

		source.SetLocalTransform(parent, .() { Position = .(100, 0, 0), Rotation = .Identity, Scale = .One });
		source.SetLocalTransform(child, .() { Position = .(10, 0, 0), Rotation = .Identity, Scale = .One });

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		Test.Assert(dest.EntityCount == 2);

		EntityHandle destParent = .Invalid;
		EntityHandle destChild = .Invalid;
		for (let e in dest.Entities)
		{
			if (dest.GetEntityName(e) == "Parent") destParent = e;
			if (dest.GetEntityName(e) == "Child") destChild = e;
		}
		Test.Assert(destParent.IsAssigned);
		Test.Assert(destChild.IsAssigned);
		Test.Assert(dest.GetParent(destChild) == destParent);

		dest.Update(0);
		Test.Assert(Math.Abs(dest.GetWorldMatrix(destParent).M41 - 100) < 0.001f);
		Test.Assert(Math.Abs(dest.GetWorldMatrix(destChild).M41 - 110) < 0.001f);
	}

	[Test]
	public static void RoundTrip_MultipleEntities()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		source.CreateEntity("A");
		source.CreateEntity("B");
		source.CreateEntity("C");

		let dest = scope Scene();
		RoundTrip(source, dest, registry);
		Test.Assert(dest.EntityCount == 3);
	}

	[Test]
	public static void RoundTrip_InactiveEntity()
	{
		let registry = CreateRegistry();
		defer delete registry;
		let source = scope Scene();
		let entity = source.CreateEntity("Inactive");
		source.SetActive(entity, false);

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		EntityHandle found = .Invalid;
		for (let e in dest.Entities)
			found = e;

		Test.Assert(found.IsAssigned);
		Test.Assert(!dest.IsActive(found));
	}

	// ---- Component serialization tests ----

	[Test]
	public static void RoundTrip_ComponentData()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let healthMgr = new HealthManager();
		source.AddModule(healthMgr);

		let entity = source.CreateEntity("Warrior");
		let handle = healthMgr.CreateComponent(entity);
		let comp = healthMgr.Get(handle);
		comp.Health = 75.5f;
		comp.Armor = 42;
		comp.IsInvulnerable = true;

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		// Find the entity
		let destEntity = dest.FindEntity(source.GetEntityId(entity));
		Test.Assert(destEntity.IsAssigned);

		// Registry should have created a HealthManager on dest
		let destMgr = dest.GetModule<HealthManager>();
		Test.Assert(destMgr != null);

		let destComp = destMgr.GetForEntity(destEntity);
		Test.Assert(destComp != null);
		Test.Assert(Math.Abs(destComp.Health - 75.5f) < 0.001f);
		Test.Assert(destComp.Armor == 42);
		Test.Assert(destComp.IsInvulnerable == true);
	}

	[Test]
	public static void RoundTrip_MultipleComponentTypes()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let healthMgr = new HealthManager();
		let nameTagMgr = new NameTagManager();
		source.AddModule(healthMgr);
		source.AddModule(nameTagMgr);

		let entity = source.CreateEntity("Hero");

		let hh = healthMgr.CreateComponent(entity);
		healthMgr.Get(hh).Health = 200;

		let nh = nameTagMgr.CreateComponent(entity);
		nameTagMgr.Get(nh).DisplayName.Set("Sir Lancelot");

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		let destEntity = dest.FindEntity(source.GetEntityId(entity));
		Test.Assert(destEntity.IsAssigned);

		let destHealth = dest.GetModule<HealthManager>()?.GetForEntity(destEntity);
		Test.Assert(destHealth != null);
		Test.Assert(Math.Abs(destHealth.Health - 200) < 0.001f);

		let destName = dest.GetModule<NameTagManager>()?.GetForEntity(destEntity);
		Test.Assert(destName != null);
		Test.Assert(destName.DisplayName.Equals("Sir Lancelot"));
	}

	[Test]
	public static void RoundTrip_EntityWithoutComponents()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let healthMgr = new HealthManager();
		source.AddModule(healthMgr);

		// Two entities: one with component, one without
		let withComp = source.CreateEntity("WithComp");
		healthMgr.CreateComponent(withComp);

		let withoutComp = source.CreateEntity("WithoutComp");

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		Test.Assert(dest.EntityCount == 2);

		let destMgr = dest.GetModule<HealthManager>();
		Test.Assert(destMgr != null);

		let destWithComp = dest.FindEntity(source.GetEntityId(withComp));
		let destWithout = dest.FindEntity(source.GetEntityId(withoutComp));

		Test.Assert(destMgr.GetForEntity(destWithComp) != null);
		Test.Assert(destMgr.GetForEntity(destWithout) == null);
	}

	[Test]
	public static void RoundTrip_EntityRef()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let targetMgr = new TargetManager();
		source.AddModule(targetMgr);

		let leader = source.CreateEntity("Leader");
		let follower = source.CreateEntity("Follower");

		let th = targetMgr.CreateComponent(follower);
		let tc = targetMgr.Get(th);
		tc.Target = EntityRef(source, leader);
		tc.FollowDistance = 3.0f;

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		let destFollower = dest.FindEntity(source.GetEntityId(follower));
		let destLeader = dest.FindEntity(source.GetEntityId(leader));
		Test.Assert(destFollower.IsAssigned);
		Test.Assert(destLeader.IsAssigned);

		let destMgr = dest.GetModule<TargetManager>();
		let destComp = destMgr?.GetForEntity(destFollower);
		Test.Assert(destComp != null);
		Test.Assert(Math.Abs(destComp.FollowDistance - 3.0f) < 0.001f);

		// EntityRef should have the right Guid, resolve it
		Test.Assert(destComp.Target.PersistentId == source.GetEntityId(leader));
		Test.Assert(destComp.Target.Resolve(dest));
		Test.Assert(destComp.Target.CachedHandle == destLeader);
	}

	[Test]
	public static void RoundTrip_ComponentWithParentChild()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let healthMgr = new HealthManager();
		source.AddModule(healthMgr);

		let parent = source.CreateEntity("Parent");
		let child = source.CreateEntity("Child");
		source.SetParent(child, parent);

		healthMgr.CreateComponent(parent);
		healthMgr.Get(healthMgr.CreateComponent(child)).Health = 50;

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		Test.Assert(dest.EntityCount == 2);

		let destParent = dest.FindEntity(source.GetEntityId(parent));
		let destChild = dest.FindEntity(source.GetEntityId(child));
		Test.Assert(dest.GetParent(destChild) == destParent);

		let destMgr = dest.GetModule<HealthManager>();
		Test.Assert(destMgr.GetForEntity(destParent) != null);

		let childComp = destMgr.GetForEntity(destChild);
		Test.Assert(childComp != null);
		Test.Assert(Math.Abs(childComp.Health - 50) < 0.001f);
	}

	[Test]
	public static void RoundTrip_ListField()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let patrolMgr = new PatrolManager();
		source.AddModule(patrolMgr);

		let guard = source.CreateEntity("Guard");
		let ph = patrolMgr.CreateComponent(guard);
		let pc = patrolMgr.Get(ph);
		pc.Speed = 3.5f;
		pc.Loop = false;
		pc.Waypoints.Add(.() { X = 0, Y = 0, Z = 0, WaitTime = 1.0f });
		pc.Waypoints.Add(.() { X = 10, Y = 0, Z = 0, WaitTime = 2.0f });
		pc.Waypoints.Add(.() { X = 10, Y = 0, Z = 10, WaitTime = 0.5f });

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		let destGuard = dest.FindEntity(source.GetEntityId(guard));
		Test.Assert(destGuard.IsAssigned);

		let destMgr = dest.GetModule<PatrolManager>();
		let destComp = destMgr?.GetForEntity(destGuard);
		Test.Assert(destComp != null);
		Test.Assert(Math.Abs(destComp.Speed - 3.5f) < 0.001f);
		Test.Assert(destComp.Loop == false);
		Test.Assert(destComp.Waypoints.Count == 3);

		Test.Assert(Math.Abs(destComp.Waypoints[0].X - 0) < 0.001f);
		Test.Assert(Math.Abs(destComp.Waypoints[0].WaitTime - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(destComp.Waypoints[1].X - 10) < 0.001f);
		Test.Assert(Math.Abs(destComp.Waypoints[1].WaitTime - 2.0f) < 0.001f);
		Test.Assert(Math.Abs(destComp.Waypoints[2].Z - 10) < 0.001f);
		Test.Assert(Math.Abs(destComp.Waypoints[2].WaitTime - 0.5f) < 0.001f);
	}

	[Test]
	public static void RoundTrip_EmptyList()
	{
		let registry = CreateRegistry();
		defer delete registry;

		let source = scope Scene();
		let patrolMgr = new PatrolManager();
		source.AddModule(patrolMgr);

		let guard = source.CreateEntity("IdleGuard");
		let ph = patrolMgr.CreateComponent(guard);
		patrolMgr.Get(ph).Speed = 1.0f;
		// No waypoints added - empty list

		let dest = scope Scene();
		RoundTrip(source, dest, registry);

		let destMgr = dest.GetModule<PatrolManager>();
		let destComp = destMgr?.GetForEntity(dest.FindEntity(source.GetEntityId(guard)));
		Test.Assert(destComp != null);
		Test.Assert(destComp.Waypoints.Count == 0);
		Test.Assert(Math.Abs(destComp.Speed - 1.0f) < 0.001f);
	}
}
