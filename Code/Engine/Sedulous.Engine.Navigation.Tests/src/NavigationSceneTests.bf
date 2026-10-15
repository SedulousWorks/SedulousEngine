using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Navigation;
using Sedulous.Navigation;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation.Tests;

/// A baked zone and an agent inside a live scene: the scene start loads the zone and registers
/// the agent, and the tick steers it and writes the steered position back.
class NavigationSceneTests
{
	/// Twelve seconds at thirty hertz, which is ample to cross the test zone.
	private const int cCrossingSteps = 360;
	private const float cStep = 1.0f / 30.0f;

	private static void Run(Scene scene, int steps, NavAgentComponent* until = null)
	{
		for (int i < steps)
		{
			if ((until != null) && until.Finished)
				return;
			scene.Update(cStep);
		}
	}

	/// The plain crossing: an agent that moves its entity walks the zone and reports arrival.
	[Test]
	public static void AMovingAgentNavigatesAcrossItsZone()
	{
		let fixture = scope NavigationSceneFixture("scratch_navscene_db");
		let zoneId = fixture.CookGroundZone("zone");

		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);

		// The scene system carries the debug settings block, off by default.
		let system = scene.GetSystem<NavigationSceneSystem>();
		Test.Assert(system != null);
		Test.Assert(system.SettingsType != null);
		Test.Assert(!system.Settings.DebugDraw);
		system.Settings.DebugDraw = true;
		Test.Assert(system.Settings.DebugDraw);

		let zoneEntity = scene.CreateEntity("zone");
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		Test.Assert(zone.Zone.Get != null);
		Test.Assert(zone.Zone.Get.IsValid);

		let agentEntity = scene.CreateEntity("agent");
		scene.SetLocalPosition(agentEntity, .(-5, 0, 0));
		let agent = scene.GetSystem<NavAgentComponentManager>().Add(agentEntity);

		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);

		// Registered with the zone and given a crowd slot.
		Test.Assert(agent.ZoneIndex >= 0);
		Test.Assert(agent.AgentId >= 0);

		agent.Navigate(.(5, 0, 0));
		Test.Assert(!agent.Finished);

		let start = scene.GetWorldPosition(agentEntity);
		Run(scene, cCrossingSteps, agent);

		let end = scene.GetWorldPosition(agentEntity);
		Test.Assert(agent.Finished);
		// It actually crossed the zone, and ended near the target.
		Test.Assert(end.X > start.X + 5.0f);
		Test.Assert(Math.Abs(end.X - 5.0f) < 1.5f);
		Test.Assert(agent.RemainingDistance < 1.0f);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// A zone re-baked while the scene runs (the editor cooks the new navmesh and reloads it
	/// under a playing scene): the crowd was built over the old navmesh, which the reload parks
	/// and then frees. The zone rebuilds its crowd over the new one and its agent carries on to
	/// where it was going. It used to keep stepping the old crowd over the freed navmesh (an
	/// editor crash in Raptor; ASan reports the use after free here without the rebuild).
	[Test]
	public static void AZonesNavmeshReloadedMidRunCarriesItsAgentOnOverTheNewOne()
	{
		let fixture = scope NavigationSceneFixture("scratch_navreload_db");
		let zoneId = fixture.CookGroundZone("zone");

		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zoneEntity = scene.CreateEntity("zone");
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		Test.Assert(zone.Zone.Get != null);

		let agentEntity = scene.CreateEntity("agent");
		scene.SetLocalPosition(agentEntity, .(-5, 0, 0));
		let agent = scene.GetSystem<NavAgentComponentManager>().Add(agentEntity);
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(agent.AgentId >= 0);

		// Part of the way.
		agent.Navigate(.(5, 0, 0));
		Run(scene, 45);
		let midway = scene.GetWorldPosition(agentEntity).X;
		Test.Assert(midway > -4.0f, scope $"it set off, at {midway}");
		Test.Assert(!agent.Finished);

		// Re-baked bigger and reloaded; the old navmesh parked, then freed for good, all before
		// the scene steps again.
		let before = zone.Zone.Get;
		fixture.WriteGroundZone(zoneId, 12.0f);
		fixture.Manager.Reload(zoneId);
		Test.Assert(zone.Zone.Get != null);
		Test.Assert(zone.Zone.Get !== before, "a new product");
		for (int frame < 16)
			fixture.Manager.CollectGarbage();

		Run(scene, cCrossingSteps, agent);
		let end = scene.GetWorldPosition(agentEntity);
		Test.Assert(agent.Finished, "it arrived");
		Test.Assert(Math.Abs(end.X - 5.0f) < 1.5f, scope $"where it was going, at {end.X}");
		Test.Assert(end.X > midway, "from where it had got to");

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// The bake and the runtime both use the scale free frame, so a zone on a SCALED entity
	/// behaves exactly as an unscaled one: the navmesh's world unit geometry is PLACED, never
	/// warped.
	[Test]
	public static void AScaledZoneEntityPlacesTheNavmeshRigidly()
	{
		let fixture = scope NavigationSceneFixture("scratch_navscene_scaled_db");
		let zoneId = fixture.CookGroundZone("zone");

		let scene = scope Scene("nav-scaled");
		NavigationScene.AddNavigationSceneManagers(scene);

		let zoneEntity = scene.CreateEntity("zone");
		{
			// The desynchronising scale, before the rigid frame.
			var transform = Transform();
			transform.Scale = .(2.0f, 2.0f, 2.0f);
			scene.SetLocalTransform(zoneEntity, transform);
		}

		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		Test.Assert(zone.Zone.Get != null);
		Test.Assert(zone.Zone.Get.IsValid);

		let agentEntity = scene.CreateEntity("agent");
		scene.SetLocalPosition(agentEntity, .(-5, 0, 0));
		let agent = scene.GetSystem<NavAgentComponentManager>().Add(agentEntity);

		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		// The scaled zone still loaded, because the frame dropped the scale.
		Test.Assert(agent.ZoneIndex >= 0);

		agent.Navigate(.(5, 0, 0));
		Run(scene, cCrossingSteps, agent);

		let end = scene.GetWorldPosition(agentEntity);
		Test.Assert(agent.Finished);
		// The same arrival as the unscaled zone, and ON the ground rather than floated or
		// sunk.
		Test.Assert(Math.Abs(end.X - 5.0f) < 1.5f);
		Test.Assert(Math.Abs(end.Y) < 0.5f);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// A per agent speed applies LIVE, and an arrival radius parks the agent on the ring
	/// rather than on the point.
	[Test]
	public static void SpeedAppliesLiveAndAnArrivalRadiusStopsShort()
	{
		let fixture = scope NavigationSceneFixture("scratch_navspeed_db");
		let zoneId = fixture.CookGroundZone("zone");

		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);

		let zoneEntity = scene.CreateEntity("zone");
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		Test.Assert(zone.Zone.Get != null);

		let agents = scene.GetSystem<NavAgentComponentManager>();

		// The SLOW agent: a lower speed covers less ground in the same steps.
		let slowEntity = scene.CreateEntity("slow");
		scene.SetLocalPosition(slowEntity, .(-5, 0, -2));
		let slow = agents.Add(slowEntity);

		// The ARRIVING agent: a stop distance parks it on the ring.
		let arriveEntity = scene.CreateEntity("arrive");
		scene.SetLocalPosition(arriveEntity, .(-5, 0, 2));
		let arrive = agents.Add(arriveEntity);

		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(slow.AgentId >= 0);
		Test.Assert(arrive.AgentId >= 0);

		// A live change: the tick pushes it into the crowd.
		slow.MaxSpeed = 0.8f;
		slow.Navigate(.(5, 0, -2));
		arrive.NavigateAt(.(5, 0, 2), 3.5f, 2.5f);

		// Three seconds.
		Run(scene, 90);

		// Three seconds at eight tenths of a unit a second cannot cross ten units, while the
		// default agent with a ring of two and a half has already parked.
		let slowPosition = scene.GetWorldPosition(slowEntity);
		Test.Assert(!slow.Finished);
		Test.Assert(slowPosition.X < 0.0f);
		Test.Assert(slowPosition.X > -4.5f);

		Test.Assert(arrive.Finished);
		let arrivePosition = scene.GetWorldPosition(arriveEntity);
		let dx = arrivePosition.X - 5.0f;
		let dz = arrivePosition.Z - 2.0f;
		let distance = Math.Sqrt(dx * dx + dz * dz);
		// Parked ON the ring, not on the point.
		Test.Assert(distance > 1.2f);
		Test.Assert(distance < 3.5f);
		Test.Assert(arrive.RemainingDistance > 1.2f);

		// The introspection cache: the moving agent reads as walking on a valid request with a
		// live speed intent, and the parked one has released its target.
		Test.Assert(slow.CrowdState == .Walking);
		Test.Assert(slow.CrowdTargetState == .Valid);
		Test.Assert(slow.CrowdDesiredSpeed > 0.0f);
		// Capped by the per agent speed.
		Test.Assert(slow.CrowdDesiredSpeed < 1.0f);
		Test.Assert(arrive.CrowdState == .Walking);
		// The arrival cleared it.
		Test.Assert(arrive.CrowdTargetState == .None);

		// Raising the speed mid run applies live, so it now finishes the crossing.
		slow.MaxSpeed = 6.0f;
		Run(scene, 240, slow);
		Test.Assert(slow.Finished);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// Records the warnings that reach it.
	private class WarningLog : BaseLogger
	{
		public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);
		public this() : base(.Warning, "Test") {}
		protected override void LogMessage(LogLevel level, StringView message) { Lines.Add(new String(message)); }

		public bool Has(StringView text)
		{
			for (let line in Lines)
			{
				if (line.Contains(text))
					return true;
			}
			return false;
		}
	}

	/// An agent that cannot join the navmesh, and a zone with no usable navmesh, say so: an
	/// agent that never moves is otherwise a mystery.
	[Test]
	public static void AnAgentOrAZoneThatCannotNavigateSaysSo()
	{
		let fixture = scope NavigationSceneFixture("scratch_navscene_warn_db");
		let zoneId = fixture.CookGroundZone("zone");

		let log = new WarningLog();
		InitGlobalLogger(log, true);
		defer ShutdownGlobalLogger();

		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zones = scene.GetSystem<NavMeshZoneComponentManager>();
		let agents = scene.GetSystem<NavAgentComponentManager>();

		// A baked zone over a 20 m ground, its box reaching 15 m.
		let baked = scene.CreateEntity("baked");
		let zone = zones.Add(baked);
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);

		// A zone with no asset, far away.
		let empty = scene.CreateEntity("empty");
		scene.SetLocalPosition(empty, .(100, 0, 0));
		zones.Add(empty).Extents = .(5, 5, 5);

		// On the ground (fine), inside the box off the ground, in the empty zone, and nowhere.
		let fine = scene.CreateEntity("fine");
		agents.Add(fine);
		let offMesh = scene.CreateEntity("offMesh");
		scene.SetLocalPosition(offMesh, .(13, 0, 13));
		agents.Add(offMesh);
		let inEmpty = scene.CreateEntity("inEmpty");
		scene.SetLocalPosition(inEmpty, .(100, 0, 0));
		agents.Add(inEmpty);
		let lost = scene.CreateEntity("lost");
		scene.SetLocalPosition(lost, .(-300, 0, 0));
		agents.Add(lost);

		scene.UpdateTransforms();
		scene.Start();

		Test.Assert(log.Has("navigation zone 'empty' has no usable navmesh"), "the empty zone says so");
		Test.Assert(log.Has("agent 'offMesh'") && log.Has("found no navmesh where it stands"), "the agent off the ground says so");
		Test.Assert(log.Has("agent 'inEmpty'") && log.Has("agent 'lost'"), "the agents in no usable zone say so");
		Test.Assert(!log.Has("'fine'") && !log.Has("'baked'"), "what works says nothing");
	}

	/// A zone's MaxAgents is how many agents its crowd moves: past the old fixed 128 for
	/// Masquerade's crowd, and only what it was given for a small zone.
	[Test]
	public static void AZonesMaxAgentsIsHowManyAgentsItsCrowdMoves()
	{
		let fixture = scope NavigationSceneFixture("scratch_navmax_db");
		let zoneId = fixture.Database.RootGroup.CreateInstance("zone", "Sedulous.Navigation.Resource.NavigationZoneSource").Id;
		fixture.WriteGroundZone(zoneId, 30.0f);

		int Joined(int32 limit, int count)
		{
			let scene = scope Scene("navmax");
			NavigationScene.AddNavigationSceneManagers(scene);
			let zoneEntity = scene.CreateEntity("zone");
			let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(zoneEntity);
			zone.Extents = .(35, 10, 35);
			zone.MaxAgents = limit;
			zone.Zone.SetId(zoneId);
			zone.Zone.Bind(fixture.Manager);
			let agents = scene.GetSystem<NavAgentComponentManager>();
			for (int i < count)
			{
				let e = scene.CreateEntity();
				scene.SetLocalPosition(e, .(-25.0f + (float)(i % 25) * 2.0f, 0, -25.0f + (float)(i / 25) * 2.0f));
				agents.Add(e).Radius = 0.3f;
			}
			scene.UpdateTransforms();
			scene.Start();
			int n = 0;
			agents.ForEach(scope [&](agent, entity) => { if (agent.AgentId >= 0) n++; });
			scene.Stop();
			return n;
		}
		Test.Assert(Joined(200, 150) == 150, "Masquerade's crowd: past the old fixed 128");
		Test.Assert(Joined(3, 5) == 3, "a small zone takes only what it was given");
	}

	/// A version 1 zone record (no agent limit) reads, leaving the limit as it was.
	[Test]
	public static void AVersionOneZoneRecordReadsWithTheDefaultAgentLimit()
	{
		let stream = scope MemoryStream();
		{
			// The version 1 fields, by hand: the extents, the bake profile and the zone.
			let writer = scope BinarySerializer(stream, .Write);
			var extents = Float3(20, 10, 20);
			writer.Key("extents");
			Sedulous.Core.Serialization.Serialize(writer, ref extents);
			for (let value in float[6](0.3f, 0.2f, 0.6f, 2.0f, 0.9f, 45.0f))
			{
				var v = value;
				SerializeValue(writer, "f", ref v);
			}
			var id = Guid();
			SerializeValue(writer, "zone", ref id);
			var trailing = 77u;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		reader.PushVersionScope(scope SerializedDataVersion[](.(TypeIdOf("navigation.Zone"), 1)));
		var zone = NavMeshZoneComponent();
		zone.MaxAgents = 7;
		zone.Serialize(reader);
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		reader.PopVersionScope();
		Test.Assert(reader.IsOk);
		Test.Assert(zone.MaxAgents == 7, "no maxAgents asked of a version 1 record");
		Test.Assert(Math.Abs(zone.AgentRadius - 0.6f) < 1e-4f);
		Test.Assert(trailing == 77, "nothing past the version 1 fields was consumed");
	}

	/// A warp puts the agent somewhere else at once (a respawn): moving its entity alone is
	/// undone, as the crowd owns the position. Warped mid walk, it stops where it lands, and
	/// walks on from there.
	[Test]
	public static void AWarpedAgentIsWhereItWasSentAndWalksOnFromThere()
	{
		let fixture = scope NavigationSceneFixture("scratch_navwarp_db");
		let zoneId = fixture.CookGroundZone("zone");

		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(scene.CreateEntity("zone"));
		zone.Extents = .(15, 10, 15);
		// One slot: the warp gives its slot back before it takes one, so even the agent of a
		// full crowd warps.
		zone.MaxAgents = 1;
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		let agentEntity = scene.CreateEntity("agent");
		scene.SetLocalPosition(agentEntity, .(-5, 0, 0));
		let agent = scene.GetSystem<NavAgentComponentManager>().Add(agentEntity);
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(agent.AgentId >= 0);

		// Walking east, it is warped to the far corner: there next tick, stopped.
		agent.Navigate(.(5, 0, 0));
		Run(scene, 10);
		agent.Warp(.(6, 0, 6));
		scene.Update(cStep);
		var at = scene.GetWorldPosition(agentEntity);
		Test.Assert((Math.Abs(at.X - 6.0f) < 0.3f) && (Math.Abs(at.Z - 6.0f) < 0.3f), scope $"warped to ({at.X}, {at.Z})");
		Test.Assert(agent.Finished);
		// And it stays there: the crowd holds it where it was sent, not where it was.
		Run(scene, 15);
		at = scene.GetWorldPosition(agentEntity);
		Test.Assert((Math.Abs(at.X - 6.0f) < 0.3f) && (Math.Abs(at.Z - 6.0f) < 0.3f), scope $"held at ({at.X}, {at.Z})");

		// From there it walks on to a new target.
		agent.Navigate(.(6, 0, -6));
		Run(scene, cCrossingSteps, agent);
		at = scene.GetWorldPosition(agentEntity);
		Test.Assert(agent.Finished);
		Test.Assert(Math.Abs(at.Z + 6.0f) < 1.5f, scope $"walked on to z {at.Z}");

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// The scene, zone and one agent at (-5, 0, 0) the moving tests share, started and
	/// simulating.
	private static NavAgentComponent* StartWithAgent(NavigationSceneFixture fixture, Guid zoneId, Scene scene,
		out EntityHandle agentEntity)
	{
		NavigationScene.AddNavigationSceneManagers(scene);
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(scene.CreateEntity("zone"));
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		agentEntity = scene.CreateEntity("agent");
		scene.SetLocalPosition(agentEntity, .(-5, 0, 0));
		return scene.GetSystem<NavAgentComponentManager>().Add(agentEntity);
	}

	/// Move(vx, vz): an agent driven by a velocity (a player's stick) instead of to a point. No
	/// path is planned, so it starts the frame it is asked, keeps the speed asked, and stands on
	/// Move(0, 0).
	[Test]
	public static void AnAgentMovedByAVelocityGoesAtOnceAtThatSpeed()
	{
		let fixture = scope NavigationSceneFixture("scratch_navmove_db");
		let zoneId = fixture.CookGroundZone("zone");
		let scene = scope Scene("nav");
		let agent = StartWithAgent(fixture, zoneId, scene, let agentEntity);
		agent.MaxSpeed = 3.0f;
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(agent.AgentId >= 0);

		// East at 1.5 m/s: moving within a few frames, then 1.5 m a second.
		for (int step < 3)
		{
			agent.Move(1.5f, 0.0f);
			scene.Update(cStep);
		}
		Test.Assert(scene.GetWorldPosition(agentEntity).X > -5.0f + 0.01f, "moving at once");
		let before = scene.GetWorldPosition(agentEntity).X;
		for (int step < 60)
		{
			agent.Move(1.5f, 0.0f);
			scene.Update(cStep);
		}
		let travelled = scene.GetWorldPosition(agentEntity).X - before;
		Test.Assert(Math.Abs(travelled - 3.0f) < 0.3f, scope $"two seconds at 1.5 m/s went {travelled}");
		Test.Assert(Math.Abs(scene.GetWorldPosition(agentEntity).Z) < 0.1f);

		// Move(0, 0): it stands where it is, still in the crowd.
		for (int step < 30)
		{
			agent.Move(0.0f, 0.0f);
			scene.Update(cStep);
		}
		let stood = scene.GetWorldPosition(agentEntity).X;
		Run(scene, 15);
		Test.Assert(Math.Abs(scene.GetWorldPosition(agentEntity).X - stood) < 0.02f);
		Test.Assert(agent.AgentId >= 0);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// A version 2 agent record (no Avoid Others) reads as one that avoids others, as all did.
	[Test]
	public static void AVersionTwoAgentRecordReadsAsOneThatAvoidsOthers()
	{
		let stream = scope MemoryStream();
		{
			// The version 2 fields, by hand.
			let writer = scope BinarySerializer(stream, .Write);
			for (let value in float[4](0.3f, 1.7f, 3.0f, 6.0f))
			{
				var v = value;
				SerializeValue(writer, "f", ref v);
			}
			var moveEntity = true;
			SerializeValue(writer, "moveEntity", ref moveEntity);
			var stopDistance = 0.0f;
			SerializeValue(writer, "stopDistance", ref stopDistance);
			var trailing = 77u;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		reader.PushVersionScope(scope SerializedDataVersion[](.(TypeIdOf("navigation.Agent"), 2)));
		var agent = NavAgentComponent();
		agent.AvoidOthers = false;
		agent.Serialize(reader);
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		reader.PopVersionScope();
		Test.Assert(reader.IsOk);
		Test.Assert(!agent.AvoidOthers, "no avoidOthers asked of a version 2 record: left as it was");
		Test.Assert(Math.Abs(agent.Radius - 0.3f) < 1e-4f);
		Test.Assert(trailing == 77, "nothing past the version 2 fields was consumed");
		Test.Assert(NavAgentComponent().AvoidOthers, "and a fresh agent, which a load starts from, avoids others");
	}

	/// How far off its line a walker driven east past a standing agent strays, the least gap
	/// between them, and where it ends up.
	private struct PassRun
	{
		public float Stray = 0.0f;
		public float Closest = 100.0f;
		public float EndX = 0.0f;
	}

	/// `live`: avoidance set after the start, as an inspector edit or a script changes it while
	/// the agent is in its crowd.
	private static PassRun WalkPast(NavigationSceneFixture fixture, Guid zoneId, bool avoidOthers, bool live = false)
	{
		let scene = scope Scene("nav");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(scene.CreateEntity("zone"));
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		let agents = scene.GetSystem<NavAgentComponentManager>();
		let standing = scene.CreateEntity("standing");
		// A little off the line, as people are.
		scene.SetLocalPosition(standing, .(0, 0, 0.15f));
		agents.Add(standing).Radius = 0.4f;
		let walker = scene.CreateEntity("walker");
		scene.SetLocalPosition(walker, .(-4, 0, 0));
		var w = agents.Add(walker);
		w.Radius = 0.4f;
		if (!live)
			w.AvoidOthers = avoidOthers;
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		if (live)
			agents.Get(walker).AvoidOthers = avoidOthers;
		var run = PassRun();
		// Five seconds at thirty hertz, at 1.5 m/s.
		for (int step < 150)
		{
			w = agents.Get(walker);
			w.Move(1.5f, 0.0f);
			scene.Update(cStep);
			let p = scene.GetWorldPosition(walker);
			let q = scene.GetWorldPosition(standing);
			run.Stray = Math.Max(run.Stray, Math.Abs(p.Z));
			run.Closest = Math.Min(run.Closest, Math.Sqrt((p.X - q.X) * (p.X - q.X) + (p.Z - q.Z) * (p.Z - q.Z)));
		}
		run.EndX = scene.GetWorldPosition(walker).X;
		scene.SetSimulationEnabled(false);
		scene.Stop();
		return run;
	}

	/// Avoid Others: a velocity driven agent that avoids others holds back from one standing in
	/// its way (Detour's avoidance will not close on it: to a player, an invisible wall); one
	/// that does not shoulders past, the crowd's collision step pushing the two apart.
	[Test]
	public static void AnAgentThatDoesNotAvoidOthersShouldersPastOneInItsWay()
	{
		let fixture = scope NavigationSceneFixture("scratch_navavoid_db");
		let zoneId = fixture.CookGroundZone("zone");
		let avoiding = WalkPast(fixture, zoneId, true);
		let straight = WalkPast(fixture, zoneId, false);
		Test.Assert(avoiding.Closest > 1.0f, scope $"held back, short of the one in its way (closest {avoiding.Closest})");
		Test.Assert(avoiding.EndX < 0.0f, scope $"and never got past it (ended at {avoiding.EndX})");
		Test.Assert(straight.EndX > 1.0f, scope $"past it (ended at {straight.EndX})");
		Test.Assert(straight.Closest > 0.3f, scope $"brushing it aside, not through its middle (closest {straight.Closest})");
		Test.Assert(straight.Stray < 0.5f, scope $"near its line (strayed {straight.Stray})");
		// Turned off while it is in its crowd, it goes straight past as well.
		let turnedOff = WalkPast(fixture, zoneId, false, true);
		Test.Assert(turnedOff.EndX > 1.0f, scope $"turned off live, past it (ended at {turnedOff.EndX})");
	}

	/// An agent added after the scene starts (a spawned prefab's, a network spawn's) joins the
	/// crowd on the next update, and a destroyed one leaves it: in a zone that takes one agent,
	/// the first, gone, makes room for a second added later, which then walks.
	[Test]
	public static void AnAgentAddedLaterJoinsItsCrowdAndADestroyedOneLeavesIt()
	{
		let fixture = scope NavigationSceneFixture("scratch_navlate_db");
		let zoneId = fixture.CookGroundZone("zone");
		let scene = scope Scene("navlate");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(scene.CreateEntity("zone"));
		zone.Extents = .(15, 10, 15);
		// Room for one.
		zone.MaxAgents = 1;
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		let agents = scene.GetSystem<NavAgentComponentManager>();
		let first = scene.CreateEntity("first");
		scene.SetLocalPosition(first, .(-5, 0, 0));
		agents.Add(first);
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert(agents.Get(first).AgentId >= 0);

		scene.DestroyEntity(first);
		// Its slot is given back.
		scene.Update(cStep);

		let second = scene.CreateEntity("second");
		scene.SetLocalPosition(second, .(-5, 0, 2));
		agents.Add(second);
		scene.UpdateTransforms();
		// It joins.
		scene.Update(cStep);
		Test.Assert(agents.Get(second).AgentId >= 0, "the late agent joined the crowd the first left");

		agents.Get(second).Navigate(.(5, 0, 2));
		for (int step < cCrossingSteps)
		{
			if (agents.Get(second).Finished)
				break;
			scene.Update(cStep);
		}
		Test.Assert(agents.Get(second).Finished);
		Test.Assert(Math.Abs(scene.GetWorldPosition(second).X - 5.0f) < 1.5f);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}

	/// A destroyed agent's slot is freed in the crowd it was taken in. Destroyed in the frame its
	/// zone's navmesh reloads, the crowd is rebuilt with the agents left re-added from slot
	/// nought, so freeing the old number after the rebuild would take out whoever holds it now.
	[Test]
	public static void ADestroyedAgentsSlotIsFreedBeforeAReloadRebuildsItsCrowd()
	{
		let fixture = scope NavigationSceneFixture("scratch_navgone_db");
		let zoneId = fixture.CookGroundZone("zone");
		let scene = scope Scene("navgone");
		NavigationScene.AddNavigationSceneManagers(scene);
		let zone = scene.GetSystem<NavMeshZoneComponentManager>().Add(scene.CreateEntity("zone"));
		zone.Extents = .(15, 10, 15);
		zone.Zone.SetId(zoneId);
		zone.Zone.Bind(fixture.Manager);
		let agents = scene.GetSystem<NavAgentComponentManager>();
		let gone = scene.CreateEntity("gone");
		scene.SetLocalPosition(gone, .(-5, 0, -2));
		agents.Add(gone);
		let walker = scene.CreateEntity("walker");
		scene.SetLocalPosition(walker, .(-5, 0, 2));
		agents.Add(walker);
		scene.UpdateTransforms();
		scene.Start();
		scene.SetSimulationEnabled(true);
		Test.Assert((agents.Get(gone).AgentId == 0) && (agents.Get(walker).AgentId == 1));
		agents.Get(walker).Navigate(.(5, 0, 2));
		Run(scene, 10);

		scene.DestroyEntity(gone);
		fixture.WriteGroundZone(zoneId, 12.0f);
		fixture.Manager.Reload(zoneId);
		for (int frame < 16)
			fixture.Manager.CollectGarbage();

		Run(scene, cCrossingSteps, agents.Get(walker));
		Test.Assert(agents.Get(walker).Finished, "the one left still walks");
		Test.Assert(Math.Abs(scene.GetWorldPosition(walker).X - 5.0f) < 1.5f);

		scene.SetSimulationEnabled(false);
		scene.Stop();
	}
}
