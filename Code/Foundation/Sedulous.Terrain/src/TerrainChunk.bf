using Sedulous.Core;

namespace Sedulous.Terrain;

/// One terrain chunk: where it sits in the chunk grid, which block of samples it covers, and
/// its LOCAL space bounds. The renderer and the physics apply the entity's transform.
struct TerrainChunk
{
	public int32 ChunkX = 0;
	public int32 ChunkZ = 0;
	/// The sample grid origin: the chunk covers 64 quads from here in both directions.
	public int32 GridX0 = 0;
	public int32 GridZ0 = 0;
	public AABB Bounds = AABB.Empty();

	public this() {}
}
