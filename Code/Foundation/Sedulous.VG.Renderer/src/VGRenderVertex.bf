namespace Sedulous.VG.Renderer;

using System;
using Sedulous.VG;

/// GPU vertex format for vector graphics rendering.
/// Matches the vg shader vertex input layout.
[CRepr]
public struct VGRenderVertex
{
	public float[2] Position;
	public float[2] TexCoord;
	public float[4] Color;
	public float Coverage;

	/// Convert from VGVertex (CPU format) to VGRenderVertex (GPU format).
	public this(VGVertex v)
	{
		Position = .(v.Position.X, v.Position.Y);
		TexCoord = .(v.TexCoord.X, v.TexCoord.Y);
		Color = .(v.Color.R / 255.0f, v.Color.G / 255.0f, v.Color.B / 255.0f, v.Color.A / 255.0f);
		Coverage = v.Coverage;
	}
}
