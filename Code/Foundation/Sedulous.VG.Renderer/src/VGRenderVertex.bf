namespace Sedulous.VG.Renderer;

using System;
using Sedulous.Core.Mathematics;
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
	///
	/// UI colors are authored in sRGB (hex codes, theme byte values), so we
	/// decode them to linear before they reach the shader. The swapchain is
	/// sRGB and re-encodes on write - skipping this conversion would double-
	/// encode color values and produce washed-out greys.
	public this(VGVertex v)
	{
		Position = .(v.Position.X, v.Position.Y);
		TexCoord = .(v.TexCoord.X, v.TexCoord.Y);
		Color = .(
			Sedulous.Core.Mathematics.Color.ConvertSrgbColorChannelToLinear(v.Color.R / 255.0f),
			Sedulous.Core.Mathematics.Color.ConvertSrgbColorChannelToLinear(v.Color.G / 255.0f),
			Sedulous.Core.Mathematics.Color.ConvertSrgbColorChannelToLinear(v.Color.B / 255.0f),
			v.Color.A / 255.0f
		);
		Coverage = v.Coverage;
	}
}
