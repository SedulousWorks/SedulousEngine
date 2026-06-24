namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Messaging;

/// Manages enemy components: moves enemies along waypoints, detects death and
/// arrival at the end. Publishes EnemyKilledMsg and EnemyReachedEndMsg.
class EnemyComponentManager : ComponentManager<EnemyComponent>
{
	/// Message bus for publishing game events.
	public MessageBus Bus;

	/// Game speed multiplier. Set by GameSubsystem each frame.
	public float GameSpeed = 1.0f;


	/// Waypoints that enemies follow (set by GameSubsystem from MapData).
	public List<Vector3> Waypoints;

	/// Model manifest for constructing ResourceRefs when spawning enemies.
	public ModelManifest Manifest;

	public override StringView SerializationTypeId => "TowerDefense.EnemyComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.Update, new => UpdateEnemies, simulationOnly: true);
	}

	/// Spawns an enemy entity at the first waypoint.
	public EntityHandle SpawnEnemy(EnemyType type)
	{
		if (Waypoints == null || Waypoints.Count == 0 || Scene == null)
			return .Invalid;

		let stats = EnemyStats.Get(type);
		let spawnPos = Waypoints[0];

		// Create entity
		let entity = Scene.CreateEntity("Enemy");
		var transform = Transform();
		transform.Position = spawnPos;
		transform.Rotation = .Identity;
		transform.Scale = .One;
		Scene.SetLocalTransform(entity, transform);

		// Attach mesh from manifest
		let meshMgr = Scene.GetModule<MeshComponentManager>();
		if (meshMgr != null && Manifest != null)
		{
			let entry = Manifest.Get(stats.ModelName);
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

		// Attach enemy component
		let compHandle = CreateComponent(entity);
		if (let comp = Get(compHandle))
		{
			comp.Type = type;
			comp.MaxHealth = stats.Health;
			comp.CurrentHealth = stats.Health;
			comp.Speed = stats.Speed;
			comp.Reward = stats.Reward;
			comp.WaypointIndex = 1; // start heading toward second waypoint
			comp.DistanceAlongPath = 0;
		}

		return entity;
	}

	private void UpdateEnemies(float deltaTime)
	{
		if (Waypoints == null || Waypoints.Count == 0)
			return;

		let scene = Scene;
		if (scene == null)
			return;

		// Collect entities to destroy (can't destroy during iteration)
		let toDestroy = scope List<EntityHandle>();

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.Initialized)
				continue;

			// Check death
			if (comp.CurrentHealth <= 0)
			{
				if (Bus != null)
				{
					let deathPos = scene.GetLocalTransform(comp.Owner).Position;
					EnemyKilledMsg msg = .()
					{
						EntityId = comp.Owner,
						Reward = comp.Reward,
						Position = deathPos
					};
					Bus.Publish<EnemyKilledMsg>(ref msg);
				}
				toDestroy.Add(comp.Owner);
				continue;
			}

			// Move toward current waypoint
			if (comp.WaypointIndex >= Waypoints.Count)
			{
				// Reached the end
				if (Bus != null)
				{
					EnemyReachedEndMsg msg = .()
					{
						EntityId = comp.Owner,
						LivesLost = 1
					};
					Bus.Queue<EnemyReachedEndMsg>(msg);
				}
				toDestroy.Add(comp.Owner);
				continue;
			}

			let targetPos = Waypoints[comp.WaypointIndex];
			let localT = scene.GetLocalTransform(comp.Owner);
			let currentPos = localT.Position;
			let direction = targetPos - currentPos;
			let distance = direction.Length();

			if (distance < 0.1f)
			{
				// Reached waypoint, advance to next
				comp.WaypointIndex++;
			}
			else
			{
				// Move toward waypoint
				let moveDir = Vector3.Normalize(direction);
				let moveAmount = comp.Speed * deltaTime * GameSpeed;
				let newPos = currentPos + moveDir * Math.Min(moveAmount, distance);

				comp.DistanceAlongPath += Math.Min(moveAmount, distance);

				var transform = Transform();
				transform.Position = newPos;
				// Face movement direction
				transform.Rotation = Quaternion.CreateFromAxisAngle(.(0, 1, 0),
					Math.Atan2(moveDir.X, moveDir.Z));
				transform.Scale = .One;
				scene.SetLocalTransform(comp.Owner, transform);
			}
		}

		// Destroy dead/finished enemies
		for (let entity in toDestroy)
			scene.DestroyEntity(entity);
	}

	/// Draws camera-facing health bar quads above all active enemies.
	public void DrawHealthBars(Sedulous.Renderer.Debug.DebugDraw debugDraw, Vector3 camRight, Vector3 camUp)
	{
		let scene = Scene;
		if (scene == null || debugDraw == null) return;

		let barWidth = 0.6f;
		let barHeight = 0.08f;
		let barY = 1.2f;

		let right = camRight;
		let up = camUp;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.Initialized || comp.CurrentHealth <= 0)
				continue;

			let pos = scene.GetLocalTransform(comp.Owner).Position;
			let healthRatio = Math.Clamp((float)comp.CurrentHealth / (float)comp.MaxHealth, 0, 1);

			let halfW = barWidth * 0.5f;
			let halfH = barHeight * 0.5f;
			let center = pos + .(0, barY, 0);

			// Background (dark red)
			debugDraw.DrawQuad(
				center - right * halfW + up * halfH,
				center + right * halfW + up * halfH,
				center + right * halfW - up * halfH,
				center - right * halfW - up * halfH,
				.(60, 20, 20, 200), overlay: true);

			// Health fill - left-aligned, billboard
			let fillW = barWidth * healthRatio;
			let fillLeft = center - right * halfW;

			uint8 r = (uint8)(255 * (1.0f - healthRatio));
			uint8 g = (uint8)(255 * healthRatio);

			debugDraw.DrawQuad(
				fillLeft + up * halfH,
				fillLeft + right * fillW + up * halfH,
				fillLeft + right * fillW - up * halfH,
				fillLeft - up * halfH,
				.(r, g, 0, 230), overlay: true);
		}
	}
}
