namespace Sedulous.Engine.Navigation;

using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;

/// Component for a navigation agent on the crowd.
/// The NavigationComponentManager creates crowd agents from these components,
/// syncs positions to entity transforms, and processes move targets.
class NavAgentComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.Bool("SyncToTransform", ref SyncToTransform);
		s.Float("Radius", ref Radius);
		s.Float("Height", ref Height);
		s.Float("MaxAcceleration", ref MaxAcceleration);
		s.Float("MaxSpeed", ref MaxSpeed);
		s.Float("CollisionQueryRange", ref CollisionQueryRange);
		s.Float("PathOptimizationRange", ref PathOptimizationRange);
		s.Float("SeparationWeight", ref SeparationWeight);
		var oaType = (int32)ObstacleAvoidanceType;
		s.Int32("ObstacleAvoidanceType", ref oaType);
		if (s.IsReading) ObstacleAvoidanceType = (uint8)oaType;
	}

	// --- Configuration ---

	/// Whether to sync agent position back to entity transform.
	public bool SyncToTransform = true;

	/// Agent radius.
	public float Radius = 0.6f;

	/// Agent height.
	public float Height = 2.0f;

	/// Maximum acceleration.
	public float MaxAcceleration = 8.0f;

	/// Maximum speed.
	public float MaxSpeed = 3.5f;

	/// Collision query range.
	public float CollisionQueryRange = 12.0f;

	/// Path optimization range.
	public float PathOptimizationRange = 30.0f;

	/// Separation weight between agents.
	public float SeparationWeight = 2.0f;

	/// Obstacle avoidance quality level (0-3).
	public uint8 ObstacleAvoidanceType = 3;

	// --- Runtime state (managed by NavigationComponentManager) ---

	/// Index of this agent in the CrowdManager (-1 = not added).
	public int32 CrowdAgentIndex = -1;

	/// Whether this agent needs to be added to the crowd.
	public bool NeedsAgentCreation = true;

	/// Move target position (null = no active target).
	public Vector3? MoveTarget;

	/// Whether the agent is currently on the crowd.
	public bool IsOnCrowd => CrowdAgentIndex >= 0;
}
