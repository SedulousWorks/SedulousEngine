using System;
using System.Collections;
using Sedulous.Geometry;

namespace Samples.AnimatedCrowd;

/// Merges a character's skinned parts into ONE mesh, a submesh per original part.
///
/// A straight concatenation is enough because the parts share a skeleton and render in its root
/// space: there is no transform to reconcile, only index values to rebase. That is what lets the
/// crowd draw a whole character as one instanced set instead of several.
static class SkinnedMeshMerge
{
	/// THE CALLER OWNS the result. Null when there is nothing to merge.
	public static StaticMesh Merge(List<SkinnedPart> parts)
	{
		if (parts.IsEmpty)
			return null;

		let merged = new SkinnedMesh();

		uint32 totalIndices = 0;
		for (let part in parts)
			totalIndices += part.Mesh.IndexCount;

		// Resize sets the LOGICAL count up front, so Count reports the full size immediately
		// and the fill position has to be tracked separately: Add advances its own cursor.
		merged.Indices.Resize(totalIndices);

		uint32 written = 0;
		for (let part in parts)
		{
			let source = part.Mesh;
			let vertexBase = merged.VertexCount;

			for (let vertex in source.Vertices)
				merged.Vertices.Add(vertex);

			let skinning = source.SkinningStream;
			for (int i < skinning.Length)
				merged.Skinning.Add(skinning[i]);

			// A part with no skinning stream still needs its vertices to have entries, or the
			// two streams desynchronise for everything after it.
			while (merged.Skinning.Count < merged.Vertices.Count)
				merged.Skinning.Add(.());

			if (source.SubMeshes.IsEmpty)
			{
				SubMesh submesh = .();
				submesh.StartIndex = (int32)written;
				submesh.IndexCount = (int32)source.IndexCount;
				submesh.MaterialIndex = (part.MaterialIndex >= 0) ? part.MaterialIndex : 0;

				for (uint32 k < source.IndexCount)
				{
					merged.Indices.Add(source.Indices.Get(k) + vertexBase);
					written++;
				}
				merged.SubMeshes.Add(submesh);
			}
			else
			{
				for (let original in source.SubMeshes)
				{
					var submesh = original;
					submesh.StartIndex = (int32)written;

					for (int32 k < original.IndexCount)
					{
						merged.Indices.Add(
							source.Indices.Get((uint32)(original.StartIndex + k)) + vertexBase);
						written++;
					}
					merged.SubMeshes.Add(submesh);
				}
			}
		}

		if (let first = parts[0].Mesh as SkinnedMesh)
			merged.SkeletonIndex = first.SkeletonIndex;

		merged.CalculateBounds();
		return merged;
	}
}
