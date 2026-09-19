using System;
using Sedulous.Core;

namespace Sedulous.Core;

/// Six Planes and eight Corners derived from a view-projection Matrix.
///
/// The Planes point OUTWARD, so a point is inside when it is on the negative side of
/// every one. That sign convention is the thing to get right: inverted, culling either
/// keeps everything or discards everything, and both look plausible in a profiler.
[CRepr]
[Scriptable]
struct BoundingFrustum
{
	public const int32 CornerCount = 8;
	public const int32 PlaneCount = 6;

	public Float4x4 Matrix;
	public Plane[PlaneCount] Planes;
	public Float3[CornerCount] Corners;

	public this()
	{
		Matrix = default;
		Planes = default;
		Corners = default;
	}

	public this(Float4x4 m)
	{
		Matrix = default;
		Planes = default;
		Corners = default;
		SetMatrix(m);
	}

	public Plane Near => Planes[0];
	public Plane Far => Planes[1];
	public Plane Left => Planes[2];
	public Plane Right => Planes[3];
	public Plane Top => Planes[4];
	public Plane Bottom => Planes[5];

	/// Gribb-Hartmann plane extraction for a row-vector, row-major view-projection with
	/// NDC z in [0,1]. The Planes come out pointing outward.
	public void SetMatrix(Float4x4 m) mut
	{
		Matrix = m;
		Planes[0] = .(Float3(-m[0, 2], -m[1, 2], -m[2, 2]), -m[3, 2]);                     // Near
		Planes[1] = .(Float3(m[0, 2] - m[0, 3], m[1, 2] - m[1, 3], m[2, 2] - m[2, 3]),
			m[3, 2] - m[3, 3]);                                                            // Far
		Planes[2] = .(Float3(-m[0, 3] - m[0, 0], -m[1, 3] - m[1, 0], -m[2, 3] - m[2, 0]),
			-m[3, 3] - m[3, 0]);                                                           // Left
		Planes[3] = .(Float3(m[0, 0] - m[0, 3], m[1, 0] - m[1, 3], m[2, 0] - m[2, 3]),
			m[3, 0] - m[3, 3]);                                                            // Right
		Planes[4] = .(Float3(m[0, 1] - m[0, 3], m[1, 1] - m[1, 3], m[2, 1] - m[2, 3]),
			m[3, 1] - m[3, 3]);                                                            // Top
		Planes[5] = .(Float3(-m[0, 3] - m[0, 1], -m[1, 3] - m[1, 1], -m[2, 3] - m[2, 1]),
			-m[3, 3] - m[3, 1]);                                                           // Bottom

		for (int i < PlaneCount)
			NormalizePlane(ref Planes[i]);

		let nl = PlaneRay(Planes[0], Planes[2]);   // near meets left
		let rn = PlaneRay(Planes[3], Planes[0]);   // right meets near
		let lf = PlaneRay(Planes[2], Planes[1]);   // left meets far
		let fr = PlaneRay(Planes[1], Planes[3]);   // far meets right
		Corners[0] = PlanePoint(Planes[4], nl);
		Corners[1] = PlanePoint(Planes[4], rn);
		Corners[2] = PlanePoint(Planes[5], rn);
		Corners[3] = PlanePoint(Planes[5], nl);
		Corners[4] = PlanePoint(Planes[4], lf);
		Corners[5] = PlanePoint(Planes[4], fr);
		Corners[6] = PlanePoint(Planes[5], fr);
		Corners[7] = PlanePoint(Planes[5], lf);
	}

	public ContainmentType Contains(Float3 point)
	{
		for (int i < PlaneCount)
		{
			if (ApproxGreater(Dot(Planes[i].Normal, point) + Planes[i].D, 0.0f))
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
			if (Dot(Corners[i], plane.Normal) + plane.D > 0.0f)
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
		let len = Length(p.Normal);
		p.Normal /= len;
		p.D /= len;
	}

	/// The line where two Planes meet.
	private static Ray PlaneRay(Plane p1, Plane p2)
	{
		let dir = Cross(p1.Normal, p2.Normal);
		let a = p1.Normal * p2.D - p2.Normal * p1.D;
		let pos = Cross(a, dir) * (1.0f / LengthSquared(dir));
		return .(pos, dir);
	}

	/// Where a ray meets a plane.
	private static Float3 PlanePoint(Plane p, Ray r)
	{
		let dist = (-p.D - Dot(p.Normal, r.Position)) / Dot(p.Normal, r.Direction);
		return r.Position + r.Direction * dist;
	}
}
