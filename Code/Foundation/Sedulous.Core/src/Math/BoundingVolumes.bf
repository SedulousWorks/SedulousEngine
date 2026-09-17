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
			switch (s.Intersects(f.Planes[i]))
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
		let c = Float3(s.Radius, s.Radius, s.Radius);
		return .(s.Center - c, s.Center + c);
	}

	/// Sedulous's corner order: index 0 is (min.X, max.Y, max.Z) through to 7 being
	/// (min.X, min.Y, min.Z).
	public static void GetCorners(AABB b, ref Float3[8] corners)
	{
		corners[0] = .(b.Min.X, b.Max.Y, b.Max.Z);
		corners[1] = .(b.Max.X, b.Max.Y, b.Max.Z);
		corners[2] = .(b.Max.X, b.Min.Y, b.Max.Z);
		corners[3] = .(b.Min.X, b.Min.Y, b.Max.Z);
		corners[4] = .(b.Min.X, b.Max.Y, b.Min.Z);
		corners[5] = .(b.Max.X, b.Max.Y, b.Min.Z);
		corners[6] = .(b.Max.X, b.Min.Y, b.Min.Z);
		corners[7] = .(b.Min.X, b.Min.Y, b.Min.Z);
	}

	/// AABB.Contains already answers this as a bool; this is the ContainmentType form,
	/// which cannot be an overload because only the return type differs.
	public static ContainmentType ContainsCT(AABB b, Float3 p) =>
		b.Contains(p) ? .Contains : .Disjoint;

	public static PlaneIntersectionType Intersects(AABB b, Plane plane)
	{
		let pos = Float3(
			plane.Normal.X >= 0 ? b.Min.X : b.Max.X,
			plane.Normal.Y >= 0 ? b.Min.Y : b.Max.Y,
			plane.Normal.Z >= 0 ? b.Min.Z : b.Max.Z);
		let neg = Float3(
			plane.Normal.X >= 0 ? b.Max.X : b.Min.X,
			plane.Normal.Y >= 0 ? b.Max.Y : b.Min.Y,
			plane.Normal.Z >= 0 ? b.Max.Z : b.Min.Z);

		if (Dot(plane.Normal, pos) + plane.D > 0.0f)
			return .Front;
		if (Dot(plane.Normal, neg) + plane.D < 0.0f)
			return .Back;
		return .Intersecting;
	}

	public static bool Intersects(AABB b, BoundingSphere s)
	{
		let clamped = ClampVec(s.Center, b.Min, b.Max);
		return LengthSquared(s.Center - clamped) <= s.Radius * s.Radius;
	}

	/// The transformed bounds that encloses the transformed original: the centre moves and
	/// the extents pick up the absolute row sums.
	public static AABB TransformAABB(AABB b, Float4x4 m)
	{
		let c = b.Center();
		let e = b.Extents();
		let nc = Float3(
			c.X * m[0, 0] + c.Y * m[1, 0] + c.Z * m[2, 0] + m[3, 0],
			c.X * m[0, 1] + c.Y * m[1, 1] + c.Z * m[2, 1] + m[3, 1],
			c.X * m[0, 2] + c.Y * m[1, 2] + c.Z * m[2, 2] + m[3, 2]);
		let ne = Float3(
			Abs(m[0, 0]) * e.X + Abs(m[1, 0]) * e.Y + Abs(m[2, 0]) * e.Z,
			Abs(m[0, 1]) * e.X + Abs(m[1, 1]) * e.Y + Abs(m[2, 1]) * e.Z,
			Abs(m[0, 2]) * e.X + Abs(m[1, 2]) * e.Y + Abs(m[2, 2]) * e.Z);
		return .(nc - ne, nc + ne);
	}

	// ---- frustum against bounds ----

	public static ContainmentType Contains(BoundingFrustum f, AABB b)
	{
		var intersects = false;
		for (int i < BoundingFrustum.PlaneCount)
		{
			switch (Intersects(b, f.Planes[i]))
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
		let clamped = ClampVec(s.Center, b.Min, b.Max);
		if (s.Radius * s.Radius <= LengthSquared(s.Center - clamped))
			return .Disjoint;

		if ((s.Center.X > b.Max.X - s.Radius) || (s.Center.Y > b.Max.Y - s.Radius) ||
			(s.Center.Z > b.Max.Z - s.Radius) || (b.Min.X + s.Radius > s.Center.X) ||
			(b.Min.Y + s.Radius > s.Center.Y) || (b.Min.Z + s.Radius > s.Center.Z) ||
			(b.Max.X - b.Min.X <= s.Radius) || (b.Max.Y - b.Min.Y <= s.Radius) ||
			(b.Max.Z - b.Min.Z <= s.Radius))
			return .Intersects;

		return .Contains;
	}

	// ---- sphere cross-type ----

	public static bool Intersects(BoundingSphere a, BoundingSphere b)
	{
		let combined = a.Radius + b.Radius;
		return LengthSquared(a.Center - b.Center) <= combined * combined;
	}

	public static bool Intersects(BoundingSphere s, AABB b) => Intersects(b, s);
	public static bool Intersects(BoundingSphere s, BoundingFrustum f) => Intersects(f, s);

	public static ContainmentType Contains(BoundingSphere s, BoundingFrustum f)
	{
		if (!Intersects(f, s))
			return .Disjoint;
		for (int i < BoundingFrustum.CornerCount)
		{
			if (s.Contains(f.Corners[i]) == .Disjoint)
				return .Intersects;
		}
		return .Contains;
	}

	public static BoundingSphere BoundingSphereFromFrustum(BoundingFrustum f)
	{
		var corners = f.Corners;
		return BoundingSphere.FromPoints(Span<Float3>(&corners[0], BoundingFrustum.CornerCount));
	}

	// ---- ray intersections; false means no hit, and outT is only set on a hit ----

	public static bool Intersects(Ray ray, Plane plane, out float outT)
	{
		outT = 0.0f;
		let nDotDir = Dot(plane.Normal, ray.Direction);
		if (ApproxZero(nDotDir))
			return false;

		let dist = -(Dot(plane.Normal, ray.Position) + plane.D) / nDotDir;
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
		let r2 = sphere.Radius * sphere.Radius;
		let offset = sphere.Center - ray.Position;
		let offLen2 = LengthSquared(offset);
		if (offLen2 < r2)
		{
			outT = 0.0f;   // the ray starts inside
			return true;
		}

		let toCenter = Dot(ray.Direction, offset);
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

		if (ApproxZero(ray.Direction.X))
		{
			if ((ray.Position.X < bounds.Min.X) || (ray.Position.X > bounds.Max.X))
				return false;
		}
		else
		{
			mn = (bounds.Min.X - ray.Position.X) / ray.Direction.X;
			mx = (bounds.Max.X - ray.Position.X) / ray.Direction.X;
			if (mn > mx)
			{
				let t = mn; mn = mx; mx = t;
			}
			hasMin = true;
			hasMax = true;
		}

		if (ApproxZero(ray.Direction.Y))
		{
			if ((ray.Position.Y < bounds.Min.Y) || (ray.Position.Y > bounds.Max.Y))
				return false;
		}
		else
		{
			var y0 = (bounds.Min.Y - ray.Position.Y) / ray.Direction.Y;
			var y1 = (bounds.Max.Y - ray.Position.Y) / ray.Direction.Y;
			if (y0 > y1)
			{
				let t = y0; y0 = y1; y1 = t;
			}
			if (!hasMin || (y0 > mn)) { mn = y0; hasMin = true; }
			if (!hasMax || (y1 > mx)) { mx = y1; hasMax = true; }
		}

		if (ApproxZero(ray.Direction.Z))
		{
			if ((ray.Position.Z < bounds.Min.Z) || (ray.Position.Z > bounds.Max.Z))
				return false;
		}
		else
		{
			var z0 = (bounds.Min.Z - ray.Position.Z) / ray.Direction.Z;
			var z1 = (bounds.Max.Z - ray.Position.Z) / ray.Direction.Z;
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
		if (f.Contains(ray.Position) == .Contains)
		{
			outT = 0.0f;
			return true;
		}

		var mx = -FloatMax;
		var mn = FloatMax;
		for (int i < BoundingFrustum.PlaneCount)
		{
			let n = f.Planes[i].Normal;
			let dirDotN = Dot(ray.Direction, n);
			let posDotN = Dot(ray.Position, n) + f.Planes[i].D;

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
		let d2 = LengthSquared(a.Center - b.Center);
		let combined = a.Radius + b.Radius;
		if (d2 > combined * combined)
			return .Disjoint;

		let sub = a.Radius - b.Radius;
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
		if (s.Center.X < bounds.Min.X)
			dist += (s.Center.X - bounds.Min.X) * (s.Center.X - bounds.Min.X);
		else if (s.Center.X > bounds.Max.X)
			dist += (s.Center.X - bounds.Max.X) * (s.Center.X - bounds.Max.X);

		if (s.Center.Y < bounds.Min.Y)
			dist += (s.Center.Y - bounds.Min.Y) * (s.Center.Y - bounds.Min.Y);
		else if (s.Center.Y > bounds.Max.Y)
			dist += (s.Center.Y - bounds.Max.Y) * (s.Center.Y - bounds.Max.Y);

		if (s.Center.Z < bounds.Min.Z)
			dist += (s.Center.Z - bounds.Min.Z) * (s.Center.Z - bounds.Min.Z);
		else if (s.Center.Z > bounds.Max.Z)
			dist += (s.Center.Z - bounds.Max.Z) * (s.Center.Z - bounds.Max.Z);

		return (dist <= s.Radius * s.Radius) ? .Intersects : .Disjoint;
	}

	public static ContainmentType ContainsCT(AABB b, AABB o)
	{
		if ((o.Max.X < b.Min.X) || (o.Min.X > b.Max.X) ||
			(o.Max.Y < b.Min.Y) || (o.Min.Y > b.Max.Y) ||
			(o.Max.Z < b.Min.Z) || (o.Min.Z > b.Max.Z))
			return .Disjoint;

		if ((o.Min.X >= b.Min.X) && (o.Max.X <= b.Max.X) &&
			(o.Min.Y >= b.Min.Y) && (o.Max.Y <= b.Max.Y) &&
			(o.Min.Z >= b.Min.Z) && (o.Max.Z <= b.Max.Z))
			return .Contains;

		return .Intersects;
	}

	public static ContainmentType ContainsCT(AABB b, BoundingFrustum f)
	{
		if (!Intersects(f, b))
			return .Disjoint;
		for (int i < BoundingFrustum.CornerCount)
		{
			if (ContainsCT(b, f.Corners[i]) == .Disjoint)
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
			switch (g.Intersects(f.Planes[i]))
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
