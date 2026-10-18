using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A box-shadow value of more than one shadow, the first painted on top as CSS paints them.
///
/// A list rides in a StyleValue BORROWED: the sheet that parsed it owns it, and a transition's
/// in-between list is owned by the view's transition state. One shadow needs no list; it rides
/// inline as StyleValue.Shadow.
class BoxShadowList : RefCounted
{
	/// The most shadows a value holds; a list written with more keeps its first ones.
	public const int cMaxShadows = 4;

	private BoxShadow[cMaxShadows] mShadows = .();
	private int mCount = 0;

	public this() {}

	public int Count => mCount;

	public BoxShadow this[int index] => mShadows[index];

	/// Appends `shadow`; false, nothing kept, once the list holds cMaxShadows.
	public bool Add(BoxShadow shadow)
	{
		if (mCount >= cMaxShadows)
			return false;
		mShadows[mCount] = shadow;
		mCount++;
		return true;
	}

	public void Clear() => mCount = 0;
}
