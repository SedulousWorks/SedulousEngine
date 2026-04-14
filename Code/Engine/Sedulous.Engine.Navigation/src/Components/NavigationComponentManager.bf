namespace Sedulous.Engine.Navigation;

using System;
using Sedulous.Scenes;
using Sedulous.Core.Mathematics;

/// Manages navigation agent components: creates/removes crowd agents,
/// processes move targets, syncs agent positions to entity transforms.
///
/// FixedUpdate: steps the crowd simulation.
/// Update: creates agents for new components, processes move targets,
///         syncs agent positions back to entity transforms.
class NavigationComponentManager : ComponentManager<NavAgentComponent>
{
	/// The navigation world for this scene (set by NavigationSubsystem).
	public NavWorld NavWorld { get; set; }

	public override StringView SerializationTypeId => "Sedulous.NavAgentComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterFixedUpdate(new => FixedUpdateNavigation);
		RegisterUpdate(.Update, new => UpdateNavigation);
	}

	/// Steps the crowd + tile cache at fixed timestep.
	private void FixedUpdateNavigation(float deltaTime)
	{
		if (NavWorld == null) return;
		NavWorld.Update(deltaTime);
	}

	/// Creates agents, processes move targets, syncs positions.
	private void UpdateNavigation(float deltaTime)
	{
		if (NavWorld == null) return;
		let scene = Scene;
		if (scene == null) return;
		let crowd = NavWorld.Crowd;
		if (crowd == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			// Create crowd agent if needed
			if (comp.NeedsAgentCreation && !comp.IsOnCrowd)
			{
				let worldMatrix = scene.GetWorldMatrix(comp.Owner);
				let position = worldMatrix.Translation;
				float[3] pos = .(position.X, position.Y, position.Z);

				var agentParams = CrowdAgentParams.Default;
				agentParams.Radius = comp.Radius;
				agentParams.Height = comp.Height;
				agentParams.MaxAcceleration = comp.MaxAcceleration;
				agentParams.MaxSpeed = comp.MaxSpeed;
				agentParams.CollisionQueryRange = comp.CollisionQueryRange;
				agentParams.PathOptimizationRange = comp.PathOptimizationRange;
				agentParams.SeparationWeight = comp.SeparationWeight;
				agentParams.ObstacleAvoidanceType = comp.ObstacleAvoidanceType;

				let agentIdx = crowd.AddAgent(pos, agentParams);
				if (agentIdx >= 0)
				{
					comp.CrowdAgentIndex = agentIdx;
					comp.NeedsAgentCreation = false;
				}
			}

			if (!comp.IsOnCrowd) continue;

			// Process move target request
			if (comp.MoveTarget.HasValue)
			{
				let target = comp.MoveTarget.Value;
				float[3] targetPos = .(target.X, target.Y, target.Z);
				NavWorld.RequestMoveTarget(comp.CrowdAgentIndex, targetPos);
				comp.MoveTarget = null;
			}

			// Sync agent position back to entity transform
			if (comp.SyncToTransform)
			{
				float[3] agentPos = ?;
				crowd.GetAgentPosition(comp.CrowdAgentIndex, out agentPos);
				var transform = scene.GetLocalTransform(comp.Owner);
				transform.Position = .(agentPos[0], agentPos[1], agentPos[2]);
				scene.SetLocalTransform(comp.Owner, transform);
			}
		}
	}

	protected override void OnComponentDestroyed(NavAgentComponent comp)
	{
		if (comp.IsOnCrowd && NavWorld != null && NavWorld.Crowd != null)
		{
			NavWorld.Crowd.RemoveAgent(comp.CrowdAgentIndex);
			comp.CrowdAgentIndex = -1;
		}
	}
}
