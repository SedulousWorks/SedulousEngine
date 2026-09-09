namespace Sedulous.Navigation;

/// The agent profile a navmesh is baked FOR.
///
/// The radius, height and climb are baked IN, so a navmesh is per profile: a zone with two
/// sizes of agent needs two of them. The cell sizes set the voxel resolution the bake works
/// at. The defaults are Recast's own human sized starting point.
struct NavigationBakeParams
{
	/// The voxel size across, in world units.
	public float CellSize = 0.3f;
	/// The voxel size vertically.
	public float CellHeight = 0.2f;

	/// Eroded off every walkable edge, so an agent of this width never clips a wall.
	public float AgentRadius = 0.6f;
	/// The headroom it needs to stand.
	public float AgentHeight = 2.0f;
	/// The step or ledge it walks up.
	public float AgentMaxClimb = 0.9f;
	/// Anything steeper is not walkable.
	public float AgentMaxSlopeDegrees = 45.0f;

	/// The cells along a tile's edge, so a tile spans this many times the cell size. Sixty
	/// four at three tenths is a little under twenty units: a small zone stays one tile and a
	/// large one splits, which is also what makes a partial rebake regenerate one tile rather
	/// than the zone.
	public uint32 TileCells = 64;

	/// Whether the tiles bake across workers. They are independent and the assembly stays row
	/// major, so THE OUTPUT IS THE SAME EITHER WAY: this trades latency, never bytes.
	public bool ParallelBake = true;

	public this() {}
}
