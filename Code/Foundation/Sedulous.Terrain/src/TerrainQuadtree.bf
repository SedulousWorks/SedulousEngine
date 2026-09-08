using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Terrain;

/// A quadtree over the chunk grid, for hierarchical frustum culling.
///
/// Leaves are single chunks and internal nodes carry the union of their children's bounds,
/// so a node the frustum misses prunes its whole subtree. Works for ANY grid side, splitting
/// unevenly when a side is odd.
class TerrainQuadtree
{
	private List<TerrainQuadtreeNode> mNodes = new .() ~ delete _;
	/// BORROWED for the build only: nothing here holds it afterwards.
	private Span<TerrainChunk> mChunks;
	private int32 mSide = 0;

	public bool IsEmpty => mNodes.IsEmpty;
	public int NodeCount => mNodes.Count;

	/// The flat node storage, the root being index zero.
	///
	/// SNAPSHOT FRIENDLY: a copy of this span culls identically through CullNodes, with no
	/// reference back to this object or to the chunks it was built from.
	public Span<TerrainQuadtreeNode> Nodes => .(mNodes.Ptr, mNodes.Count);

	public void Build(Span<TerrainChunk> chunks, int32 chunksPerSide)
	{
		mNodes.Clear();
		mChunks = chunks;
		mSide = chunksPerSide;

		if ((chunksPerSide > 0) && (chunks.Length >= (int)chunksPerSide * (int)chunksPerSide))
			BuildNode(0, chunksPerSide, 0, chunksPerSide);

		// The chunks were needed only while the leaves were being filled in.
		mChunks = default;
	}

	/// The indices of the chunks whose bounds the frustum does not miss.
	public void Cull(BoundingFrustum frustum, List<int32> outVisible) =>
		CullNodes(Nodes, frustum, outVisible);

	/// Culling over a BARE node span, which is the form the renderer uses against its frame
	/// arena copy: no live tree is dereferenced at draw time.
	public static void CullNodes(Span<TerrainQuadtreeNode> nodes, BoundingFrustum frustum,
		List<int32> outVisible)
	{
		outVisible.Clear();
		if (!nodes.IsEmpty)
			CullNodeIn(nodes, 0, frustum, outVisible);
	}

	/// Builds over the chunk rectangle, upper bounds exclusive, and answers the node's index.
	private int32 BuildNode(int32 x0, int32 x1, int32 z0, int32 z1)
	{
		let nodeIndex = (int32)mNodes.Count;
		mNodes.Add(TerrainQuadtreeNode());

		if (((x1 - x0) == 1) && ((z1 - z0) == 1))
		{
			let chunkIndex = z0 * mSide + x0;
			mNodes[nodeIndex].ChunkIndex = chunkIndex;
			mNodes[nodeIndex].Bounds = mChunks[chunkIndex].Bounds;
			return nodeIndex;
		}

		// A side of one does not split, which is what makes an odd grid work.
		let xm = ((x1 - x0) > 1) ? ((x0 + x1) / 2) : x1;
		let zm = ((z1 - z0) > 1) ? ((z0 + z1) / 2) : z1;
		let xEdges = int32[3](x0, xm, x1);
		let zEdges = int32[3](z0, zm, z1);
		let xCount = ((x1 - x0) > 1) ? 2 : 1;
		let zCount = ((z1 - z0) > 1) ? 2 : 1;

		var bounds = AABB.Empty();
		var childCount = 0;
		for (int zi < zCount)
		{
			for (int xi < xCount)
			{
				let child = BuildNode(xEdges[xi], xEdges[xi + 1], zEdges[zi], zEdges[zi + 1]);
				mNodes[nodeIndex].Children[childCount++] = child;
				bounds = Merge(bounds, mNodes[child].Bounds);
			}
		}

		mNodes[nodeIndex].ChildCount = (int32)childCount;
		mNodes[nodeIndex].Bounds = bounds;
		return nodeIndex;
	}

	private static void CullNodeIn(Span<TerrainQuadtreeNode> nodes, int32 nodeIndex,
		BoundingFrustum frustum, List<int32> outVisible)
	{
		let node = nodes[nodeIndex];
		if (Contains(frustum, node.Bounds) == .Disjoint)
			return;

		if (node.IsLeaf)
		{
			outVisible.Add(node.ChunkIndex);
			return;
		}

		for (int i < node.ChildCount)
			CullNodeIn(nodes, node.Children[i], frustum, outVisible);
	}
}
