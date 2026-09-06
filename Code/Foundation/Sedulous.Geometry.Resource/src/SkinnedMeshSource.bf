using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;

namespace Sedulous.Geometry;

/// A cooked skinned mesh: the static cooked data, the parallel skinning stream, and the
/// skeleton reference.
///
/// IS-A StaticMeshSource, mirroring the mesh hierarchy, so the static half is described
/// and filled in one place. The generated body carries the inherited fields, so the wire
/// shape is the static fields followed by these.
[Serializable(1)]
class SkinnedMeshSource : StaticMeshSource
{
	/// Raw VertexSkinning bytes, one per static vertex.
	public List<uint8> SkinningBlob = new .() ~ delete _;
	public int32 SkeletonIndex = -1;

	public static void FromMesh(SkinnedMesh mesh, SkinnedMeshSource outSource)
	{
		StaticMeshSource.FromMesh(mesh, outSource);

		outSource.SkinningBlob.Clear();
		if (mesh.SkinningDataSize > 0)
		{
			outSource.SkinningBlob.Resize((int)mesh.SkinningDataSize);
			Internal.MemCpy(outSource.SkinningBlob.Ptr, mesh.SkinningData, (int)mesh.SkinningDataSize);
		}

		outSource.SkeletonIndex = mesh.SkeletonIndex;
	}

	/// Whether the skinning stream really is parallel to the static one.
	///
	/// The invariant is one 24 byte influence per vertex, and it is worth checking rather
	/// than assuming: a payload that fails it has been read at the wrong offset, and the
	/// symptom of using it anyway is a mesh that animates into garbage while every status
	/// says the load succeeded. The build fails instead, so the asset gets re-imported.
	public bool HasParallelSkinningStream
	{
		get
		{
			let vertexCount = VertexBlob.Count / sizeof(StaticMeshVertex);
			return SkinningBlob.Count == vertexCount * sizeof(VertexSkinning);
		}
	}

	public void FillSkinned(SkinnedMesh mesh)
	{
		FillStatic(mesh);

		let count = SkinningBlob.Count / sizeof(VertexSkinning);
		mesh.Skinning.Clear();
		mesh.Skinning.Resize(count);
		if (count > 0)
			Internal.MemCpy(mesh.Skinning.Ptr, SkinningBlob.Ptr, count * sizeof(VertexSkinning));

		mesh.SkeletonIndex = SkeletonIndex;
	}
}
