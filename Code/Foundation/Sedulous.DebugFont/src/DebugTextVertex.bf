namespace Sedulous.DebugFont;

using System;
using Sedulous.Core.Mathematics;

/// Vertex format for debug text rendering (position + texcoord + color).
[CRepr]
public struct DebugTextVertex
{
	public Vector3 Position;
	public Vector2 TexCoord;
	public Color Color;

	public this(Vector3 position, Vector2 texCoord, Color color)
	{
		Position = position;
		TexCoord = texCoord;
		Color = color;
	}

	public this(float x, float y, float z, float u, float v, Color color)
	{
		Position = .(x, y, z);
		TexCoord = .(u, v);
		Color = color;
	}

	/// Size in bytes.
	public const int32 SizeInBytes = 24; // 12 (Vec3) + 8 (Vec2) + 4 (Color)
}
