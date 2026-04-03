using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Vertex structure for vector graphics with analytical AA support
[CRepr]
public struct VGVertex
{
	/// Position in screen/world coordinates
	public Vector2 Position;
	/// Texture coordinates (UV)
	public Vector2 TexCoord;
	/// Vertex color (RGBA)
	public Color Color;
	/// Coverage for analytical anti-aliasing (0.0 = fully transparent fringe, 1.0 = fully opaque)
	public float Coverage;

	/// Size in bytes of this vertex structure
	public const int32 SizeInBytes = 24; // 8 + 8 + 4 + 4

	/// Fixed UV for solid color drawing
	public const float SolidUV = 0.5f;

	public this(Vector2 position, Vector2 texCoord, Color color, float coverage = 1.0f)
	{
		Position = position;
		TexCoord = texCoord;
		Color = color;
		Coverage = coverage;
	}

	public this(float x, float y, float u, float v, Color color, float coverage = 1.0f)
	{
		Position = .(x, y);
		TexCoord = .(u, v);
		Color = color;
		Coverage = coverage;
	}

	/// Create a solid-color vertex (no texture)
	public static VGVertex Solid(Vector2 position, Color color, float coverage = 1.0f)
	{
		return .(position, .(SolidUV, SolidUV), color, coverage);
	}

	/// Create a solid-color vertex (no texture)
	public static VGVertex Solid(float x, float y, Color color, float coverage = 1.0f)
	{
		return .(x, y, SolidUV, SolidUV, color, coverage);
	}
}
