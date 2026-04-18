namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Drag state machine states.
public enum DragState
{
	/// No drag in progress.
	Idle,
	/// Mouse was pressed on a drag source, waiting for threshold.
	Potential,
	/// Drag is active: adorner shown, drop targets being queried.
	Active
}

/// Manages drag-and-drop operations within a UIContext.
/// Called by InputManager at the right points in the mouse event pipeline.
public class DragDropManager
{
	private UIContext mContext;

	// State
	private DragState mState = .Idle;

	// Drag session data
	private View mSourceView;
	private IDragSource mDragSource;
	private DragData mDragData ~ delete _;
	private DragAdorner mAdorner;
	private PopupLayer mAdornerPopupLayer;
	private MouseButton mDragButton;

	// Potential drag tracking
	private float mStartScreenX;
	private float mStartScreenY;

	// Drop target tracking
	private View mCurrentDropTargetView;
	private IDropTarget mCurrentDropTarget;
	private DragDropEffects mCurrentEffect = .None;

	/// Drag threshold in screen pixels.
	public float DragThreshold = 4.0f;

	/// Offset of the drag visual from the cursor.
	public float AdornerOffsetX = 4.0f;
	public float AdornerOffsetY = 4.0f;

	/// Cursor shown when over an accepting drop target.
	public CursorType AcceptCursor = .Move;

	/// Cursor shown when over a rejecting drop target.
	public CursorType RejectCursor = .NotAllowed;

	/// Last known screen position during drag.
	public float LastScreenX { get; private set; }
	public float LastScreenY { get; private set; }

	/// Last known global (desktop) mouse position during drag.
	/// Set by application layer for cross-window drag positioning.
	public float LastGlobalX { get; set; }
	public float LastGlobalY { get; set; }

	/// Current drag state.
	public DragState State => mState;

	/// Whether a drag is active (adorner visible, drop targets queried).
	public bool IsDragging => mState == .Active;

	/// Whether a potential drag is being tracked.
	public bool IsPotentialDrag => mState == .Potential;

	/// The current drag data, or null if no drag active.
	public DragData CurrentDragData => mDragData;

	/// The current drop effect.
	public DragDropEffects CurrentEffect => mCurrentEffect;

	public this(UIContext context)
	{
		mContext = context;
	}

	public ~this()
	{
		// Don't call CancelDrag/CompleteDrag during destruction — other
		// managers (FocusManager, PopupLayer) may already be deleted.
		// Just clean up owned data.
		delete mDragData;
		mDragData = null;
		mState = .Idle;
	}

	// === Public API (called by InputManager) ===

	/// Called by InputManager.ProcessMouseDown when a view or ancestor
	/// implements IDragSource. Returns true if potential drag started.
	public bool BeginPotentialDrag(View sourceView, IDragSource source,
		float screenX, float screenY, MouseButton button)
	{
		if (mState != .Idle) return false;
		if (button != .Left) return false;

		mSourceView = sourceView;
		mDragSource = source;
		mDragButton = button;
		mStartScreenX = screenX;
		mStartScreenY = screenY;
		mState = .Potential;
		return true;
	}

	/// Called by InputManager.ProcessMouseMove.
	/// Returns true if the drag system consumed the event.
	public bool UpdateDrag(float screenX, float screenY)
	{
		if (mState == .Idle) return false;

		LastScreenX = screenX;
		LastScreenY = screenY;

		if (mState == .Potential)
		{
			let dx = screenX - mStartScreenX;
			let dy = screenY - mStartScreenY;
			let dist = Math.Sqrt(dx * dx + dy * dy);

			if (dist < DragThreshold)
				return false; // Not yet — let normal mouse processing continue.

			// Threshold exceeded — activate drag.
			if (!ActivateDrag())
			{
				mState = .Idle;
				mSourceView = null;
				mDragSource = null;
				return false;
			}
		}

		// Active drag — update adorner and drop target.
		UpdateAdornerPosition(screenX, screenY);
		UpdateDropTarget(screenX, screenY);
		return true;
	}

	/// Called by InputManager.ProcessMouseUp.
	/// Returns true if the drag system consumed the event.
	public bool EndDrag(float screenX, float screenY)
	{
		if (mState == .Idle) return false;

		LastScreenX = screenX;
		LastScreenY = screenY;

		if (mState == .Potential)
		{
			// Never reached threshold — cancel silently.
			mState = .Idle;
			mSourceView = null;
			mDragSource = null;
			return false;
		}

		// Active drag — attempt drop.
		UpdateDropTarget(screenX, screenY);

		// Close adorner BEFORE OnDrop. OnDrop may destroy views
		// (and their PopupLayer) as part of re-docking.
		if (mAdorner != null)
		{
			if (mAdornerPopupLayer != null)
				mAdornerPopupLayer.ClosePopup(mAdorner);
			mAdorner = null;
			mAdornerPopupLayer = null;
		}

		// Clear source view reference before OnDrop so that if OnDrop
		// triggers tree modifications (e.g. CleanupEmptyNodes detaching
		// the source), OnElementDeleted won't prematurely fire CompleteDrag.
		let savedSourceView = mSourceView;
		mSourceView = null;

		DragDropEffects effect = .None;
		if (mCurrentDropTarget != null && mCurrentEffect != .None)
		{
			let local = mCurrentDropTargetView.ToLocal(.(screenX, screenY));
			effect = mCurrentDropTarget.OnDrop(mDragData, local.X, local.Y);
		}

		mSourceView = savedSourceView;
		CompleteDrag(effect, effect == .None);
		return true;
	}

	/// Cancel the current drag operation (e.g., Escape key).
	public void CancelDrag()
	{
		if (mState == .Idle) return;

		if (mState == .Active)
			CompleteDrag(.None, true);
		else
		{
			mState = .Idle;
			mSourceView = null;
			mDragSource = null;
		}
	}

	/// Called when a view is about to be deleted.
	public void OnElementDeleted(View view)
	{
		if (mState == .Idle) return;

		if (view === mSourceView)
		{
			if (mState == .Active)
				CompleteDrag(.None, true);
			else
			{
				mState = .Idle;
				mSourceView = null;
				mDragSource = null;
			}
			return;
		}

		if (view === mCurrentDropTargetView)
		{
			mCurrentDropTarget.OnDragLeave(mDragData);
			mCurrentDropTargetView = null;
			mCurrentDropTarget = null;
			mCurrentEffect = .None;
		}
	}

	// === Internal ===

	/// Activate the drag: create data, adorner, set capture.
	private bool ActivateDrag()
	{
		// Reset customizable properties to defaults.
		AdornerOffsetX = 4.0f;
		AdornerOffsetY = 4.0f;
		AcceptCursor = .Move;
		RejectCursor = .NotAllowed;

		// Ask source for data.
		mDragData = mDragSource.CreateDragData();
		if (mDragData == null)
			return false;

		// Ask source for visual.
		let visual = mDragSource.CreateDragVisual(mDragData);

		// Notify source (can customize offset/cursor here).
		mDragSource.OnDragStarted(mDragData);

		// Create adorner with final offset values.
		mAdorner = new DragAdorner(visual, AdornerOffsetX, AdornerOffsetY);

		// Measure adorner.
		let popupLayer = mContext.ActivePopupLayer;
		float viewportW = mContext.ActiveInputRoot.ViewportSize.X;
		float viewportH = mContext.ActiveInputRoot.ViewportSize.Y;
		mAdorner.Measure(.AtMost(viewportW), .AtMost(viewportH));

		// Show adorner via PopupLayer.
		mAdornerPopupLayer = popupLayer;
		let dpiScale = mContext.DpiScale;
		let logicalX = mStartScreenX / dpiScale;
		let logicalY = mStartScreenY / dpiScale;
		mAdornerPopupLayer.ShowPopup(mAdorner, null,
			logicalX + AdornerOffsetX, logicalY + AdornerOffsetY,
			closeOnClickOutside: false, isModal: false, ownsView: true);

		// Set mouse capture on source view.
		mContext.FocusManager.SetCapture(mSourceView);

		mState = .Active;
		return true;
	}

	/// Update the adorner's position to follow the cursor.
	private void UpdateAdornerPosition(float screenX, float screenY)
	{
		if (mAdorner == null || mAdornerPopupLayer == null) return;

		// During cross-window drag, ActivePopupLayer may differ from
		// the one that owns the adorner. Only update if on the same layer.
		if (mContext.ActivePopupLayer !== mAdornerPopupLayer) return;

		let dpiScale = mContext.DpiScale;
		let logicalX = screenX / dpiScale;
		let logicalY = screenY / dpiScale;
		mAdornerPopupLayer.UpdatePopupPosition(mAdorner,
			logicalX + mAdorner.OffsetX,
			logicalY + mAdorner.OffsetY);
	}

	/// Hit-test for drop targets, fire enter/leave/over.
	private void UpdateDropTarget(float screenX, float screenY)
	{
		let hitView = mContext.HitTest(.(screenX, screenY));

		// Walk parent chain to find IDropTarget.
		View newTargetView = null;
		IDropTarget newTarget = null;
		FindDropTarget(hitView, out newTargetView, out newTarget);

		if (newTarget !== mCurrentDropTarget)
		{
			// Leave old target.
			if (mCurrentDropTarget != null)
				mCurrentDropTarget.OnDragLeave(mDragData);

			mCurrentDropTargetView = newTargetView;
			mCurrentDropTarget = newTarget;

			// Enter new target.
			if (mCurrentDropTarget != null)
			{
				let local = newTargetView.ToLocal(.(screenX, screenY));
				mCurrentDropTarget.OnDragEnter(mDragData, local.X, local.Y);
				mCurrentEffect = mCurrentDropTarget.CanAcceptDrop(mDragData, local.X, local.Y);
			}
			else
			{
				mCurrentEffect = .None;
			}
		}
		else if (mCurrentDropTarget != null)
		{
			// Same target — fire over.
			let local = mCurrentDropTargetView.ToLocal(.(screenX, screenY));
			mCurrentDropTarget.OnDragOver(mDragData, local.X, local.Y);
			mCurrentEffect = mCurrentDropTarget.CanAcceptDrop(mDragData, local.X, local.Y);
		}
	}

	/// Walk up the parent chain from hitView to find the first IDropTarget.
	private void FindDropTarget(View hitView, out View targetView, out IDropTarget target)
	{
		targetView = null;
		target = null;

		var current = hitView;
		while (current != null)
		{
			if (let dt = current as IDropTarget)
			{
				targetView = current;
				target = dt;
				return;
			}
			current = current.Parent;
		}
	}

	/// Clean up after drag ends (success or cancel).
	private void CompleteDrag(DragDropEffects effect, bool cancelled)
	{
		// Leave current drop target.
		if (mCurrentDropTarget != null)
		{
			mCurrentDropTarget.OnDragLeave(mDragData);
			mCurrentDropTargetView = null;
			mCurrentDropTarget = null;
			mCurrentEffect = .None;
		}

		// Release capture.
		mContext.FocusManager.ReleaseCapture();

		// Remove adorner (PopupLayer owns it, will delete).
		if (mAdorner != null)
		{
			if (mAdornerPopupLayer != null)
				mAdornerPopupLayer.ClosePopup(mAdorner);
			mAdorner = null;
			mAdornerPopupLayer = null;
		}

		// Notify source.
		if (mDragSource != null)
			mDragSource.OnDragCompleted(mDragData, effect, cancelled);

		// Clean up.
		delete mDragData;
		mDragData = null;
		mSourceView = null;
		mDragSource = null;
		mState = .Idle;
	}
}
