using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Keyboard focus and mouse capture.
///
/// Both are tracked by ViewId rather than by pointer, so a view that has been deleted simply
/// stops resolving instead of leaving the manager holding a dangling pointer.
///
/// Focus is RETAINED whatever its source, so typing, list navigation and tab continuity all
/// key off the focused view. What the source decides is only whether the focus RING draws:
/// pointer and programmatic focus hold focus without one.
class FocusManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;
	private ViewId mFocusedId = .();
	private ViewId mCapturedId = .();
	private FocusSource mFocusSource = .Programmatic;
	/// Outstanding saved entries, held by the popups that saved them. A consumer reads a depth
	/// of nought to tell a real blur from focus moving into a popup.
	private int mSavedCount = 0;

	public this(UIContext context)
	{
		mContext = context;
	}

	public ViewId FocusedId => mFocusedId;
	public FocusSource Source => mFocusSource;
	public int FocusStackDepth => mSavedCount;

	/// The focused view, resolved through the context's registry. Null when nothing holds
	/// focus, or when the view that did has gone.
	public View FocusedView => mContext.GetViewById(mFocusedId);

	public ViewId CapturedId => mCapturedId;
	public View CapturedView => mCapturedId.IsValid ? mContext.GetViewById(mCapturedId) : null;
	/// An id alone is not capture: the view it names must still exist.
	public bool HasCapture => mCapturedId.IsValid && (CapturedView != null);
	public void SetCapture(View view) => mCapturedId = (view != null) ? view.Id : ViewId.Invalid;
	public void ReleaseCapture() => mCapturedId = ViewId.Invalid;

	/// Forgets a view that is going away, so focus and capture cannot outlive it.
	public void OnViewDeleted(View view)
	{
		if (mFocusedId == view.Id)
			mFocusedId = ViewId.Invalid;
		if (mCapturedId == view.Id)
			mCapturedId = ViewId.Invalid;
	}

	// ---- Setting focus ------------------------------------------------------------------------

	/// Moves focus, telling both views about it.
	///
	/// Re-focusing the SAME view with a different source is not a no op: tabbing back onto a
	/// control that was clicked changes whether the ring draws, even though focus never moved.
	public void SetFocus(View view, FocusSource source = .Programmatic)
	{
		if (view == null)
		{
			ClearFocus();
			return;
		}

		if (view.Id == mFocusedId)
		{
			if (mFocusSource != source)
			{
				mFocusSource = source;
				view.InvalidateVisual(); // the ring alone; the geometry did not change
			}
			return;
		}

		if (let previous = FocusedView)
		{
			previous.OnFocusLost();
			previous.InvalidateVisual();
		}

		mFocusedId = view.Id;
		mFocusSource = source;
		view.OnFocusGained();
		view.InvalidateVisual();
	}

	public void ClearFocus()
	{
		if (let previous = FocusedView)
		{
			previous.OnFocusLost();
			previous.InvalidateVisual();
		}

		mFocusedId = ViewId.Invalid;
		mFocusSource = .Programmatic;
	}

	/// Focuses the first focusable view in tab order inside a subtree. False when there is none.
	///
	/// PROGRAMMATIC, so a dialog opening holds focus without lighting up a ring nobody asked
	/// for.
	public bool FocusFirstIn(View subtree)
	{
		let focusables = scope List<View>();
		CollectFocusable(subtree, focusables);
		if (focusables.IsEmpty)
			return false;

		SortByTabIndex(focusables);
		SetFocus(focusables[0], .Programmatic);
		return true;
	}

	// ---- Saving and restoring -------------------------------------------------------------------

	/// Saves the current focus and its SOURCE, then clears it, which is what a focus taking
	/// popup does as it opens. The caller keeps the entry.
	public SavedFocus SaveAndClearFocus()
	{
		SavedFocus saved = .();
		saved.Id = mFocusedId;
		saved.Source = mFocusSource;
		mSavedCount++;
		ClearFocus();
		return saved;
	}

	/// Gives focus back, with the ORIGINAL source: a button that was clicked comes back from a
	/// modal holding focus but still ringless.
	///
	/// A no op unless the view still resolves AND is still focusable, effectively enabled and
	/// not Gone. It may have been disabled, hidden or destroyed while the popup was open, and
	/// restoring onto it would strand the keyboard somewhere the person cannot see.
	public void RestoreFocus(SavedFocus saved)
	{
		if (mSavedCount > 0)
			mSavedCount--;

		if (!saved.Id.IsValid)
			return;

		// Ids never recycle, so resolving one that has gone is safe: it simply answers null.
		let view = mContext.GetViewById(saved.Id);
		if (view == null)
			return;

		if (!view.IsFocusable || !view.IsEffectivelyEnabled() || (view.Visibility == .Gone))
			return;

		SetFocus(view, saved.Source);
	}

	// ---- Tab traversal ------------------------------------------------------------------------

	/// Tab. WRAPS at the end, and a starting index of -1, meaning nothing focused, lands on the
	/// first entry.
	public void FocusNext()
	{
		let focusables = scope List<View>();
		CollectFocusable(FocusRoot, focusables);
		if (focusables.IsEmpty)
			return;

		SortByTabIndex(focusables);
		let next = (FindCurrentIndex(focusables) + 1) % focusables.Count;
		SetFocus(focusables[next], .Keyboard);
	}

	/// Shift tab.
	public void FocusPrev()
	{
		let focusables = scope List<View>();
		CollectFocusable(FocusRoot, focusables);
		if (focusables.IsEmpty)
			return;

		SortByTabIndex(focusables);
		let count = focusables.Count;
		let previous = (FindCurrentIndex(focusables) - 1 + count) % count;
		SetFocus(focusables[previous], .Keyboard);
	}

	// ---- Directional traversal ------------------------------------------------------------------

	/// Arrow key or gamepad focus movement. False when nothing lies that way.
	///
	/// Three rules in order: an EXPLICIT override on the focused view wins; a focused container
	/// is DESCENDED into rather than skipped past; and otherwise the nearest candidate in the
	/// direction wins, scored so a small sideways drift beats a large one.
	public bool MoveFocus(FocusDirection direction)
	{
		let focused = FocusedView;
		if (focused == null)
			return false;

		if (TryExplicitOverride(focused, direction))
			return true;

		let focusables = scope List<View>();
		CollectFocusable(FocusRoot, focusables);
		if (focusables.Count <= 1)
			return false;

		if (TryDescendInto(focused, direction))
			return true;

		return TryNearestInDirection(focused, direction, focusables);
	}

	private bool TryExplicitOverride(View focused, FocusDirection direction)
	{
		ViewId? explicitId = null;
		switch (direction)
		{
		case .Up: explicitId = focused.NextFocusUp;
		case .Down: explicitId = focused.NextFocusDown;
		case .Left: explicitId = focused.NextFocusLeft;
		case .Right: explicitId = focused.NextFocusRight;
		}

		if ((explicitId == null) || !explicitId.Value.IsValid)
			return false;

		let target = mContext.GetViewById(explicitId.Value);
		if ((target == null) || !target.IsFocusable || !target.IsEffectivelyEnabled())
			return false;

		SetFocus(target, .Keyboard);
		return true;
	}

	/// Moving into a focused CONTAINER enters it rather than jumping over it: down and right
	/// take the first child, up and left the last.
	private bool TryDescendInto(View focused, FocusDirection direction)
	{
		let group = focused as ViewGroup;
		if (group == null)
			return false;

		let children = scope List<View>();
		CollectFocusable(group, children);
		if (children.IsEmpty)
			return false;

		SortByTabIndex(children);
		switch (direction)
		{
		case .Down, .Right:
			SetFocus(children[0], .Keyboard);
			return true;
		case .Up, .Left:
			SetFocus(children[children.Count - 1], .Keyboard);
			return true;
		}
	}

	/// The nearest candidate in the direction, scored as the axial distance plus TWICE the
	/// perpendicular one. Weighting the sideways drift is what keeps arrow movement in a
	/// column rather than wandering into the next one.
	private bool TryNearestInDirection(View focused, FocusDirection direction,
		List<View> focusables)
	{
		let focusedOrigin = focused.LocalToScreen(.(0, 0));
		let focusedX = focusedOrigin.X + focused.Width * 0.5f;
		let focusedY = focusedOrigin.Y + focused.Height * 0.5f;

		View best = null;
		var bestScore = FloatMax;

		for (let candidate in focusables)
		{
			if (candidate.Id == focused.Id)
				continue;
			// A descendant is INSIDE the focused view, so moving to it is not movement.
			if (IsDescendantOf(candidate, focused))
				continue;

			let origin = candidate.LocalToScreen(.(0, 0));
			let dx = (origin.X + candidate.Width * 0.5f) - focusedX;
			let dy = (origin.Y + candidate.Height * 0.5f) - focusedY;

			var inDirection = false;
			var axial = 0.0f;
			var perpendicular = 0.0f;
			switch (direction)
			{
			case .Up:
				inDirection = dy < 0;
				axial = Abs(dy);
				perpendicular = Abs(dx);
			case .Down:
				inDirection = dy > 0;
				axial = Abs(dy);
				perpendicular = Abs(dx);
			case .Left:
				inDirection = dx < 0;
				axial = Abs(dx);
				perpendicular = Abs(dy);
			case .Right:
				inDirection = dx > 0;
				axial = Abs(dx);
				perpendicular = Abs(dy);
			}

			if (!inDirection)
				continue;

			let score = axial + perpendicular * 2.0f;
			if (score < bestScore)
			{
				bestScore = score;
				best = candidate;
			}
		}

		if (best == null)
			return false;

		SetFocus(best, .Keyboard);
		return true;
	}

	// ---- Helpers --------------------------------------------------------------------------------

	private static bool IsDescendantOf(View view, View ancestor)
	{
		var current = view.Parent;
		while (current != null)
		{
			if (current == ancestor)
				return true;
			current = current.Parent;
		}
		return false;
	}

	/// Every focusable, tab stopping view in a subtree, in TREE order.
	///
	/// A Gone or effectively disabled view takes its whole subtree out: nothing inside a
	/// disabled panel should be reachable by keyboard.
	private void CollectFocusable(View view, List<View> output)
	{
		if ((view == null) || (view.Visibility == .Gone) || !view.IsEffectivelyEnabled())
			return;

		if (view.IsFocusable && view.IsTabStop)
			output.Add(view);

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				CollectFocusable(group.GetChildAt(i), output);
		}
	}

	/// Tab order: an explicit positive TabIndex first, in order, then everything left at nought
	/// in reading order, top to bottom and left to right.
	///
	/// The one unit tolerance is what stops a row of controls whose tops differ by a rounding
	/// error from being ordered vertically instead of across.
	private void SortByTabIndex(List<View> views)
	{
		views.Sort(scope (a, b) =>
			{
				let aIndex = a.TabIndex;
				let bIndex = b.TabIndex;
				if ((aIndex > 0) && (bIndex > 0))
					return aIndex <=> bIndex;
				if ((aIndex > 0) && (bIndex == 0))
					return -1;
				if ((aIndex == 0) && (bIndex > 0))
					return 1;

				let aOrigin = a.LocalToScreen(.(0, 0));
				let bOrigin = b.LocalToScreen(.(0, 0));
				let yDiff = aOrigin.Y - bOrigin.Y;
				if (Abs(yDiff) > 1.0f)
					return (yDiff < 0) ? -1 : 1;

				let xDiff = aOrigin.X - bOrigin.X;
				if (Abs(xDiff) > 1.0f)
					return (xDiff < 0) ? -1 : 1;

				return 0;
			});
	}

	/// Where the focused view sits in a list, or -1 when it is not in it at all, which is what
	/// makes the first Tab land on the first entry.
	private int FindCurrentIndex(List<View> views)
	{
		for (int i < views.Count)
		{
			if (views[i].Id == mFocusedId)
				return i;
		}
		return -1;
	}

	/// What keyboard traversal is confined to.
	///
	/// The topmost focus taking popup when one is open, and the window root otherwise. Scoping
	/// to the popup does two things at once: a modal TRAPS Tab and arrows rather than reaching
	/// background controls through its own backdrop, and popup content becomes reachable at
	/// all, since popups are not ViewGroup children and a walk from the root never finds them.
	private View FocusRoot
	{
		get
		{
			let root = mContext.ActiveInputRoot;
			if (root == null)
				return null;

			// PEEKED, never created: looking for a focus scope must not bring a layer into
			// being on a window that has never shown a popup.
			if (let layer = root.PeekPopupLayer)
			{
				if (let scopePopup = layer.TopmostFocusScopePopup)
					return scopePopup;
			}

			return root;
		}
	}
}
