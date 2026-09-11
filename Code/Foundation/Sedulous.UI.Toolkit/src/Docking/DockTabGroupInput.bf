using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[DockTabGroup]]: selecting, closing, scrolling the strip, and dragging a tab out.
extension DockTabGroup
{
	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		// Close buttons FIRST: they sit inside their tab's rectangle, so testing the tab first
		// would swallow every close.
		for (int32 i = 0; i < mCloseRects.Count; i++)
		{
			if ((mCloseRects[i].Width <= 0) || (i >= mPanels.Count) || !mPanels[i].Closable)
				continue;

			if (!mCloseRects[i].Contains(.(e.X, e.Y)))
				continue;

			mPanels[i].RequestClose();
			e.Handled = true;
			return;
		}

		mDragTabIndex = -1;
		for (int32 i = 0; i < mTabRects.Count; i++)
		{
			if (!mTabRects[i].Contains(.(e.X, e.Y)))
				continue;

			SetSelectedIndex(i);
			// Remembered so a drag that follows knows which tab it started on; the drag itself
			// only begins once the movement threshold is passed.
			mDragTabIndex = i;
			e.Handled = true;
			return;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		int32 hovered = -1;
		for (int32 i = 0; i < mTabRects.Count; i++)
		{
			if (mTabRects[i].Contains(.(e.X, e.Y)))
			{
				hovered = i;
				break;
			}
		}

		if (hovered == mHoveredTabIndex)
			return;

		mHoveredTabIndex = hovered;
		Invalidate();
	}

	public override void OnMouseLeave()
	{
		if (mHoveredTabIndex == -1)
			return;

		mHoveredTabIndex = -1;
		Invalidate();
	}

	/// The wheel scrolls the strip when it overflows.
	///
	/// Wheel arguments arrive in ROOT space, unlike the localised mouse events, so they are
	/// converted before the band is tested. Without that the check only passes when the group
	/// happens to sit at the very top of the window.
	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (!mTabOverflow)
			return;

		let origin = LocalToScreen(.Zero);
		let localX = e.X - origin.X;
		let localY = e.Y - origin.Y;

		if ((localY < 0.0f) || (localY >= mTabHeight) || (localX < 0.0f) || (localX >= Width))
			return;

		// A trackpad sends the horizontal axis; a wheel sends the vertical. Either scrolls the
		// strip, because there is only one direction it can go.
		let delta = (e.DeltaY != 0.0f) ? e.DeltaY : e.DeltaX;
		if (delta == 0.0f)
			return;

		mTabScroll -= delta * 40.0f; // clamped by the next draw, which knows the strip's width
		mHoveredTabIndex = -1;
		Invalidate();
		e.Handled = true;
	}

	// ---- IDragSource ----------------------------------------------------------------------------

	public override IDragSource AsDragSource() => this;

	public DragData CreateDragData()
	{
		if ((mDragTabIndex < 0) || (mDragTabIndex >= mPanels.Count))
			return null;

		return new DockPanelDragData(mPanels[mDragTabIndex]);
	}

	public View CreateDragVisual(DragData data)
	{
		let panelData = data as DockPanelDragData;
		if (panelData == null)
			return null;

		let preview = new DockDragPreview();
		preview.SetTitle(panelData.Panel.Title);
		return preview;
	}

	/// The panel LEAVES the group as the drag begins, so the strip closes up under the cursor
	/// and it is obvious the tab is in flight rather than still docked.
	public void OnDragStarted(DragData data)
	{
		let panelData = data as DockPanelDragData;
		if (panelData == null)
			return;

		mDraggedPanel = panelData.Panel;
		mDragOriginalIndex = mDragTabIndex;
		// RemovePanel hands back a reference, which is held here for the drag's duration.
		RemovePanel(mDraggedPanel);

		// The chip sits above and left of the cursor, so the pointer stays over the drop zone
		// it is aiming at.
		if (Context != null)
		{
			Context.DragDrop.AdornerOffsetX = -30.0f;
			Context.DragDrop.AdornerOffsetY = -12.0f;
		}
	}

	/// A CANCELLED drag FLOATS the panel rather than putting it back.
	///
	/// Cancelled means the drop landed outside every target, and a tab dragged clear of the
	/// dock is asking to become its own window. It is dropped where the PREVIEW was, cursor
	/// plus the adorner offset, so the window appears where the chip already was instead of
	/// jumping on release.
	///
	/// With no host to float through there is nowhere for it to go, so it goes back.
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		let panel = mDraggedPanel;
		mDraggedPanel = null;
		let originalIndex = mDragOriginalIndex;
		mDragOriginalIndex = -1;
		mDragTabIndex = -1;

		if (!cancelled || (panel == null))
			return;

		let dockHost = panel.DockHost;
		if (dockHost == null)
		{
			InsertPanel(originalIndex, panel);
			return;
		}

		let context = dockHost.HostContext;
		var x = 100.0f;
		var y = 100.0f;
		if (context != null)
		{
			let dragDrop = context.DragDrop;
			x = dragDrop.LastScreenX + dragDrop.AdornerOffsetX;
			y = dragDrop.LastScreenY + dragDrop.AdornerOffsetY;
		}

		dockHost.FloatPanel(panel, x, y);
	}
}
