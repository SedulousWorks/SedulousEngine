namespace Sedulous.Drawing.Renderer;

using System;
using Sedulous.Drawing;

/// GPU vertex format for 2D drawing rendering.
/// Matches the shader vertex input layout.
[CRepr]
public struct DrawingRenderVertex
{
	public float[2] Position;
	public float[2] TexCoord;
	public float[4] Color;

	/// Convert from DrawVertex (CPU format) to DrawingRenderVertex (GPU format).
	///
	/// UI colors are authored in sRGB (hex codes, theme byte values), so we
	/// decode them to linear before they reach the shader. The swapchain is
	/// sRGB and re-encodes on write - skipping this conversion would double-
	/// encode color values and produce washed-out greys.
	public this(DrawVertex v)
	{
		Position = .(v.Position.X, v.Position.Y);
		TexCoord = .(v.TexCoord.X, v.TexCoord.Y);
		Color = .(
			Sedulous.Core.Mathematics.Color32.ConvertSrgbColorChannelToLinear(v.Color.R / 255.0f),
			Sedulous.Core.Mathematics.Color32.ConvertSrgbColorChannelToLinear(v.Color.G / 255.0f),
			Sedulous.Core.Mathematics.Color32.ConvertSrgbColorChannelToLinear(v.Color.B / 255.0f),
			v.Color.A / 255.0f
		);
	}
}
