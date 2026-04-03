namespace Sedulous.DebugFont;

using System;
using Sedulous.Core.Mathematics;

/// Vertex format for debug drawing (position + color).
[CRepr]
public struct DebugVertex
{
	public Vector3 Position;
	public Color Color;

	public this(Vector3 position, Color color)
	{
		Position = position;
		Color = color;
	}

	public this(float x, float y, float z, Color color)
	{
		Position = .(x, y, z);
		Color = color;
	}

	/// Size in bytes.
	public const int32 SizeInBytes = 16; // 12 (Vec3) + 4 (Color)
}
