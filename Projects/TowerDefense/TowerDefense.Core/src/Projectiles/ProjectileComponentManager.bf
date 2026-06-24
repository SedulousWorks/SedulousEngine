namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Messaging;

/// Manages projectile components: homing movement, collision detection, damage.
class ProjectileComponentManager : ComponentManager<ProjectileComponent>
{
	public MessageBus Bus;
	public EnemyComponentManager EnemyMgr;
	public ModelManifest Manifest;
	public float GameSpeed = 1.0f;

	public override StringView SerializationTypeId => "TowerDefense.ProjectileComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostTransform, new => UpdateProjectiles, simulationOnly: true);
	}

	/// Spawns a projectile entity heading toward a target.
	public void SpawnProjectile(Vector3 origin, EntityHandle target, int32 damage, StringView ammoModelName)
	{
		let scene = Scene;
		if (scene == null)
			return;

		let entity = scene.CreateEntity("Projectile");
		var transform = Transform();
		transform.Position = origin;
		transform.Rotation = .Identity;
		transform.Scale = .(0.5f, 0.5f, 0.5f); // projectiles are small
		scene.SetLocalTransform(entity, transform);

		// Attach mesh from manifest
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr != null && Manifest != null)
		{
			let entry = Manifest.Get(ammoModelName);
			if (entry != null)
			{
				let meshHandle = meshMgr.CreateComponent(entity);
				if (let mesh = meshMgr.Get(meshHandle))
				{
					var meshRef = entry.GetMeshRef();
					defer meshRef.Dispose();
					mesh.SetMeshRef(meshRef);

					for (int32 slot = 0; slot < entry.MaterialCount; slot++)
					{
						var matRef = entry.GetMaterialRef(slot);
						defer matRef.Dispose();
						mesh.SetMaterialRef(slot, matRef);
					}
				}
			}
		}

		// Attach projectile component
		let compHandle = CreateComponent(entity);
		if (let comp = Get(compHandle))
		{
			comp.Damage = damage;
			comp.TargetEntity = target;
			comp.Speed = 15.0f;
			comp.Lifetime = 3.0f;
			comp.Age = 0;
			comp.LastDirection = .(0, 0, 1); // default forward
		}
	}

	private void UpdateProjectiles(float deltaTime)
	{
		let scene = Scene;
		if (scene == null)
			return;

		let toDestroy = scope List<EntityHandle>();

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.Initialized)
				continue;

			comp.Age += deltaTime * GameSpeed;

			// Self-destruct on lifetime expire
			if (comp.Age >= comp.Lifetime)
			{
				toDestroy.Add(comp.Owner);
				continue;
			}

			let currentPos = scene.GetWorldMatrix(comp.Owner).Translation;
			Vector3 targetPos = default;
			bool hasTarget = false;

			// Get target position
			if (scene.IsValid(comp.TargetEntity) && EnemyMgr != null)
			{
				if (let enemy = EnemyMgr.GetForEntity(comp.TargetEntity))
				{
					if (enemy.CurrentHealth > 0)
					{
						targetPos = scene.GetWorldMatrix(comp.TargetEntity).Translation;
						hasTarget = true;
					}
				}
			}

			// Move toward target or continue in last direction
			Vector3 moveDir;
			if (hasTarget)
			{
				moveDir = Vector3.Normalize(targetPos - currentPos);
				comp.LastDirection = moveDir;
			}
			else
			{
				moveDir = comp.LastDirection;
			}

			let moveAmount = comp.Speed * deltaTime * GameSpeed;
			let newPos = currentPos + moveDir * moveAmount;

			var transform = Transform();
			transform.Position = newPos;
			transform.Rotation = Quaternion.CreateFromAxisAngle(.(0, 1, 0), Math.Atan2(moveDir.X, moveDir.Z));
			transform.Scale = .(0.5f, 0.5f, 0.5f);
			scene.SetLocalTransform(comp.Owner, transform);

			// Check hit - distance to target
			if (hasTarget)
			{
				let dist = (targetPos - newPos).Length();
				if (dist < 0.3f)
				{
					// Hit! Apply damage
					if (let enemy = EnemyMgr.GetForEntity(comp.TargetEntity))
						enemy.CurrentHealth -= comp.Damage;

					// Publish hit message
					if (Bus != null)
					{
						ProjectileHitMsg msg = .()
						{
							ProjectileEntity = comp.Owner,
							TargetEntity = comp.TargetEntity,
							HitPosition = newPos,
							Damage = comp.Damage
						};
						Bus.Queue<ProjectileHitMsg>(msg);
					}

					toDestroy.Add(comp.Owner);
				}
			}
		}

		// Destroy hit/expired projectiles
		for (let entity in toDestroy)
			scene.DestroyEntity(entity);
	}
}
