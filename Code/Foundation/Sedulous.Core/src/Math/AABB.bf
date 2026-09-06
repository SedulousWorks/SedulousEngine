using System;

namespace Sedulous.Core;

/// Axis-aligned bounding box.
[CRepr]
struct AABB
{
	public Float3 min;
	public Float3 max;

	public this() { min = default; max = default; }
	public this(Float3 min, Float3 max) { this.min = min; this.max = max; }

	/// An inverted box, min above max, so the first Expand sets real bounds.
	public static AABB Empty() => .(
		Float3(FloatMax, FloatMax, FloatMax),
		Float3(-FloatMax, -FloatMax, -FloatMax));

	public static AABB FromCenterExtents(Float3 center, Float3 extents) =>
		.(center - extents, center + extents);

	public Float3 Center() => (min + max) * 0.5f;
	public Float3 Size() => max - min;
	public Float3 Extents() => (max - min) * 0.5f;

	public bool IsValid() => (min.x <= max.x) && (min.y <= max.y) && (min.z <= max.z);

	public bool Contains(Float3 p) =>
		(p.x >= min.x) && (p.x <= max.x) &&
		(p.y >= min.y) && (p.y <= max.y) &&
		(p.z >= min.z) && (p.z <= max.z);

	public bool Intersects(AABB other) =>
		(min.x <= other.max.x) && (max.x >= other.min.x) &&
		(min.y <= other.max.y) && (max.y >= other.min.y) &&
		(min.z <= other.max.z) && (max.z >= other.min.z);

	/// Grows the box to include a point.
	public void Expand(Float3 p) mut
	{
		min = Min(min, p);
		max = Max(max, p);
	}
}

static
{
	public static AABB Merge(AABB a, AABB b) => .(Min(a.min, b.min), Max(a.max, b.max));
}
