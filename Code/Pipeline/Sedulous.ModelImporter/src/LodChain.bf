using System;
using System.Collections;
using Sedulous.Geometry;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Attaching an authored level of detail to the mesh it belongs to.
///
/// A level's vertices join the shared blob, its indices join the one index buffer offset past
/// what was already there, and one range lands per part.
static class LodChain
{
	/// Appends an ALREADY converted level to a base.
	///
	/// The level's part count has to MATCH the base's submesh count: the material layout
	/// belongs to the chain as a whole and a level never re-sorts it. A mismatch is refused
	/// with the base untouched, because half an appended level is worse than none.
	public static bool AppendConverted(StaticMeshSource level, StaticMeshSource @base)
	{
		if ((level.SubStart.Count != @base.SubStart.Count) || @base.SubStart.IsEmpty)
			return false;

		let stride = sizeof(StaticMeshVertex);
		let baseVertexCount = (uint32)(@base.VertexBlob.Count / stride);
		let indexBase = (int32)@base.IndexData.Count;

		@base.VertexBlob.AddRange(level.VertexBlob);
		for (let index in level.IndexData)
			@base.IndexData.Add(index + baseVertexCount);

		if (@base.LodCount <= 1)
		{
			@base.LodCount = 1;
			@base.LodCoverage.Clear();
			@base.LodCoverage.Add(1.0f);
		}

		for (int s < level.SubStart.Count)
		{
			@base.LodStart.Add(indexBase + level.SubStart[s]);
			@base.LodIndexCount.Add(level.SubCount[s]);
		}

		// A halving ladder, which is the same one a generated chain uses, so an authored and
		// a generated chain switch at the same coverage.
		@base.LodCoverage.Add(0.25f * Math.Pow(0.5f, (float)(@base.LodCount - 1)));
		@base.LodCount++;
		return true;
	}

	public static bool AppendFromModel(ModelMesh lodMesh, StaticMeshSource @base)
	{
		let level = scope StaticMeshSource();
		MeshConvert.StaticFromModel(lodMesh, level);
		return AppendConverted(level, @base);
	}

	/// The SKINNED case: the level's parallel skinning stream appends in lockstep with its
	/// vertices, so the two cannot diverge. A level whose stream does not match its own vertex
	/// count is refused before anything is appended.
	public static bool AppendFromModel(ModelMesh lodMesh, SkinnedMeshSource @base)
	{
		let level = scope SkinnedMeshSource();
		MeshConvert.SkinnedFromModel(lodMesh, @base.SkeletonIndex, level);

		let levelVertices = level.VertexBlob.Count / sizeof(StaticMeshVertex);
		if (level.SkinningBlob.Count != levelVertices * sizeof(VertexSkinning))
			return false;

		if (!AppendConverted(level, @base))
			return false;

		@base.SkinningBlob.AddRange(level.SkinningBlob);
		return true;
	}
}
