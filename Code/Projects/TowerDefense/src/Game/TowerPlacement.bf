namespace TowerDefense;

using System;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core.Resources;
using Sedulous.Messaging;
using Sedulous.Shell.Input;
using Sedulous.Renderer.Debug;

/// Handles tower placement, selection, upgrade, and sell.
/// Draws debug markers on tower slots and shows a preview tower at the cursor.
class TowerPlacement
{
	/// Currently selected tower type for placement. null = nothing selected.
	public TowerType? SelectedType;

	/// Currently selected placed tower (for info/upgrade/sell). Invalid = none.
	public EntityHandle SelectedTower = .Invalid;

	/// Model manifest for constructing ResourceRefs.
	public ModelManifest Manifest;

	/// Resource system for prefab spawning.
	public ResourceSystem ResourceSystem;

	/// Serializer provider for prefab spawning.
	public Sedulous.Serialization.ISerializerProvider SerializerProvider;

	/// Component type registry for prefab spawning.
	public ComponentTypeRegistry TypeRegistry;


	/// Hover grid position (valid when mouse is over a valid cell).
	public int32 HoverX;
	public int32 HoverZ;
	public bool HoverValid;

	// Preview entity - follows the mouse cursor when a tower is selected
	private EntityHandle mPreviewBase = .Invalid;
	private EntityHandle mPreviewWeapon = .Invalid;
	private TowerType? mPreviewType;

	/// Places a tower, selects a placed tower, or updates hover. Call each frame.
	public void Update(
		IMouse mouse, Scene scene, GameSubsystem gameSub,
		TowerComponentManager towerMgr, EntityHandle cameraEntity)
	{
		HoverValid = false;

		if (scene == null || !gameSub.IsGameplayPhase)
		{
			HidePreview(scene);
			return;
		}

		// Right click cancels tower selection or deselects placed tower
		if (mouse.IsButtonPressed(.Right))
		{
			if (SelectedType != null)
			{
				SelectedType = null;
			}
			else if (scene.IsValid(SelectedTower))
			{
				DeselectTower(gameSub);
			}
			return;
		}

		// Get camera matrices for unprojection
		let cameraMgr = scene.GetModule<CameraComponentManager>();
		if (cameraMgr == null) return;
		let camComp = cameraMgr.GetForEntity(cameraEntity);
		if (camComp == null) return;
		let renderSub = gameSub.Context.GetSubsystem<RenderSubsystem>();
		if (renderSub == null) return;
		let pipeline = renderSub.GetPipeline(scene);
		if (pipeline == null) return;

		let viewMatrix = camComp.GetViewMatrix(scene);
		let aspect = (float)pipeline.OutputWidth / (float)pipeline.OutputHeight;
		let projMatrix = camComp.GetProjectionMatrix(aspect);
		let viewProj = viewMatrix * projMatrix;

		// Unproject mouse position to ray
		let ndcX = (2.0f * mouse.X / (float)pipeline.OutputWidth) - 1.0f;
		let ndcY = 1.0f - (2.0f * mouse.Y / (float)pipeline.OutputHeight);

		Matrix invVP = .Identity;
		if (!Matrix.TryInvert(viewProj, out invVP))
			return;

		var nearWorld = Vector4.Transform(Vector4(ndcX, ndcY, 0, 1), invVP);
		var farWorld = Vector4.Transform(Vector4(ndcX, ndcY, 1, 1), invVP);

		if (Math.Abs(nearWorld.W) < 0.0001f || Math.Abs(farWorld.W) < 0.0001f)
			return;

		let nearPos = Vector3(nearWorld.X, nearWorld.Y, nearWorld.Z) / nearWorld.W;
		let farPos = Vector3(farWorld.X, farWorld.Y, farWorld.Z) / farWorld.W;
		let rayDir = farPos - nearPos;

		// Intersect with Y=0 plane
		if (Math.Abs(rayDir.Y) < 0.001f)
			return;

		let t = -nearPos.Y / rayDir.Y;
		if (t < 0) return;

		let hitPos = nearPos + rayDir * t;

		// Convert to grid
		int32 gx, gz;
		if (!gameSub.Map.CurrentMap.WorldToGrid(hitPos, out gx, out gz))
		{
			HidePreview(scene);
			return;
		}

		HoverX = gx;
		HoverZ = gz;

		if (SelectedType != null)
		{
			// Placement mode
			HoverValid = gameSub.Map.CanPlaceTower(gx, gz);

			let worldPos = gameSub.Map.CurrentMap.GridToWorld(gx, gz);
			UpdatePreview(scene, worldPos);

			// Place on left click
			if (mouse.IsButtonPressed(.Left) && HoverValid)
			{
				let towerType = SelectedType.Value;
				let stats = TowerStats.Get(towerType);
				let cost = stats.Levels[0].Cost;

				if (gameSub.SpendGold(cost))
				{
					let entity = BuildTower(scene, towerMgr, gameSub, towerType, gx, gz);

					if (entity != .Invalid)
					{
						gameSub.Map.OccupyCell(gx, gz);

						if (gameSub.Bus != null)
						{
							TowerPlacedMsg msg = .()
							{
								EntityId = entity,
								Type = towerType,
								GridX = gx,
								GridZ = gz
							};
							gameSub.Bus.Queue<TowerPlacedMsg>(msg);
						}

						Console.WriteLine("[Tower] Placed {} at ({}, {}), cost {}", towerType, gx, gz, cost);
					}
				}
				else
				{
					Console.WriteLine("[Tower] Not enough gold for {} (need {}, have {})", towerType, cost, gameSub.Gold);
				}
			}
		}
		else
		{
			// Selection mode - no tower type selected, click to select placed tower
			HidePreview(scene);

			if (mouse.IsButtonPressed(.Left))
			{
				// Find tower at clicked grid position
				let found = FindTowerAt(towerMgr, gx, gz);
				if (found != .Invalid)
					SelectTower(found, gameSub);
				else
					DeselectTower(gameSub);
			}
		}
	}

	// ==================== Tower Selection ====================

	/// Select a placed tower for info/upgrade/sell.
	public void SelectTower(EntityHandle entity, GameSubsystem gameSub)
	{
		SelectedTower = entity;
		SelectedType = null; // deselect placement mode

		if (gameSub.Bus != null)
		{
			TowerSelectedMsg msg = .() { EntityId = entity };
			gameSub.Bus.Queue<TowerSelectedMsg>(msg);
		}
	}

	/// Deselect the currently selected placed tower.
	public void DeselectTower(GameSubsystem gameSub)
	{
		SelectedTower = .Invalid;

		if (gameSub.Bus != null)
		{
			TowerSelectedMsg msg = .() { EntityId = .Invalid };
			gameSub.Bus.Queue<TowerSelectedMsg>(msg);
		}
	}

	/// Upgrade the selected tower. Returns true if successful.
	public bool UpgradeTower(GameSubsystem gameSub, TowerComponentManager towerMgr)
	{
		if (!towerMgr.Scene.IsValid(SelectedTower))
			return false;

		let comp = towerMgr.GetForEntity(SelectedTower);
		if (comp == null || comp.Level >= 3)
			return false;

		let stats = TowerStats.Get(comp.Type);
		let upgradeCost = stats.Levels[comp.Level].Cost; // next level's cost
		if (!gameSub.SpendGold(upgradeCost))
			return false;

		comp.Level++;
		let newStats = stats.Levels[comp.Level - 1];
		comp.Damage = newStats.Damage;
		comp.Range = newStats.Range;
		comp.FireRate = newStats.FireRate;
		comp.TotalInvested += upgradeCost;

		if (gameSub.Bus != null)
		{
			TowerUpgradedMsg msg = .() { EntityId = SelectedTower, NewLevel = comp.Level };
			gameSub.Bus.Queue<TowerUpgradedMsg>(msg);
		}

		Console.WriteLine("[Tower] Upgraded to level {}, cost {}", comp.Level, upgradeCost);
		return true;
	}

	/// Sell the selected tower. Returns refund amount.
	public int32 SellTower(GameSubsystem gameSub, TowerComponentManager towerMgr, Scene scene)
	{
		if (!scene.IsValid(SelectedTower))
			return 0;

		let comp = towerMgr.GetForEntity(SelectedTower);
		if (comp == null)
			return 0;

		let refund = comp.TotalInvested / 2;
		let type = comp.Type;
		let gx = comp.GridX;
		let gz = comp.GridZ;

		gameSub.AddGold(refund);
		gameSub.Map.FreeCell(gx, gz);
		scene.DestroyEntity(SelectedTower);

		if (gameSub.Bus != null)
		{
			TowerSoldMsg msg = .() { EntityId = SelectedTower, Type = type, Refund = refund };
			gameSub.Bus.Queue<TowerSoldMsg>(msg);
		}

		SelectedTower = .Invalid;

		// Auto-deselect
		if (gameSub.Bus != null)
		{
			TowerSelectedMsg selMsg = .() { EntityId = .Invalid };
			gameSub.Bus.Queue<TowerSelectedMsg>(selMsg);
		}

		Console.WriteLine("[Tower] Sold {} at ({}, {}), refund {}", type, gx, gz, refund);
		return refund;
	}

	/// Find a tower entity at the given grid position.
	private EntityHandle FindTowerAt(TowerComponentManager towerMgr, int32 gx, int32 gz)
	{
		for (let comp in towerMgr.ActiveComponents)
		{
			if (comp.IsActive && comp.Initialized && comp.GridX == gx && comp.GridZ == gz)
				return comp.Owner;
		}
		return .Invalid;
	}

	/// Draws a flat rectangle as overlay lines at a given Y height.
	private static void DrawFlatRectOverlay(DebugDraw dbg, Vector3 center, float half, float y, Color32 color)
	{
		let c0 = center + .(-half, y, -half);
		let c1 = center + .( half, y, -half);
		let c2 = center + .( half, y,  half);
		let c3 = center + .(-half, y,  half);
		dbg.DrawLineOverlay(c0, c1, color);
		dbg.DrawLineOverlay(c1, c2, color);
		dbg.DrawLineOverlay(c2, c3, color);
		dbg.DrawLineOverlay(c3, c0, color);
	}

	/// Draws debug markers on tower slots and hover cell.
	public void DrawDebug(DebugDraw dbg, GameSubsystem gameSub)
	{
		if (dbg == null || gameSub.Map.CurrentMap == null)
			return;

		let map = gameSub.Map.CurrentMap;
		let y = 0.3f;

		// Draw tower slot markers when in placement mode
		if (SelectedType != null)
		{
			let slotColor = Color32(50, 200, 50, 255);
			let occupiedColor = Color32(150, 150, 150, 255);

			for (int32 z = 0; z < map.Height; z++)
			{
				for (int32 x = 0; x < map.Width; x++)
				{
					if (map.GetCell(x, z) != .TowerSlot)
						continue;

					let pos = map.GridToWorld(x, z);
					let occupied = !gameSub.Map.CanPlaceTower(x, z);
					let color = occupied ? occupiedColor : slotColor;
					let half = MapData.TileSize * 0.45f;
					DrawFlatRectOverlay(dbg, pos, half, y, color);
				}
			}

			// Hover highlight
			let hoverPos = map.GridToWorld(HoverX, HoverZ);
			let hoverColor = HoverValid ? Color32(50, 255, 50, 255) : Color32(255, 50, 50, 255);
			DrawFlatRectOverlay(dbg, hoverPos, MapData.TileSize * 0.48f, y, hoverColor);

			// Range circle for placement preview
			if (HoverValid)
			{
				let stats = TowerStats.Get(SelectedType.Value);
				let range = stats.Levels[0].Range;
				DrawRangeCircle(dbg, hoverPos, range, y, Color32(255, 255, 100, 200));
			}
		}

		// Draw range circle around selected placed tower
		if (SelectedTower != .Invalid)
		{
			let towerMgr = gameSub.TowerMgr;
			if (towerMgr != null)
			{
				let comp = towerMgr.GetForEntity(SelectedTower);
				if (comp != null)
				{
					let pos = map.GridToWorld(comp.GridX, comp.GridZ);
					DrawRangeCircle(dbg, pos, comp.Range, y, Color32(100, 200, 255, 200));
					// Highlight ring around selected tower
					DrawFlatRectOverlay(dbg, pos, MapData.TileSize * 0.48f, y, Color32(100, 200, 255, 255));
				}
			}
		}
	}

	private static void DrawRangeCircle(DebugDraw dbg, Vector3 center, float range, float y, Color32 color)
	{
		let segments = 48;
		for (int i = 0; i < segments; i++)
		{
			let a0 = (float)i / (float)segments * Math.PI_f * 2.0f;
			let a1 = (float)(i + 1) / (float)segments * Math.PI_f * 2.0f;
			let p0 = center + Vector3(Math.Cos(a0) * range, y, Math.Sin(a0) * range);
			let p1 = center + Vector3(Math.Cos(a1) * range, y, Math.Sin(a1) * range);
			dbg.DrawLineOverlay(p0, p1, color);
		}
	}

	// ==================== Mesh Attachment Helper ====================

	/// Attaches a mesh component to an entity using manifest data.
	private static void AttachMesh(Scene scene, EntityHandle entity, ModelManifestEntry entry)
	{
		if (entry == null) return;
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;

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

	// ==================== Preview Entity ====================

	private void UpdatePreview(Scene scene, Vector3 worldPos)
	{
		if (SelectedType == null)
		{
			HidePreview(scene);
			return;
		}

		if (mPreviewType != SelectedType)
		{
			HidePreview(scene);
			CreatePreview(scene);
			mPreviewType = SelectedType;
		}

		if (scene.IsValid(mPreviewBase))
		{
			var transform = Transform();
			transform.Position = worldPos;
			transform.Rotation = .Identity;
			transform.Scale = .One;
			scene.SetLocalTransform(mPreviewBase, transform);
		}
	}

	private void CreatePreview(Scene scene)
	{
		if (SelectedType == null || Manifest == null)
			return;

		let stats = TowerStats.Get(SelectedType.Value);

		mPreviewBase = scene.CreateEntity("TowerPreview");
		var transform = Transform();
		transform.Position = .Zero;
		transform.Rotation = .Identity;
		transform.Scale = .One;
		scene.SetLocalTransform(mPreviewBase, transform);

		AttachMesh(scene, mPreviewBase, Manifest.Get(stats.BaseModel));

		mPreviewWeapon = scene.CreateEntity("WeaponPreview");
		scene.SetParent(mPreviewWeapon, mPreviewBase);

		var weaponTransform = Transform();
		weaponTransform.Position = .(0, 0.5f, 0);
		weaponTransform.Rotation = .Identity;
		weaponTransform.Scale = .One;
		scene.SetLocalTransform(mPreviewWeapon, weaponTransform);

		AttachMesh(scene, mPreviewWeapon, Manifest.Get(stats.WeaponModel));
	}

	private void HidePreview(Scene scene)
	{
		if (scene != null && scene.IsValid(mPreviewBase))
			scene.DestroyEntity(mPreviewBase);

		mPreviewBase = .Invalid;
		mPreviewWeapon = .Invalid;
		mPreviewType = null;
	}

	// ==================== Tower Building ====================

	private EntityHandle BuildTower(Scene scene, TowerComponentManager towerMgr,
		GameSubsystem gameSub, TowerType type, int32 gx, int32 gz)
	{
		let stats = TowerStats.Get(type);
		let levelStats = stats.Levels[0];
		let worldPos = gameSub.Map.CurrentMap.GridToWorld(gx, gz);

		// Create root entity at grid position
		let rootEntity = scene.CreateEntity("Tower");
		var transform = Transform();
		transform.Position = worldPos;
		transform.Rotation = .Identity;
		transform.Scale = .One;
		scene.SetLocalTransform(rootEntity, transform);

		// Spawn tower prefab entities immediately as children
		let towerName = GetTowerName(type);
		if (ResourceSystem != null && SerializerProvider != null)
		{
			let prefabPath = scope String()..AppendF("project://prefabs/tower_{}.prefab", towerName);
			var prefabRef = ResourceRef(.Empty, prefabPath);
			defer prefabRef.Dispose();

			let spawnResult = PrefabSpawner.Spawn(scene, prefabRef, .Empty,
				rootEntity, TypeRegistry, SerializerProvider, ResourceSystem);
			if (spawnResult case .Ok(let sr))
				delete sr.GuidMap;
		}

		let compHandle = towerMgr.CreateComponent(rootEntity);
		if (let comp = towerMgr.Get(compHandle))
		{
			comp.Type = type;
			comp.Level = 1;
			comp.Damage = levelStats.Damage;
			comp.Range = levelStats.Range;
			comp.FireRate = levelStats.FireRate;
			comp.FireCooldown = 0;
			comp.GridX = gx;
			comp.GridZ = gz;
			// WeaponEntity and SpawnPointEntity are resolved after prefab instantiation
			comp.TotalInvested = levelStats.Cost;
		}

		return rootEntity;
	}

	private static StringView GetTowerName(TowerType type)
	{
		switch (type)
		{
		case .Ballista: return "ballista";
		case .Cannon:   return "cannon";
		case .Catapult:  return "catapult";
		case .Turret:   return "turret";
		}
	}
}
