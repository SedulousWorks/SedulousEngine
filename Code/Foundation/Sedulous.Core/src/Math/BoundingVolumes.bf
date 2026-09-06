using System;

namespace Sedulous.Core;

/// The cross-type bounding volume tests.
///
/// These relate two types apiece, so they have no single home under the one-type-per-file
/// rule and live together here, matching Raptor's BoundingVolumes partition. The types
/// themselves are in Ray, BoundingSphere, BoundingFrustum, AABB and Plane.
///
/// Frustum planes point OUTWARD throughout: a volume is inside when it is on the
/// negative side of all six.
static
{
	/// Matches Sedulous's MathUtil tolerance for float comparisons.
	public const float BoundsApprox = 1.0e-7f;

	public static bool ApproxZero(float v) => Abs(v) < BoundsApprox;
	public static bool ApproxNonZero(float v) => Abs(v) >= BoundsApprox;

	/// Sedulous's IsApproximatelyGreaterThan: exact equality counts as true, otherwise
	/// it needs both a real gap and the ordering.
	public static bool ApproxGreater(float a, float b) =>
		(a == b) || ((Abs(a - b) >= BoundsApprox) && (a > b));

	public static Float3 ClampVec(Float3 v, Float3 lo, Float3 hi) => Max(Min(v, hi), lo);

	// ---- frustum against sphere ----

	public static ContainmentType Contains(BoundingFrustum f, BoundingSphere s)
	{
		var intersects = false;
		for (int i < BoundingFrustum.PlaneCount)
		{
			switch (s.Intersects(f.planes[i]))
			{
			case .Front: return .Disjoint;
			case .Intersecting: intersects = true;
			default:
			}
		}
		return intersects ? .Intersects : .Contains;
	}

	public static bool Intersects(BoundingFrustum f, BoundingSphere s) =>
		Contains(f, s) != .Disjoint;

	// ---- AABB helpers ----

	public static AABB BoundingBoxFromSphere(BoundingSphere s)
	{
		let c = Float3(s.radius, s.radius, s.radius);
		return .(s.center - c, s.center + c);
	}

	/// Sedulous's corner order: index 0 is (min.x, max.y, max.z) through to 7 being
	/// (min.x, min.y, min.z).
	public static void GetCorners(AABB b, ref Float3[8] corners)
	{
		corners[0] = .(b.min.x, b.max.y, b.max.z);
		corners[1] = .(b.max.x, b.max.y, b.max.z);
		corners[2] = .(b.max.x, b.min.y, b.max.z);
		corners[3] = .(b.min.x, b.min.y, b.max.z);
		corners[4] = .(b.min.x, b.max.y, b.min.z);
		corners[5] = .(b.max.x, b.max.y, b.min.z);
		corners[6] = .(b.max.x, b.min.y, b.min.z);
		corners[7] = .(b.min.x, b.min.y, b.min.z);
	}

	/// AABB.Contains already answers this as a bool; this is the ContainmentType form,
	/// which cannot be an overload because only the return type differs.
	public static ContainmentType ContainsCT(AABB b, Float3 p) =>
		b.Contains(p) ? .Contains : .Disjoint;

	public static PlaneIntersectionType Intersects(AABB b, Plane plane)
	{
		let pos = Float3(
			plane.normal.x >= 0 ? b.min.x : b.max.x,
			plane.normal.y >= 0 ? b.min.y : b.max.y,
			plane.normal.z >= 0 ? b.min.z : b.max.z);
		let neg = Float3(
			plane.normal.x >= 0 ? b.max.x : b.min.x,
			plane.normal.y >= 0 ? b.max.y : b.min.y,
			plane.normal.z >= 0 ? b.max.z : b.min.z);

		if (Dot(plane.normal, pos) + plane.d > 0.0f)
			return .Front;
		if (Dot(plane.normal, neg) + plane.d < 0.0f)
			return .Back;
		return .Intersecting;
	}

	public static bool Intersects(AABB b, BoundingSphere s)
	{
		let clamped = ClampVec(s.center, b.min, b.max);
		return LengthSquared(s.center - clamped) <= s.radius * s.radius;
	}

	/// The transformed bounds that encloses the transformed original: the centre moves and
	/// the extents pick up the absolute row sums.
	public static AABB TransformAABB(AABB b, Float4x4 m)
	{
		let c = b.Center();
		let e = b.Extents();
		let nc = Float3(
			c.x * m[0, 0] + c.y * m[1, 0] + c.z * m[2, 0] + m[3, 0],
			c.x * m[0, 1] + c.y * m[1, 1] + c.z * m[2, 1] + m[3, 1],
			c.x * m[0, 2] + c.y * m[1, 2] + c.z * m[2, 2] + m[3, 2]);
		let ne = Float3(
			Abs(m[0, 0]) * e.x + Abs(m[1, 0]) * e.y + Abs(m[2, 0]) * e.z,
			Abs(m[0, 1]) * e.x + Abs(m[1, 1]) * e.y + Abs(m[2, 1]) * e.z,
			Abs(m[0, 2]) * e.x + Abs(m[1, 2]) * e.y + Abs(m[2, 2]) * e.z);
		return .(nc - ne, nc + ne);
	}

	// ---- frustum against bounds ----

	public static ContainmentType Contains(BoundingFrustum f, AABB b)
	{
		var intersects = false;
		for (int i < BoundingFrustum.PlaneCount)
		{
			switch (Intersects(b, f.planes[i]))
			{
			case .Front: return .Disjoint;
			case .Intersecting: intersects = true;
			default:
			}
		}
		return intersects ? .Intersects : .Contains;
	}

	public static bool Intersects(BoundingFrustum f, AABB b) => Contains(f, b) != .Disjoint;

	public static ContainmentType ContainsCT(AABB b, BoundingSphere s)
	{
		let clamped = ClampVec(s.center, b.min, b.max);
		if (s.radius * s.radius <= LengthSquared(s.center - clamped))
			return .Disjoint;

		if ((s.center.x > b.max.x - s.radius) || (s.center.y > b.max.y - s.radius) ||
			(s.center.z > b.max.z - s.radius) || (b.min.x + s.radius > s.center.x) ||
			(b.min.y + s.radius > s.center.y) || (b.min.z + s.radius > s.center.z) ||
			(b.max.x - b.min.x <= s.radius) || (b.max.y - b.min.y <= s.radius) ||
			(b.max.z - b.min.z <= s.radius))
			return .Intersects;

		return .Contains;
	}

	// ---- sphere cross-type ----

	public static bool Intersects(BoundingSphere a, BoundingSphere b)
	{
		let combined = a.radius + b.radius;
		return LengthSquared(a.center - b.center) <= combined * combined;
	}

	public static bool Intersects(BoundingSphere s, AABB b) => Intersects(b, s);
	public static bool Intersects(BoundingSphere s, BoundingFrustum f) => Intersects(f, s);

	public static ContainmentType Contains(BoundingSphere s, BoundingFrustum f)
	{
		if (!Intersects(f, s))
			return .Disjoint;
		for (int i < BoundingFrustum.CornerCount)
		{
			if (s.Contains(f.corners[i]) == .Disjoint)
				return .Intersects;
		}
		return .Contains;
	}

	public static BoundingSphere BoundingSphereFromFrustum(BoundingFrustum f)
	{
		var corners = f.corners;
		return BoundingSphere.FromPoints(Span<Float3>(&corners[0], BoundingFrustum.CornerCount));
	}

	// ---- ray intersections; false means no hit, and outT is only set on a hit ----

	public static bool Intersects(Ray ray, Plane plane, out float outT)
	{
		outT = 0.0f;
		let nDotDir = Dot(plane.normal, ray.direction);
		if (ApproxZero(nDotDir))
			return false;

		let dist = -(Dot(plane.normal, ray.position) + plane.d) / nDotDir;
		if (ApproxZero(dist))
		{
			outT = 0.0f;
			return true;
		}
		if (dist < 0.0f)
			return false;

		outT = dist;
		return true;
	}

	public static bool Intersects(Ray ray, BoundingSphere sphere, out float outT)
	{
		outT = 0.0f;
		let r2 = sphere.radius * sphere.radius;
		let offset = sphere.center - ray.position;
		let offLen2 = LengthSquared(offset);
		if (offLen2 < r2)
		{
			outT = 0.0f;   // the ray starts inside
			return true;
		}

		let toCenter = Dot(ray.direction, offset);
		if (toCenter < 0.0f)
			return false;

		let toSphere = r2 + toCenter * toCenter - offLen2;
		if (toSphere < 0.0f)
			return false;

		outT = toCenter - Sqrt(toSphere);
		return true;
	}

	public static bool Intersects(Ray ray, AABB bounds, out float outT)
	{
		outT = 0.0f;
		var hasMin = false;
		var hasMax = false;
		var mn = 0.0f;
		var mx = 0.0f;

		if (ApproxZero(ray.direction.x))
		{
			if ((ray.position.x < bounds.min.x) || (ray.position.x > bounds.max.x))
				return false;
		}
		else
		{
			mn = (bounds.min.x - ray.position.x) / ray.direction.x;
			mx = (bounds.max.x - ray.position.x) / ray.direction.x;
			if (mn > mx)
			{
				let t = mn; mn = mx; mx = t;
			}
			hasMin = true;
			hasMax = true;
		}

		if (ApproxZero(ray.direction.y))
		{
			if ((ray.position.y < bounds.min.y) || (ray.position.y > bounds.max.y))
				return false;
		}
		else
		{
			var y0 = (bounds.min.y - ray.position.y) / ray.direction.y;
			var y1 = (bounds.max.y - ray.position.y) / ray.direction.y;
			if (y0 > y1)
			{
				let t = y0; y0 = y1; y1 = t;
			}
			if (!hasMin || (y0 > mn)) { mn = y0; hasMin = true; }
			if (!hasMax || (y1 > mx)) { mx = y1; hasMax = true; }
		}

		if (ApproxZero(ray.direction.z))
		{
			if ((ray.position.z < bounds.min.z) || (ray.position.z > bounds.max.z))
				return false;
		}
		else
		{
			var z0 = (bounds.min.z - ray.position.z) / ray.direction.z;
			var z1 = (bounds.max.z - ray.position.z) / ray.direction.z;
			if (z0 > z1)
			{
				let t = z0; z0 = z1; z1 = t;
			}
			if (!hasMin || (z0 > mn)) { mn = z0; hasMin = true; }
			if (!hasMax || (z1 > mx)) { mx = z1; hasMax = true; }
		}

		if (hasMin && (mn < 0.0f) && (mx > 0.0f))
		{
			outT = 0.0f;
			return true;
		}
		if (mn < 0.0f)
			return false;

		outT = mn;
		return true;
	}

	public static bool Intersects(BoundingFrustum f, Ray ray, out float outT)
	{
		outT = 0.0f;
		if (f.Contains(ray.position) == .Contains)
		{
			outT = 0.0f;
			return true;
		}

		var mx = -FloatMax;
		var mn = FloatMax;
		for (int i < BoundingFrustum.PlaneCount)
		{
			let n = f.planes[i].normal;
			let dirDotN = Dot(ray.direction, n);
			let posDotN = Dot(ray.position, n) + f.planes[i].d;

			if (ApproxNonZero(dirDotN))
			{
				let value = -posDotN / dirDotN;
				if (dirDotN < 0.0f)
				{
					if (value > mn)
						return false;
					if (value > mx)
						mx = value;
				}
				else
				{
					if (value < mx)
						return false;
					if (value < mn)
						mn = value;
				}
			}
			else if (posDotN > 0.0f)
			{
				return false;
			}
		}

		let dist = mx >= 0.0f ? mx : mn;
		if (dist < 0.0f)
			return false;

		outT = dist;
		return true;
	}

	public static bool Intersects(Ray ray, BoundingFrustum f, out float outT) =>
		Intersects(f, ray, out outT);

	// ---- the remaining Contains and Intersects overloads ----

	public static ContainmentType Contains(BoundingSphere a, BoundingSphere b)
	{
		let d2 = LengthSquared(a.center - b.center);
		let combined = a.radius + b.radius;
		if (d2 > combined * combined)
			return .Disjoint;

		let sub = a.radius - b.radius;
		return (sub * sub < d2) ? .Intersects : .Contains;
	}

	/// Corner test first, then the closest-point distance.
	public static ContainmentType Contains(BoundingSphere s, AABB bounds)
	{
		Float3[8] c = ?;
		GetCorners(bounds, ref c);

		var inside = true;
		for (int i < 8)
		{
			if (s.Contains(c[i]) == .Disjoint)
			{
				inside = false;
				break;
			}
		}
		if (inside)
			return .Contains;

		var dist = 0.0f;
		if (s.center.x < bounds.min.x)
			dist += (s.center.x - bounds.min.x) * (s.center.x - bounds.min.x);
		else if (s.center.x > bounds.max.x)
			dist += (s.center.x - bounds.max.x) * (s.center.x - bounds.max.x);

		if (s.center.y < bounds.min.y)
			dist += (s.center.y - bounds.min.y) * (s.center.y - bounds.min.y);
		else if (s.center.y > bounds.max.y)
			dist += (s.center.y - bounds.max.y) * (s.center.y - bounds.max.y);

		if (s.center.z < bounds.min.z)
			dist += (s.center.z - bounds.min.z) * (s.center.z - bounds.min.z);
		else if (s.center.z > bounds.max.z)
			dist += (s.center.z - bounds.max.z) * (s.center.z - bounds.max.z);

		return (dist <= s.radius * s.radius) ? .Intersects : .Disjoint;
	}

	public static ContainmentType ContainsCT(AABB b, AABB o)
	{
		if ((o.max.x < b.min.x) || (o.min.x > b.max.x) ||
			(o.max.y < b.min.y) || (o.min.y > b.max.y) ||
			(o.max.z < b.min.z) || (o.min.z > b.max.z))
			return .Disjoint;

		if ((o.min.x >= b.min.x) && (o.max.x <= b.max.x) &&
			(o.min.y >= b.min.y) && (o.max.y <= b.max.y) &&
			(o.min.z >= b.min.z) && (o.max.z <= b.max.z))
			return .Contains;

		return .Intersects;
	}

	public static ContainmentType ContainsCT(AABB b, BoundingFrustum f)
	{
		if (!Intersects(f, b))
			return .Disjoint;
		for (int i < BoundingFrustum.CornerCount)
		{
			if (ContainsCT(b, f.corners[i]) == .Disjoint)
				return .Intersects;
		}
		return .Contains;
	}

	public static bool Intersects(AABB b, BoundingFrustum f) => Intersects(f, b);

	public static ContainmentType Contains(BoundingFrustum f, BoundingFrustum g)
	{
		var intersection = false;
		for (int i < BoundingFrustum.PlaneCount)
		{
			switch (g.Intersects(f.planes[i]))
			{
			case .Front: return .Disjoint;
			case .Intersecting: intersection = true;
			default:
			}
		}
		return intersection ? .Intersects : .Contains;
	}

	public static bool Intersects(BoundingFrustum f, BoundingFrustum g) =>
		Contains(f, g) != .Disjoint;
}
