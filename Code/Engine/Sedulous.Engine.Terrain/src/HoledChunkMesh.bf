using Sedulous.RHI;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain;

/// The index buffers of ONE holed chunk, per level of detail.
///
/// Built on the CPU by the terrain mesh's holed index walk whenever the heightfield's version
/// changes, owned by the manager's cache, and copied into the frame arena BY VALUE: the
/// buffers themselves outlive the frame through the retire queue.
///
/// A chunk with no holes draws the renderer's shared grid instead, which is the common case
/// and costs nothing.
struct HoledChunkMesh
{
	public uint32 ChunkIndex = 0;
	public IBuffer[TerrainMesh.MaxChunkLod + 1] IndexBuffers = .();
	public uint32[TerrainMesh.MaxChunkLod + 1] IndexCounts = .();
	public uint32[TerrainMesh.MaxChunkLod + 1] SurfaceIndexCounts = .();

	public this() {}
}
