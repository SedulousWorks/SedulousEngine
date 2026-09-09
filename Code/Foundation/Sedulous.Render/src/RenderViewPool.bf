using System;
using System.Collections;

namespace Sedulous.Render;

/// A per frame pool of views.
///
/// Beginning rewinds it, KEEPING the views and their draw list buffers; acquiring hands out
/// the next one. A view stays valid until the next begin.
///
/// The addresses are STABLE: the views are separate allocations rather than elements of a
/// list, so growing the pool never moves a view somebody has already acquired.
class RenderViewPool
{
	private List<RenderView> mViews = new .() ~ DeleteContainerAndItems!(_);
	private int mCount = 0;

	public void Begin() => mCount = 0;

	/// BORROWED: the pool owns what comes back.
	public RenderView Acquire()
	{
		if (mCount == mViews.Count)
			mViews.Add(new RenderView());

		return mViews[mCount++];
	}

	public int ActiveCount => mCount;
	public RenderView At(int index) => mViews[index];
}
