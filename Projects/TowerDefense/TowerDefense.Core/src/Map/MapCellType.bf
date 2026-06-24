namespace TowerDefense;

/// Type of cell in the tower defense grid.
public enum MapCellType
{
	/// Open ground, no placement allowed.
	Empty,
	/// Enemy path tile.
	Path,
	/// Valid location for tower placement.
	TowerSlot,
	/// Impassable terrain (rocks, trees).
	Blocked,
	/// Enemy spawn point.
	Spawn,
	/// Enemy destination (base to defend).
	End
}
