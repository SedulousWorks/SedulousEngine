using System;

namespace Sedulous.Core;

/// A centre and a radius.
[CRepr]
struct BoundingSphere
{
	public Float3 center;
	public float radius = 0.0f;

	public this() { center = default; }
	public this(Float3 center, float radius) { this.center = center; this.radius = radius; }

	public static BoundingSphere FromCenterRadius(Float3 c, float r) => .(c, r);

	/// The smallest sphere enclosing both.
	public static BoundingSphere Merge(BoundingSphere a, BoundingSphere b)
	{
		let offset = b.center - a.center;
		let distance = Length(offset);
		if (a.radius + b.radius >= distance)
		{
			if (distance <= a.radius - b.radius)
				return a;
			if (distance <= b.radius - a.radius)
				return b;
		}
		let n = offset * (1.0f / distance);
		let mn = Min(-a.radius, distance - b.radius);
		let mx = (Max(a.radius, distance + b.radius) - mn) * 0.5f;
		return .(a.center + n * (mx + mn), mx);
	}

	/// Ritter-style enclosing sphere of a point set.
	///
	/// Sedulous's X-axis branch has a copy-paste bug, interpolating minX with minY; this
	/// is ported correctly, as Raptor's is.
	public static BoundingSphere FromPoints(Span<Float3> points)
	{
		if (points.IsEmpty)
			return .(Float3(0, 0, 0), 0.0f);

		var minX = points[0];
		var maxX = points[0];
		var minY = points[0];
		var maxY = points[0];
		var minZ = points[0];
		var maxZ = points[0];

		for (int i = 1; i < points.Length; i++)
		{
			let p = points[i];
			if (p.x < minX.x) minX = p;
			if (p.x > maxX.x) maxX = p;
			if (p.y < minY.y) minY = p;
			if (p.y > maxY.y) maxY = p;
			if (p.z < minZ.z) minZ = p;
			if (p.z > maxZ.z) maxZ = p;
		}

		let dX = Distance(minX, maxX);
		let dY = Distance(minY, maxY);
		let dZ = Distance(minZ, maxZ);

		Float3 center;
		float radius;
		if ((dX > dY) && (dX > dZ))
		{
			center = Lerp(minX, maxX, 0.5f);
			radius = dX * 0.5f;
		}
		else if (dY > dZ)
		{
			center = Lerp(minY, maxY, 0.5f);
			radius = dY * 0.5f;
		}
		else
		{
			center = Lerp(minZ, maxZ, 0.5f);
			radius = dZ * 0.5f;
		}

		for (int i = 0; i < points.Length; i++)
		{
			let rel = points[i] - center;
			let dist = Length(rel);
			if (dist > radius)
			{
				radius = (radius + dist) * 0.5f;
				center = center + rel * (1.0f - radius / dist);
			}
		}
		return .(center, radius);
	}

	public void Expand(Float3 p) mut
	{
		let rel = p - center;
		let dist = Length(rel);
		if (dist > radius)
		{
			let nr = (radius + dist) * 0.5f;
			center = center + rel * (1.0f - nr / dist);
			radius = nr;
		}
	}

	public ContainmentType Contains(Float3 point) =>
		LengthSquared(point - center) < radius * radius ? .Contains : .Disjoint;

	/// Signed-distance plane test. Front means fully on the normal's positive side.
	public PlaneIntersectionType Intersects(Plane plane)
	{
		let dist = Dot(plane.normal, center) + plane.d;
		if (dist > radius)
			return .Front;
		if (dist < -radius)
			return .Back;
		return .Intersecting;
	}
}
