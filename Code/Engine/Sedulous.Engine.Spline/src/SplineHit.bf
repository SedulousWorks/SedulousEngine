using System;
using Sedulous.Core;

namespace Sedulous.Engine.Spline;

/// One sample of a spline, in WORLD space.
///
/// Invalid with everything zeroed when the entity carries no spline, which is the same shape
/// a ray cast result uses: a miss is a value, not an error.
[Scriptable(.AllPublic)]
struct SplineHit
{
	public bool Valid = false;
	/// The curve parameter the sample answers for.
	public float T = 0.0f;
	public Float3 Position = .Zero;
	/// Unit length.
	public Float3 Tangent = .Zero;

	public this() {}
}
