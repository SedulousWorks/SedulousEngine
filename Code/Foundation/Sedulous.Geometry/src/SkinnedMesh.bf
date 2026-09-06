using System;
using System.Collections;

namespace Sedulous.Geometry;

/// A skinned mesh: the static stream, a parallel skinning stream, and a skeleton
/// reference.
///
/// IS-A StaticMesh, and deliberately so. The static data is byte identical and in the same
/// place, so a SkinnedMesh passes anywhere a StaticMesh is expected and the static draw
/// path just works; the skinned path additionally binds the skinning stream.
class SkinnedMesh : StaticMesh
{
	/// Parallel to Vertices: one entry per static vertex.
	public List<VertexSkinning> Skinning = new .() ~ delete _;
	/// Index into the import skeleton list, or -1 for none.
	public int32 SkeletonIndex = -1;

	public override bool IsSkinned => true;
	public override Span<VertexSkinning> SkinningStream => .(Skinning.Ptr, Skinning.Count);

	public static uint32 SkinningStride => (uint32)sizeof(VertexSkinning);
	public uint8* SkinningData => Skinning.IsEmpty ? null : (uint8*)Skinning.Ptr;
	public uint32 SkinningDataSize => (uint32)Skinning.Count * SkinningStride;

	public override void ClearForReload()
	{
		base.ClearForReload();
		Skinning.Clear();
		SkeletonIndex = -1;
	}
}
