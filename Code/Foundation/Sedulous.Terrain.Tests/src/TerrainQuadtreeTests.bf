using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;

namespace Sedulous.Terrain.Tests;

/// The quadtree over the chunk grid, and the draw list the renderer extracts from it.
class TerrainQuadtreeTests
{
	/// A 129 grid, two chunks a side, over a 128 by 128 world, rising along +X.
	private static Heightfield MakeRampX(int32 size = 129)
	{
		let field = new Heightfield(size, .((float)(size - 1), (float)(size - 1)), 0.0f, 10.0f);
		for (int32 z = 0; z < size; z++)
		{
			for (int32 x = 0; x < size; x++)
				field.SetSample(x, z, (uint16)((float)x / (float)(size - 1) * 65535.0f));
		}
		return field;
	}

	private static Float4x4 Projection() => Float4x4.PerspectiveFovRH(1.2f, 1.0f, 1.0f, 5000.0f);

	/// Directly above the terrain, looking down at it.
	private static Float4x4 LookingDown() =>
		Float4x4.LookAtRH(.(0.0f, 300.0f, 0.1f), .(0.0f, 0.0f, 0.0f), .(0.0f, 0.0f, 1.0f));

	/// Far off to one side, looking further away from the terrain.
	private static Float4x4 LookingAway() =>
		Float4x4.LookAtRH(.(5000.0f, 100.0f, 0.0f), .(6000.0f, 100.0f, 0.0f), .(0.0f, 1.0f, 0.0f));

	private static void BuildOver(Heightfield field, List<TerrainChunk> outChunks,
		TerrainQuadtree tree)
	{
		TerrainChunks.BuildChunks(field, outChunks);
		tree.Build(outChunks, TerrainChunks.ChunksPerSide(field.Size));
	}

	[Test]
	public static void TheTreeCoversTheChunkGrid()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		Test.Assert(!tree.IsEmpty);
		Test.Assert(tree.NodeCount == 5, "a root over four leaves");
	}

	/// A single chunk grid is a tree of ONE node, which is itself a leaf.
	[Test]
	public static void ASingleChunkGridIsOneLeaf()
	{
		let field = MakeRampX(65);
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		Test.Assert(tree.NodeCount == 1);
		Test.Assert(tree.Nodes[0].IsLeaf);
		Test.Assert(tree.Nodes[0].ChunkIndex == 0);
	}

	/// An ODD side splits unevenly rather than refusing to build, so a heightfield of 193
	/// tiles as happily as one of 257.
	[Test]
	public static void AnOddSidedGridStillBuilds()
	{
		let field = MakeRampX(193);
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);
		Test.Assert(chunks.Count == 9, "three by three");
		Test.Assert(!tree.IsEmpty);

		// Every chunk is still reachable, which is what an uneven split has to preserve.
		let visible = scope List<int32>();
		tree.Cull(Everything(), visible);
		Test.Assert(visible.Count == 9);
	}

	/// A frustum that contains the whole world, so culling drops nothing.
	private static BoundingFrustum Everything() =>
		.(Float4x4.LookAtRH(.(0.0f, 5000.0f, 0.1f), .(0.0f, 0.0f, 0.0f), .(0.0f, 0.0f, 1.0f))
			* Float4x4.PerspectiveFovRH(2.0f, 1.0f, 1.0f, 20000.0f));

	/// An empty grid builds an empty tree rather than a root over nothing.
	[Test]
	public static void AnEmptyGridBuildsNoTree()
	{
		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		tree.Build(chunks, 0);

		Test.Assert(tree.IsEmpty);
		Test.Assert(tree.NodeCount == 0);

		let visible = scope List<int32>();
		tree.Cull(Everything(), visible);
		Test.Assert(visible.IsEmpty);
	}

	[Test]
	public static void CullingKeepsWhatTheFrustumSeesAndDropsTheRest()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		let visible = scope List<int32>();
		tree.Cull(BoundingFrustum(LookingDown() * Projection()), visible);
		Test.Assert(visible.Count == 4, "from above, every chunk");

		tree.Cull(BoundingFrustum(LookingAway() * Projection()), visible);
		Test.Assert(visible.IsEmpty, "and looking away, none");
	}

	/// The nodes cull identically through a COPY, which is what lets the renderer snapshot
	/// them into its frame arena instead of dereferencing a tree whose owner may have moved
	/// on mid frame.
	[Test]
	public static void ACopyOfTheNodesCullsIdentically()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		let snapshot = scope List<TerrainQuadtreeNode>();
		for (let node in tree.Nodes)
			snapshot.Add(node);

		let frustum = BoundingFrustum(LookingDown() * Projection());
		let fromTree = scope List<int32>();
		tree.Cull(frustum, fromTree);

		let fromCopy = scope List<int32>();
		TerrainQuadtree.CullNodes(snapshot, frustum, fromCopy);

		Test.Assert(fromCopy.Count == fromTree.Count);
		for (int i < fromTree.Count)
			Test.Assert(fromCopy[i] == fromTree[i]);
	}

	[Test]
	public static void ExtractingGivesACulledAndLevelledDrawList()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		let thresholds = scope float[](1.0f, 0.2f, 0.05f);
		let identity = Float4x4.Identity();
		let draws = scope List<ChunkDraw>();

		let view = LookingDown();
		TerrainChunks.ExtractVisibleChunkDraws(tree, chunks, identity, view, Projection(),
			BoundingFrustum(view * Projection()), thresholds, 0.0f, draws);

		Test.Assert(draws.Count == 4);
		for (let draw in draws)
		{
			Test.Assert((draw.ChunkIndex >= 0) && (draw.ChunkIndex < 4));
			Test.Assert(draw.Lod <= 3, "within the thresholds it was given");
			Test.Assert(draw.Lod == TerrainChunks.SelectChunkLod(chunks[draw.ChunkIndex], identity,
				view, Projection(), thresholds), "the same level the per chunk call picks");
		}
	}

	[Test]
	public static void ExtractingSomethingOffScreenDrawsNothing()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		let thresholds = scope float[](1.0f, 0.2f, 0.05f);
		let view = LookingAway();
		let draws = scope List<ChunkDraw>();

		TerrainChunks.ExtractVisibleChunkDraws(tree, chunks, Float4x4.Identity(), view, Projection(),
			BoundingFrustum(view * Projection()), thresholds, 0.0f, draws);
		Test.Assert(draws.IsEmpty);
	}

	/// Extraction over a bare node span is the same as over the tree, which is the form the
	/// renderer actually calls.
	[Test]
	public static void ExtractingOverASnapshotMatchesTheTree()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		let tree = scope TerrainQuadtree();
		BuildOver(field, chunks, tree);

		let snapshot = scope List<TerrainQuadtreeNode>();
		for (let node in tree.Nodes)
			snapshot.Add(node);

		let thresholds = scope float[](1.0f, 0.2f, 0.05f);
		let identity = Float4x4.Identity();
		let view = LookingDown();
		let frustum = BoundingFrustum(view * Projection());

		let fromTree = scope List<ChunkDraw>();
		TerrainChunks.ExtractVisibleChunkDraws(tree, chunks, identity, view, Projection(), frustum,
			thresholds, 0.0f, fromTree);

		let fromSnapshot = scope List<ChunkDraw>();
		TerrainChunks.ExtractVisibleChunkDraws(Span<TerrainQuadtreeNode>(snapshot.Ptr,
			snapshot.Count), chunks, identity, view, Projection(), frustum, thresholds, 0.0f,
			fromSnapshot);

		Test.Assert(fromSnapshot.Count == fromTree.Count);
		for (int i < fromTree.Count)
		{
			Test.Assert(fromSnapshot[i].ChunkIndex == fromTree[i].ChunkIndex);
			Test.Assert(fromSnapshot[i].Lod == fromTree[i].Lod);
		}
	}

	[Test]
	public static void ASplatLayerTilesOnceByDefault()
	{
		let layer = SplatLayer();
		Test.Assert(layer.TileScale == 1.0f);
	}
}
