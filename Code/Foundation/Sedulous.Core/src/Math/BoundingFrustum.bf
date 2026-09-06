using System;

namespace Sedulous.Core;

/// Six planes and eight corners derived from a view-projection matrix.
///
/// The planes point OUTWARD, so a point is inside when it is on the negative side of
/// every one. That sign convention is the thing to get right: inverted, culling either
/// keeps everything or discards everything, and both look plausible in a profiler.
[CRepr]
struct BoundingFrustum
{
	public const int32 CornerCount = 8;
	public const int32 PlaneCount = 6;

	public Float4x4 matrix;
	public Plane[PlaneCount] planes;
	public Float3[CornerCount] corners;

	public this()
	{
		matrix = default;
		planes = default;
		corners = default;
	}

	public this(Float4x4 m)
	{
		matrix = default;
		planes = default;
		corners = default;
		SetMatrix(m);
	}

	public Plane Near => planes[0];
	public Plane Far => planes[1];
	public Plane Left => planes[2];
	public Plane Right => planes[3];
	public Plane Top => planes[4];
	public Plane Bottom => planes[5];

	/// Gribb-Hartmann plane extraction for a row-vector, row-major view-projection with
	/// NDC z in [0,1]. The planes come out pointing outward.
	public void SetMatrix(Float4x4 m) mut
	{
		matrix = m;
		planes[0] = .(Float3(-m[0, 2], -m[1, 2], -m[2, 2]), -m[3, 2]);                     // Near
		planes[1] = .(Float3(m[0, 2] - m[0, 3], m[1, 2] - m[1, 3], m[2, 2] - m[2, 3]),
			m[3, 2] - m[3, 3]);                                                            // Far
		planes[2] = .(Float3(-m[0, 3] - m[0, 0], -m[1, 3] - m[1, 0], -m[2, 3] - m[2, 0]),
			-m[3, 3] - m[3, 0]);                                                           // Left
		planes[3] = .(Float3(m[0, 0] - m[0, 3], m[1, 0] - m[1, 3], m[2, 0] - m[2, 3]),
			m[3, 0] - m[3, 3]);                                                            // Right
		planes[4] = .(Float3(m[0, 1] - m[0, 3], m[1, 1] - m[1, 3], m[2, 1] - m[2, 3]),
			m[3, 1] - m[3, 3]);                                                            // Top
		planes[5] = .(Float3(-m[0, 3] - m[0, 1], -m[1, 3] - m[1, 1], -m[2, 3] - m[2, 1]),
			-m[3, 3] - m[3, 1]);                                                           // Bottom

		for (int i < PlaneCount)
			NormalizePlane(ref planes[i]);

		let nl = PlaneRay(planes[0], planes[2]);   // near meets left
		let rn = PlaneRay(planes[3], planes[0]);   // right meets near
		let lf = PlaneRay(planes[2], planes[1]);   // left meets far
		let fr = PlaneRay(planes[1], planes[3]);   // far meets right
		corners[0] = PlanePoint(planes[4], nl);
		corners[1] = PlanePoint(planes[4], rn);
		corners[2] = PlanePoint(planes[5], rn);
		corners[3] = PlanePoint(planes[5], nl);
		corners[4] = PlanePoint(planes[4], lf);
		corners[5] = PlanePoint(planes[4], fr);
		corners[6] = PlanePoint(planes[5], fr);
		corners[7] = PlanePoint(planes[5], lf);
	}

	public ContainmentType Contains(Float3 point)
	{
		for (int i < PlaneCount)
		{
			if (ApproxGreater(Dot(planes[i].normal, point) + planes[i].d, 0.0f))
				return .Disjoint;
		}
		return .Contains;
	}

	public PlaneIntersectionType Intersects(Plane plane)
	{
		var front = false;
		var back = false;
		for (int i < CornerCount)
		{
			if (Dot(corners[i], plane.normal) + plane.d > 0.0f)
				front = true;
			else
				back = true;

			if (front && back)
				return .Intersecting;
		}
		return front ? .Front : .Back;
	}

	private static void NormalizePlane(ref Plane p)
	{
		let len = Length(p.normal);
		p.normal /= len;
		p.d /= len;
	}

	/// The line where two planes meet.
	private static Ray PlaneRay(Plane p1, Plane p2)
	{
		let dir = Cross(p1.normal, p2.normal);
		let a = p1.normal * p2.d - p2.normal * p1.d;
		let pos = Cross(a, dir) * (1.0f / LengthSquared(dir));
		return .(pos, dir);
	}

	/// Where a ray meets a plane.
	private static Float3 PlanePoint(Plane p, Ray r)
	{
		let dist = (-p.d - Dot(p.normal, r.position)) / Dot(p.normal, r.direction);
		return r.position + r.direction * dist;
	}
}
