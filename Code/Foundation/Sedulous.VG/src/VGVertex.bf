using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// The vertex vector graphics tessellate into, carrying analytical antialiasing coverage.
///
/// The colour is a full FLOAT RGBA rather than four bytes. Packing it would only quantise
/// to eight bits for no GPU benefit, because the renderer's colour attribute is four
/// floats and re-expands immediately; the quantisation showed up as visible banding across
/// gradients and antialiased fringes.
///
/// One layout serves every pipeline but the analytic box (VGBoxVertex), and two pipelines read
/// some fields for another value; each has a named constructor so the write site says which
/// (and the shader names its input the same way):
/// - the box shadow (BoxShadow, vg_shadow.ps): TexCoord is the rounded box SDF operand q and
///   Coverage the corner radius in blur sigma units, negative for an inset shadow;
/// - a distance-field glyph's effect pass (Glyph, vg_df.ps): Effect is the edge shift and the
///   ramp width;
/// - a layer composite (LayerComposite, vg_layer.ps): Effect is the colour filter as offsets
///   from no filter, (1 - saturation, brightness - 1).
[CRepr]
struct VGVertex
{
	/// In screen or world coordinates, depending on the transform in effect.
	public Float2 Position = .Zero;
	/// The texture coordinate; the SDF operand for a box shadow.
	public Float2 TexCoord = .Zero;
	public Color Color = .(1, 1, 1, 1);
	/// Zero at a transparent fringe, one inside. What makes the edges smooth without
	/// multisampling. The signed corner radius for a box shadow.
	public float Coverage = 1.0f;
	/// Zero but for two pipelines. A distance-field glyph's effect pass (TextEffects), in the
	/// field's units (0.5 is the edge): X moves the edge outward, Y widens it into a soft ramp;
	/// either nonzero reads the field's true distance (alpha) instead of the multi-channel
	/// median. A layer composite: (1 - saturation, brightness - 1).
	public Float2 Effect = .Zero;

	/// The stride the renderer's vertex layout declares: 8 + 8 + 16 + 4 + 8.
	public const int32 SizeInBytes = 44;

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

	/// A box shadow's vertex (VGDrawMode.BoxShadow): `shadowOperand` is the rounded box SDF
	/// operand q = |p - c| - (halfSize - r) in blur sigma units, carried in TexCoord;
	/// `signedCornerRadius` is the corner radius r in sigma units, negative for an inset
	/// shadow, carried in Coverage.
	public static VGVertex BoxShadow(Float2 position, Float2 shadowOperand, Color color, float signedCornerRadius)
		=> .(position, shadowOperand, color, signedCornerRadius);

	/// A distance-field glyph's vertex: `edgeShiftRamp`, carried in Effect, is X the edge's move
	/// outward and Y its ramp width, in field units (zeros for the plain glyph pass).
	public static VGVertex Glyph(Float2 position, Float2 uv, Color color, Float2 edgeShiftRamp)
	{
		var vertex = VGVertex(position, uv, color, 1.0f);
		vertex.Effect = edgeShiftRamp;
		return vertex;
	}

	/// A layer composite's vertex (VGDrawMode.Layer): the colour filter rides Effect as offsets
	/// from no filter, (1 - saturation, brightness - 1), so a plain composite carries zeros.
	public static VGVertex LayerComposite(Float2 position, Float2 uv, Color tint, float saturation, float brightness)
	{
		var vertex = VGVertex(position, uv, tint);
		vertex.Effect = .(1.0f - saturation, brightness - 1.0f);
		return vertex;
	}
}
