using System;

namespace Sedulous.UI;

/// Keyboard focus and mouse capture.
///
/// Both are tracked by ViewId rather than by pointer, so a view that has been deleted simply
/// stops resolving instead of leaving the manager holding a dangling pointer.
///
/// PARTIAL PORT: the state and its accessors are here. Focus movement, tab and directional
/// navigation, save and restore, and the deletion sweep stay in the ledger's FocusManager.cppm
/// and InputImpl.cpp.
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

	public ViewId CapturedId => mCapturedId;
	public void ReleaseCapture() => mCapturedId = ViewId.Invalid;
}
