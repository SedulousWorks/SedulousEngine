namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Resize edge/corner identification.
enum ResizeEdge
{
	None,
	Top, Bottom, Left, Right,
	TopLeft, TopRight, BottomLeft, BottomRight
}

/// A dockable window that wraps a DockablePanel.
/// Virtual mode: shown via PopupLayer as a draggable, resizable overlay.
/// Double-click title bar to re-dock.
public class DockableWindow : ViewGroup, IDockableWindow
{
	private DockablePanel mPanel;
	private float mTitleBarHeight = 24;
	public bool IsOSWindow;
	public IDockableWindowHost WindowHost;

	// Resize state
	private const float ResizeHitSize = 5.0f;
	private const float MinWidth = 150.0f;
	private const float MinHeight = 100.0f;
	private float mRequestedWidth = 0;
	private float mRequestedHeight = 0;
	private bool mResizing;
	private ResizeEdge mResizeEdge = .None;
	private float mResizeStartMouseX;
	private float mResizeStartMouseY;
	private float mResizeStartX;
	private float mResizeStartY;
	private float mResizeStartW;
	private float mResizeStartH;

	public Event<delegate void(DockableWindow)> OnDockRequested ~ _.Dispose();
	public Event<delegate void(DockableWindow)> OnCloseRequested ~ _.Dispose();

	/// The panel contained in this floating window.
	public DockablePanel Panel => mPanel;

	/// Explicit size for the window. Set during resize or initial float.
	public float RequestedWidth
	{
		get => mRequestedWidth;
		set { mRequestedWidth = Math.Max(value, MinWidth); Invalidate(); }
	}

	public float RequestedHeight
	{
		get => mRequestedHeight;
		set { mRequestedHeight = Math.Max(value, MinHeight); Invalidate(); }
	}

	public this(DockablePanel panel)
	{
		mPanel = panel;
		if (panel != null)
			AddView(panel);
	}

	// === Measure / Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = (mRequestedWidth > 0)
			? constraints.ConstrainWidth(mRequestedWidth)
			: constraints.ConstrainWidth(250);
		let h = (mRequestedHeight > 0)
			? constraints.ConstrainHeight(mRequestedHeight)
			: constraints.ConstrainHeight(200);

		if (mPanel != null)
			mPanel.Measure(BoxConstraints.Tight(w, h));

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mPanel != null)
			mPanel.Layout(0, 0, width, height);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!IsOSWindow)
		{
			let bgDrawable = ResolveStyleDrawable(.Background);
			if (bgDrawable != null)
				bgDrawable.Draw(ctx, .(0, 0, Width, Height));
			else
				ctx.VG.FillRect(.(0, 0, Width, Height), .(42, 44, 54, 255));

			let borderColor = ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
			ctx.VG.StrokeRect(.(0, 0, Width, Height), borderColor, 2);
		}

		DrawChildren(ctx);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		// Title bar double-click to re-dock.
		if (e.Y < mTitleBarHeight && e.ClickCount >= 2)
		{
			OnDockRequested(this);
			e.Handled = true;
			return;
		}

		// Edge/corner resize.
		{
			let edge = HitTestEdge(e.X, e.Y);
			if (edge != .None)
			{
				mResizing = true;
				mResizeEdge = edge;

				// Anchor pos+size+mouse in the host's screen-coord frame
				// (logical px, main-window-relative). For OS-hosted windows
				// we MUST use the host bounds, not View.Width/Height: those
				// reflect the inner LAYOUT extent (`RootView` divides
				// ViewportSize by DpiScale), and writing them back into
				// Window.Width would shrink the OS window. Virtual popup
				// fallback uses LocalToScreen + View.Width/Height which IS
				// the right frame for `PopupLayer.UpdatePopupPosition`.
				if (IsOSWindow && WindowHost != null &&
					WindowHost.TryGetDockableWindowBounds(this,
						out mResizeStartX, out mResizeStartY,
						out mResizeStartW, out mResizeStartH))
				{
					WindowHost.GetGlobalMousePosition(out mResizeStartMouseX, out mResizeStartMouseY);
				}
				else
				{
					let screenPos = LocalToScreen(.(0, 0));
					mResizeStartX = screenPos.X;
					mResizeStartY = screenPos.Y;
					mResizeStartW = Width;
					mResizeStartH = Height;
					let screenMouse = LocalToScreen(.(e.X, e.Y));
					mResizeStartMouseX = screenMouse.X;
					mResizeStartMouseY = screenMouse.Y;
				}

				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mResizing)
		{
			// Read the current mouse in the same frame the anchor was recorded
			// in. OS-hosted: desktop-global (stable across OS-window moves /
			// resizes). Virtual popup: PopupLayer-local via LocalToScreen.
			float curX, curY;
			if (IsOSWindow && WindowHost != null)
			{
				WindowHost.GetGlobalMousePosition(out curX, out curY);
			}
			else
			{
				let screenMouse = LocalToScreen(.(e.X, e.Y));
				curX = screenMouse.X;
				curY = screenMouse.Y;
			}
			let dx = curX - mResizeStartMouseX;
			let dy = curY - mResizeStartMouseY;

			var newX = mResizeStartX;
			var newY = mResizeStartY;
			var newW = mResizeStartW;
			var newH = mResizeStartH;

			// Apply delta based on which edge/corner is being dragged
			switch (mResizeEdge)
			{
			case .Right:
				newW = Math.Max(MinWidth, mResizeStartW + dx);
			case .Bottom:
				newH = Math.Max(MinHeight, mResizeStartH + dy);
			case .Left:
				let dw = Math.Min(dx, mResizeStartW - MinWidth);
				newX = mResizeStartX + dw;
				newW = mResizeStartW - dw;
			case .Top:
				let dh = Math.Min(dy, mResizeStartH - MinHeight);
				newY = mResizeStartY + dh;
				newH = mResizeStartH - dh;
			case .BottomRight:
				newW = Math.Max(MinWidth, mResizeStartW + dx);
				newH = Math.Max(MinHeight, mResizeStartH + dy);
			case .BottomLeft:
				let dw = Math.Min(dx, mResizeStartW - MinWidth);
				newX = mResizeStartX + dw;
				newW = mResizeStartW - dw;
				newH = Math.Max(MinHeight, mResizeStartH + dy);
			case .TopRight:
				newW = Math.Max(MinWidth, mResizeStartW + dx);
				let dh = Math.Min(dy, mResizeStartH - MinHeight);
				newY = mResizeStartY + dh;
				newH = mResizeStartH - dh;
			case .TopLeft:
				let dw = Math.Min(dx, mResizeStartW - MinWidth);
				newX = mResizeStartX + dw;
				newW = mResizeStartW - dw;
				let dh = Math.Min(dy, mResizeStartH - MinHeight);
				newY = mResizeStartY + dh;
				newH = mResizeStartH - dh;
			case .None:
			}

			mRequestedWidth = newW;
			mRequestedHeight = newH;

			if (IsOSWindow)
			{
				if (WindowHost != null)
					WindowHost.ResizeDockableWindow(this, newX, newY, newW, newH);
			}
			else
			{
				Root?.PopupLayer?.UpdatePopupPosition(this, newX, newY);
			}

			e.Handled = true;
			return;
		}

		// Update cursor based on edge proximity
		let edge = HitTestEdge(e.X, e.Y);
		Cursor = EdgeToCursor(edge);
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mResizing && e.Button == .Left)
		{
			mResizing = false;
			mResizeEdge = .None;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	public override void OnMouseLeave()
	{
		if (!mResizing)
			Cursor = .Default;
	}

	// === Hit testing ===

	/// Intercept edge zones for resize before delegating to children.
	public override View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled || Visibility != .Visible) return null;
		if (localPoint.X < 0 || localPoint.Y < 0 || localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		// During active resize, consume all input
		if (mResizing)
			return this;

		// Check if the cursor is on an edge — intercept for resize
		if (HitTestEdge(localPoint.X, localPoint.Y) != .None)
			return this;

		// Otherwise delegate to children normally
		return base.HitTest(localPoint);
	}

	// === IDockableWindow ===

	/// Detach and return the panel. Caller takes ownership.
	public DockablePanel DetachPanel()
	{
		let panel = mPanel;
		if (panel != null)
		{
			RemoveView(panel);
			mPanel = null;
		}
		return panel;
	}

	// === Resize helpers ===

	private ResizeEdge HitTestEdge(float x, float y)
	{
		let s = ResizeHitSize;
		let onLeft = x < s;
		let onRight = x >= Width - s;
		let onTop = y < s;
		let onBottom = y >= Height - s;

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

	private static CursorType EdgeToCursor(ResizeEdge edge)
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
