using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// A stack of [[UIScreen]]s over one root view: push, pop, replace, clear, top.
///
/// The top screen owns focus and input according to its mode; screens below it are shielded
/// when it is Modal or Opaque, and hidden as well when it is Opaque. Focus is SAVED on push and
/// restored on pop, each entry remembering only what it displaced, so screens leaving out of
/// order can never cross restore one another's focus.
///
/// STRUCTURAL SAFETY. Every tree mutation runs inline only while the context is idle. Called
/// mid dispatch, from a button's click handler or an animation's completion, it defers through
/// the context's mutation queue instead, because removing a view from inside the very loop
/// walking it is how this crashes. The stack's OWN bookkeeping updates synchronously, so Top
/// and Count are correct the instant a call returns, whether or not the tree has caught up.
class ScreenStack
{
	private struct Entry
	{
		/// OWNED: the stack's own reference, separate from the tree's.
		public UIScreen Screen = null;
		/// What this screen displaced when it was pushed, given back when it pops.
		public SavedFocus SavedFocus = .();

		public this() {}
	}

	/// BORROWED: the host owns the root. Null until attached, which makes every call a no op.
	private RootView mRoot = null;
	private List<Entry> mEntries = new .() ~ ReleaseEntries!(_);

	/// OWNS the completion callbacks handed to in flight transitions.
	///
	/// A CANCELLED animation is deleted without firing its completion, so a callback deleted by
	/// the handler alone would leak on that path. Owning them here means either the handler
	/// runs and takes it, or the stack outlives the animation and deletes it.
	private List<delegate void()> mPendingCompletions = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	private static mixin ReleaseEntries(var entries)
	{
		for (let entry in entries)
			entry.Screen.ReleaseRef();
		delete entries;
	}

	/// The screen tier root this stack manages. Screens become its children.
	public void Attach(RootView root) => mRoot = root;

	public RootView Root => mRoot;

	public UIScreen Top => mEntries.IsEmpty ? null : mEntries[mEntries.Count - 1].Screen;

	public int Count => mEntries.Count;

	// ---- Stack operations ---------------------------------------------------------------------

	/// Pushes a screen on top. CONSUMES the caller's reference, as AddView does; a caller that
	/// keeps the pointer for itself calls AddRef first.
	///
	/// Returns the screen so it can be addressed at once: its subtree is searchable even before
	/// a deferred attach lands. With no root attached there is nowhere to put it, so the
	/// reference is released and null comes back.
	public UIScreen Push(UIScreen screen)
	{
		if (screen == null)
			return null;

		if (mRoot == null)
		{
			screen.ReleaseRef();
			return null;
		}

		// Bookkeeping first and synchronously, so Top and Count are right immediately.
		Entry entry = .();
		entry.Screen = screen;
		if (let focus = Focus)
			entry.SavedFocus = focus.SaveAndClearFocus();

		let previousTop = Top;
		mEntries.Add(entry);

		RunStructural(new () =>
			{
				if (mRoot == null)
					return;

				if (previousTop != null)
					previousTop.OnHidden();

				// Modal and Opaque eat input below them; an Overlay lets it through.
				screen.IsHitTestVisible = screen.ShieldsInput;
				screen.AddRef();
				mRoot.AddView(screen);
				RecomputeVisibility();
				screen.OnEnter();
				screen.OnShown();

				if (let focus = Focus)
				{
					View target = null;
					if (!screen.DefaultFocus.IsEmpty)
						target = screen.FindByName(screen.DefaultFocus);

					if (target != null)
						focus.SetFocus(target, .Programmatic);
					else
						focus.FocusFirstIn(screen);
				}

				PlayTransition(screen, screen.InTransition, true, null);
			});

		return screen;
	}

	/// Pops the top screen: plays its out transition, then detaches it and gives focus back.
	/// A no op when empty.
	public void Pop()
	{
		if (mEntries.IsEmpty)
			return;

		let entry = mEntries[mEntries.Count - 1];
		mEntries.RemoveAt(mEntries.Count - 1);
		let screen = entry.Screen;
		let saved = entry.SavedFocus;

		PlayTransition(screen, screen.OutTransition, false, new() =>
			{
				RunStructural(new() =>
					{
						if (mRoot != null)
							mRoot.RemoveView(screen);

						screen.OnExit();
						RecomputeVisibility();

						if (let newTop = Top)
							newTop.OnShown();

						if (let focus = Focus)
							focus.RestoreFocus(saved);

						// The stack's own reference, released LAST so everything above runs
						// while the screen is certainly still alive.
						screen.ReleaseRef();
					});
			});
	}

	/// Replaces the top screen: the outgoing one leaves with NO out transition, because the
	/// incoming screen is taking over the same moment. CONSUMES the caller's reference.
	///
	/// The replaced entry's saved focus is dropped rather than restored: the new screen is
	/// about to claim focus, and handing it back for one frame first only flickers.
	public UIScreen Replace(UIScreen screen)
	{
		if (!mEntries.IsEmpty)
		{
			let entry = mEntries[mEntries.Count - 1];
			mEntries.RemoveAt(mEntries.Count - 1);
			let previous = entry.Screen;

			RunStructural(new() =>
				{
					if (mRoot != null)
						mRoot.RemoveView(previous);

					previous.OnExit();
					previous.ReleaseRef();
				});
		}

		return Push(screen);
	}

	/// Pops every screen, with no transitions.
	public void Clear()
	{
		while (!mEntries.IsEmpty)
		{
			let entry = mEntries[mEntries.Count - 1];
			mEntries.RemoveAt(mEntries.Count - 1);
			let screen = entry.Screen;

			RunStructural(new() =>
				{
					if (mRoot != null)
						mRoot.RemoveView(screen);

					screen.OnExit();
					screen.ReleaseRef();
				});
		}
	}

	/// Back or Cancel: pops the top screen UNLESS it is the last one, because emptying the
	/// stack would leave the player looking at nothing and what "leave the last screen" means
	/// is the host's decision, not the stack's. True when a screen was popped.
	public bool HandleBack()
	{
		if (mEntries.Count <= 1)
			return false;

		Pop();
		return true;
	}

	// ---- Internals ----------------------------------------------------------------------------

	private UIContext Ctx => (mRoot != null) ? mRoot.Context : null;

	private FocusManager Focus
	{
		get
		{
			let context = Ctx;
			return (context != null) ? context.GetFocusManager() : null;
		}
	}

	/// True with no context at all, headless or a root not yet added to one, because then
	/// nothing is dispatching and there is nothing to re enter.
	private bool SafeToMutateNow
	{
		get
		{
			let context = Ctx;
			return (context == null) || (context.CurrentPhase == .Idle);
		}
	}

	/// CONSUMES the action, whichever path it takes.
	private void RunStructural(delegate void() action)
	{
		if (SafeToMutateNow)
		{
			action();
			delete action;
			return;
		}

		Ctx.MutationQueue.QueueAction(action);
	}

	/// Screens show from the top down until, and including, the first that hides what is below
	/// it; everything under that one is hidden. Recomputed from scratch after every push and
	/// pop, so the answer never depends on the order things happened in.
	private void RecomputeVisibility()
	{
		var covered = false;
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let screen = mEntries[i].Screen;
			screen.Visibility = covered ? .Hidden : .Visible;
			if (screen.HidesBelow)
				covered = true;
		}
	}

	/// Starts a transition and calls onDone when it finishes, which is IMMEDIATELY when there
	/// is nothing to animate: no context, no animation manager, or a kind of None. CONSUMES
	/// onDone, which may be null.
	private void PlayTransition(UIScreen screen, TransitionDesc desc, bool isEnter,
		delegate void() onDone)
	{
		let context = Ctx;
		let animations = (context != null) ? context.Animations : null;

		if ((animations == null) || (screen == null) || (desc.Kind == .None))
		{
			if (onDone != null)
			{
				onDone();
				delete onDone;
			}
			return;
		}

		// Arriving eases out and leaving eases in, so a screen decelerates into place and
		// accelerates away rather than doing the same thing twice.
		let ease = (desc.Easing != null) ? desc.Easing
			: (isEnter ? Easing.EaseOutCubic : Easing.EaseInCubic);
		let duration = (desc.Duration > 0.0f) ? desc.Duration : 0.2f;
		let size = (mRoot != null) ? mRoot.LogicalSize : Float2.Zero;

		Animation animation = null;
		switch (desc.Kind)
		{
		case .Fade:
			animation = isEnter ? ViewAnimator.FadeIn(screen, duration, ease)
				: ViewAnimator.FadeOut(screen, duration, ease);

		case .SlideLeft:
			animation = isEnter ? ViewAnimator.TranslateX(screen, size.X, 0.0f, duration, ease)
				: ViewAnimator.TranslateX(screen, 0.0f, size.X, duration, ease);

		case .SlideRight:
			animation = isEnter ? ViewAnimator.TranslateX(screen, -size.X, 0.0f, duration, ease)
				: ViewAnimator.TranslateX(screen, 0.0f, -size.X, duration, ease);

		case .SlideUp:
			animation = isEnter ? ViewAnimator.TranslateY(screen, size.Y, 0.0f, duration, ease)
				: ViewAnimator.TranslateY(screen, 0.0f, size.Y, duration, ease);

		case .SlideDown:
			animation = isEnter ? ViewAnimator.TranslateY(screen, -size.Y, 0.0f, duration, ease)
				: ViewAnimator.TranslateY(screen, 0.0f, -size.Y, duration, ease);

		case .Scale:
			// Scale carries a fade alongside it: scaling alone reads as the screen growing out
			// of nothing, which looks like a glitch rather than an arrival.
			animation = isEnter ? ViewAnimator.ScaleTo(screen, 0.9f, 1.0f, duration, ease)
				: ViewAnimator.ScaleTo(screen, 1.0f, 0.9f, duration, ease);
			animations.Add(isEnter ? ViewAnimator.FadeIn(screen, duration, ease)
				: ViewAnimator.FadeOut(screen, duration, ease));

		case .None:
		}

		if (animation == null)
		{
			if (onDone != null)
			{
				onDone();
				delete onDone;
			}
			return;
		}

		if (onDone != null)
		{
			mPendingCompletions.Add(onDone);
			animation.OnComplete.Add(new(finished) =>
				{
					if (mPendingCompletions.Remove(onDone))
					{
						onDone();
						delete onDone;
					}
				});
		}

		animations.Add(animation);
	}
}
