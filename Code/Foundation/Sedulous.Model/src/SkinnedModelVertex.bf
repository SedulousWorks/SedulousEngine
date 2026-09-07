using System;
using Sedulous.Core;

namespace Sedulous.Model;

/// The vertex an importer produces for an animated model: 76 bytes.
///
/// The static half is laid out exactly as ModelVertex, with the joints and weights on the
/// end. [CRepr] for the same reason: this is a layout, not a record.
[CRepr]
struct SkinnedModelVertex
{
	public Float3 Position;    // 12
	public Float3 Normal;      // 12
	public Float2 TexCoord;    //  8
	public uint32 Color;       //  4
	public Float4 Tangent;     // 16
	public uint16[4] Joints;   //  8, up to four bone indices
	public Float4 Weights;     // 16
	// 76

	public this()
	{
		Position = .Zero; Normal = .UnitY; TexCoord = .Zero;
		Color = 0xFFFFFFFF; Tangent = .(1, 0, 0, 1);
		Joints = .(0, 0, 0, 0); Weights = .(1, 0, 0, 0);
	}

	public this(Float3 position, Float3 normal, Float2 texCoord, uint32 color, Float4 tangent,
		uint16[4] joints, Float4 weights)
	{
		Position = position; Normal = normal; TexCoord = texCoord;
		Color = color; Tangent = tangent; Joints = joints; Weights = weights;
	}
}
