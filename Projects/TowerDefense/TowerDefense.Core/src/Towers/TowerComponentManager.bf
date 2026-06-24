namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;

/// Manages tower components: acquires targets, rotates weapons, fires projectiles.
class TowerComponentManager : ComponentManager<TowerComponent>
{
	public MessageBus Bus;
	public EnemyComponentManager EnemyMgr;
	public ProjectileComponentManager ProjectileMgr;
	public float GameSpeed = 1.0f;

	public override StringView SerializationTypeId => "TowerDefense.TowerComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostTransform, new => UpdateTowers, simulationOnly: true);
	}

	private void UpdateTowers(float deltaTime)
	{
		let scene = Scene;
		if (scene == null || EnemyMgr == null)
			return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.Initialized)
				continue;

			// Resolve weapon and spawn point entities from prefab children (deferred instantiation)
			if (!scene.IsValid(comp.WeaponEntity))
			{
				let children = scope List<EntityHandle>();
				scene.GetChildren(comp.Owner, children);
				for (let child in children)
					FindNamedChildren(scene, child, comp);
			}

			// Decrement fire cooldown (scaled by game speed)
			comp.FireCooldown -= deltaTime * GameSpeed;

			// Acquire or validate target
			let towerPos = scene.GetWorldMatrix(comp.Owner).Translation;
			AcquireTarget(comp, towerPos, scene);

			// Rotate weapon child toward target
			if (scene.IsValid(comp.TargetEntity) && scene.IsValid(comp.WeaponEntity))
			{
				let targetPos = scene.GetWorldMatrix(comp.TargetEntity).Translation;
				let dir = targetPos - towerPos;
				let yaw = Math.Atan2(dir.X, dir.Z);

				var weaponTransform = Transform();
				weaponTransform.Position = .(0, 0.5f, 0); // local offset above base
				weaponTransform.Rotation = Quaternion.CreateFromAxisAngle(.(0, 1, 0), yaw);
				weaponTransform.Scale = .One;
				scene.SetLocalTransform(comp.WeaponEntity, weaponTransform);
			}

			// Fire when ready
			if (comp.FireCooldown <= 0 && scene.IsValid(comp.TargetEntity))
			{
				comp.FireCooldown = 1.0f / comp.FireRate;

				// Get fire origin from spawn point entity, or fallback to offset above tower
				Vector3 fireOrigin;
				if (scene.IsValid(comp.SpawnPointEntity))
					fireOrigin = scene.GetWorldMatrix(comp.SpawnPointEntity).Translation;
				else
					fireOrigin = towerPos + .(0, 0.6f, 0);

				// Publish shot message
				if (Bus != null)
				{
					TowerShotMsg msg = .()
					{
						TowerEntity = comp.Owner,
						TargetEntity = comp.TargetEntity,
						Origin = fireOrigin,
						TowerType = comp.Type
					};
					Bus.Queue<TowerShotMsg>(msg);
				}

				// Spawn projectile
				if (ProjectileMgr != null)
				{
					let stats = TowerStats.Get(comp.Type);
					ProjectileMgr.SpawnProjectile(
						fireOrigin,
						comp.TargetEntity,
						(int32)comp.Damage,
						stats.AmmoModel
					);
				}
			}
		}
	}

	/// Finds the best target for a tower: in range, furthest along the path.
	private void AcquireTarget(TowerComponent tower, Vector3 towerPos, Scene scene)
	{
		// Check if current target is still valid and in range
		if (scene.IsValid(tower.TargetEntity))
		{
			let targetPos = scene.GetWorldMatrix(tower.TargetEntity).Translation;
			let dist = (targetPos - towerPos).Length();
			if (dist <= tower.Range)
			{
				// Check enemy is still alive
				if (let enemy = EnemyMgr.GetForEntity(tower.TargetEntity))
				{
					if (enemy.CurrentHealth > 0)
						return; // current target still valid
				}
			}
		}

		// Need new target - find enemy in range with highest DistanceAlongPath
		tower.TargetEntity = .Invalid;
		float bestDistance = -1;

		for (let enemy in EnemyMgr.ActiveComponents)
		{
			if (!enemy.IsActive || !enemy.Initialized || enemy.CurrentHealth <= 0)
				continue;

			let enemyPos = scene.GetWorldMatrix(enemy.Owner).Translation;
			let dist = (enemyPos - towerPos).Length();

			if (dist <= tower.Range && enemy.DistanceAlongPath > bestDistance)
			{
				bestDistance = enemy.DistanceAlongPath;
				tower.TargetEntity = enemy.Owner;
			}
		}
	}

	/// Recursively searches an entity and its children for "Weapon" and "ProjectileSpawnPoint".
	private static void FindNamedChildren(Scene scene, EntityHandle entity, TowerComponent comp)
	{
		let name = scene.GetEntityName(entity);
		if (name == "Weapon")
			comp.WeaponEntity = entity;
		else if (name == "ProjectileSpawnPoint")
			comp.SpawnPointEntity = entity;

		let children = scope List<EntityHandle>();
		scene.GetChildren(entity, children);
		for (let child in children)
			FindNamedChildren(scene, child, comp);
	}
}
