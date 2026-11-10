using System;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Engine.GUI;

namespace Sedulous.Engine.DefaultApp;

/// An application's profiler overlay, on the GUI.
/// Whether an app has one, and what turns it on, is the app's to decide; the GUI only gives it a
/// place to draw, its overlay layer (GuiSubsystem.PushOverlay), above every screen and run, where a
/// tree that takes no pointer leaves the game playable under it. DefaultApplication owns one (F3,
/// --profile-overlay, the web page's ?profile-overlay); another app can own its own.
class ProfilerOverlayHost
{
	/// BORROWED: the store it shows and arms while shown (a test's own, or the process's).
	private Sedulous.Profiler.Profiler mProfiler;
	/// BORROWED, while shown.
	private GuiSubsystem mGui = null;
	private LiveProfileSource mSource ~ delete _;
	/// Ours: the overlay holds a reference of its own.
	private ProfileFocus mFocus ~ { if (_ != null) _.ReleaseRef(); };
	/// Ours: the overlay layer holds a reference of its own while it is shown.
	private ProfilerOverlay mOverlay ~ { if (_ != null) _.ReleaseRef(); };

	public this(Sedulous.Profiler.Profiler profiler)
	{
		mProfiler = profiler;
	}

	public ~this()
	{
		Hide();
		// The views let go of the source before it goes.
		if (mFocus != null)
			mFocus.SetSource(null);
	}

	/// Shows it on `gui`'s overlay layer and arms the profiler (counted: a capture or the editor's
	/// profiler keeps its own arm). Nothing in a ShippingRelease build, or with no profiler.
	public void Show(GuiSubsystem gui)
	{
#if !SHIPPING
		if ((mGui != null) || (mProfiler == null) || (gui == null))
			return;
		if (mOverlay == null)
		{
			mSource = new LiveProfileSource(mProfiler);
			mFocus = new ProfileFocus();
			mOverlay = new ProfilerOverlay();
			mOverlay.Focus = mFocus;
			mFocus.SetSource(mSource);
		}
		gui.PushOverlay(mOverlay);
		mProfiler.Arm();
		mGui = gui;
		mOverlay.Refresh();
#endif
	}

	/// Takes it down and lets the profiler go. Before the GUI it shows on shuts down.
	public void Hide()
	{
		if (mGui == null)
			return;
		mGui.RemoveOverlay(mOverlay);
		mProfiler.Disarm();
		mGui = null;
	}

	public void Toggle(GuiSubsystem gui)
	{
		if (Shown)
			Hide();
		else
			Show(gui);
	}

	public bool Shown => mGui != null;

	/// Each frame, before the GUI draws: the overlay reads the frames that ended since.
	public void Refresh()
	{
		if (mGui != null)
			mOverlay.Refresh();
	}

	/// The overlay once it has been shown (tests, an app placing it in another corner).
	public ProfilerOverlay Overlay => mOverlay;
}
