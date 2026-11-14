using System;
using System.Collections;
using Sedulous.Core;

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
	/// Per joint, the bind pose box of the vertices it moves (weight above zero); an invalid
	/// box for a joint that moves none. Derived from the streams by CalculateJointBounds, as
	/// Bounds is by CalculateBounds.
	public List<AABB> JointBounds = new .() ~ delete _;

	public override bool IsSkinned => true;
	public override Span<VertexSkinning> SkinningStream => .(Skinning.Ptr, Skinning.Count);

	public static uint32 SkinningStride => (uint32)sizeof(VertexSkinning);
	public uint8* SkinningData => Skinning.IsEmpty ? null : (uint8*)Skinning.Ptr;
	public uint32 SkinningDataSize => (uint32)Skinning.Count * SkinningStride;

	/// Recomputes JointBounds from the static and skinning streams; none when they differ in
	/// length, so the mesh culls by Bounds.
	public void CalculateJointBounds()
	{
		JointBounds.Clear();
		if (Skinning.Count != Vertices.Count)
			return;

		for (int i < Vertices.Count)
		{
			let skin = Skinning[i];
			for (int k < 4)
			{
				if (skin.Weights[k] <= 0.0f)
					continue;
				let joint = (int)skin.Joints[k];
				while (JointBounds.Count <= joint)
					JointBounds.Add(AABB.Empty());
				JointBounds[joint].Expand(Vertices[i].Position);
			}
		}
	}

	/// A skinned vertex is a weighted average of its joints' matrices applied to it, so it lies
	/// within the boxes of those joints, each carried by its joint's matrix: their union bounds
	/// the posed mesh.
	public override bool PosedBounds(Span<Float4x4> palette, out AABB posed)
	{
		posed = Bounds;
		// A joint past the palette: the pose cannot be bounded from it.
		if (JointBounds.IsEmpty || (palette.Length < JointBounds.Count))
			return false;

		var union = AABB.Empty();
		for (int j < JointBounds.Count)
		{
			if (!JointBounds[j].IsValid())
				continue;
			let moved = TransformAABB(JointBounds[j], palette[j]);
			union.Expand(moved.Min);
			union.Expand(moved.Max);
		}
		if (!union.IsValid())
			return false;
		posed = union;
		return true;
	}

	public override void ClearForReload()
	{
		base.ClearForReload();
		Skinning.Clear();
		JointBounds.Clear();
		SkeletonIndex = -1;
	}
}
