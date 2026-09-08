using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// The vertex vector graphics tessellate into, carrying analytical antialiasing coverage.
///
/// The colour is a full FLOAT RGBA rather than four bytes. Packing it would only quantise
/// to eight bits for no GPU benefit, because the renderer's colour attribute is four
/// floats and re-expands immediately; the quantisation showed up as visible banding across
/// gradients and antialiased fringes.
[CRepr]
struct VGVertex
{
	/// In screen or world coordinates, depending on the transform in effect.
	public Float2 Position = .Zero;
	public Float2 TexCoord = .Zero;
	public Color Color = .(1, 1, 1, 1);
	/// Zero at a transparent fringe, one inside. What makes the edges smooth without
	/// multisampling.
	public float Coverage = 1.0f;

	/// The stride the renderer's vertex layout declares.
	public const int32 SizeInBytes = 36;

	/// The UV a solid colour vertex uses: the middle of whatever is bound, so a solid draw
	/// samples one texel of a white texture rather than needing a separate pipeline.
	public const float SolidUV = 0.5f;

	public this() {}

	public this(Float2 position, Float2 texCoord, Color color, float coverage = 1.0f)
	{
		Position = position;
		TexCoord = texCoord;
		Color = color;
		Coverage = coverage;
	}

	public this(float x, float y, float u, float v, Color color, float coverage = 1.0f)
		: this(.(x, y), .(u, v), color, coverage) {}

	public static VGVertex Solid(Float2 position, Color color, float coverage = 1.0f)
		=> .(position, .(SolidUV, SolidUV), color, coverage);

	public static VGVertex Solid(float x, float y, Color color, float coverage = 1.0f)
		=> .(x, y, SolidUV, SolidUV, color, coverage);
}
