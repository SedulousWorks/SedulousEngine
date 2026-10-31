using Sedulous.Core;

namespace Sedulous.UI;

/// Runs a drag from the mouse going down on a source to the drop landing.
///
/// A three state machine, and the middle state is the point of it: Potential means the mouse is
/// down on something draggable but the gesture is still ambiguous. Until it passes the
/// threshold the click keeps behaving like a click, so a drag source is still clickable.
class DragDropManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;

	private DragState mState = .Idle;

	// The session, all BORROWED except the data.
	private View mSourceView = null;
	private IDragSource mDragSource = null;
	/// OWNED.
	private DragData mDragData ~ _?.ReleaseRef();
	/// BORROWED: the popup layer owns the adorner while it is shown.
	private DragAdorner mAdorner = null;
	private PopupLayer mAdornerPopupLayer = null;
	private MouseButton mDragButton = .Left;

	private float mStartScreenX = 0.0f;
	private float mStartScreenY = 0.0f;

	private View mCurrentDropTargetView = null;
	private IDropTarget mCurrentDropTarget = null;
	private DragDropEffects mCurrentEffect = .None;

	private float mLastScreenX = 0.0f;
	private float mLastScreenY = 0.0f;

	public this(UIContext context)
	{
		mContext = context;
	}

	public ~this()
	{
		// NOT CancelDrag or CompleteDrag here: other managers may already be gone, and a
		// notification into a half destroyed context is worse than a drag that simply stops.
		mState = .Idle;
	}

	// ---- Tunables, which a source may change in OnDragStarted -----------------------------------

	/// How far the mouse must travel before a press becomes a drag, in screen pixels.
	public float DragThreshold = 4.0f;
	public float AdornerOffsetX = 4.0f;
	public float AdornerOffsetY = 4.0f;
	public CursorType AcceptCursor = .Move;
	public CursorType RejectCursor = .NotAllowed;

	// ---- Queries ------------------------------------------------------------------------------

	public float LastScreenX => mLastScreenX;
	public float LastScreenY => mLastScreenY;
	public DragState State => mState;
	public bool IsDragging => mState == .Active;
	public bool IsPotentialDrag => mState == .Potential;
	public DragData CurrentDragData => mDragData;
	public DragDropEffects CurrentEffect => mCurrentEffect;

	// ---- The gesture --------------------------------------------------------------------------

	/// The mouse went down on a drag source. Answers whether the press was taken as a possible
	/// drag; the caller lets normal click handling continue either way until the threshold.
	public bool BeginPotentialDrag(View sourceView, IDragSource source, float screenX,
		float screenY, MouseButton button)
	{
		if (mState != .Idle)
			return false;
		// Left button only: a right drag is a different gesture entirely.
		if (button != .Left)
			return false;

		mSourceView = sourceView;
		mDragSource = source;
		mDragButton = button;
		mStartScreenX = screenX;
		mStartScreenY = screenY;
		mState = .Potential;
		return true;
	}

	/// The mouse moved. Answers whether the drag consumed it.
	public bool UpdateDrag(float screenX, float screenY)
	{
		// The adorner follows the cursor, so a moving drag always needs a redraw.
		mContext.MarkNeedsRedraw();

		if (mState == .Idle)
			return false;

		mLastScreenX = screenX;
		mLastScreenY = screenY;

		if (mState == .Potential)
		{
			let dx = screenX - mStartScreenX;
			let dy = screenY - mStartScreenY;
			if (Sqrt(dx * dx + dy * dy) < DragThreshold)
				return false; // still ambiguous: let ordinary mouse handling continue

			if (!ActivateDrag())
			{
				ResetSession();
				return false;
			}
		}

		UpdateAdornerPosition(screenX, screenY);
		UpdateDropTarget(screenX, screenY);
		return true;
	}

	/// The mouse came up. Answers whether the drag consumed it.
	public bool EndDrag(float screenX, float screenY)
	{
		if (mState == .Idle)
			return false;

		mLastScreenX = screenX;
		mLastScreenY = screenY;

		// Never reached the threshold: it was a click after all, so end quietly and let the
		// click stand.
		if (mState == .Potential)
		{
			ResetSession();
			return false;
		}

		UpdateDropTarget(screenX, screenY);

		// The adorner closes BEFORE OnDrop, because OnDrop may destroy views, and their popup
		// layer with them, as part of re-docking.
		CloseAdorner();

		// The source view is cleared BEFORE OnDrop too: a tree change inside the handler
		// reaches OnViewDeleted, which would otherwise fire CompleteDrag underneath us.
		let savedSourceView = mSourceView;
		mSourceView = null;

		var effect = DragDropEffects.None;
		if ((mCurrentDropTarget != null) && (mCurrentEffect != .None))
		{
			let local = mCurrentDropTargetView.ScreenToLocal(.(screenX, screenY));
			effect = mCurrentDropTarget.OnDrop(mDragData, local.X, local.Y);
		}

		mSourceView = savedSourceView;
		CompleteDrag(effect, effect == .None);
		return true;
	}

	/// Abandons the drag, which is what Escape does.
	public void CancelDrag()
	{
		if (mState == .Idle)
			return;

		if (mState == .Active)
			CompleteDrag(.None, true);
		else
			ResetSession();
	}

	/// A view going away mid drag. The SOURCE leaving cancels the whole thing; a drop target
	/// leaving is told it was left, so its highlight comes off.
	public void OnViewDeleted(View view)
	{
		if (mState == .Idle)
			return;

		if (view == mSourceView)
		{
			if (mState == .Active)
				CompleteDrag(.None, true);
			else
				ResetSession();
			return;
		}

		if (view == mCurrentDropTargetView)
		{
			mCurrentDropTarget.OnDragLeave(mDragData);
			mCurrentDropTargetView = null;
			mCurrentDropTarget = null;
			mCurrentEffect = .None;
		}
	}

	// ---- Internals ----------------------------------------------------------------------------

	/// Past the threshold: ask the source for its data and visual, put up the adorner, and take
	/// the mouse. False when the source declines to produce data.
	private bool ActivateDrag()
	{
		// The tunables reset first, so a source that customised them last time does not leak
		// that into a drag from somewhere else.
		AdornerOffsetX = 4.0f;
		AdornerOffsetY = 4.0f;
		AcceptCursor = .Move;
		RejectCursor = .NotAllowed;

		mDragData = mDragSource.CreateDragData();
		if (mDragData == null)
			return false;

		let visual = mDragSource.CreateDragVisual(mDragData);

		// Told BEFORE the adorner is built, so the source can still change the offsets and
		// cursors that go into it.
		mDragSource.OnDragStarted(mDragData);

		let root = mContext.ActiveInputRoot;
		if (root == null)
		{
			visual?.ReleaseRef();
			return false;
		}

		let adorner = new DragAdorner(visual, AdornerOffsetX, AdornerOffsetY);
		mAdorner = adorner;
		mAdornerPopupLayer = root.GetPopupLayer();
		// Not dismissable, not modal, and takes NO focus: a drag must not disturb what the
		// keyboard was on.
		mAdornerPopupLayer.ShowPopup(adorner, null, mStartScreenX + AdornerOffsetX,
			mStartScreenY + AdornerOffsetY, false, false, true, false);

		// The source keeps the mouse for the whole gesture, so leaving its bounds does not end
		// the drag.
		mContext.GetFocusManager().SetCapture(mSourceView);

		mState = .Active;
		return true;
	}

	private void UpdateAdornerPosition(float screenX, float screenY)
	{
		if ((mAdorner == null) || (mAdornerPopupLayer == null))
			return;

		mAdornerPopupLayer.UpdatePopupPosition(mAdorner, screenX + mAdorner.OffsetX,
			screenY + mAdorner.OffsetY);
	}

	/// Finds what is under the cursor and keeps the enter, over and leave notifications
	/// straight.
	private void UpdateDropTarget(float screenX, float screenY)
	{
		let root = mContext.ActiveInputRoot;
		let hitView = (root != null) ? root.HitTest(.(screenX, screenY)) : null;
		FindDropTarget(hitView, var newTargetView, var newTarget);

		if (newTarget != mCurrentDropTarget)
		{
			if (mCurrentDropTarget != null)
				mCurrentDropTarget.OnDragLeave(mDragData);

			mCurrentDropTargetView = newTargetView;
			mCurrentDropTarget = newTarget;

			if (mCurrentDropTarget != null)
			{
				let local = newTargetView.ScreenToLocal(.(screenX, screenY));
				mCurrentDropTarget.OnDragEnter(mDragData, local.X, local.Y);
				mCurrentEffect = mCurrentDropTarget.CanAcceptDrop(mDragData, local.X, local.Y);
			}
			else
			{
				mCurrentEffect = .None;
			}

			return;
		}

		if (mCurrentDropTarget == null)
			return;

		// The same target: it hears about the move, and is asked again, since what it will
		// accept may depend on WHERE over it the cursor is.
		let local = mCurrentDropTargetView.ScreenToLocal(.(screenX, screenY));
		mCurrentDropTarget.OnDragOver(mDragData, local.X, local.Y);
		mCurrentEffect = mCurrentDropTarget.CanAcceptDrop(mDragData, local.X, local.Y);
	}

	/// The nearest drop target at or above a view, so dropping onto a label inside a panel
	/// finds the panel.
	private static void FindDropTarget(View hitView, out View targetView, out IDropTarget target)
	{
		targetView = null;
		target = null;

		var current = hitView;
		while (current != null)
		{
			if (let dropTarget = current.AsDropTarget())
			{
				targetView = current;
				target = dropTarget;
				return;
			}
			current = current.Parent;
		}
	}

	private void CloseAdorner()
	{
		if (mAdorner == null)
			return;

		if (mAdornerPopupLayer != null)
			mAdornerPopupLayer.ClosePopup(mAdorner);

		mAdorner = null;
		mAdornerPopupLayer = null;
	}

	private void CompleteDrag(DragDropEffects effect, bool cancelled)
	{
		if (mCurrentDropTarget != null)
		{
			mCurrentDropTarget.OnDragLeave(mDragData);
			mCurrentDropTargetView = null;
			mCurrentDropTarget = null;
			mCurrentEffect = .None;
		}

		mContext.GetFocusManager().ReleaseCapture();
		CloseAdorner();

		if (mDragSource != null)
			mDragSource.OnDragCompleted(mDragData, effect, cancelled);

		if (mDragData != null)
		{
			mDragData.ReleaseRef();
			mDragData = null;
		}
		mSourceView = null;
		mDragSource = null;
		mState = .Idle;
	}

	/// Back to idle without notifying anyone: for a gesture that never became a drag.
	private void ResetSession()
	{
		mState = .Idle;
		mSourceView = null;
		mDragSource = null;
	}
}
