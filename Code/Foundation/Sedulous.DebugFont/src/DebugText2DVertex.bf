namespace Sedulous.DebugFont;

using System;
using Sedulous.Core.Mathematics;

/// Vertex format for 2D screen-space debug text (position + texcoord + color).
[CRepr]
public struct DebugText2DVertex
{
	public Vector2 Position;  // Screen-space position in pixels
	public Vector2 TexCoord;
	public Color Color;

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

	/// Size in bytes.
	public const int32 SizeInBytes = 20; // 8 (Vec2) + 8 (Vec2) + 4 (Color)
}
