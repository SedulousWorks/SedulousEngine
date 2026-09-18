using System;

namespace Sedulous.Core;

/// A centre and a Radius.
[CRepr]
[Scriptable(.AllPublic)]
struct BoundingSphere
{
	public Float3 Center;
	public float Radius = 0.0f;

	[Inline]
	public this() { Center = default; }
	[Inline]
	public this(Float3 center, float radius) { this.Center = center; this.Radius = radius; }

	public static BoundingSphere FromCenterRadius(Float3 c, float r) => .(c, r);

	/// The smallest sphere enclosing both.
	public static BoundingSphere Merge(BoundingSphere a, BoundingSphere b)
	{
		let offset = b.Center - a.Center;
		let distance = Length(offset);
		if (a.Radius + b.Radius >= distance)
		{
			if (distance <= a.Radius - b.Radius)
				return a;
			if (distance <= b.Radius - a.Radius)
				return b;
		}
		let n = offset * (1.0f / distance);
		let mn = Min(-a.Radius, distance - b.Radius);
		let mx = (Max(a.Radius, distance + b.Radius) - mn) * 0.5f;
		return .(a.Center + n * (mx + mn), mx);
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
			if (p.X < minX.X) minX = p;
			if (p.X > maxX.X) maxX = p;
			if (p.Y < minY.Y) minY = p;
			if (p.Y > maxY.Y) maxY = p;
			if (p.Z < minZ.Z) minZ = p;
			if (p.Z > maxZ.Z) maxZ = p;
		}

		let dX = Distance(minX, maxX);
		let dY = Distance(minY, maxY);
		let dZ = Distance(minZ, maxZ);

		Float3 Center;
		float Radius;
		if ((dX > dY) && (dX > dZ))
		{
			Center = Lerp(minX, maxX, 0.5f);
			Radius = dX * 0.5f;
		}
		else if (dY > dZ)
		{
			Center = Lerp(minY, maxY, 0.5f);
			Radius = dY * 0.5f;
		}
		else
		{
			Center = Lerp(minZ, maxZ, 0.5f);
			Radius = dZ * 0.5f;
		}

		for (int i = 0; i < points.Length; i++)
		{
			let rel = points[i] - Center;
			let dist = Length(rel);
			if (dist > Radius)
			{
				Radius = (Radius + dist) * 0.5f;
				Center = Center + rel * (1.0f - Radius / dist);
			}
		}
		return .(Center, Radius);
	}

	public void Expand(Float3 p) mut
	{
		let rel = p - Center;
		let dist = Length(rel);
		if (dist > Radius)
		{
			let nr = (Radius + dist) * 0.5f;
			Center = Center + rel * (1.0f - nr / dist);
			Radius = nr;
		}
	}

	public ContainmentType Contains(Float3 point) =>
		LengthSquared(point - Center) < Radius * Radius ? .Contains : .Disjoint;

	/// Signed-distance plane test. Front means fully on the normal's positive side.
	public PlaneIntersectionType Intersects(Plane plane)
	{
		let dist = Dot(plane.Normal, Center) + plane.D;
		if (dist > Radius)
			return .Front;
		if (dist < -Radius)
			return .Back;
		return .Intersecting;
	}
}
