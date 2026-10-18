using System;

namespace Sedulous.UI;

/// Where an interpolated value that needs a list keeps it: a box-shadow of two or more. The
/// value StyleValueOps.Lerp answers BORROWS it, so the owner keeps this as long as the value is
/// in use, and the next Lerp into it rewrites it.
class StyleLerpScratch
{
	public BoxShadowList Shadows = new .() ~ _.ReleaseRef();

	public this() {}

	/// Whether `value` borrows a list this holds.
	public bool Holds(StyleValue value) => (value case .Shadows(let list)) && (list == Shadows);
}
