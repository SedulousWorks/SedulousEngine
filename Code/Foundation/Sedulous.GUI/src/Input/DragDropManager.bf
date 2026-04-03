using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Manages drag and drop operations for a GUIContext.
public class DragDropManager
{
	private GUIContext mContext;

	// Current drag state
	private bool mIsDragging = false;
	private bool mDragPending = false;
	private DragData mDragData ~ delete _;
	private ElementHandle<UIElement> mDragSource;
	private ElementHandle<UIElement> mCurrentDropTarget;
	private DragDropEffects mAllowedEffects = .None;
	private DragDropEffects mCurrentEffect = .None;
	private Vector2 mDragStartPosition;
	private Vector2 mCurrentPosition;

	// Visual feedback
	private DragAdorner mAdorner = new .() ~ delete _;

	// Configuration
	private float mDragThreshold = 4.0f;

	// Events
	private EventAccessor<delegate void(DragEventArgs)> mDragStarted = new .() ~ delete _;
	private EventAccessor<delegate void(DragEventArgs)> mDragCompleted = new .() ~ delete _;

	/// Creates a DragDropManager for the given context.
	public this(GUIContext context)
	{
		mContext = context;
		mDragSource = .Invalid;
		mCurrentDropTarget = .Invalid;
	}

	/// Whether a drag operation is currently in progress.
	public bool IsDragging => mIsDragging;

	/// Whether a drag is pending (mouse down but threshold not exceeded).
	public bool IsDragPending => mDragPending;

	/// The current drag data (null if not dragging).
	public DragData DragData => mDragData;

	/// The source element of the current drag.
	public UIElement DragSource => mDragSource.TryResolve();

	/// The current drop target element.
	public UIElement CurrentDropTarget => mCurrentDropTarget.TryResolve();

	/// The current drag effect.
	public DragDropEffects CurrentEffect => mCurrentEffect;

	/// The drag adorner for visual feedback.
	public DragAdorner Adorner => mAdorner;

	/// Drag threshold in pixels before drag starts (default 4).
	public float DragThreshold
	{
		get => mDragThreshold;
		set => mDragThreshold = Math.Max(1, value);
	}

	/// Event fired when drag actually starts (after threshold).
	public EventAccessor<delegate void(DragEventArgs)> DragStarted => mDragStarted;

	/// Event fired when drag completes (drop or cancel).
	public EventAccessor<delegate void(DragEventArgs)> DragCompleted => mDragCompleted;

	/// Initiates a potential drag operation. Call from OnMouseDown.
	/// The actual drag starts when mouse moves beyond DragThreshold.
	public void BeginPotentialDrag(UIElement source, DragData data, DragDropEffects allowedEffects, Vector2 startPos)
	{
		if (source == null || data == null)
			return;

		// Clean up any existing drag
		if (mIsDragging || mDragPending)
			CancelDrag();

		mDragPending = true;
		mDragSource = source;
		delete mDragData;
		mDragData = data;
		mAllowedEffects = allowedEffects;
		mDragStartPosition = startPos;
		mCurrentPosition = startPos;

		// Capture mouse to source
		mContext.FocusManager?.SetCapture(source);
	}

	/// Called during mouse move to update drag state.
	public void UpdateDrag(Vector2 currentPos)
	{
		mCurrentPosition = currentPos;

		// Check if we should start actual drag
		if (mDragPending && !mIsDragging)
		{
			let delta = currentPos - mDragStartPosition;
			if (Math.Abs(delta.X) > mDragThreshold || Math.Abs(delta.Y) > mDragThreshold)
			{
				StartDrag();
			}
			return;
		}

		if (!mIsDragging)
			return;

		// Update adorner position
		mAdorner.Position = currentPos;

		// Hit test for drop target
		let hitElement = mContext.HitTestLogical(currentPos.X, currentPos.Y);
		let dropTarget = FindDropTarget(hitElement);

		UpdateDropTarget(dropTarget, currentPos);
	}

	/// Completes the drag operation (on mouse up).
	public void EndDrag(Vector2 dropPos)
	{
		if (mDragPending && !mIsDragging)
		{
			// Drag never started (didn't exceed threshold)
			CancelDrag();
			return;
		}

		if (!mIsDragging)
			return;

		// Attempt drop on current target
		let dropTarget = mCurrentDropTarget.TryResolve();
		bool dropped = false;

		if (dropTarget != null && mCurrentEffect != .None)
		{
			if (let target = dropTarget as IDropTarget)
			{
				let args = scope DragEventArgs(mDragData, dropPos, mCurrentEffect);
				args.Source = mDragSource.TryResolve();
				target.OnDrop(args);
				dropped = args.Handled;
			}
		}

		// Notify source
		let source = mDragSource.TryResolve();
		if (let dragSource = source as IDragSource)
		{
			let args = scope DragEventArgs(mDragData, dropPos, dropped ? mCurrentEffect : .None);
			args.Source = source;
			args.Handled = dropped;
			dragSource.OnDragCompleted(args);
		}

		// Fire DragCompleted event
		let completedArgs = scope DragEventArgs(mDragData, dropPos, dropped ? mCurrentEffect : .None);
		completedArgs.Source = source;
		completedArgs.Handled = dropped;
		mDragCompleted.[Friend]Invoke(completedArgs);

		// Clean up
		CleanupDrag();
	}

	/// Cancels the current drag operation.
	public void CancelDrag()
	{
		if (!mIsDragging && !mDragPending)
			return;

		// Send DragLeave to current target
		let currentTarget = mCurrentDropTarget.TryResolve();
		if (currentTarget != null)
		{
			if (let target = currentTarget as IDropTarget)
			{
				let args = scope DragEventArgs(mDragData, mCurrentPosition, .None);
				target.OnDragLeave(args);
			}
		}

		// Notify source of cancellation
		let source = mDragSource.TryResolve();
		if (mIsDragging)
		{
			if (let dragSource = source as IDragSource)
			{
				let args = scope DragEventArgs(mDragData, mCurrentPosition, .None);
				args.Source = source;
				dragSource.OnDragCompleted(args);
			}

			// Fire DragCompleted with None effect (cancelled)
			let args = scope DragEventArgs(mDragData, mCurrentPosition, .None);
			args.Source = source;
			mDragCompleted.[Friend]Invoke(args);
		}

		CleanupDrag();
	}

	/// Renders the drag adorner if dragging.
	public void Render(DrawContext ctx)
	{
		if (mIsDragging)
			mAdorner.Render(ctx);
	}

	/// Called when an element is deleted.
	public void OnElementDeleted(UIElementId elementId)
	{
		if (mDragSource.Id == elementId || mCurrentDropTarget.Id == elementId)
		{
			CancelDrag();
		}
	}

	private void StartDrag()
	{
		mIsDragging = true;
		mDragPending = false;

		// Set up adorner
		let source = mDragSource.TryResolve();
		if (let dragSource = source as IDragSource)
		{
			dragSource.CreateDragVisual(mAdorner);
		}
		mAdorner.Position = mCurrentPosition;
		mAdorner.Effect = .None;
		mAdorner.IsVisible = true;

		// Fire DragStarted event
		let args = scope DragEventArgs(mDragData, mDragStartPosition, mAllowedEffects);
		args.Source = source;
		mDragStarted.[Friend]Invoke(args);

		// Notify source
		if (let dragSource = source as IDragSource)
		{
			dragSource.OnDragStarted(args);
		}
	}

	private UIElement FindDropTarget(UIElement hitElement)
	{
		// Walk up the tree to find an IDropTarget
		// Note: We don't skip the drag source - CanAcceptDrop handles rejection.
		// This allows tab reordering where the source and target are the same DockTabGroup.
		var current = hitElement;
		while (current != null)
		{
			if (let target = current as IDropTarget)
			{
				// Check if this target can accept the drag data
				if (target.CanAcceptDrop(mDragData))
					return current;
			}
			current = current.Parent;
		}
		return null;
	}

	private void UpdateDropTarget(UIElement newTarget, Vector2 pos)
	{
		let currentTarget = mCurrentDropTarget.TryResolve();

		if (newTarget != currentTarget)
		{
			// Leave old target
			if (currentTarget != null)
			{
				if (let target = currentTarget as IDropTarget)
				{
					let args = scope DragEventArgs(mDragData, pos, mCurrentEffect);
					target.OnDragLeave(args);
				}
			}

			mCurrentDropTarget = newTarget;
			mCurrentEffect = .None;

			// Enter new target
			if (newTarget != null)
			{
				if (let target = newTarget as IDropTarget)
				{
					let args = scope DragEventArgs(mDragData, pos, mAllowedEffects);
					target.OnDragEnter(args);
					mCurrentEffect = args.Effect;
				}
			}
		}
		else if (newTarget != null)
		{
			// Over same target - send DragOver
			if (let target = newTarget as IDropTarget)
			{
				let args = scope DragEventArgs(mDragData, pos, mAllowedEffects);
				args.Effect = mCurrentEffect;
				target.OnDragOver(args);
				mCurrentEffect = args.Effect;
			}
		}

		// Update adorner based on current effect
		mAdorner.Effect = mCurrentEffect;
	}

	private void CleanupDrag()
	{
		mIsDragging = false;
		mDragPending = false;
		delete mDragData;
		mDragData = null;
		mDragSource = .Invalid;
		mCurrentDropTarget = .Invalid;
		mAllowedEffects = .None;
		mCurrentEffect = .None;

		// Release capture
		mContext.FocusManager?.ReleaseCapture();

		// Reset adorner
		mAdorner.Reset();
	}
}
