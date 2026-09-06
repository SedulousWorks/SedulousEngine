using System;
using Sedulous.Core;

namespace Sedulous.Geometry;

/// The parallel skinning stream: 24 bytes, locations 6 and 7.
///
/// One per static vertex. A skinned mesh stores this ALONGSIDE the static stream rather
/// than interleaving with it, so the static stream stays byte identical to a static
/// mesh's and the static draw path works on both unchanged.
///
/// [CRepr] for the same reason as StaticMeshVertex: this is a GPU layout, not a record.
[CRepr]
struct VertexSkinning
{
	/// Bone indices, uploaded as uint16x4 (packed uint32x2).
	public uint16[4] Joints;  //  8
	/// Bone weights, summing to one.
	public Float4 Weights;    // 16
	// 24

	public this()
	{
		Joints = .(0, 0, 0, 0);
		Weights = .(1.0f, 0.0f, 0.0f, 0.0f);
	}

	public this(uint16[4] joints, Float4 weights)
	{
		Joints = joints;
		Weights = weights;
	}
}
