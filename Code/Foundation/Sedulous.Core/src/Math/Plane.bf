using System;

namespace Sedulous.Core;

/// A plane, Normal dot p + D = 0.
[CRepr]
struct Plane
{
	public Float3 Normal;
	public float D;

	public this() { Normal = default; D = 0.0f; }
	public this(Float3 normal, float d) { this.Normal = normal; this.D = d; }

	public static Plane FromPointNormal(in Float3 point, in Float3 unitNormal) =>
		.(unitNormal, -Dot(unitNormal, point));

	/// Positive in front, on the Normal's side; negative behind; near zero on the plane.
	public float SignedDistance(Float3 p) => Dot(Normal, p) + D;

	public Plane Normalized()
	{
		let length = Length(Normal);
		if (length <= Epsilon)
			return this;
		let inv = 1.0f / length;
		return .(Normal * inv, D * inv);
	}
}
