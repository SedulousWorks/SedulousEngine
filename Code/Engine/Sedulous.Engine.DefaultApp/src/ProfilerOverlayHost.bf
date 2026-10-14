using System;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;
using Sedulous.UI;
using Sedulous.Engine.UI;

namespace Sedulous.Engine.DefaultApp;

/// An application's profiler overlay. Whether an app has one, and what turns it on, is the
/// app's to decide; the UI only gives it a place to draw, its screen tier's global overlay
/// layer (PushScreenOverlay), above every scene and run, where a view that takes no pointer
/// leaves the game playable under it. DefaultApplication owns one (F3, --profile-overlay, the
/// web page's ?profile-overlay); another app can own its own.
class ProfilerOverlayHost
{
	/// BORROWED: the store it shows and arms while shown (a test's own, or the process's).
	private Sedulous.Profiler.Profiler mProfiler;
	/// BORROWED, while shown.
	private UISubsystem mUI = null;
	private LiveProfileSource mSource ~ delete _;
	/// Ours: the screen tier holds a reference of its own while it is shown.
	private ProfilerOverlay mOverlay ~ { if (_ != null) _.ReleaseRef(); };

	public this(Sedulous.Profiler.Profiler profiler)
	{
		mProfiler = profiler;
	}

	public ~this()
	{
		Hide();
	}

	/// Shows it on `ui`'s screen tier and arms the profiler (counted: a capture or the panel
	/// keeps its own arm). Nothing in a ShippingRelease build, or with no profiler.
	public void Show(UISubsystem ui)
	{
#if !SHIPPING
		if ((mUI != null) || (mProfiler == null) || (ui == null))
			return;
		if (mOverlay == null)
		{
			mSource = new LiveProfileSource(mProfiler);
			mOverlay = new ProfilerOverlay();
			mOverlay.Source = mSource;
			var fill = LayoutStyle();
			fill.Width = SizeSpec.Match();
			fill.Height = SizeSpec.Match();
			mOverlay.SetLayout(fill);
		}
		mOverlay.AddRef(); // the overlay layer consumes one
		ui.PushScreenOverlay(mOverlay);
		mProfiler.Arm();
		mUI = ui;
		mOverlay.Refresh();
#endif
	}

	/// Takes it down and lets the profiler go. Before the UI it shows on shuts down.
	public void Hide()
	{
		if (mUI == null)
			return;
		mUI.RemoveScreenOverlay(mOverlay);
		mProfiler.Disarm();
		mUI = null;
	}

	public void Toggle(UISubsystem ui)
	{
		if (Shown)
			Hide();
		else
			Show(ui);
	}

	public bool Shown => mUI != null;

	/// Each frame, before the UI draws: the views take the frames that ended since.
	public void Refresh()
	{
		if (mUI != null)
			mOverlay.Refresh();
	}

	/// The overlay once it has been shown (tests, an app placing it in another corner).
	public ProfilerOverlay Overlay => mOverlay;
}
