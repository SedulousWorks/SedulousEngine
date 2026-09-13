using System;
using System.Collections;
using Sedulous.Core;
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
}
