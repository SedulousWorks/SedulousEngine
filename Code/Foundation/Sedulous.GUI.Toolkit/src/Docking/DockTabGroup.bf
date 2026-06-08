namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Tab container for docked panels. Shows tabs at the top and content below.
/// Close buttons appear in the tab strip: always on the active tab (if closable),
/// on hover for inactive tabs (if closable). Panel headers are hidden when tabbed.
/// Implements IDragSource for tab dragging.
public class DockTabGroup : ViewGroup, IDragSource
{
	private List<DockablePanel> mPanels = new .() ~ delete _; // Non-owning refs
	private int mSelectedIndex = -1;
	private float mTabHeight = 24;
	private int mHoveredTabIndex = -1;
	private List<RectangleF> mTabRects = new .() ~ delete _;
	private List<RectangleF> mCloseRects = new .() ~ delete _; // Per-tab close button rects

	private const float CloseButtonSize = 8.0f; // Icon size (half-extent of X lines)
	private const float CloseButtonPadding = 6.0f; // Space reserved for close area
	private const float CloseButtonWidth = CloseButtonSize + CloseButtonPadding * 2; // Total width

	// Drag state for tab dragging.
	private int mDragTabIndex = -1;
	private DockablePanel mDraggedPanel;
	private int mDragOriginalIndex = -1;

	/// Fired when the selected tab changes (user click or programmatic).
	public Event<delegate void(DockablePanel)> OnTabSelected ~ _.Dispose();

	public this()
	{
	}

	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			if (value >= -1 && value < mPanels.Count && mSelectedIndex != value)
			{
				if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
					mPanels[mSelectedIndex].Visibility = .Gone;

				mSelectedIndex = value;

				if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
					mPanels[mSelectedIndex].Visibility = .Visible;

				Invalidate();
				OnTabSelected(SelectedPanel);

				// Notify the DockManager (if any) about the tab change
				View ancestor = Parent;
				while (ancestor != null)
				{
					if (let dm = ancestor as DockManager)
					{
						dm.OnPanelActivated(SelectedPanel);
						break;
					}
					ancestor = ancestor.Parent;
				}
			}
		}
	}

	public int PanelCount => mPanels.Count;
	public float TabHeight { get => mTabHeight; set { mTabHeight = Math.Max(16, value); Invalidate(); } }

	public DockablePanel SelectedPanel =>
		(mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count) ? mPanels[mSelectedIndex] : null;

	/// Add a panel as a tab. DockTabGroup does NOT take ownership.
	public void AddPanel(DockablePanel panel)
	{
		mPanels.Add(panel);
		panel.Visibility = .Gone;
		panel.ShowHeader = false; // Tab strip replaces panel header
		AddView(panel);

		if (mSelectedIndex < 0)
			SelectedIndex = 0;
		else
			Invalidate();
	}

	/// Insert a panel at a specific index.
	public void InsertPanel(int index, DockablePanel panel)
	{
		let idx = Math.Clamp(index, 0, mPanels.Count);
		mPanels.Insert(idx, panel);
		panel.Visibility = .Gone;
		panel.ShowHeader = false;
		AddView(panel);

		if (mSelectedIndex < 0)
			SelectedIndex = 0;
		else
		{
			if (idx <= mSelectedIndex)
				mSelectedIndex++;
			Invalidate();
		}
	}

	/// Remove a panel from this group. Returns the panel (caller manages lifecycle).
	public DockablePanel RemovePanel(DockablePanel panel)
	{
		let idx = mPanels.IndexOf(panel);
		if (idx < 0) return null;

		mPanels.RemoveAt(idx);
		RemoveView(panel);
		panel.ShowHeader = true; // Restore header for standalone/floating

		if (mSelectedIndex >= mPanels.Count)
			SelectedIndex = mPanels.Count - 1;
		else if (idx <= mSelectedIndex && mSelectedIndex > 0)
			SelectedIndex = mSelectedIndex - 1;
		else
			Invalidate();

		return panel;
	}

	/// Get the panel at the given index.
	public DockablePanel GetPanel(int index)
	{
		if (index >= 0 && index < mPanels.Count) return mPanels[index];
		return null;
	}

	/// Purge any panels that are pending deletion (defense-in-depth).
	private void PurgeDeletedPanels()
	{
		bool changed = false;
		for (int i = mPanels.Count - 1; i >= 0; i--)
		{
			if (mPanels[i].IsPendingDeletion || mPanels[i].Parent != this)
			{
				mPanels.RemoveAt(i);
				changed = true;
			}
		}
		if (changed && mSelectedIndex >= mPanels.Count)
			mSelectedIndex = mPanels.Count - 1;
	}

	// === Measure / Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		PurgeDeletedPanels();

		let w = constraints.ConstrainWidth(150);
		let h = constraints.ConstrainHeight(100);

		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			let panel = mPanels[mSelectedIndex];
			if (panel.Visibility != .Gone)
				panel.Measure(BoxConstraints.Tight(w, Math.Max(0, h - mTabHeight)));
		}

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		PurgeDeletedPanels();

		let contentY = mTabHeight;
		let contentH = Math.Max(0, height - mTabHeight);

		for (int i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			if (i == mSelectedIndex)
			{
				panel.Visibility = .Visible;
				panel.Measure(BoxConstraints.Tight(width, contentH));
				panel.Layout(0, contentY, width, contentH);
			}
			else
			{
				panel.Visibility = .Gone;
			}
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let contentY = mTabHeight;
		let contentH = Height - mTabHeight;

		// Tab bar background (top).
		let stripDrawable = ResolvePartDrawable("strip", .Background, .Normal);
		if (stripDrawable != null)
			stripDrawable.Draw(ctx, .(0, 0, Width, mTabHeight));
		else
			ctx.VG.FillRect(.(0, 0, Width, mTabHeight), .(35, 37, 46, 255));

		// Content area (below tabs).
		let contentDrawable = ResolvePartDrawable("content", .Background, .Normal);
		if (contentDrawable != null)
			contentDrawable.Draw(ctx, .(0, contentY, Width, contentH));
		else
			ctx.VG.FillRect(.(0, contentY, Width, contentH), .(42, 44, 54, 255));

		// Draw selected panel.
		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			let panel = mPanels[mSelectedIndex];
			if (panel.Visibility != .Gone)
			{
				ctx.VG.PushState();
				ctx.VG.Translate(panel.Bounds.X, panel.Bounds.Y);
				panel.OnDraw(ctx);
				ctx.VG.PopState();
			}
		}

		// Draw tabs.
		mTabRects.Clear();
		mCloseRects.Clear();
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(11);
		if (font == null) return;

		let borderColor = ResolveStyleColor(.BorderColor, .(35, 37, 46, 255));
		let closeColor = ResolvePartColor("close-button", .TextColor, .Normal, .(180, 185, 200, 150));

		float tabX = 2;
		for (int i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			let textW = font.Font.MeasureString(panel.Title);
			var tabW = textW + 16;
			if (panel.Closable)
				tabW += CloseButtonWidth;
			let tabRect = RectangleF(tabX, 0, tabW, mTabHeight);
			mTabRects.Add(tabRect);

			// Tab background
			if (i == mSelectedIndex)
			{
				let activeTabDrawable = ResolvePartDrawable("tab", .Background, .Checked);
				if (activeTabDrawable != null)
					activeTabDrawable.Draw(ctx, tabRect);
				else
					ctx.VG.FillRect(tabRect, .(42, 44, 54, 255));
			}
			else if (i == mHoveredTabIndex)
			{
				let hoverTabDrawable = ResolvePartDrawable("tab", .Background, .Hover);
				if (hoverTabDrawable != null)
					hoverTabDrawable.Draw(ctx, tabRect);
				else
					ctx.VG.FillRect(tabRect, Palette.Lighten(borderColor, 0.1f));
			}

			// Tab text
			let textColor = (i == mSelectedIndex)
				? ResolvePartColor("tab", .TextColor, .Checked, .(220, 225, 235, 255))
				: ResolvePartColor("tab", .TextColor, .Normal, .(180, 185, 200, 153));
			ctx.VG.DrawText(panel.Title, font, .(tabX + 8, 0, textW, mTabHeight), .Left, .Middle, textColor);

			// Close button - show on active tab always, on hovered inactive tab
			if (panel.Closable)
			{
				let cbX = tabX + tabW - CloseButtonPadding - CloseButtonSize;
				let cbY = (mTabHeight - CloseButtonSize) * 0.5f;
				let closeRect = RectangleF(tabX + tabW - CloseButtonWidth, 0, CloseButtonWidth, mTabHeight);
				mCloseRects.Add(closeRect);

				let showClose = (i == mSelectedIndex) || (i == mHoveredTabIndex);
				if (showClose)
				{
					let closeIcon = ResolvePartDrawable("close-button", .Background, .Normal);
					if (closeIcon != null)
					{
						ctx.VG.PushOpacity(closeColor.A / 255.0f);
						closeIcon.Draw(ctx, .(cbX, cbY, CloseButtonSize, CloseButtonSize));
						ctx.VG.PopOpacity();
					}
					else
					{
						// Fallback: draw X lines
						let cx = cbX + CloseButtonSize * 0.5f;
						let cy = cbY + CloseButtonSize * 0.5f;
						let sz = 3.0f;
						ctx.VG.DrawLine(.(cx - sz, cy - sz), .(cx + sz, cy + sz), closeColor, 1.5f);
						ctx.VG.DrawLine(.(cx + sz, cy - sz), .(cx - sz, cy + sz), closeColor, 1.5f);
					}
				}
			}
			else
			{
				mCloseRects.Add(.Empty);  // Empty rect for non-closable tabs
			}

			tabX += tabW + 2;
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		// Check close buttons first
		for (int i = 0; i < mCloseRects.Count; i++)
		{
			let cr = mCloseRects[i];
			if (cr.Width > 0 && i < mPanels.Count && mPanels[i].Closable)
			{
				if (e.X >= cr.X && e.X < cr.X + cr.Width && e.Y >= cr.Y && e.Y < cr.Y + cr.Height)
				{
					mPanels[i].OnCloseRequested(mPanels[i]);
					e.Handled = true;
					return;
				}
			}
		}

		// Check tab selection
		mDragTabIndex = -1;
		for (int i = 0; i < mTabRects.Count; i++)
		{
			let r = mTabRects[i];
			if (e.X >= r.X && e.X < r.X + r.Width && e.Y >= r.Y && e.Y < r.Y + r.Height)
			{
				SelectedIndex = i;
				mDragTabIndex = i;
				e.Handled = true;
				return;
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		int hovered = -1;
		for (int i = 0; i < mTabRects.Count; i++)
		{
			let r = mTabRects[i];
			if (e.X >= r.X && e.X < r.X + r.Width && e.Y >= r.Y && e.Y < r.Y + r.Height)
			{ hovered = i; break; }
		}

		if (hovered != mHoveredTabIndex)
		{
			mHoveredTabIndex = hovered;
			Invalidate(); // Redraw to show/hide close button on hover
		}
	}

	public override void OnMouseLeave()
	{
		if (mHoveredTabIndex != -1)
		{
			mHoveredTabIndex = -1;
			Invalidate();
		}
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		if (mDragTabIndex < 0 || mDragTabIndex >= mPanels.Count)
			return null;
		return new DockPanelDragData(mPanels[mDragTabIndex]);
	}

	public View CreateDragVisual(DragData data)
	{
		if (let panelData = data as DockPanelDragData)
		{
			let preview = new DockDragPreview();
			preview.SetTitle(panelData.Panel.Title);
			return preview;
		}
		return null;
	}

	public void OnDragStarted(DragData data)
	{
		if (let panelData = data as DockPanelDragData)
		{
			mDraggedPanel = panelData.Panel;
			mDragOriginalIndex = mDragTabIndex;
			RemovePanel(mDraggedPanel);

			// Position preview so the title bar is under the cursor.
			if (Context?.DragDropManager != null)
			{
				Context.DragDropManager.AdornerOffsetX = -30;
				Context.DragDropManager.AdornerOffsetY = -12;
			}
		}
	}

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		if (cancelled && mDraggedPanel != null)
		{
			let dockHost = mDraggedPanel.DockHost;
			if (dockHost != null)
			{
				let screenX = dockHost.Context?.DragDropManager.LastScreenX ?? 100;
				let screenY = dockHost.Context?.DragDropManager.LastScreenY ?? 100;
				dockHost.FloatPanel(mDraggedPanel, screenX, screenY);
			}
			else
			{
				InsertPanel(mDragOriginalIndex, mDraggedPanel);
			}
		}

		mDraggedPanel = null;
		mDragOriginalIndex = -1;
		mDragTabIndex = -1;
	}
}
