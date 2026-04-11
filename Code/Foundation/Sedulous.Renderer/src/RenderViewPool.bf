namespace Sedulous.Renderer;

using System;
using System.Collections;

/// Pool of RenderView instances reused across frames.
///
/// Per-view extraction means the renderer needs N views per frame: one for the
/// main camera plus one per shadow caster (and eventually reflection probes,
/// portals, etc.). Allocating new RenderView + ExtractedRenderData every frame
/// would churn memory; the pool keeps them alive across frames and just clears
/// the per-view render data lists at the start of each frame.
///
/// Usage:
///   pool.BeginFrame();              // clears all entries' render data lists
///   let main = pool.Acquire();      // get next free view
///   // ... fill main's matrices, extract into main.RenderData ...
///   for each shadow caster:
///     let shadow = pool.Acquire();
///     // ... fill shadow's matrices, extract ...
///   for view in pool.ActiveViews:
///     pipeline.Render(encoder, view);
class RenderViewPool
{
	private List<RenderView> mPool = new .() ~ DeleteContainerAndItems!(_);
	private int32 mUsedCount = 0;

	/// All currently-acquired views for this frame.
	public Span<RenderView> ActiveViews
	{
		get
		{
			if (mUsedCount == 0)
				return .();
			return Span<RenderView>(&mPool[0], mUsedCount);
		}
	}

	/// Number of views acquired this frame.
	public int32 ActiveCount => mUsedCount;

	/// Resets the pool for a new frame and clears all entries' render data lists.
	/// MUST be called before RenderContext.BeginFrame() so the lists drop their
	/// references to the previous frame's arena memory before the arena rewinds.
	public void BeginFrame()
	{
		for (let view in mPool)
			view.RenderData.Clear();
		mUsedCount = 0;
	}

	/// Acquires the next free view, growing the pool if needed.
	public RenderView Acquire()
	{
		if (mUsedCount < mPool.Count)
		{
			let view = mPool[mUsedCount];
			mUsedCount++;
			return view;
		}

		let view = new RenderView();
		mPool.Add(view);
		mUsedCount++;
		return view;
	}
}
