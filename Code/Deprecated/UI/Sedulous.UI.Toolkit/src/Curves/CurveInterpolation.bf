namespace Sedulous.UI.Toolkit;

/// How a channel's curve fills the gap between two keys.
///
/// Hermite is FIRST, so a default constructed descriptor gets it. It is the right default for
/// the two things curves are mostly used for here, particle parameters and animation easing,
/// where a smooth ramp is what is wanted and a straight line looks mechanical.
enum CurveInterpolation
{
	/// Cubic, through the per key tangents.
	Hermite,
	/// Straight between neighbours; tangents ignored.
	Linear,
	/// Hold: the value jumps at the next key rather than approaching it.
	Step
}
