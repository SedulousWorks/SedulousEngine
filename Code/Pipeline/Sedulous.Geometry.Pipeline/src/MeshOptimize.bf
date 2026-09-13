using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Geometry;
using meshoptimizer_Beef;

namespace Sedulous.Geometry.Pipeline;

/// The cook time mesh passes: a reorder that leaves the geometry identical, and a level of
/// detail chain generated from it.
///
/// EVERY pass is a pure reorder. The triangle set, the winding, the submesh ranges and the
/// vertex VALUES are unchanged, so what renders is identical and only the fetch and cache
/// behaviour improves.
static class MeshOptimize
{
	private static int Stride => sizeof(StaticMeshVertex);

	/// The cache miss ratio over every triangle range, which the cook log prints and the tests
	/// watch. Sixteen entries is the modern GPU model the library recommends.
	private static float TriangleAcmr(StaticMeshSource source, int vertexCount)
	{
		var weighted = 0.0f;
		var triangles = 0;
		for (int i < source.SubStart.Count)
		{
			let primitive = (i < source.SubPrimitive.Count) ? source.SubPrimitive[i] : 0;
			let count = source.SubCount[i];
			if (((PrimitiveType)primitive != .Triangles) || (count < 3))
				continue;

			let stats = meshopt_analyzeVertexCache(&source.IndexData[source.SubStart[i]],
				(uint)count, (uint)vertexCount, 16, 0, 0);
			weighted += stats.acmr * (float)(count / 3);
			triangles += count / 3;
		}
		return (triangles > 0) ? weighted / (float)triangles : 0.0f;
	}

	/// Every submesh window and every index, checked BEFORE anything is touched: a malformed
	/// asset cooks as it stands, loudly, rather than being reordered into something worse.
	private static bool RangesAreValid(StaticMeshSource source, int vertexCount, bool warn)
	{
		for (int i < source.SubStart.Count)
		{
			let start = (int64)source.SubStart[i];
			let count = (i < source.SubCount.Count) ? (int64)source.SubCount[i] : -1;
			if ((start < 0) || (count < 0) || ((start + count) > (int64)source.IndexData.Count))
			{
				if (warn)
					GlobalLog(.Warning, "Cook: mesh '{}' submesh {} has an invalid range, so it is not optimised",
						source.Name, i);
				return false;
			}
		}
		for (int i < source.LodStart.Count)
		{
			let start = (int64)source.LodStart[i];
			let count = (i < source.LodIndexCount.Count) ? (int64)source.LodIndexCount[i] : -1;
			if ((start < 0) || (count < 0) || ((start + count) > (int64)source.IndexData.Count))
			{
				if (warn)
					GlobalLog(.Warning, "Cook: mesh '{}' level of detail range {} is invalid, so it is not optimised",
						source.Name, i);
				return false;
			}
		}
		for (let index in source.IndexData)
		{
			if (index >= (uint32)vertexCount)
			{
				if (warn)
					GlobalLog(.Warning, "Cook: mesh '{}' index {} is past its {} vertices, so it is not optimised",
						source.Name, index, vertexCount);
				return false;
			}
		}
		return true;
	}

	/// Generates a level of detail chain into the source, border locked per submesh so a seam
	/// between two of them cannot crack apart.
	///
	/// Does nothing when the source already HAS a chain, since an authored one wins, when it
	/// has no triangle submeshes, or when it is malformed. Deterministic.
	public static uint32 GenerateLodChain(StaticMeshSource source,
		LodGenerationSettings settings = .())
	{
		let vertexCount = source.VertexBlob.Count / Stride;
		if ((vertexCount == 0) || source.IndexData.IsEmpty || source.SubStart.IsEmpty
			|| (source.LodCount > 1))
		{
			return 0;
		}
		if (!RangesAreValid(source, vertexCount, false))
			return 0;

		let positions = (float*)source.VertexBlob.Ptr;
		const uint32 cMaxGeneratedLevels = 3; // the ladder is three halvings
		let submeshCount = source.SubStart.Count;
		uint32 levelsAdded = 0;

		// Each level simplifies from the PREVIOUS one, which is cheaper and more coherent
		// than always going back to the finest.
		var previous = new List<List<uint32>>();
		defer { DeleteContainerAndItems!(previous); }
		for (int s < submeshCount)
		{
			let list = new List<uint32>();
			previous.Add(list);
			let primitive = (s < source.SubPrimitive.Count) ? source.SubPrimitive[s] : 0;
			if ((PrimitiveType)primitive != .Triangles)
				continue; // a non triangle submesh never simplifies; its range repeats level nought
			for (int i < source.SubCount[s])
				list.Add(source.IndexData[source.SubStart[s] + i]);
		}

		for (uint32 levelIndex < cMaxGeneratedLevels)
		{
			// Simplify every triangle submesh first, and commit the level only if EVERY one got
			// acceptably close: a chain is per MESH, so a level either exists for all of them
			// or not at all.
			var level = new List<List<uint32>>();
			var committed = false;
			defer { if (!committed) DeleteContainerAndItems!(level); }
			for (int s < submeshCount)
				level.Add(new List<uint32>());

			var acceptable = true;
			var levelTriangles = 0;
			for (int s < submeshCount)
			{
				if (previous[s].IsEmpty)
					continue; // a non triangle submesh: empty here, and repeats below

				let sourceCount = previous[s].Count;
				let target = ((sourceCount / 3) / 2) * 3; // half the triangles, aligned
				if (target < 3)
				{
					acceptable = false;
					break;
				}

				level[s].Count = sourceCount; // simplify writes at most this many
				float resultError = 0.0f;
				let written = (int)meshopt_simplify(level[s].Ptr, previous[s].Ptr,
					(uint)sourceCount, positions, (uint)vertexCount, (uint)Stride, (uint)target,
					settings.TargetError, .LockBorder, &resultError);
				level[s].Count = written;

				// Accepted when the simplifier got NEAR the halving target inside the error
				// bound. Stalling just below the source count means quality is exhausted.
				if ((written == 0) || (written > (sourceCount * 3) / 4))
				{
					acceptable = false;
					break;
				}
				levelTriangles += written / 3;
			}

			if (!acceptable || (levelTriangles < (int)settings.MinTriangles))
				break; // the chain is as long as quality allows, never padded

			if (source.LodCount <= 1)
			{
				source.LodCount = 1;
				source.LodCoverage.Clear();
				source.LodCoverage.Add(1.0f);
			}
			for (int s < submeshCount)
			{
				if (level[s].IsEmpty)
				{
					// A non triangle submesh repeats its finest range, so every level keeps the
					// full submesh table.
					source.LodStart.Add(source.SubStart[s]);
					source.LodIndexCount.Add(source.SubCount[s]);
					continue;
				}
				source.LodStart.Add((int32)source.IndexData.Count);
				source.LodIndexCount.Add((int32)level[s].Count);
				source.IndexData.AddRange(level[s]);
			}
			source.LodCoverage.Add(0.25f * Math.Pow(0.5f, (float)(source.LodCount - 1)));
			source.LodCount++;
			levelsAdded++;

			DeleteContainerAndItems!(previous);
			previous = level;
			committed = true;
		}

		if (levelsAdded > 0)
			GlobalLog(.Information, "Cook: mesh '{}' gained {} level(s) of detail", source.Name,
				levelsAdded);
		return levelsAdded;
	}

	/// A vertex cache and overdraw reorder per triangle submesh, then ONE whole mesh vertex
	/// fetch remap that reorders the blob, rewrites every index and compacts away vertices no
	/// index references.
	///
	/// A non triangle submesh keeps its index ORDER, though the remap still rewrites its index
	/// values. Deterministic. A skinned source's parallel skinning stream receives the
	/// identical permutation, and a stream whose size does not match refuses the whole pass
	/// rather than letting the two diverge.
	public static void OptimizeStaticMeshSource(StaticMeshSource source,
		MeshOptimizeStats* outStats = null)
	{
		let vertexCount = source.VertexBlob.Count / Stride;
		MeshOptimizeStats stats = .();
		stats.VerticesBefore = (uint32)vertexCount;
		stats.VerticesAfter = (uint32)vertexCount;

		mixin Give()
		{
			if (outStats != null)
				*outStats = stats;
			return;
		}

		if ((vertexCount == 0) || source.IndexData.IsEmpty || source.SubStart.IsEmpty)
			Give!();
		if (!RangesAreValid(source, vertexCount, true))
			Give!();

		let skinned = source as SkinnedMeshSource;
		if ((skinned != null)
			&& (skinned.SkinningBlob.Count != vertexCount * sizeof(VertexSkinning)))
		{
			GlobalLog(.Warning,
				"Cook: mesh '{}' has a skinning stream of the wrong size, so it is not optimised",
				source.Name);
			Give!();
		}

		stats.AcmrBefore = TriangleAcmr(source, vertexCount);

		// The reorder. Positions sit at offset nought of the vertex, and 1.05 is the library's
		// recommended balance between overdraw and cache.
		let positions = (float*)source.VertexBlob.Ptr;
		for (int i < source.SubStart.Count)
		{
			let primitive = (i < source.SubPrimitive.Count) ? source.SubPrimitive[i] : 0;
			let count = source.SubCount[i];
			if (((PrimitiveType)primitive != .Triangles) || (count < 3) || ((count % 3) != 0))
				continue;

			let range = &source.IndexData[source.SubStart[i]];
			meshopt_optimizeVertexCache(range, range, (uint)count, (uint)vertexCount);
			meshopt_optimizeOverdraw(range, range, (uint)count, positions, (uint)vertexCount,
				(uint)Stride, 1.05f);
			stats.TriangleSubmeshes++;
		}

		// A chain's levels get the same reorder: each is its own triangle range, whose
		// primitive type mirrors the submesh it came from.
		let submeshCount = source.SubStart.Count;
		for (int i < source.LodStart.Count)
		{
			let submesh = (submeshCount > 0) ? (i % submeshCount) : 0;
			let primitive = (submesh < source.SubPrimitive.Count) ? source.SubPrimitive[submesh] : 0;
			let count = source.LodIndexCount[i];
			if (((PrimitiveType)primitive != .Triangles) || (count < 3) || ((count % 3) != 0))
				continue;

			let range = &source.IndexData[source.LodStart[i]];
			meshopt_optimizeVertexCache(range, range, (uint)count, (uint)vertexCount);
			meshopt_optimizeOverdraw(range, range, (uint)count, positions, (uint)vertexCount,
				(uint)Stride, 1.05f);
		}

		// The whole mesh remap.
		let remap = scope List<uint32>();
		remap.Count = vertexCount;
		let uniqueCount = (int)meshopt_optimizeVertexFetchRemap(remap.Ptr, source.IndexData.Ptr,
			(uint)source.IndexData.Count, (uint)vertexCount);

		let remappedBlob = scope List<uint8>();
		remappedBlob.Count = uniqueCount * Stride;
		meshopt_remapVertexBuffer(remappedBlob.Ptr, source.VertexBlob.Ptr, (uint)vertexCount,
			(uint)Stride, remap.Ptr);

		if (skinned != null)
		{
			let skinStride = sizeof(VertexSkinning);
			let remappedSkin = scope List<uint8>();
			remappedSkin.Count = uniqueCount * skinStride;
			meshopt_remapVertexBuffer(remappedSkin.Ptr, skinned.SkinningBlob.Ptr,
				(uint)vertexCount, (uint)skinStride, remap.Ptr);
			skinned.SkinningBlob.Clear();
			skinned.SkinningBlob.AddRange(remappedSkin);
		}

		meshopt_remapIndexBuffer(source.IndexData.Ptr, source.IndexData.Ptr,
			(uint)source.IndexData.Count, remap.Ptr);
		source.VertexBlob.Clear();
		source.VertexBlob.AddRange(remappedBlob);
		stats.VerticesAfter = (uint32)uniqueCount;

		stats.AcmrAfter = TriangleAcmr(source, uniqueCount);
		GlobalLog(.Information,
			"Cook: mesh '{}' optimised {} triangle submesh(es), cache miss ratio {} to {}, vertices {} to {}",
			source.Name, stats.TriangleSubmeshes, stats.AcmrBefore, stats.AcmrAfter,
			stats.VerticesBefore, stats.VerticesAfter);

		if (outStats != null)
			*outStats = stats;
	}
}
