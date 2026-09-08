namespace Sedulous.Terrain;

/// One chunk to draw this frame: which chunk, and the level of detail whose index buffer to
/// bind for it.
struct ChunkDraw
{
	public int32 ChunkIndex = 0;
	public uint32 Lod = 0;

	public this() {}

	public this(int32 chunkIndex, uint32 lod)
	{
		ChunkIndex = chunkIndex;
		Lod = lod;
	}
}
