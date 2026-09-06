using System;

namespace Sedulous.Core;

/// A plane, normal dot p + d = 0.
[CRepr]
struct Plane
{
	public Float3 normal;
	public float d;

	public this() { normal = default; d = 0.0f; }
	public this(Float3 normal, float d) { this.normal = normal; this.d = d; }

	public static Plane FromPointNormal(Float3 point, Float3 unitNormal) =>
		.(unitNormal, -Dot(unitNormal, point));

	/// Positive in front, on the normal's side; negative behind; near zero on the plane.
	public float SignedDistance(Float3 p) => Dot(normal, p) + d;

	public Plane Normalized()
	{
		let length = Length(normal);
		if (length <= Epsilon)
			return this;
		let inv = 1.0f / length;
		return .(normal * inv, d * inv);
	}
}
