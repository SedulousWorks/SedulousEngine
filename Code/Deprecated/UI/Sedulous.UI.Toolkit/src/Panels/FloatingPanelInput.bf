using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[FloatingPanel]]: dragging by the title strip, resizing from the edges, and the two header
/// controls.
extension FloatingPanel
{
	/// The resize band is claimed BEFORE the children, so the grip still works where content
	/// sits under it.
	public override View HitTest(Float2 localPoint)
	{
		if ((Visibility == .Visible) && IsInteractionEnabled && !mCollapsed
			&& (localPoint.X >= 0) && (localPoint.Y >= 0)
			&& (localPoint.X < Width) && (localPoint.Y < Height)
			&& InResizeBand(localPoint, ?, ?))
			return this;

		return base.HitTest(localPoint);
	}

	public override CursorType CursorAt(Float2 localPoint)
	{
		if (!mCollapsed && InResizeBand(localPoint, let right, let bottom))
		{
			if (right && bottom)
				return .SizeNWSE;
			return right ? .SizeWE : .SizeNS;
		}

		if (localPoint.Y < HeaderHeight)
			return (InChevronBox(localPoint) || InCloseBox(localPoint)) ? .Hand : .Move;

		return .Default;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		let point = Float2(e.X, e.Y);

		if (point.Y < HeaderHeight)
		{
			if (InCloseBox(point))
			{
				OnClose();
				e.Handled = true;
				return;
			}

			if (InChevronBox(point))
			{
				SetCollapsed(!mCollapsed);
				e.Handled = true;
				return;
			}
		}

		if (!mCollapsed && InResizeBand(point, let right, let bottom))
		{
			mResizing = true;
			mResizeRight = right;
			mResizeBottom = bottom;
			// The offset from the grabbed point to the corner, so the corner stays under the
			// cursor rather than snapping to it.
			mGrabOffsetX = Width - e.X;
			mGrabOffsetY = Height - e.Y;
			Capture();
			e.Handled = true;
			return;
		}

		if (point.Y < HeaderHeight)
		{
			mDragging = true;
			mGrabLocalX = e.X;
			mGrabLocalY = e.Y;
			Capture();
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mResizing)
		{
			// ABSOLUTE, not incremental. The top left is fixed during a bottom right resize, so
			// the cursor position maps straight to a size and there is nothing to accumulate
			// drift into.
			if (mResizeRight)
				mUserWidth = Clamp(e.X + mGrabOffsetX, MinWidth, MaxWidthInParent());
			if (mResizeBottom)
				mUserHeight = Clamp(e.Y + mGrabOffsetY, MinHeight, MaxHeightInParent());

			Invalidate();
			e.Handled = true;
			return;
		}

		if (mDragging)
		{
			// Also absolute: the new position is the pointer in the parent's space less where
			// in the panel it was grabbed, which keeps the grabbed point under the cursor.
			var placement = Layout;
			placement.Left = e.X + Bounds.X - mGrabLocalX;
			placement.Top = e.Y + Bounds.Y - mGrabLocalY;
			SetLayout(placement);
			ClampToParent();
			Invalidate();
			e.Handled = true;
			return;
		}

		let hovering = (e.Y < HeaderHeight) && InCloseBox(.(e.X, e.Y));
		if (hovering != mCloseHover)
		{
			mCloseHover = hovering;
			Invalidate();
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button != .Left) || (!mResizing && !mDragging))
			return;

		mResizing = false;
		mDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		if (!mCloseHover)
			return;

		mCloseHover = false;
		Invalidate();
	}

	// ---- Regions --------------------------------------------------------------------------------

	private void Capture()
	{
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	private bool InChevronBox(Float2 p) =>
		(p.X >= 0) && (p.X < ChevronBoxWidth) && (p.Y >= 0) && (p.Y < HeaderHeight);

	private bool InCloseBox(Float2 p) =>
		(p.X >= Width - CloseBoxWidth) && (p.X < Width) && (p.Y >= 0) && (p.Y < HeaderHeight);

	/// The EDGE bands live inside the content inset, which is the border area outside the hosted
	/// content, so they never eat the content's own edge: a wider band would claim the outer few
	/// pixels of a hosted grid's scroll bar. The bottom right CORNER keeps a larger square.
	private bool InResizeBand(Float2 p, out bool right, out bool bottom)
	{
		let inCorner = (p.X >= Width - ResizeCorner) && (p.Y >= Height - ResizeCorner);
		right = inCorner || (p.X >= Width - ContentInset);
		bottom = inCorner || (p.Y >= Height - ContentInset);
		return (right || bottom) && (p.Y > HeaderHeight);
	}
}
