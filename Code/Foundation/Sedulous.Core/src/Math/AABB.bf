using System;

namespace Sedulous.Core;

/// Axis-aligned bounding box.
[CRepr]
struct AABB
{
	public Float3 Min;
	public Float3 Max;

	public this() { Min = default; Max = default; }
	public this(Float3 min, Float3 max) { this.Min = min; this.Max = max; }

	/// An inverted box, Min above Max, so the first Expand sets real bounds.
	public static AABB Empty() => .(
		Float3(FloatMax, FloatMax, FloatMax),
		Float3(-FloatMax, -FloatMax, -FloatMax));

	public static AABB FromCenterExtents(Float3 center, Float3 extents) =>
		.(center - extents, center + extents);

	public Float3 Center() => (Min + Max) * 0.5f;
	public Float3 Size() => Max - Min;
	public Float3 Extents() => (Max - Min) * 0.5f;

	public bool IsValid() => (Min.X <= Max.X) && (Min.Y <= Max.Y) && (Min.Z <= Max.Z);

	public bool Contains(Float3 p) =>
		(p.X >= Min.X) && (p.X <= Max.X) &&
		(p.Y >= Min.Y) && (p.Y <= Max.Y) &&
		(p.Z >= Min.Z) && (p.Z <= Max.Z);

	public bool Intersects(AABB other) =>
		(Min.X <= other.Max.X) && (Max.X >= other.Min.X) &&
		(Min.Y <= other.Max.Y) && (Max.Y >= other.Min.Y) &&
		(Min.Z <= other.Max.Z) && (Max.Z >= other.Min.Z);

	/// Grows the box to include a point.
	///
	/// The free Min and Max are qualified because the fields of the same name shadow
	/// them here: unqualified, `Min(Min, p)` resolves Min to the field and tries to
	/// invoke a Float3. Sedulous hits the same thing and writes Math.Min per component.
	public void Expand(Float3 p) mut
	{
		Min = Sedulous.Core.Min(Min, p);
		Max = Sedulous.Core.Max(Max, p);
	}
}

static
{
	public static AABB Merge(AABB a, AABB b) => .(Min(a.Min, b.Min), Max(a.Max, b.Max));
}
