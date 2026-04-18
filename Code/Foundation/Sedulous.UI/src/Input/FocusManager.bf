namespace Sedulous.UI;

using System;
using System.Collections;

/// Manages keyboard focus and mouse capture. Focused and captured views
/// are stored as ViewIds for deletion safety.
public class FocusManager
{
	private UIContext mContext;
	private ViewId mFocusedId;
	private ViewId mCapturedId;
	private List<ViewId> mFocusStack = new .() ~ delete _;

	public this(UIContext context)
	{
		mContext = context;
	}

	/// The currently focused view (null if none or deleted).
	public View FocusedView => mContext.GetElementById(mFocusedId);
	public ViewId FocusedId => mFocusedId;

	/// The currently captured view (null if none or deleted).
	public View CapturedView => mContext.GetElementById(mCapturedId);
	public bool HasCapture => mCapturedId.IsValid && CapturedView != null;

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
			let view = mContext.GetElementById(savedId);
			if (view != null)
			{
				SetFocus(view);
				return;
			}
			// Dead ID — skip and try the next one.
		}
		// Stack empty or all dead — leave focus cleared.
	}

	/// Current depth of the focus stack (for debugging/testing).
	public int FocusStackDepth => mFocusStack.Count;

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

	/// Move focus to the next focusable+tab-stop view (Tab key).
	/// HTML-style: TabIndex > 0 sorted first, then TabIndex == 0 in tree order.
	/// When a modal popup is active, constrain to views within it.
	public void FocusNext()
	{
		let focusables = scope List<View>();
		let root = GetFocusRoot();
		CollectFocusable(root, focusables);
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

	/// Notify that a view was deleted — clear any references.
	public void OnElementDeleted(View view)
	{
		if (mFocusedId == view.Id) mFocusedId = .Invalid;
		if (mCapturedId == view.Id) mCapturedId = .Invalid;
	}

	// === Internal ===

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
		// TabIndex > 0 sorted by value first, then TabIndex == 0 in tree order
		// (tree order is already the order CollectFocusable produced).
		list.Sort(scope (a, b) =>
		{
			let aIdx = a.TabIndex;
			let bIdx = b.TabIndex;
			if (aIdx > 0 && bIdx > 0) return aIdx <=> bIdx;
			if (aIdx > 0 && bIdx == 0) return -1; // explicit before natural
			if (aIdx == 0 && bIdx > 0) return 1;
			return 0; // both 0 -> preserve tree order
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
		let popupLayer = mContext.PopupLayer;
		if (popupLayer != null && popupLayer.HasModalPopup)
		{
			let modal = popupLayer.TopmostModalPopup;
			if (modal != null) return modal;
		}
		return mContext.ActiveInputRoot;
	}
}
