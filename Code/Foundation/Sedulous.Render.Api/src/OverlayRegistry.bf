using System;
using System.Collections;

namespace Sedulous.Render;

/// A registry of overlay sources, kept sorted by their order.
///
/// NON OWNING: a caller registers and unregisters, and must do the second before it destroys
/// the source. Insertion sorted, and STABLE on ties, so two overlays at the same order keep
/// the order they registered in rather than shuffling between frames.
class OverlayRegistry<TOverlay> where TOverlay : IOverlay
{
	private List<TOverlay> mItems = new .() ~ delete _;

	/// IDEMPOTENT: registering something twice is not registering it twice.
	public void Add(TOverlay overlay)
	{
		if ((overlay == null) || Contains(overlay))
			return;

		var index = 0;
		while ((index < mItems.Count) && (mItems[index].OverlayOrder <= overlay.OverlayOrder))
			index++;

		mItems.Insert(index, overlay);
	}

	public void Remove(TOverlay overlay)
	{
		for (int i < mItems.Count)
		{
			if (mItems[i] == overlay)
			{
				mItems.RemoveAt(i);
				return;
			}
		}
	}

	public bool Contains(TOverlay overlay)
	{
		for (let item in mItems)
		{
			if (item == overlay)
				return true;
		}
		return false;
	}

	public bool IsEmpty => mItems.IsEmpty;
	public int Count => mItems.Count;

	/// In order. BORROWED: the registry owns nothing here.
	public Span<TOverlay> Items => .(mItems.Ptr, mItems.Count);
}
