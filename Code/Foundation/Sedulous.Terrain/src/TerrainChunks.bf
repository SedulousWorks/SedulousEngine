using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Lod;

namespace Sedulous.Terrain;

/// The chunk grid over a heightfield, and the per chunk level of detail selection.
///
/// A heightfield of side 64k + 1 tiles into k by k chunks of 64 quads that share their edges.
/// Everything here is pure: a view and a projection are plain matrices, so all of it is
/// testable without a device.
static class TerrainChunks
{
	/// Chunks along one side of a heightfield of a given size.
	public static int32 ChunksPerSide(int32 heightfieldSize) =>
		(heightfieldSize > 1) ? ((heightfieldSize - 1) / TerrainMesh.ChunkQuads) : 0;

	/// Builds the chunk grid: each chunk's XZ footprint from the world mapping, and its Y
	/// range from the heightfield's own block bounds.
	///
	/// ROW MAJOR with the chunk row outermost, so the chunk at (cx, cz) is at index
	/// cz * ChunksPerSide + cx.
	public static void BuildChunks(Heightfield field, List<TerrainChunk> outChunks)
	{
		outChunks.Clear();

		let side = ChunksPerSide(field.Size);
		for (int32 cz = 0; cz < side; cz++)
		{
			for (int32 cx = 0; cx < side; cx++)
			{
				let gx0 = cx * TerrainMesh.ChunkQuads;
				let gz0 = cz * TerrainMesh.ChunkQuads;
				field.CellBounds(gx0, gz0, gx0 + TerrainMesh.ChunkQuads,
					gz0 + TerrainMesh.ChunkQuads, let minY, let maxY);

				let w0 = field.GridToWorld((float)gx0, (float)gz0);
				let w1 = field.GridToWorld((float)(gx0 + TerrainMesh.ChunkQuads),
					(float)(gz0 + TerrainMesh.ChunkQuads));

				var chunk = TerrainChunk();
				chunk.ChunkX = cx;
				chunk.ChunkZ = cz;
				chunk.GridX0 = gx0;
				chunk.GridZ0 = gz0;
				chunk.Bounds = .(.(w0.X, minY, w0.Y), .(w1.X, maxY, w1.Y));
				outChunks.Add(chunk);
			}
		}
	}

	/// A chunk's LOCAL space bounding sphere, which is the bridge to the shared coverage
	/// metric.
	public static BoundingSphere ChunkBoundingSphere(TerrainChunk chunk) =>
		.(chunk.Bounds.Center(), Length(chunk.Bounds.Extents()));

	/// A chunk's level of detail through the SHARED coverage metric, which is one formula for
	/// meshes and terrain alike.
	///
	/// The chunk's local sphere is placed in the world by `chunkToWorld`, which the terrain
	/// instance model keeps to a translation and a rotation about Y so the radius survives,
	/// projected to a screen coverage, and walked against the DESCENDING thresholds.
	public static uint32 SelectChunkLod(TerrainChunk chunk, Float4x4 chunkToWorld, Float4x4 view,
		Float4x4 projection, Span<float> coverageThresholds, float bias = 0.0f)
	{
		let sphere = ChunkBoundingSphere(chunk);
		let worldCenter = TransformPoint(sphere.Center, chunkToWorld);
		let coverage = LodMath.ProjectedSphereCoverage(view, projection, worldCenter, sphere.Radius,
			bias);
		return LodMath.SelectLevelByCoverage(coverageThresholds, coverage);
	}

	/// Every chunk's level for one view, which is what the renderer feeds the draw.
	public static void SelectChunkLods(Span<TerrainChunk> chunks, Float4x4 chunkToWorld,
		Float4x4 view, Float4x4 projection, Span<float> coverageThresholds, float bias,
		List<uint32> outLods)
	{
		outLods.Clear();
		outLods.Reserve(chunks.Length);

		for (let chunk in chunks)
			outLods.Add(SelectChunkLod(chunk, chunkToWorld, view, projection, coverageThresholds, bias));
	}

	/// The renderer's per frame extract: cull the chunk quadtree, then pick a level for each
	/// chunk that survived. The draw list the GPU renderer consumes.
	public static void ExtractVisibleChunkDraws(Span<TerrainQuadtreeNode> nodes,
		Span<TerrainChunk> chunks, Float4x4 chunkToWorld, Float4x4 view, Float4x4 projection,
		BoundingFrustum frustum, Span<float> coverageThresholds, float bias,
		List<ChunkDraw> outDraws)
	{
		outDraws.Clear();

		let visible = scope List<int32>();
		TerrainQuadtree.CullNodes(nodes, frustum, visible);
		outDraws.Reserve(visible.Count);

		for (let chunkIndex in visible)
		{
			let lod = SelectChunkLod(chunks[chunkIndex], chunkToWorld, view, projection,
				coverageThresholds, bias);
			outDraws.Add(.(chunkIndex, lod));
		}
	}

	/// Over a live tree, for a caller that owns one.
	public static void ExtractVisibleChunkDraws(TerrainQuadtree tree, Span<TerrainChunk> chunks,
		Float4x4 chunkToWorld, Float4x4 view, Float4x4 projection, BoundingFrustum frustum,
		Span<float> coverageThresholds, float bias, List<ChunkDraw> outDraws)
	{
		ExtractVisibleChunkDraws(tree.Nodes, chunks, chunkToWorld, view, projection, frustum,
			coverageThresholds, bias, outDraws);
	}
}
