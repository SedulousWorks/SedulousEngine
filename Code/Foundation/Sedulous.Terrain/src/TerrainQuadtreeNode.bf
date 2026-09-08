using Sedulous.Core;

namespace Sedulous.Terrain;

/// One quadtree node over the chunk grid.
///
/// Deliberately a PLAIN VALUE with no references out. The render extraction snapshots the
/// node array into its frame arena, because a pointer to the tree is only as stable as its
/// owner and owners do mutate mid frame; a node that referred back to anything would make
/// that snapshot a lie.
struct TerrainQuadtreeNode
{
	public AABB Bounds = AABB.Empty();
	/// At or above zero for a leaf, which is one chunk.
	public int32 ChunkIndex = -1;
	public int32 ChildCount = 0;
	public int32[4] Children = .(-1, -1, -1, -1);

	public this() {}

	public bool IsLeaf => ChunkIndex >= 0;
}
