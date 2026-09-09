namespace Sedulous.Particles;

/// What every particle curve shares: its fixed size, and the basis it interpolates with.
///
/// FIXED at eight keys rather than a list, because a curve is a VALUE that lives inside a
/// system's settings: a heap allocation per curve would put an indirection on the spawn path
/// and make copying a system's settings a deep copy.
static class ParticleCurve
{
	public const int32 MaxKeys = 8;

	/// The cubic Hermite basis. The tangents arrive already scaled by the segment they span,
	/// since a tangent is a rate and means nothing until it is told over how long.
	public static float Hermite(float p0, float m0, float p1, float m1, float t)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		return (2.0f * t3 - 3.0f * t2 + 1.0f) * p0
			+ (t3 - 2.0f * t2 + t) * m0
			+ (-2.0f * t3 + 3.0f * t2) * p1
			+ (t3 - t2) * m1;
	}

	/// Below this a segment has no length worth dividing by.
	public const float MinSegment = 1.0e-6f;
}
