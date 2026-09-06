using Sedulous.Core;

namespace Sedulous.Spline;

/// A position on the curve and the parameter it was found at.
struct SplineSample
{
	public Float3 Position;
	/// The GLOBAL parameter: segment index plus the local fraction within it.
	public float T;

	public this() { Position = .Zero; T = 0.0f; }
	public this(Float3 position, float t) { Position = position; T = t; }
}
