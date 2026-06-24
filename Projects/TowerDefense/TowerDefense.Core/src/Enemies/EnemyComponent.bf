namespace TowerDefense;

using Sedulous.Engine.Core;

/// Component attached to enemy entities. Tracks health, movement along waypoints.
class EnemyComponent : Component
{
	public EnemyType Type;
	public float MaxHealth;
	public float CurrentHealth;
	public float Speed;
	public int32 Reward;

	/// Current target waypoint index in the path.
	public int32 WaypointIndex;

	/// Total distance traveled along the path (for tower targeting priority).
	public float DistanceAlongPath;
}
