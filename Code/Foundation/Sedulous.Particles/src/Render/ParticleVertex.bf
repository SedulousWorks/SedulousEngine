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
	public Color32 Color;

	/// Rotation angle in radians.
	public float Rotation;

	/// Texture coordinate offset (atlas sub-region origin).
	public Vector2 TexCoordOffset;

	/// Texture coordinate scale (atlas sub-region size).
	public Vector2 TexCoordScale;

	/// Screen-space velocity for stretched billboards.
	public Vector2 Velocity2D;

	/// Per-particle render mode (mirrors `ParticleRenderMode`). The extractor
	/// stamps every particle in a system with the system's render mode; the
	/// vertex shader branches the basis construction on this value so a
	/// single draw can mix particles authored with different modes (in
	/// practice each batch is uniform, but the per-vertex value keeps the
	/// shader self-contained and avoids needing a per-draw uniform).
	public uint32 RenderMode;

	/// Size in bytes.
	public static int SizeInBytes => 56;
}
