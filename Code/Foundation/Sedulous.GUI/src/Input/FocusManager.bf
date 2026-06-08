namespace Sedulous.GUI;

using System;
using System.Collections;

/// Manages keyboard focus and mouse capture. Focused and captured views
/// are stored as ViewIds for deletion safety - if a view is deleted,
/// lookups return null rather than dangling.
public class FocusManager
{
	private UIContext mContext;
	private ViewId mFocusedId;
	private ViewId mCapturedId;
	private List<ViewId> mFocusStack = new .();

	public this(UIContext context)
	{
		mContext = context;
	}

	// =================================================================
	// Focus
	// =================================================================

	/// The currently focused view (null if none or deleted).
	public View FocusedView => mContext.GetViewById(mFocusedId);
	public ViewId FocusedId => mFocusedId;

	/// Set keyboard focus to a view. Fires OnFocusLost/OnFocusGained.
	public void SetFocus(View view)
	{
		if (view == null) { ClearFocus(); return; }
		if (view.Id == mFocusedId) return;

		let oldFocused = FocusedView;
		if (oldFocused != null)
			oldFocused.OnFocusLost();

		mFocusedId = view.Id;
		view.OnFocusGained();
	}

	/// Clear focus (no view is focused).
	public void ClearFocus()
	{
		let oldFocused = FocusedView;
		if (oldFocused != null)
			oldFocused.OnFocusLost();
		mFocusedId = .Invalid;
	}

	// =================================================================
	// Focus stack (for popups)
	// =================================================================

	/// Push the current focus onto the stack and clear focus.
	/// Called when a popup opens to save and suspend current focus.
	public void PushFocus()
	{
		mFocusStack.Add(mFocusedId);
		ClearFocus();
	}

	/// Pop the focus stack, restoring the most recent live focused view.
	/// Skips dead ViewIds (views deleted while the popup was open).
	/// Called when a popup closes.
	public void PopFocus()
	{
		while (mFocusStack.Count > 0)
		{
			let savedId = mFocusStack.PopBack();
			if (!savedId.IsValid)
				continue;
			let view = mContext.GetViewById(savedId);
			if (view != null)
			{
				SetFocus(view);
				return;
			}
			// Dead ID - skip and try the next one.
		}
		// Stack empty or all dead - leave focus cleared.
	}

	/// Current depth of the focus stack.
	public int FocusStackDepth => mFocusStack.Count;

	// =================================================================
	// Mouse capture
	// =================================================================

	/// The currently captured view (null if none or deleted).
	public View CapturedView => mCapturedId.IsValid ? mContext.GetViewById(mCapturedId) : null;
	public bool HasCapture => mCapturedId.IsValid && CapturedView != null;

	/// Set mouse capture. While captured, all mouse events route to this view.
	public void SetCapture(View view)
	{
		mCapturedId = (view != null) ? view.Id : .Invalid;
	}

	/// Release mouse capture.
	public void ReleaseCapture()
	{
		mCapturedId = .Invalid;
	}

	// =================================================================
	// Tab navigation
	// =================================================================

	/// Move focus to the next focusable+tab-stop view (Tab key).
	/// HTML-style: TabIndex > 0 sorted first, then TabIndex == 0 in tree order.
	/// When a modal popup is active, constrain to views within it.
	public void FocusNext()
	{
		let focusables = scope List<View>();
		CollectFocusable(GetFocusRoot(), focusables);
		if (focusables.Count == 0) return;

		SortByTabIndex(focusables);

		let currentIdx = FindCurrentIndex(focusables);
		let nextIdx = (currentIdx + 1) % focusables.Count;
		SetFocus(focusables[nextIdx]);
	}

	/// Move focus to the previous focusable+tab-stop view (Shift+Tab).
	public void FocusPrev()
	{
		let focusables = scope List<View>();
		CollectFocusable(GetFocusRoot(), focusables);
		if (focusables.Count == 0) return;

		SortByTabIndex(focusables);

		let currentIdx = FindCurrentIndex(focusables);
		let prevIdx = (currentIdx - 1 + focusables.Count) % focusables.Count;
		SetFocus(focusables[prevIdx]);
	}

	// =================================================================
	// Directional focus navigation
	// =================================================================

	/// Move focus in the given direction using the spatial picker.
	/// Checks explicit NextFocus overrides first, then uses distance-based
	/// scoring (Android FocusFinder-style).
	/// Returns true if focus moved to a new view.
	public bool MoveFocus(FocusDirection direction)
	{
		let focused = FocusedView;
		if (focused == null) return false;

		// Check explicit override first
		ViewId? explicitId = null;
		switch (direction)
		{
		case .Up:    explicitId = focused.NextFocusUp;
		case .Down:  explicitId = focused.NextFocusDown;
		case .Left:  explicitId = focused.NextFocusLeft;
		case .Right: explicitId = focused.NextFocusRight;
		}

		if (explicitId.HasValue && explicitId.Value.IsValid)
		{
			let target = mContext.GetViewById(explicitId.Value);
			if (target != null && target.IsFocusable && target.IsEffectivelyEnabled)
			{
				SetFocus(target);
				return true;
			}
		}

		// Spatial picker: find the best candidate in the given direction
		let focusables = scope List<View>();
		CollectFocusable(GetFocusRoot(), focusables);
		if (focusables.Count <= 1) return false;

		// If the focused view is a container, check if we should descend
		// into it (focus the first/last child in the direction).
		if (let group = focused as ViewGroup)
		{
			let childFocusables = scope List<View>();
			CollectFocusable(group, childFocusables);
			if (childFocusables.Count > 0)
			{
				SortByTabIndex(childFocusables);
				switch (direction)
				{
				case .Down, .Right:
					SetFocus(childFocusables[0]); // first child
					return true;
				case .Up, .Left:
					SetFocus(childFocusables[childFocusables.Count - 1]); // last child
					return true;
				}
			}
		}

		let focusedScreen = focused.LocalToScreen(.(0, 0));
		let focusedCX = focusedScreen.X + focused.Width * 0.5f;
		let focusedCY = focusedScreen.Y + focused.Height * 0.5f;

		View bestCandidate = null;
		float bestScore = float.MaxValue;

		for (let candidate in focusables)
		{
			if (candidate.Id == focused.Id) continue;

			// Skip candidates that are descendants of the focused view —
			// those were handled by the "descend into container" logic above.
			if (IsDescendantOf(candidate, focused)) continue;

			let candidateScreen = candidate.LocalToScreen(.(0, 0));
			let candidateCX = candidateScreen.X + candidate.Width * 0.5f;
			let candidateCY = candidateScreen.Y + candidate.Height * 0.5f;

			let dx = candidateCX - focusedCX;
			let dy = candidateCY - focusedCY;

			bool inDirection = false;
			float axialDist = 0;
			float perpDist = 0;

			switch (direction)
			{
			case .Up:
				inDirection = dy < 0;
				axialDist = Math.Abs(dy);
				perpDist = Math.Abs(dx);
			case .Down:
				inDirection = dy > 0;
				axialDist = Math.Abs(dy);
				perpDist = Math.Abs(dx);
			case .Left:
				inDirection = dx < 0;
				axialDist = Math.Abs(dx);
				perpDist = Math.Abs(dy);
			case .Right:
				inDirection = dx > 0;
				axialDist = Math.Abs(dx);
				perpDist = Math.Abs(dy);
			}

			if (!inDirection) continue;

			// Score: axial distance + perpendicular penalty (weighted)
			let score = axialDist + perpDist * 2.0f;
			if (score < bestScore)
			{
				bestScore = score;
				bestCandidate = candidate;
			}
		}

		if (bestCandidate != null)
		{
			SetFocus(bestCandidate);
			return true;
		}

		return false;
	}

	/// Check if a view is a descendant of an ancestor.
	private static bool IsDescendantOf(View view, View ancestor)
	{
		var v = view.Parent;
		while (v != null)
		{
			if (v === ancestor) return true;
			v = v.Parent;
		}
		return false;
	}

	// =================================================================
	// Deletion safety
	// =================================================================

	/// Notify that a view was deleted - clear any references to it.
	public void OnViewDeleted(View view)
	{
		if (mFocusedId == view.Id) mFocusedId = .Invalid;
		if (mCapturedId == view.Id) mCapturedId = .Invalid;
	}

	// =================================================================
	// Internal
	// =================================================================

	private void CollectFocusable(View view, List<View> output)
	{
		if (view.Visibility == .Gone || !view.IsEffectivelyEnabled)
			return;

		if (view.IsFocusable && view.IsTabStop)
			output.Add(view);

		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				CollectFocusable(group.GetChildAt(i), output);
		}
	}

	private void SortByTabIndex(List<View> list)
	{
		// TabIndex > 0 sorted by value first, then TabIndex == 0 sorted
		// by spatial position (top-to-bottom, left-to-right).
		list.Sort(scope (a, b) =>
		{
			let aIdx = a.TabIndex;
			let bIdx = b.TabIndex;
			if (aIdx > 0 && bIdx > 0) return aIdx <=> bIdx;
			if (aIdx > 0 && bIdx == 0) return -1; // explicit before natural
			if (aIdx == 0 && bIdx > 0) return 1;

			// Both TabIndex == 0: sort by screen position (top-to-bottom, left-to-right)
			let aScreen = a.LocalToScreen(.(0, 0));
			let bScreen = b.LocalToScreen(.(0, 0));
			let yDiff = aScreen.Y - bScreen.Y;
			if (Math.Abs(yDiff) > 1.0f)
				return (yDiff < 0) ? -1 : 1;
			let xDiff = aScreen.X - bScreen.X;
			if (Math.Abs(xDiff) > 1.0f)
				return (xDiff < 0) ? -1 : 1;
			return 0;
		});
	}

	private int FindCurrentIndex(List<View> list)
	{
		for (int i = 0; i < list.Count; i++)
		{
			if (list[i].Id == mFocusedId)
				return i;
		}
		return -1;
	}

	/// Get the root view for focus traversal. If a modal popup is active,
	/// constrain to the topmost modal; otherwise use the full root.
	private View GetFocusRoot()
	{
		let root = mContext.ActiveInputRoot;
		if (root != null)
		{
			let popupLayer = root.PopupLayer;
			if (popupLayer != null && popupLayer.HasModalPopup)
			{
				let modal = popupLayer.TopmostModalPopup;
				if (modal != null) return modal;
			}
		}
		return root;
	}

	public ~this()
	{
		delete mFocusStack;
	}
}
