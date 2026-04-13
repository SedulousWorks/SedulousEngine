namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Vertex data for CPU-simulated billboard particles.
/// Used as per-instance data (one per particle, step rate = per instance).
/// The vertex shader generates a quad from SV_VertexID using these fields.
[CRepr]
public struct ParticleVertex
{
	/// World-space position of the particle center.
	public Vector3 Position;

	/// Billboard size (width, height).
	public Vector2 Size;

	/// Packed RGBA color.
	public Color Color;

	/// Rotation angle in radians.
	public float Rotation;

	/// Texture coordinate offset (atlas sub-region origin).
	public Vector2 TexCoordOffset;

	/// Texture coordinate scale (atlas sub-region size).
	public Vector2 TexCoordScale;

	/// Screen-space velocity for stretched billboards.
	public Vector2 Velocity2D;

	/// Size in bytes.
	public static int SizeInBytes => 52;
}
