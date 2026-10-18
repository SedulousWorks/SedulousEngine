using System;

namespace Sedulous.UI;

/// Where an interpolated value that needs a list keeps it: a box-shadow of two or more, a
/// transform, a transform-origin. The
/// value StyleValueOps.Lerp answers BORROWS it, so the owner keeps this as long as the value is
/// in use, and the next Lerp into it rewrites it.
class StyleLerpScratch
{
	public BoxShadowList Shadows = new .() ~ _.ReleaseRef();
	public TransformList Transform = new .() ~ _.ReleaseRef();
	public StylePoint Point = new .() ~ _.ReleaseRef();

	public this() {}

	/// Whether `value` borrows a list this holds.
	public bool Holds(StyleValue value)
	{
		switch (value)
		{
		case .Shadows(let list): return list == Shadows;
		case .Transform(let list): return list == Transform;
		case .Point(let point): return point == Point;
		default: return false;
		}
	}
}
