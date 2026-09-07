using System;
using Sedulous.Core;

namespace Sedulous.Model;

/// The standard vertex an importer produces for a static model: 52 bytes.
///
/// [CRepr] because the size and field order are a layout contract, and Beef reorders
/// struct fields for packing otherwise. Tangent.W carries the TBN handedness.
[CRepr]
struct ModelVertex
{
	public Float3 Position;  // 12
	public Float3 Normal;    // 12
	public Float2 TexCoord;  //  8
	public uint32 Color;     //  4, packed RGBA
	public Float4 Tangent;   // 16, xyz tangent, w handedness
	// 52

	public this()
	{
		Position = .Zero; Normal = .UnitY; TexCoord = .Zero;
		Color = 0xFFFFFFFF; Tangent = .(1, 0, 0, 1);
	}

	public this(Float3 position, Float3 normal, Float2 texCoord, uint32 color = 0xFFFFFFFF,
		Float4 tangent = .(1, 0, 0, 1))
	{
		Position = position; Normal = normal; TexCoord = texCoord;
		Color = color; Tangent = tangent;
	}
}
