using System;
using Sedulous.Core;

namespace Sedulous.Geometry;

/// The static vertex stream: 52 bytes, matching the Mesh vertex layout at locations 0..4.
///
/// [CRepr] is a HARD requirement, not a tidiness choice. Beef is free to reorder a struct's
/// fields for packing, and this one is a GPU layout contract: the array is uploaded to a
/// vertex buffer verbatim and read by a shader that knows where each attribute sits. C
/// layout, declaration order, natural alignment, and the size is asserted in the tests.
///
/// Tangent.W is the TBN HANDEDNESS sign, +-1, following glTF: the shader's bitangent is
/// cross(N, T.xyz) * T.w, so normal maps on mirrored UV geometry light correctly.
[CRepr]
struct StaticMeshVertex
{
	public Float3 Position;  // 12
	public Float3 Normal;    // 12
	public Float2 TexCoord;  //  8
	/// Packed RGBA with R in the low byte, matching Unorm8x4.
	public uint32 Color;     //  4
	public Float4 Tangent;   // 16, xyz = tangent, w = handedness
	// 52

	public this()
	{
		Position = .Zero;
		Normal = .UnitY;
		TexCoord = .Zero;
		Color = 0xFFFFFFFF;
		Tangent = .(1.0f, 0.0f, 0.0f, 1.0f);
	}

	public this(Float3 position, Float3 normal, Float2 texCoord, uint32 color, Float4 tangent)
	{
		Position = position;
		Normal = normal;
		TexCoord = texCoord;
		Color = color;
		Tangent = tangent;
	}

	/// Float3 tangent convenience for the procedural builders: handedness defaults to +1.
	public this(Float3 position, Float3 normal, Float2 texCoord, uint32 color, Float3 tangent)
	{
		Position = position;
		Normal = normal;
		TexCoord = texCoord;
		Color = color;
		Tangent = .(tangent.X, tangent.Y, tangent.Z, 1.0f);
	}
}
