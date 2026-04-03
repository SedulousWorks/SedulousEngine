using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// Vertex structure for 2D drawing with position, texture coordinates, and color.
[CRepr]
public struct DrawVertex
{
	/// Position in screen/world coordinates
	public Vector2 Position;
	/// Texture coordinates (UV)
	public Vector2 TexCoord;
	/// Vertex color (RGBA)
	public Color Color;

	/// Size in bytes of this vertex structure
	public const int32 SizeInBytes = 20; // 8 + 8 + 4

	public this(Vector2 position, Vector2 texCoord, Color color)
	{
		Position = position;
		TexCoord = texCoord;
		Color = color;
	}

	public this(float x, float y, float u, float v, Color color)
	{
		Position = .(x, y);
		TexCoord = .(u, v);
		Color = color;
	}

	/// Create a vertex with no texture (uses white pixel UV)
	public static DrawVertex Solid(Vector2 position, Color color, Vector2 whitePixelUV = default)
	{
		return .(position, whitePixelUV, color);
	}

	/// Create a vertex with no texture (uses white pixel UV)
	public static DrawVertex Solid(float x, float y, Color color, Vector2 whitePixelUV = default)
	{
		return .(x, y, whitePixelUV.X, whitePixelUV.Y, color);
	}
}
