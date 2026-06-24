namespace TowerDefense;

using Sedulous.Engine.Core;

/// Component attached to projectile entities.
class ProjectileComponent : Component
{
	public int32 Damage;
	public float Speed = 15.0f;
	public EntityHandle TargetEntity = .Invalid;
	public float Lifetime = 3.0f;
	public float Age;

	/// Last known direction (used if target dies mid-flight).
	public Sedulous.Core.Mathematics.Vector3 LastDirection;
}
