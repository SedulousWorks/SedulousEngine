using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A floating window containing a dockable panel.
/// Can be dragged to reposition and docked back into the layout.
public class FloatingWindow : Control
{
	private DockManager mManager;
	private DockablePanel mPanel /*~ delete _*/;
	private Vector2 mPosition;
	private Vector2 mSize = .(300, 200);

	// Dragging state
	private bool mIsDragging = false;
	private Vector2 mDragOffset;

	// Image support
	private ImageBrush? mFrameImage;

	// Resize state
	private bool mIsResizing = false;
	private ResizeEdge mResizeEdge = .None;
	private Vector2 mResizeStartPos;
	private RectangleF mResizeStartBounds;
	private const float ResizeBorderSize = 6;
	private const float MinWindowSize = 100;

	// Re-docking state
	private DockPosition? mPendingDockPosition = null;
	private DockTabGroup mPendingTargetGroup = null;  // Target group for per-panel docking

	private enum ResizeEdge
	{
		None,
		Left,
		Right,
		Top,
		Bottom,
		TopLeft,
		TopRight,
		BottomLeft,
		BottomRight
	}

	/// Creates a floating window for a panel.
	public this(DockManager manager, DockablePanel panel)
	{
		mManager = manager;
		mPanel = panel;
		IsFocusable = false;
		IsTabStop = false;

		if (mPanel != null)
			mPanel.ParentGroup = null;
	}

	/// The panel in this floating window.
	public DockablePanel Panel
	{
		get => mPanel;
		set
		{
			if (mPanel != null && Context != null)
				mPanel.OnDetachedFromContext();
			mPanel = value;
			if (mPanel != null && Context != null)
				mPanel.OnAttachedToContext(Context);
		}
	}

	/// The position of the floating window.
	public Vector2 Position
	{
		get => mPosition;
		set
		{
			mPosition = value;
			InvalidateLayout();
		}
	}

	/// The size of the floating window.
	public Vector2 Size
	{
		get => mSize;
		set
		{
			mSize = .(Math.Max(MinWindowSize, value.X), Math.Max(MinWindowSize, value.Y));
			InvalidateLayout();
		}
	}

	/// Image for the window frame (replaces background + border, shadow preserved).
	public ImageBrush? FrameImage
	{
		get => mFrameImage;
		set => mFrameImage = value;
	}

	/// The bounds of this floating window.
	public RectangleF WindowBounds => .(mPosition.X, mPosition.Y, mSize.X, mSize.Y);

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		if (mPanel != null)
			mPanel.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		if (mPanel != null)
			mPanel.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mPanel != null)
			mPanel.Measure(constraints);
		return .(mSize.X, mSize.Y);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (mPanel != null)
		{
			mPanel.Arrange(WindowBounds);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = WindowBounds;

		// Window shadow (always drawn)
		let shadowOffset = 4.0f;
		ctx.FillRect(.(bounds.X + shadowOffset, bounds.Y + shadowOffset, bounds.Width, bounds.Height),
			Color(0, 0, 0, 60));

		// Window frame
		if (mFrameImage.HasValue && mFrameImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mFrameImage.Value, bounds);
		}
		else
		{
			// Window background
			ctx.FillRect(bounds, Color(45, 45, 45, 255));

			// Window border
			ctx.DrawRect(bounds, Color(80, 80, 80, 255), 1);
		}

		// Render panel content
		if (mPanel != null)
		{
			mPanel.Render(ctx);
		}

		// Resize handles (subtle indicators at corners)
		if (mIsResizing || IsMouseOverResizeEdge(mLastMousePos))
		{
			let handleSize = 8.0f;
			let handleColor = Color(100, 150, 200, 150);

			// Bottom-right corner handle
			ctx.FillRect(.(bounds.Right - handleSize, bounds.Bottom - handleSize, handleSize, handleSize), handleColor);
		}
	}

	// === Input ===

	private Vector2 mLastMousePos;

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);
		mLastMousePos = .(e.ScreenX, e.ScreenY);

		if (mIsDragging)
		{
			mPosition = .(e.ScreenX - mDragOffset.X, e.ScreenY - mDragOffset.Y);
			InvalidateLayout();

			// Update dock zone indicators while dragging
			if (mManager != null)
			{
				let zoneIndicator = mManager.[Friend]mZoneIndicator;
				let dropIndicator = mManager.[Friend]mDropTargetIndicator;
				let pos = Vector2(e.ScreenX, e.ScreenY);

				// First, check for per-group drop targets (tab groups)
				let groupTarget = mManager.UpdateFloatingDragTarget(pos);
				if (groupTarget != null)
				{
					// We have a per-group target
					let group = groupTarget.Value.group;
					let zone = groupTarget.Value.zone;

					mPendingTargetGroup = group;
					mPendingDockPosition = zone;

					// For edge zones, the group renders its own highlight - hide the drop indicator
					// For center zone (tabbing), show the drop indicator since group doesn't render anything
					if (zone == .Center)
					{
						let dropBounds = CalculateGroupDropBounds(group, zone);
						dropIndicator.Show(dropBounds, zone);
					}
					else
					{
						dropIndicator.Hide();
					}

					// Clear global zone hover
					zoneIndicator.UpdateHover(.(-1000, -1000));
				}
				else
				{
					// No per-group target, check global zone indicator
					mPendingTargetGroup = null;

					let hoveredZone = zoneIndicator.UpdateHover(pos);
					if (hoveredZone != null)
					{
						let targetBounds = mManager.[Friend]CalculateDropBounds(hoveredZone.Value);
						dropIndicator.Show(targetBounds, hoveredZone.Value);
						mPendingDockPosition = hoveredZone;
					}
					else
					{
						dropIndicator.Hide();
						mPendingDockPosition = null;
					}
				}
			}

			e.Handled = true;
		}
		else if (mIsResizing)
		{
			HandleResize(.(e.ScreenX, e.ScreenY));
			e.Handled = true;
		}
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button != .Left)
			return;

		let point = Vector2(e.ScreenX, e.ScreenY);
		let bounds = WindowBounds;

		// Check resize edges first
		let edge = GetResizeEdge(point);
		if (edge != .None)
		{
			mIsResizing = true;
			mResizeEdge = edge;
			mResizeStartPos = point;
			mResizeStartBounds = bounds;
			if (Context != null)
				Context.FocusManager?.SetCapture(this);
			e.Handled = true;
			return;
		}

		// Check close button - handle directly without going through events
		if (mPanel != null && mPanel.IsPointOnCloseButton(point))
		{
			// Close this floating window
			if (mManager != null)
				mManager.RemoveFloatingWindow(this);
			e.Handled = true;
			return;
		}

		// Check title bar for dragging
		if (mPanel != null && mPanel.TitleBarBounds.Contains(point.X, point.Y))
		{
			mIsDragging = true;
			mDragOffset = .(point.X - mPosition.X, point.Y - mPosition.Y);
			mPendingDockPosition = null;

			// Show dock zone indicators while dragging
			if (mManager != null)
			{
				let center = Vector2(
					mManager.ArrangedBounds.X + mManager.ArrangedBounds.Width / 2,
					mManager.ArrangedBounds.Y + mManager.ArrangedBounds.Height / 2
				);
				mManager.[Friend]mZoneIndicator.Show(center);
				mManager.[Friend]mShowingIndicators = true;
			}

			if (Context != null)
				Context.FocusManager?.SetCapture(this);
			e.Handled = true;
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (e.Button == .Left)
		{
			if (mIsDragging)
			{
				// Release capture FIRST before any cleanup
				if (Context != null)
					Context.FocusManager?.ReleaseCapture();

				// Hide dock indicators and clear feedback
				if (mManager != null)
				{
					mManager.[Friend]mZoneIndicator.Hide();
					mManager.[Friend]mDropTargetIndicator.Hide();
					mManager.[Friend]mShowingIndicators = false;
					mManager.ClearAllFloatingDragFeedback();
				}

				mIsDragging = false;

				// Capture pending dock info before clearing
				let targetGroup = mPendingTargetGroup;
				let dockPos = mPendingDockPosition;
				mPendingTargetGroup = null;
				mPendingDockPosition = null;

				// Check if we should dock
				let shouldDock = dockPos != null && mManager != null && mPanel != null;
				if (shouldDock)
				{
					let panel = mPanel;
					let zone = dockPos.Value;

					// Remove panel from this floating window (without deleting it)
					mPanel = null;

					// Dock the panel
					if (targetGroup != null)
					{
						// Per-group docking
						if (zone == .Center)
						{
							// Add as tab to the group
							targetGroup.AddPanel(panel);
						}
						else
						{
							// Edge docking - create split relative to the group
							mManager.DockPanelRelativeToGroup(panel, targetGroup, zone);
						}
					}
					else
					{
						// Global docking (to entire layout)
						mManager.DockPanel(panel, zone);
					}

					// Remove this floating window (deferred deletion)
					// IMPORTANT: Don't access any instance members after this call
					mManager.RemoveFloatingWindow(this);
				}

				e.Handled = true;
			}
			else if (mIsResizing)
			{
				mIsResizing = false;
				if (Context != null)
					Context.FocusManager?.ReleaseCapture();
				e.Handled = true;
			}
		}
	}

	private ResizeEdge GetResizeEdge(Vector2 point)
	{
		let bounds = WindowBounds;

		bool onLeft = point.X >= bounds.X && point.X < bounds.X + ResizeBorderSize;
		bool onRight = point.X > bounds.Right - ResizeBorderSize && point.X <= bounds.Right;
		bool onTop = point.Y >= bounds.Y && point.Y < bounds.Y + ResizeBorderSize;
		bool onBottom = point.Y > bounds.Bottom - ResizeBorderSize && point.Y <= bounds.Bottom;

		if (onTop && onLeft) return .TopLeft;
		if (onTop && onRight) return .TopRight;
		if (onBottom && onLeft) return .BottomLeft;
		if (onBottom && onRight) return .BottomRight;
		if (onLeft) return .Left;
		if (onRight) return .Right;
		if (onTop) return .Top;
		if (onBottom) return .Bottom;

		return .None;
	}

	private bool IsMouseOverResizeEdge(Vector2 point)
	{
		return GetResizeEdge(point) != .None;
	}

	/// Calculates drop preview bounds for a group and zone.
	private RectangleF CalculateGroupDropBounds(DockTabGroup group, DockPosition zone)
	{
		let bounds = group.ArrangedBounds;

		switch (zone)
		{
		case .Top:
			return .(bounds.X, bounds.Y, bounds.Width, bounds.Height * 0.5f);
		case .Bottom:
			return .(bounds.X, bounds.Y + bounds.Height * 0.5f, bounds.Width, bounds.Height * 0.5f);
		case .Left:
			return .(bounds.X, bounds.Y, bounds.Width * 0.5f, bounds.Height);
		case .Right:
			return .(bounds.X + bounds.Width * 0.5f, bounds.Y, bounds.Width * 0.5f, bounds.Height);
		case .Center:
			return bounds;
		default:
			return bounds;
		}
	}

	private void HandleResize(Vector2 currentPos)
	{
		let delta = currentPos - mResizeStartPos;
		var newBounds = mResizeStartBounds;

		switch (mResizeEdge)
		{
		case .Left:
			newBounds.X += delta.X;
			newBounds.Width -= delta.X;
		case .Right:
			newBounds.Width += delta.X;
		case .Top:
			newBounds.Y += delta.Y;
			newBounds.Height -= delta.Y;
		case .Bottom:
			newBounds.Height += delta.Y;
		case .TopLeft:
			newBounds.X += delta.X;
			newBounds.Width -= delta.X;
			newBounds.Y += delta.Y;
			newBounds.Height -= delta.Y;
		case .TopRight:
			newBounds.Width += delta.X;
			newBounds.Y += delta.Y;
			newBounds.Height -= delta.Y;
		case .BottomLeft:
			newBounds.X += delta.X;
			newBounds.Width -= delta.X;
			newBounds.Height += delta.Y;
		case .BottomRight:
			newBounds.Width += delta.X;
			newBounds.Height += delta.Y;
		case .None:
			return;
		}

		// Apply minimum size constraints
		if (newBounds.Width < MinWindowSize)
		{
			if (mResizeEdge == .Left || mResizeEdge == .TopLeft || mResizeEdge == .BottomLeft)
				newBounds.X = mResizeStartBounds.Right - MinWindowSize;
			newBounds.Width = MinWindowSize;
		}
		if (newBounds.Height < MinWindowSize)
		{
			if (mResizeEdge == .Top || mResizeEdge == .TopLeft || mResizeEdge == .TopRight)
				newBounds.Y = mResizeStartBounds.Bottom - MinWindowSize;
			newBounds.Height = MinWindowSize;
		}

		mPosition = .(newBounds.X, newBounds.Y);
		mSize = .(newBounds.Width, newBounds.Height);
		InvalidateLayout();
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		let bounds = WindowBounds;
		if (!bounds.Contains(point.X, point.Y))
			return null;

		// Check resize edges first - FloatingWindow handles these
		if (GetResizeEdge(point) != .None)
			return this;

		// Check title bar
		if (mPanel != null && mPanel.TitleBarBounds.Contains(point.X, point.Y))
		{
			// FloatingWindow handles close button directly (avoids event callback issues)
			if (mPanel.IsPointOnCloseButton(point))
				return this;
			// Let panel handle other buttons (pin)
			if (mPanel.IsPointOnTitleBarButton(point))
				return mPanel;
			// FloatingWindow handles window dragging for non-button areas
			return this;
		}

		// Check panel content (not title bar)
		if (mPanel != null)
		{
			let hit = mPanel.HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// === Child Detachment ===

	/// Override to support polymorphic child detachment.
	/// Called by MutationQueue when deleting the panel.
	public override UIElement TryDetachChild(UIElement child)
	{
		if (child == mPanel)
		{
			let result = mPanel;
			mPanel = null;
			if (result != null)
			{
				result.SetParent(null);
				if (Context != null)
					result.OnDetachedFromContext();
			}
			return result;
		}
		return null;
	}

	// === Visual Children ===

	public override int VisualChildCount => mPanel != null ? 1 : 0;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mPanel != null)
			return mPanel;
		return null;
	}
}
