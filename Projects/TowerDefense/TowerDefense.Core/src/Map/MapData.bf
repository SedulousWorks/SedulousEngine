namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Defines the layout of a tower defense map.
class MapData
{
	public int32 Width;
	public int32 Height;
	public MapCellType[] Cells ~ delete _;
	public List<Vector3> Waypoints = new .() ~ delete _;
	public String Name = new .() ~ delete _;

	/// Tile size in world units.
	public const float TileSize = 1.0f;

	public MapCellType GetCell(int32 x, int32 z)
	{
		if (x < 0 || x >= Width || z < 0 || z >= Height)
			return .Blocked;
		return Cells[z * Width + x];
	}

	public void SetCell(int32 x, int32 z, MapCellType type)
	{
		if (x >= 0 && x < Width && z >= 0 && z < Height)
			Cells[z * Width + x] = type;
	}

	/// Converts grid coordinates to world position (center of tile).
	public Vector3 GridToWorld(int32 x, int32 z)
	{
		return .(
			(float)x * TileSize,
			0,
			(float)z * TileSize
		);
	}

	/// Converts world position to grid coordinates. Returns false if out of bounds.
	public bool WorldToGrid(Vector3 worldPos, out int32 x, out int32 z)
	{
		x = (int32)Math.Round(worldPos.X / TileSize);
		z = (int32)Math.Round(worldPos.Z / TileSize);
		return x >= 0 && x < Width && z >= 0 && z < Height;
	}

	/// Forest Path - 12x12 grid with a snake path.
	///
	///   x: 0  1  2  3  4  5  6  7  8  9  10 11
	/// z11: .  E  .  .  .  .  .  .  .  .  .  .
	/// z10: .  P  .  T  .  T  .  T  .  T  .  .
	/// z9:  .  P  P  P  P  P  P  P  P  P  .  .
	/// z8:  .  .  T  .  T  .  T  .  T  .  .  .
	/// z7:  .  .  T  .  T  .  T  .  T  .  .  .
	/// z6:  .  .  P  P  P  P  P  P  P  P  .  .
	/// z5:  .  .  .  T  .  T  .  T  .  T  .  .
	/// z4:  .  .  .  T  .  T  .  T  .  T  .  .
	/// z3:  .  P  P  P  P  P  P  P  P  P  .  .
	/// z2:  .  .  T  .  T  .  T  .  T  .  .  #
	/// z1:  .  .  T  .  T  .  T  .  T  .  .  #
	/// z0:  S  P  P  P  P  P  P  P  P  P  P  .
	///
	public static MapData CreateMap1()
	{
		let map = new MapData();
		map.Name.Set("Forest Path");
		map.Width = 12;
		map.Height = 12;
		map.Cells = new MapCellType[144];

		// Start with all empty
		for (int i = 0; i < 144; i++)
			map.Cells[i] = .Empty;

		// Spawn at bottom-left
		map.SetCell(0, 0, .Spawn);

		// Right along z=0
		for (int32 x = 1; x <= 10; x++)
			map.SetCell(x, 0, .Path);

		// Up at x=10
		for (int32 z = 1; z <= 3; z++)
			map.SetCell(10, z, .Path);

		// Left along z=3
		for (int32 x = 9; x >= 1; x--)
			map.SetCell(x, 3, .Path);

		// Up at x=1
		for (int32 z = 4; z <= 6; z++)
			map.SetCell(1, z, .Path);

		// Right along z=6
		for (int32 x = 2; x <= 10; x++)
			map.SetCell(x, 6, .Path);

		// Up at x=10
		for (int32 z = 7; z <= 9; z++)
			map.SetCell(10, z, .Path);

		// Left along z=9
		for (int32 x = 9; x >= 1; x--)
			map.SetCell(x, 9, .Path);

		// Up at x=1 to end
		map.SetCell(1, 10, .Path);

		// End
		map.SetCell(1, 11, .End);

		// Tower slots - placed alongside each horizontal path segment
		// Between z=0 and z=3
		map.SetCell(2, 1, .TowerSlot);  map.SetCell(4, 1, .TowerSlot);
		map.SetCell(6, 1, .TowerSlot);  map.SetCell(8, 1, .TowerSlot);
		map.SetCell(2, 2, .TowerSlot);  map.SetCell(4, 2, .TowerSlot);
		map.SetCell(6, 2, .TowerSlot);  map.SetCell(8, 2, .TowerSlot);

		// Between z=3 and z=6
		map.SetCell(3, 4, .TowerSlot);  map.SetCell(5, 4, .TowerSlot);
		map.SetCell(7, 4, .TowerSlot);  map.SetCell(9, 4, .TowerSlot);
		map.SetCell(3, 5, .TowerSlot);  map.SetCell(5, 5, .TowerSlot);
		map.SetCell(7, 5, .TowerSlot);  map.SetCell(9, 5, .TowerSlot);

		// Between z=6 and z=9
		map.SetCell(2, 7, .TowerSlot);  map.SetCell(4, 7, .TowerSlot);
		map.SetCell(6, 7, .TowerSlot);  map.SetCell(8, 7, .TowerSlot);
		map.SetCell(2, 8, .TowerSlot);  map.SetCell(4, 8, .TowerSlot);
		map.SetCell(6, 8, .TowerSlot);  map.SetCell(8, 8, .TowerSlot);

		// Above z=9
		map.SetCell(3, 10, .TowerSlot);  map.SetCell(5, 10, .TowerSlot);
		map.SetCell(7, 10, .TowerSlot);  map.SetCell(9, 10, .TowerSlot);

		// Blocked tiles (decoration along edges)
		map.SetCell(0, 2, .Blocked);   map.SetCell(0, 5, .Blocked);
		map.SetCell(0, 8, .Blocked);   map.SetCell(0, 11, .Blocked);
		map.SetCell(11, 1, .Blocked);  map.SetCell(11, 4, .Blocked);
		map.SetCell(11, 7, .Blocked);  map.SetCell(11, 10, .Blocked);

		// Waypoints trace the snake path
		map.Waypoints.Add(map.GridToWorld(0, 0));   // Spawn
		map.Waypoints.Add(map.GridToWorld(10, 0));  // end of row 0
		map.Waypoints.Add(map.GridToWorld(10, 3));  // up at right
		map.Waypoints.Add(map.GridToWorld(1, 3));   // left along row 3
		map.Waypoints.Add(map.GridToWorld(1, 6));   // up at left
		map.Waypoints.Add(map.GridToWorld(10, 6));  // right along row 6
		map.Waypoints.Add(map.GridToWorld(10, 9));  // up at right
		map.Waypoints.Add(map.GridToWorld(1, 9));   // left along row 9
		map.Waypoints.Add(map.GridToWorld(1, 11));  // up to End

		return map;
	}
}
