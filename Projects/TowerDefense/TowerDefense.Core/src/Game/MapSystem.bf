namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;

/// Builds tile entities from MapData and manages grid cell occupancy.
/// Uses neighbor-aware tile selection for path tiles (straights, corners, ends).
class MapSystem
{
	private MapData mCurrentMap ~ delete _;
	private List<EntityHandle> mTileEntities = new .() ~ delete _;
	private bool[] mOccupied ~ delete _;

	public MapData CurrentMap => mCurrentMap;

	/// Initializes map data without creating tile entities.
	/// Used on the cached path where the scene already has tile entities.
	public void InitMapData(MapData map)
	{
		if (mCurrentMap != null)
			delete mCurrentMap;
		mCurrentMap = map;
		delete mOccupied;
		mOccupied = new bool[map.Width * map.Height];
	}

	/// Builds the map: creates tile entities for each cell.
	public void BuildMap(MapData map, Scene scene, ModelManifest manifest)
	{
		// Clear previous map
		ClearMap(scene);

		if (mCurrentMap != null)
			delete mCurrentMap;
		mCurrentMap = map;
		mOccupied = new bool[map.Width * map.Height];

		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null || manifest == null)
			return;

		for (int32 z = 0; z < map.Height; z++)
		{
			for (int32 x = 0; x < map.Width; x++)
			{
				let cellType = map.GetCell(x, z);

				// Determine tile model and rotation based on cell type and neighbors
				let tileInfo = GetTileInfo(map, x, z, cellType);
				if (tileInfo.ModelName.IsEmpty)
					continue;

				let entry = manifest.Get(tileInfo.ModelName);
				if (entry == null)
					continue;

				let entityName = scope String();
				entityName.AppendF("Tile_{}_{}", x, z);

				let entity = scene.CreateEntity(entityName);
				let worldPos = map.GridToWorld(x, z);

				var transform = Transform();
				transform.Position = worldPos;
				transform.Rotation = Quaternion.CreateFromAxisAngle(.(0, 1, 0), tileInfo.YRotation);
				transform.Scale = .One;
				scene.SetLocalTransform(entity, transform);

				// Attach mesh component
				AttachMesh(meshMgr, entity, entry);

				mTileEntities.Add(entity);

				// Add tower slot marker on top of tower slot tiles
				if (cellType == .TowerSlot)
					PlaceMarker(scene, manifest, meshMgr, worldPos);
			}
		}

		Console.WriteLine("[MapSystem] Built map '{}': {}x{}, {} tiles", map.Name, map.Width, map.Height, mTileEntities.Count);
	}

	/// Places a selection marker on top of a tower slot tile.
	private void PlaceMarker(Scene scene, ModelManifest manifest,
		MeshComponentManager meshMgr, Vector3 worldPos)
	{
		let entry = manifest.Get("selection-a");
		if (entry == null)
			return;

		let markerEntity = scene.CreateEntity("Marker");
		var markerTransform = Transform();
		markerTransform.Position = worldPos + .(0, 0.01f, 0); // slightly above tile
		markerTransform.Rotation = .Identity;
		markerTransform.Scale = .One;
		scene.SetLocalTransform(markerEntity, markerTransform);

		AttachMesh(meshMgr, markerEntity, entry);
		mTileEntities.Add(markerEntity);
	}

	/// Attaches a mesh component to an entity using manifest data.
	private static void AttachMesh(MeshComponentManager meshMgr, EntityHandle entity, ModelManifestEntry entry)
	{
		let compHandle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(compHandle))
		{
			var meshRef = entry.GetMeshRef();
			defer meshRef.Dispose();
			comp.SetMeshRef(meshRef);

			for (int32 slot = 0; slot < entry.MaterialCount; slot++)
			{
				var matRef = entry.GetMaterialRef(slot);
				defer matRef.Dispose();
				comp.SetMaterialRef(slot, matRef);
			}
		}
	}

	/// Clears all tile entities from the scene.
	public void ClearMap(Scene scene)
	{
		for (let entity in mTileEntities)
		{
			if (scene.IsValid(entity))
				scene.DestroyEntity(entity);
		}
		mTileEntities.Clear();
	}

	/// Whether a tower can be placed at this grid position.
	public bool CanPlaceTower(int32 x, int32 z)
	{
		if (mCurrentMap == null)
			return false;
		if (x < 0 || x >= mCurrentMap.Width || z < 0 || z >= mCurrentMap.Height)
			return false;
		if (mCurrentMap.GetCell(x, z) != .TowerSlot)
			return false;
		return !mOccupied[z * mCurrentMap.Width + x];
	}

	/// Marks a cell as occupied by a tower.
	public void OccupyCell(int32 x, int32 z)
	{
		if (mCurrentMap != null && x >= 0 && x < mCurrentMap.Width && z >= 0 && z < mCurrentMap.Height)
			mOccupied[z * mCurrentMap.Width + x] = true;
	}

	/// Frees a cell (tower sold or destroyed).
	public void FreeCell(int32 x, int32 z)
	{
		if (mCurrentMap != null && x >= 0 && x < mCurrentMap.Width && z >= 0 && z < mCurrentMap.Height)
			mOccupied[z * mCurrentMap.Width + x] = false;
	}

	/// Returns the waypoints for enemy path.
	public List<Vector3> GetWaypoints()
	{
		return mCurrentMap?.Waypoints;
	}

	// ==================== Tile Selection Logic ====================

	struct TileInfo
	{
		public StringView ModelName;
		public float YRotation; // radians
	}

	/// Returns true if the cell at (x,z) is a path-like cell (Path, Spawn, End).
	private bool IsPathCell(MapData map, int32 x, int32 z)
	{
		let cell = map.GetCell(x, z);
		return cell == .Path || cell == .Spawn || cell == .End;
	}

	/// Determines the tile model and Y rotation based on cell type and neighboring path cells.
	private TileInfo GetTileInfo(MapData map, int32 x, int32 z, MapCellType cellType)
	{
		switch (cellType)
		{
		case .Empty:
			return .() { ModelName = "tile", YRotation = 0 };

		case .TowerSlot:
			return .() { ModelName = "tile", YRotation = 0 };

		case .Blocked:
			return .() { ModelName = "tile-rock", YRotation = 0 };

		case .Spawn:
			// Spawn tile - point the opening toward the first path neighbor
			let rotation = GetSpawnRotation(map, x, z);
			return .() { ModelName = "tile-spawn-round", YRotation = rotation };

		case .End:
			// End tile - point opening toward the last path neighbor
			let rotation = GetSpawnRotation(map, x, z);
			return .() { ModelName = "tile-end-round", YRotation = rotation };

		case .Path:
			return GetPathTileInfo(map, x, z);
		}
	}

	/// Determines the correct path tile (straight, corner, crossing, end) and rotation.
	private TileInfo GetPathTileInfo(MapData map, int32 x, int32 z)
	{
		// Check which neighbors are path-like
		let north = IsPathCell(map, x, z + 1); // +Z
		let south = IsPathCell(map, x, z - 1); // -Z
		let east  = IsPathCell(map, x + 1, z); // +X
		let west  = IsPathCell(map, x - 1, z); // -X

		let count = (north ? 1 : 0) + (south ? 1 : 0) + (east ? 1 : 0) + (west ? 1 : 0);

		switch (count)
		{
		case 0:
			// Isolated path tile
			return .() { ModelName = "tile-straight", YRotation = 0 };

		case 1:
			// Dead end - use tile-end-round, opening faces toward the connected neighbor
			// +90° shift from previous attempt
			if (east)  return .() { ModelName = "tile-end-round", YRotation = Math.PI_f * 0.5f };
			if (west)  return .() { ModelName = "tile-end-round", YRotation = -Math.PI_f * 0.5f };
			if (north) return .() { ModelName = "tile-end-round", YRotation = 0 };
			if (south) return .() { ModelName = "tile-end-round", YRotation = Math.PI_f };

		case 2:
			// Straight or corner
			if (north && south)
				return .() { ModelName = "tile-straight", YRotation = 0 }; // runs along Z
			if (east && west)
				return .() { ModelName = "tile-straight", YRotation = Math.PI_f * 0.5f }; // runs along X

			// Corner - determine which quadrant
			// Kenney tile-corner-round default orientation determined empirically:
			// +90° shift from previous attempt
			if (south && east) return .() { ModelName = "tile-corner-round", YRotation = Math.PI_f * 0.5f };
			if (north && east) return .() { ModelName = "tile-corner-round", YRotation = 0 };
			if (north && west) return .() { ModelName = "tile-corner-round", YRotation = -Math.PI_f * 0.5f };
			if (south && west) return .() { ModelName = "tile-corner-round", YRotation = Math.PI_f };

		case 3:
			// T-junction - use tile-split
			// tile-split by default: south, east, west (T pointing north)
			if (!north) return .() { ModelName = "tile-split", YRotation = 0 };
			if (!south) return .() { ModelName = "tile-split", YRotation = Math.PI_f };
			if (!east)  return .() { ModelName = "tile-split", YRotation = Math.PI_f * 0.5f };
			if (!west)  return .() { ModelName = "tile-split", YRotation = -Math.PI_f * 0.5f };

		case 4:
			// Crossroads
			return .() { ModelName = "tile-crossing", YRotation = 0 };
		}

		// Fallback
		return .() { ModelName = "tile-straight", YRotation = 0 };
	}

	/// Determines spawn/end tile rotation to face toward an adjacent path cell.
	private float GetSpawnRotation(MapData map, int32 x, int32 z)
	{
		// +90° shift from previous attempt
		if (IsPathCell(map, x + 1, z)) return Math.PI_f * 0.5f;    // path is east
		if (IsPathCell(map, x - 1, z)) return -Math.PI_f * 0.5f;   // path is west
		if (IsPathCell(map, x, z + 1)) return 0;                   // path is north
		if (IsPathCell(map, x, z - 1)) return Math.PI_f;           // path is south
		return 0;
	}
}
