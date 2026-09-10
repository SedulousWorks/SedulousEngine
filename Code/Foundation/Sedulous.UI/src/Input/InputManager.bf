using System;

namespace Sedulous.UI;

/// Routes input to views, tracking hover, press and capture by ViewId.
///
/// PARTIAL PORT: the state and its accessors are here. The three phase capture, target and
/// bubble dispatch, the pooled event args and every Process method stay in the ledger's
/// InputManager.cppm and InputImpl.cpp.
class InputManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;

	/// The longest gap between clicks, in seconds, and the furthest apart they may land, in
	/// pixels, still to count as a double click.
	public float DoubleClickTime = 0.5f;
	public float DoubleClickDistance = 4.0f;

	private ViewId mHoveredId = .();
	private ViewId mPressedId = .();
	private float mMouseX = 0.0f;
	private float mMouseY = 0.0f;
	private CursorType mCurrentCursor = .Default;
	/// The modifiers from the most recent key event, stamped into mouse events so that
	/// Ctrl and Shift clicking behave.
	private KeyModifiers mCurrentModifiers = .None;

	public this(UIContext context)
	{
		mContext = context;
	}

	public ViewId HoveredId => mHoveredId;
	public ViewId PressedId => mPressedId;
	public float MouseX => mMouseX;
	public float MouseY => mMouseY;
	public CursorType CurrentCursor => mCurrentCursor;
	public KeyModifiers CurrentModifiers => mCurrentModifiers;

	/// Forgets a view that is going away, so a deleted view cannot stay hovered or pressed.
	public void OnViewDeleted(View view)
	{
		if (mHoveredId == view.Id)
			mHoveredId = ViewId.Invalid;
		if (mPressedId == view.Id)
			mPressedId = ViewId.Invalid;
	}
}
