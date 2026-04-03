using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// Standard vertex format for static models (48 bytes)
[CRepr]
public struct ModelVertex
{
	public Vector3 Position;    // 12 bytes
	public Vector3 Normal;      // 12 bytes
	public Vector2 TexCoord;    // 8 bytes
	public uint32 Color;        // 4 bytes (packed RGBA)
	public Vector3 Tangent;     // 12 bytes
	// Total: 48 bytes

	public this()
	{
		Position = .Zero;
		Normal = .(0, 1, 0);
		TexCoord = .Zero;
		Color = 0xFFFFFFFF;
		Tangent = .(1, 0, 0);
	}

	public this(Vector3 position, Vector3 normal, Vector2 texCoord, uint32 color = 0xFFFFFFFF, Vector3 tangent = .(1, 0, 0))
	{
		Position = position;
		Normal = normal;
		TexCoord = texCoord;
		Color = color;
		Tangent = tangent;
	}
}

/// Skinned vertex format for animated models (72 bytes)
[CRepr]
public struct SkinnedModelVertex
{
	public Vector3 Position;      // 12 bytes
	public Vector3 Normal;        // 12 bytes
	public Vector2 TexCoord;      // 8 bytes
	public uint32 Color;          // 4 bytes (packed RGBA)
	public Vector3 Tangent;       // 12 bytes
	public uint16[4] Joints;      // 8 bytes (up to 4 bone indices)
	public Vector4 Weights;       // 16 bytes (bone weights)
	// Total: 72 bytes

	public this()
	{
		Position = .Zero;
		Normal = .(0, 1, 0);
		TexCoord = .Zero;
		Color = 0xFFFFFFFF;
		Tangent = .(1, 0, 0);
		Joints = .(0, 0, 0, 0);
		Weights = .(1, 0, 0, 0);
	}

	public this(Vector3 position, Vector3 normal, Vector2 texCoord, uint32 color, Vector3 tangent, uint16[4] joints, Vector4 weights)
	{
		Position = position;
		Normal = normal;
		TexCoord = texCoord;
		Color = color;
		Tangent = tangent;
		Joints = joints;
		Weights = weights;
	}
}
