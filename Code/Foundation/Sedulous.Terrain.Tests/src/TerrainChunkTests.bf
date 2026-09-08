using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;

namespace Sedulous.Terrain.Tests;

/// The chunk grid over a heightfield, and the level of detail chosen per chunk.
class TerrainChunkTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A 129 grid, which is two chunks a side, over a 128 by 128 world, rising along +X.
	private static Heightfield MakeRampX()
	{
		let field = new Heightfield(129, .(128.0f, 128.0f), 0.0f, 10.0f);
		for (int32 z = 0; z < 129; z++)
		{
			for (int32 x = 0; x < 129; x++)
				field.SetSample(x, z, (uint16)((float)x / 128.0f * 65535.0f));
		}
		return field;
	}

	private static Float4x4 Projection() => Float4x4.PerspectiveFovRH(1.0f, 1.0f, 1.0f, 5000.0f);

	private static Float4x4 LookingDownFrom(float height) =>
		Float4x4.LookAtRH(.(0.0f, height, 0.1f), .(0.0f, 0.0f, 0.0f), .(0.0f, 0.0f, 1.0f));

	[Test]
	public static void ChunksPerSideFollowsTheSizeContract()
	{
		Test.Assert(TerrainChunks.ChunksPerSide(65) == 1);
		Test.Assert(TerrainChunks.ChunksPerSide(129) == 2);
		Test.Assert(TerrainChunks.ChunksPerSide(257) == 4);
		Test.Assert(TerrainChunks.ChunksPerSide(193) == 3, "64k + 1 need not be a power of two");
		Test.Assert(TerrainChunks.ChunksPerSide(1025) == 16);
	}

	/// An empty grid tiles into nothing, which is what a failed heightfield build leaves.
	[Test]
	public static void AnEmptyGridHasNoChunks()
	{
		Test.Assert(TerrainChunks.ChunksPerSide(0) == 0);
		Test.Assert(TerrainChunks.ChunksPerSide(1) == 0);

		let field = scope Heightfield();
		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);
		Test.Assert(chunks.IsEmpty);
	}

	[Test]
	public static void ChunksTileTheFootprintAndTakeTheirOwnYRange()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);
		Test.Assert(chunks.Count == 4, "two by two");

		// Row major: (cx, cz) sits at cz * 2 + cx.
		let west = chunks[0];
		let east = chunks[1];
		Test.Assert((west.ChunkX == 0) && (west.ChunkZ == 0));
		Test.Assert(east.ChunkX == 1);
		Test.Assert((east.GridX0 == 64) && (east.GridZ0 == 0), "and its block of samples");

		Test.Assert(Near(west.Bounds.Min.X, -64.0f));
		Test.Assert(Near(west.Bounds.Max.X, 0.0f));
		Test.Assert(Near(east.Bounds.Min.X, 0.0f));
		Test.Assert(Near(east.Bounds.Max.X, 64.0f));

		// The ramp rises along +X, so the west chunk sits below the east one.
		Test.Assert(Near(west.Bounds.Min.Y, 0.0f));
		Test.Assert(west.Bounds.Max.Y < east.Bounds.Max.Y);
		Test.Assert(Near(east.Bounds.Max.Y, 10.0f));
	}

	/// Neighbouring chunks SHARE their edge, which is what keeps the surface continuous.
	[Test]
	public static void NeighbouringChunksShareTheirEdge()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);

		Test.Assert(Near(chunks[0].Bounds.Max.X, chunks[1].Bounds.Min.X));
		Test.Assert(Near(chunks[0].Bounds.Max.Z, chunks[2].Bounds.Min.Z));
	}

	[Test]
	public static void CloserIsNeverCoarser()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);

		// Descending, with the first at one by convention: level zero is the fallback.
		let thresholds = scope float[](1.0f, 0.2f, 0.05f);
		let identity = Float4x4.Identity();

		let near = TerrainChunks.SelectChunkLod(chunks[0], identity, LookingDownFrom(50.0f),
			Projection(), thresholds);
		let far = TerrainChunks.SelectChunkLod(chunks[0], identity, LookingDownFrom(3000.0f),
			Projection(), thresholds);

		Test.Assert(near <= far);
		Test.Assert(near == 0, "close covers a lot of screen, so the finest level");
		Test.Assert(far > 0, "and far covers little");
	}

	[Test]
	public static void TheBatchMatchesThePerChunkCall()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);

		let thresholds = scope float[](1.0f, 0.2f, 0.05f);
		let identity = Float4x4.Identity();
		let view = LookingDownFrom(50.0f);

		let lods = scope List<uint32>();
		TerrainChunks.SelectChunkLods(chunks, identity, view, Projection(), thresholds, 0.0f, lods);

		Test.Assert(lods.Count == chunks.Count);
		for (int i < chunks.Count)
		{
			Test.Assert(lods[i] == TerrainChunks.SelectChunkLod(chunks[i], identity, view,
				Projection(), thresholds));
		}
	}

	/// The bridge to the coverage metric ENCLOSES the chunk's box, or the level chosen would
	/// be for something smaller than the chunk.
	[Test]
	public static void TheBoundingSphereEnclosesTheChunk()
	{
		let field = MakeRampX();
		defer delete field;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(field, chunks);

		let sphere = TerrainChunks.ChunkBoundingSphere(chunks[0]);
		Test.Assert(Near(sphere.Center.X, chunks[0].Bounds.Center().X));
		Test.Assert(sphere.Radius >= Length(chunks[0].Bounds.Extents()) - 0.001f);
	}
}
