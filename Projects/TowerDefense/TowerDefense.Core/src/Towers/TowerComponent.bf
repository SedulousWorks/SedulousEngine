namespace TowerDefense;

using Sedulous.Engine.Core;

/// Component attached to tower entities. Tracks type, level, targeting, and fire cooldown.
class TowerComponent : Component
{
	public TowerType Type;
	public int32 Level = 1;
	public float Damage;
	public float Range;
	public float FireRate;      // shots per second
	public float FireCooldown;  // time until next shot

	/// Current target enemy entity. Invalid if no target.
	public EntityHandle TargetEntity = .Invalid;

	/// Grid position of this tower.
	public int32 GridX;
	public int32 GridZ;

	/// Child entity holding the weapon model (for rotation).
	public EntityHandle WeaponEntity = .Invalid;

	/// Projectile spawn point entity (child of weapon). Positioned in prefab via editor.
	public EntityHandle SpawnPointEntity = .Invalid;

	/// Total gold invested in this tower (initial cost + all upgrades). Used for sell refund.
	public int32 TotalInvested;
}
