using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Navigation;
using Sedulous.Navigation.Resource;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// The per scene navigation runtime.
///
/// When the scene starts it loads every zone's cooked navmesh into a live zone, one crowd and
/// one query each, and registers every agent with the zone whose box contains it. Each update
/// it applies the pending destinations and halts, steps every crowd, and writes the steered
/// position back for the agents that move their entity.
///
/// Zones bake in ZONE LOCAL space, so positions and targets transform through the zone
/// entity's frame on the way in and out.
///
/// SIMULATION ONLY: it does nothing in an editor's edit mode.
class NavigationSceneSystem : SceneSystem
{
	/// What one crowd holds.
	private const int32 cMaxAgentsPerZone = 128;

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	private List<NavigationRuntimeZone> mZones = new .() ~ DeleteContainerAndItems!(_);
	private NavigationSceneSettings mSettings = .();
	private NavigationBakeStageCache mBakeStages = new .() ~ delete _;

	public override bool IsSimulationOnly => true;

	/// The gameplay phase: the crowds step BEFORE animation and extraction read transforms.
	public override int32 UpdateOrder => -100;

	public override Type SettingsType => typeof(NavigationSceneSettings);
	public override void* SettingsInstance => &mSettings;
	public override StringView SettingsId => "navigation";

	public override void SerializeSettings(ISerializer ar)
	{
		mSettings.Serialize(ar);
	}

	public NavigationSceneSettings* Settings => &mSettings;

	/// The last bake's capture, which the overlay draws when its flag is on. TRANSIENT.
	public NavigationBakeStageCache BakeStages => mBakeStages;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	public override void OnSceneStarted()
	{
		if (mScene == null)
			return;

		// The zone load and the crowd construction, which happen once.
		using (ProfileScope("Navigation.Build"))
		{
			BuildZones();
			RegisterAgents();
		}
	}

	public override void OnSceneStopped()
	{
		ClearAndDeleteItems!(mZones);

		if (mScene == null)
			return;

		if (let agents = mScene.GetSystem<NavAgentComponentManager>())
		{
			agents.ForEach(scope (agent, entity) =>
				{
					agent.AgentId = -1;
					agent.ZoneIndex = -1;
					agent.HasTarget = false;
					agent.Finished = true;
				});
		}

		if (let zones = mScene.GetSystem<NavMeshZoneComponentManager>())
		{
			zones.ForEach(scope (zone, entity) =>
				{
					zone.RuntimeIndex = -1;
				});
		}
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (mScene == null) || mZones.IsEmpty)
			return;

		let agents = mScene.GetSystem<NavAgentComponentManager>();
		if (agents == null)
			return;

		using (ProfileScope("Navigation.Update"))
		{
			// Nought: a zone whose navmesh was re-baked and reloaded since its crowd was built
			// gets a crowd over the new one, before anything steps the old.
			RebuildReloadedZones(agents);

			// One: apply the pending requests. The crowd works in ZONE LOCAL space.
			agents.ForEach(scope (agent, entity) =>
				{
					ApplyRequests(agent);
				});

			// Two: step every crowd.
			using (ProfileScope("Navigation.Crowd"))
			{
				for (let zone in mZones)
				{
					if (zone.Crowd != null)
						zone.Crowd.Update(deltaTime);
				}
			}

			// Three: read back the world position and velocity, write the transform, and
			// settle the status.
			agents.ForEach(scope (agent, entity) =>
				{
					ReadBack(agent, entity);
				});
		}
	}

	private void ApplyRequests(NavAgentComponent* agent)
	{
		if ((agent.ZoneIndex < 0) || (agent.AgentId < 0))
			return;

		let zone = mZones[agent.ZoneIndex];
		if (zone.Crowd == null)
			return;

		// A live steering change, from a script or an inspector, pushes into the crowd. VALUE
		// COMPARED, so an unchanged agent costs two float compares.
		if ((agent.MaxSpeed != agent.AppliedSpeed)
			|| (agent.MaxAcceleration != agent.AppliedAcceleration))
		{
			var parameters = NavigationAgentParams();
			parameters.Radius = agent.Radius;
			parameters.Height = agent.Height;
			parameters.MaxSpeed = agent.MaxSpeed;
			parameters.MaxAcceleration = agent.MaxAcceleration;
			zone.Crowd.SetAgentParams(agent.AgentId, parameters);
			agent.AppliedSpeed = agent.MaxSpeed;
			agent.AppliedAcceleration = agent.MaxAcceleration;
		}

		if (agent.TargetDirty)
		{
			zone.Crowd.SetTarget(agent.AgentId,
				TransformPoint(agent.Target, zone.InverseWorld));
			agent.TargetDirty = false;
		}

		if (agent.StopRequested)
		{
			zone.Crowd.ClearTarget(agent.AgentId);
			agent.StopRequested = false;
		}
	}

	private void ReadBack(NavAgentComponent* agent, EntityHandle entity)
	{
		if ((agent.ZoneIndex < 0) || (agent.AgentId < 0))
			return;

		let zone = mZones[agent.ZoneIndex];
		if (zone.Crowd == null)
			return;
		let localPosition = zone.Crowd.AgentPosition(agent.AgentId);
		let localVelocity = zone.Crowd.AgentVelocity(agent.AgentId);
		let worldPosition = TransformPoint(localPosition, zone.World);
		agent.DesiredVelocity = TransformDirection(localVelocity, zone.World);

		// The introspection cache: the crowd's own view, which is what answers "why is this
		// agent not moving" without opening anything.
		let state = zone.Crowd.AgentState(agent.AgentId);
		agent.CrowdState = state.State;
		agent.CrowdTargetState = state.TargetState;
		agent.CrowdDesiredSpeed = state.DesiredSpeed;
		agent.PathCorners = state.CornerCount;

		if (agent.MoveEntity && agent.HasTarget)
		{
			// Assumes an UNPARENTED agent, where the local transform is the world one. A
			// parented one would need the world to parent conversion.
			var transform = mScene.GetLocalTransform(entity);
			transform.Position = worldPosition;
			mScene.SetLocalTransform(entity, transform);
		}

		if (!agent.HasTarget)
			return;

		let dx = worldPosition.X - agent.Target.X;
		let dz = worldPosition.Z - agent.Target.Z;
		agent.RemainingDistance = Math.Sqrt(dx * dx + dz * dz);

		let wasFinished = agent.Finished;
		agent.Finished = agent.RemainingDistance < (agent.Radius + 0.1f + agent.StopDistance);

		// On reaching the arrival ring, STOP steering: the crowd would otherwise keep pushing
		// the agent onto the exact point the radius existed to keep it away from. Navigating
		// again re-arms it.
		if (!wasFinished && agent.Finished && (agent.StopDistance > 0.0f))
			zone.Crowd.ClearTarget(agent.AgentId);
	}

	private void BuildZones()
	{
		let zones = mScene.GetSystem<NavMeshZoneComponentManager>();
		if (zones == null)
			return;

		zones.ForEach(scope (zone, entity) =>
			{
				let product = zone.Zone.Get;
				if ((product == null) || !product.IsValid)
				{
					zone.RuntimeIndex = -1;
					// Said, not silent: every agent in it would only report standing in no zone.
					GlobalLog(.Warning, "Navigation: navigation zone '{}' has no usable navmesh (no asset, not baked, or it did not load); agents in it will not move",
						mScene.GetEntityName(entity));
					return;
				}

				let runtime = new NavigationRuntimeZone();
				// RIGID, with the scale dropped, which is the frame the bake used.
				runtime.World = RigidPart(mScene.GetWorldMatrix(entity));
				runtime.InverseWorld = Inverse(runtime.World);
				runtime.Center = mScene.GetWorldPosition(entity);
				runtime.Extents = zone.Extents;
				runtime.Entity = entity;
				BuildCrowd(runtime, product);

				zone.RuntimeIndex = (int32)mZones.Count;
				mZones.Add(runtime);
			});
	}

	private void RegisterAgents()
	{
		let agents = mScene.GetSystem<NavAgentComponentManager>();
		if (agents == null)
			return;

		agents.ForEach(scope (agent, entity) =>
			{
				let worldPosition = mScene.GetWorldPosition(entity);
				agent.ZoneIndex = FindZoneContaining(worldPosition);
				agent.AgentId = -1;
				if (agent.ZoneIndex < 0)
				{
					// Said, not silent: an agent that never moves is otherwise a mystery.
					GlobalLog(.Warning, "Navigation: agent '{}' at ({}, {}, {}) is in no navigation zone; it will not move",
						mScene.GetEntityName(entity), worldPosition.X, worldPosition.Y, worldPosition.Z);
					return;
				}

				let zone = mZones[agent.ZoneIndex];
				agent.AgentId = AddToCrowd(zone, agent, worldPosition);
				if (agent.AgentId < 0)
				{
					GlobalLog(.Warning, "Navigation: agent '{}' at ({}, {}, {}): the zone's crowd is full; it will not move",
						mScene.GetEntityName(entity), worldPosition.X, worldPosition.Y, worldPosition.Z);
				}
				else if (zone.Crowd.AgentState(agent.AgentId).State == .Invalid)
				{
					// The crowd still adds an agent it could not place, in a state that never moves,
					// so the slot alone says nothing.
					GlobalLog(.Warning, "Navigation: agent '{}' at ({}, {}, {}) found no navmesh where it stands; it will not move (is it on baked ground, and was the zone baked?)",
						mScene.GetEntityName(entity), worldPosition.X, worldPosition.Y, worldPosition.Z);
				}
			});
	}

	/// The crowd and the query over `product`'s navmesh, which the zone then remembers.
	private void BuildCrowd(NavigationRuntimeZone zone, NavigationZoneResource product)
	{
		zone.BuiltFrom = product;
		let radius = (product.Mesh.BakedAgentRadius > 0.0f) ? product.Mesh.BakedAgentRadius : 0.6f;
		zone.Crowd = new NavigationCrowd(product.Mesh, cMaxAgentsPerZone, radius);
		zone.Query = new NavigationMeshQuery(product.Mesh);
	}

	/// An agent into a zone's crowd at `worldPosition` with its own steering profile: its
	/// slot, or minus one.
	private int32 AddToCrowd(NavigationRuntimeZone zone, NavAgentComponent* agent, Float3 worldPosition)
	{
		var parameters = NavigationAgentParams();
		parameters.Radius = agent.Radius;
		parameters.Height = agent.Height;
		parameters.MaxSpeed = agent.MaxSpeed;
		parameters.MaxAcceleration = agent.MaxAcceleration;
		// The live change compare starts in step.
		agent.AppliedSpeed = agent.MaxSpeed;
		agent.AppliedAcceleration = agent.MaxAcceleration;
		return zone.Crowd.AddAgent(TransformPoint(worldPosition, zone.InverseWorld), parameters);
	}

	/// Each zone whose reference now resolves to a different product than its crowd was built
	/// over: a re-bake reloaded while the scene runs. The crowd and the query borrow the
	/// navmesh, and the old product is freed a few frames after the swap, so they go now. A
	/// usable new navmesh gets a new crowd and query, the zone's agents added back where they
	/// stand and their destinations sent again; an unusable one (a failed reload) leaves the
	/// zone without a crowd, its agents still, until a usable one lands.
	private void RebuildReloadedZones(NavAgentComponentManager agents)
	{
		let zones = mScene.GetSystem<NavMeshZoneComponentManager>();
		if (zones == null)
			return;

		for (int i < mZones.Count)
		{
			let runtime = mZones[i];
			let component = zones.Get(runtime.Entity);
			let now = (component != null) ? component.Zone.Get : null;
			if (now === runtime.BuiltFrom)
				continue;

			// The old crowd and query go before the product they read.
			DeleteAndNullify!(runtime.Query);
			DeleteAndNullify!(runtime.Crowd);
			runtime.BuiltFrom = null;
			let usable = (now != null) && now.IsValid;
			if (usable)
				BuildCrowd(runtime, now);

			let zoneIndex = (int32)i;
			agents.ForEach(scope [&] (agent, entity) =>
				{
					if (agent.ZoneIndex != zoneIndex)
						return;
					agent.AgentId = usable ? AddToCrowd(runtime, agent, mScene.GetWorldPosition(entity)) : -1;
					// On its way again.
					agent.TargetDirty = agent.HasTarget && !agent.Finished;
				});
		}
	}

	/// The FIRST zone whose world space box contains the point, or minus one.
	private int32 FindZoneContaining(Float3 worldPosition)
	{
		for (int i < mZones.Count)
		{
			let zone = mZones[i];
			if ((Math.Abs(worldPosition.X - zone.Center.X) <= zone.Extents.X)
				&& (Math.Abs(worldPosition.Y - zone.Center.Y) <= zone.Extents.Y)
				&& (Math.Abs(worldPosition.Z - zone.Center.Z) <= zone.Extents.Z))
				return (int32)i;
		}
		return -1;
	}
}
