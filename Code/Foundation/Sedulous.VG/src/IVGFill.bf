using Sedulous.Core;

namespace Sedulous.VG;

/// How a shape is coloured.
///
/// Most of this has defaults, because a solid fill is the common case and should not have
/// to answer questions about gradient parameters it does not have.
interface IVGFill
{
	/// The colour at a point, for the paths that interpolate per vertex.
	Color GetColorAt(Float2 position, Rectangle bounds);

	/// The fill's primary colour, which is what a per vertex path uses when it does not
	/// interpolate, and what a solid fill is.
	Color BaseColor { get; }

	/// Whether the colour varies across the shape. False lets the tessellator emit one
	/// colour for every vertex rather than evaluating per vertex.
	bool RequiresInterpolation { get; }

	/// The RAW gradient parameter at a point, before any spread is applied: the projection
	/// for a linear, distance over radius for a radial, angle over a full turn for a conic.
	/// Zero for a solid.
	float GetParameterAt(Float2 position, Rectangle bounds) => 0.0f;

	/// The ramp sampled at a parameter already in zero to one. A solid returns its colour.
	Color SampleRamp(float t) => BaseColor;

	VGGradientKind GradientKind => .Solid;

	/// What happens outside zero to one. Pad for anything that is not a gradient, and for a
	/// conic, which wraps inherently.
	VGGradientSpread Spread => .Pad;

	/// The gradient space coordinate a per pixel shader consumes: a radial returns the
	/// offset from the centre over the radius, whose LENGTH the shader takes; a conic
	/// returns the offset rotated back by the start angle, whose ANGLE it takes. Unused by
	/// solid and linear fills.
	Float2 GradientCoord(Float2 position, Rectangle bounds) => .Zero;
}
