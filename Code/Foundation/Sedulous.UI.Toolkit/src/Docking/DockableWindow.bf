using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A floating window holding one [[DockablePanel]].
///
/// It is either a REAL window the system owns or an overlay drawn inside the main one, and the
/// difference runs through everything here. An overlay draws its own background and border; a
/// real one does not, because the system already did. Under system CHROME the window also owns
/// moving, resizing and closing, so the inner resize edges are switched off and a header drag
/// re-docks without the window chasing the cursor.
///
/// Resizing is measured in SCREEN coordinates from where the drag began, not accumulated
/// frame by frame, so it cannot drift and an edge dragged back returns to exactly where it was.
class DockableWindow : ViewGroup
{
	private const float ResizeHitSize = 5.0f;
	private const float MinWidth = 150.0f;
	private const float MinHeight = 100.0f;

	public bool IsOSWindow = false;
	/// Whether the hosting window carries native chrome. Set by the manager from the host's own
	/// answer, because only the application knows what it can make.
	public bool HasOSChrome = false;
	/// BORROWED: the application owns the host.
	public IDockableWindowHost WindowHost = null;

	public Event<delegate void(DockableWindow)> OnDockRequested ~ _.Dispose();
	public Event<delegate void(DockableWindow)> OnCloseRequested ~ _.Dispose();

	/// BORROWED: it is in the child list.
	private DockablePanel mPanel = null;
	private float mTitleBarHeight = 24.0f;
	private float mRequestedWidth = 0.0f;
	private float mRequestedHeight = 0.0f;

	private bool mResizing = false;
	private ResizeEdge mResizeEdge = .None;
	private float mResizeStartMouseX = 0.0f;
	private float mResizeStartMouseY = 0.0f;
	private float mResizeStartX = 0.0f;
	private float mResizeStartY = 0.0f;
	private float mResizeStartWidth = 0.0f;
	private float mResizeStartHeight = 0.0f;

	/// CONSUMES the panel's reference.
	public this(DockablePanel panel)
	{
		mPanel = panel;
		if (panel != null)
			AddView(panel);
	}

	/// BORROWED.
	public DockablePanel Panel => mPanel;

	public float RequestedWidth
	{
		get => mRequestedWidth;
		set
		{
			mRequestedWidth = Max(value, MinWidth);
			Invalidate();
		}
	}

	public float RequestedHeight
	{
		get => mRequestedHeight;
		set
		{
			mRequestedHeight = Max(value, MinHeight);
			Invalidate();
		}
	}

	/// Takes the panel out. OWNERSHIP transfers to the caller.
	public DockablePanel DetachPanel()
	{
		let panel = mPanel;
		if (panel == null)
			return null;

		// AddRef'd across the removal, because the child list holds the only reference and
		// releasing it here would free the panel the caller is being handed.
		panel.AddRef();
		RemoveView(panel);
		mPanel = null;
		return panel;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// A REAL window already has a frame around it drawn by the system; drawing another
		// would put a border inside a border.
		if (!IsOSWindow)
		{
			let bounds = Rectangle(0, 0, Width, Height);

			if (let background = ResolveStyleDrawable(.Background))
				background.Draw(ctx, bounds);
			else
				ctx.VG.FillRect(bounds, Color.Rgb(42, 44, 54));

			ctx.VG.StrokeRect(bounds, ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85)), 2);
		}

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let width = constraints.ConstrainWidth((mRequestedWidth > 0.0f) ? mRequestedWidth : 250.0f);
		let height = constraints.ConstrainHeight((mRequestedHeight > 0.0f) ? mRequestedHeight
			: 200.0f);

		if (mPanel != null)
			mPanel.Measure(BoxConstraints.Tight(width, height));

		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mPanel != null)
			mPanel.Layout(0, 0, width, height);
	}

	// ---- Input ----------------------------------------------------------------------------------

	public override View HitTest(Float2 localPoint)
	{
		if (!IsInteractionEnabled || (Visibility != .Visible))
			return null;

		if ((localPoint.X < 0) || (localPoint.Y < 0) || (localPoint.X >= Width)
			|| (localPoint.Y >= Height))
			return null;

		// A resize in progress consumes EVERYTHING, so the pointer crossing a child cannot
		// interrupt it.
		if (mResizing)
			return this;

		if (EdgeAt(localPoint.X, localPoint.Y) != .None)
			return this;

		return base.HitTest(localPoint);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		// Double clicking the title bar re-docks, which is the standard gesture and the only
		// way back for a window dragged somewhere awkward.
		if ((e.Y < mTitleBarHeight) && (e.ClickCount >= 2))
		{
			OnDockRequested(this);
			e.Handled = true;
			return;
		}

		let edge = EdgeAt(e.X, e.Y);
		if (edge == .None)
			return;

		mResizing = true;
		mResizeEdge = edge;
		CaptureResizeOrigin(e);

		if (Context != null)
			Context.GetFocusManager().SetCapture(this);

		e.Handled = true;
	}

	/// Where the window and the pointer were when the resize began.
	///
	/// From the HOST where there is one, because a real window's position is the system's to
	/// report and a local-to-screen conversion only knows about the main window.
	private void CaptureResizeOrigin(MouseEventArgs e)
	{
		if (IsOSWindow && (WindowHost != null)
			&& WindowHost.TryGetDockableWindowBounds(this, out mResizeStartX, out mResizeStartY,
				out mResizeStartWidth, out mResizeStartHeight))
		{
			WindowHost.GetGlobalMousePosition(out mResizeStartMouseX, out mResizeStartMouseY);
			return;
		}

		let windowPos = LocalToScreen(.Zero);
		mResizeStartX = windowPos.X;
		mResizeStartY = windowPos.Y;
		mResizeStartWidth = Width;
		mResizeStartHeight = Height;

		let mousePos = LocalToScreen(.(e.X, e.Y));
		mResizeStartMouseX = mousePos.X;
		mResizeStartMouseY = mousePos.Y;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mResizing)
		{
			ResizeTo(e);
			e.Handled = true;
			return;
		}

		Cursor = CursorForEdge(EdgeAt(e.X, e.Y));
	}

	private void ResizeTo(MouseEventArgs e)
	{
		float currentX;
		float currentY;
		if (IsOSWindow && (WindowHost != null))
		{
			WindowHost.GetGlobalMousePosition(out currentX, out currentY);
		}
		else
		{
			let mousePos = LocalToScreen(.(e.X, e.Y));
			currentX = mousePos.X;
			currentY = mousePos.Y;
		}

		// Measured from where the drag STARTED, so nothing accumulates.
		let dx = currentX - mResizeStartMouseX;
		let dy = currentY - mResizeStartMouseY;

		var x = mResizeStartX;
		var y = mResizeStartY;
		var width = mResizeStartWidth;
		var height = mResizeStartHeight;

		// The far edges grow the size; the NEAR ones move the corner and shrink by the same
		// amount, clamped so the far edge stays put rather than being pushed along.
		if (GrowsRight(mResizeEdge))
			width = Max(MinWidth, mResizeStartWidth + dx);
		if (GrowsBottom(mResizeEdge))
			height = Max(MinHeight, mResizeStartHeight + dy);

		if (MovesLeft(mResizeEdge))
		{
			let delta = Min(dx, mResizeStartWidth - MinWidth);
			x = mResizeStartX + delta;
			width = mResizeStartWidth - delta;
		}

		if (MovesTop(mResizeEdge))
		{
			let delta = Min(dy, mResizeStartHeight - MinHeight);
			y = mResizeStartY + delta;
			height = mResizeStartHeight - delta;
		}

		mRequestedWidth = width;
		mRequestedHeight = height;
		ApplyBounds(x, y, width, height);
	}

	private void ApplyBounds(float x, float y, float width, float height)
	{
		if (IsOSWindow)
		{
			if (WindowHost != null)
				WindowHost.ResizeDockableWindow(this, x, y, width, height);
			return;
		}

		// An overlay window is a popup, so its position belongs to the popup layer; the size
		// comes from the requested one at the next measure.
		if (let root = Root())
			root.GetPopupLayer().UpdatePopupPosition(this, x, y);
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mResizing || (e.Button != .Left))
			return;

		mResizing = false;
		mResizeEdge = .None;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		if (!mResizing)
			Cursor = .Default;
	}

	// ---- Edges ----------------------------------------------------------------------------------

	/// Which edge or corner a point is on. NONE under system chrome, where the system's own
	/// border does the resizing and an inner band would fight it.
	private ResizeEdge EdgeAt(float x, float y)
	{
		if (IsOSWindow && HasOSChrome)
			return .None;

		let onLeft = x < ResizeHitSize;
		let onRight = x >= Width - ResizeHitSize;
		let onTop = y < ResizeHitSize;
		let onBottom = y >= Height - ResizeHitSize;

		// Corners FIRST, so a point in both bands resizes diagonally rather than on whichever
		// edge happened to be tested first.
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

	private static bool GrowsRight(ResizeEdge edge) =>
		(edge == .Right) || (edge == .TopRight) || (edge == .BottomRight);

	private static bool GrowsBottom(ResizeEdge edge) =>
		(edge == .Bottom) || (edge == .BottomLeft) || (edge == .BottomRight);

	private static bool MovesLeft(ResizeEdge edge) =>
		(edge == .Left) || (edge == .TopLeft) || (edge == .BottomLeft);

	private static bool MovesTop(ResizeEdge edge) =>
		(edge == .Top) || (edge == .TopLeft) || (edge == .TopRight);

	private static CursorType CursorForEdge(ResizeEdge edge)
	{
		switch (edge)
		{
		case .Top, .Bottom: return .SizeNS;
		case .Left, .Right: return .SizeWE;
		case .TopLeft, .BottomRight: return .SizeNWSE;
		case .TopRight, .BottomLeft: return .SizeNESW;
		case .None: return .Default;
		}
	}
}
