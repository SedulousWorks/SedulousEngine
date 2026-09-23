using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;

namespace Sedulous.Terrain.Tests;

/// The holed chunk's own index buffers: a quad whose sample block holds a cut sample goes, and
/// so does the skirt segment riding on it.
class TerrainHoleIndexTests
{
	private static Heightfield MakeGrid() => new Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);

	[Test]
	public static void ASolidChunkBuildsExactlyTheSharedGrid()
	{
		let field = MakeGrid();
		defer delete field;

		let shared = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, shared);

		let holed = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, holed, let surface);

		Test.Assert(holed.Count == shared.Count, "nothing cut, so nothing dropped");
		Test.Assert(surface == TerrainMesh.ChunkLodSurfaceIndexCount(0));
		for (int i < shared.Count)
			Test.Assert(holed[i] == shared[i]);
	}

	[Test]
	public static void OneCutSampleDropsTheQuadsAroundItAtEveryLevel()
	{
		let field = MakeGrid();
		defer delete field;
		// A sample in the chunk's interior: the four quads that share it go.
		field.SetHole(10, 10, true);

		let indices = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, indices, let surface);
		Test.Assert(surface == (TerrainMesh.ChunkLodSurfaceIndexCount(0) - (4 * 6)));

		// At a coarser level the quad is bigger, so ONE quad covers the cut sample and goes:
		// a hole never shrinks with distance.
		let coarse = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 2, coarse, let coarseSurface);
		Test.Assert(coarseSurface < TerrainMesh.ChunkLodSurfaceIndexCount(2));
		Test.Assert(coarseSurface > 0, "the rest of the chunk still draws");
	}

	[Test]
	public static void AnEdgeCutTakesItsSkirtSegmentWithIt()
	{
		let field = MakeGrid();
		defer delete field;

		let solid = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, solid, let solidSurface);
		let solidSkirt = (uint32)solid.Count - solidSurface;
		Test.Assert(solidSkirt > 0);

		// A sample on the z nought edge: its quads go, and so does the skirt wall beneath
		// them, since a wall hanging under a cut rim is exactly what a player sees through.
		field.SetHole(4, 0, true);
		let cut = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, cut, let cutSurface);
		let cutSkirt = (uint32)cut.Count - cutSurface;
		Test.Assert(cutSurface < solidSurface);
		Test.Assert(cutSkirt < solidSkirt, "the skirt segment rode on the quad that went");
	}

	[Test]
	public static void AChunkCutEverywhereBuildsNothingAndTheChunkSaysSo()
	{
		let field = MakeGrid();
		defer delete field;
		for (int32 z = 0; z < 65; z++)
			for (int32 x = 0; x < 65; x++)
				field.SetHole(x, z, true);

		let indices = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, indices, let surface);
		Test.Assert(indices.IsEmpty);
		Test.Assert(surface == 0);

		// And the chunk itself carries both flags, so the renderer skips it without looking.
		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);
		Test.Assert(chunks.Count == 1);
		Test.Assert(chunks[0].HasHoles);
		Test.Assert(chunks[0].AllCut);
	}

	[Test]
	public static void AChunkWithNoCutSampleCarriesNeitherFlag()
	{
		let field = MakeGrid();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);
		Test.Assert(!chunks[0].HasHoles);
		Test.Assert(!chunks[0].AllCut);

		field.SetHole(32, 32, true);
		TerrainChunks.BuildChunks(field, chunks);
		Test.Assert(chunks[0].HasHoles);
		Test.Assert(!chunks[0].AllCut, "one cut sample is not a cut chunk");
	}

	[Test]
	public static void TheRenderRuleKeepsAQuadWhileOneSampleIsSolid()
	{
		let field = MakeGrid();
		defer delete field;

		// One cut sample touches four quads at the finest level. The strict rule drops all
		// four; the draw rule drops none, no quad being cut at every corner, and the mask
		// shapes the rim inside them.
		field.SetHole(10, 10, true);
		let strict = scope List<uint32>();
		let render = scope List<uint32>();
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, strict, let strictSurface, true);
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, render, let renderSurface, false);
		Test.Assert(strictSurface == (64 * 64 - 4) * 6);
		Test.Assert(renderSurface == 64 * 64 * 6);
		Test.Assert(render.Count == strict.Count + 4 * 6);

		// A whole three by three block cut: now four quads ARE cut at every corner, and the
		// draw rule drops exactly those.
		for (int32 z = 20; z <= 22; z++)
			for (int32 x = 20; x <= 22; x++)
				field.SetHole(x, z, true);

		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, 0, render, let blockSurface, false);
		Test.Assert(blockSurface == (64 * 64 - 4) * 6);

		// At the coarsest level the single quad spans every sample: the draw rule keeps it,
		// most of it being solid, and the strict rule drops it for the one cut.
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, TerrainMesh.MaxChunkLod, render,
			let coarseRender, false);
		Test.Assert(coarseRender == 6);
		TerrainMesh.BuildHoledChunkIndices(field, 0, 0, TerrainMesh.MaxChunkLod, strict,
			let coarseStrict, true);
		Test.Assert(coarseStrict == 0);
	}
}
