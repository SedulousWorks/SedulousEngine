namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Tab container for docked panels. Shows tabs at the bottom and content above.
/// Implements IDragSource for tab dragging.
public class DockTabGroup : ViewGroup, IDragSource
{
	private List<DockablePanel> mPanels = new .() ~ delete _; // Non-owning refs
	private int mSelectedIndex = -1;
	private float mTabHeight = 24;
	private int mHoveredTabIndex = -1;
	private List<RectangleF> mTabRects = new .() ~ delete _;

	// Drag state for tab dragging.
	private int mDragTabIndex = -1;
	private DockablePanel mDraggedPanel;
	private int mDragOriginalIndex = -1;

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

				InvalidateLayout();
			}
		}
	}

	public int PanelCount => mPanels.Count;
	public float TabHeight { get => mTabHeight; set { mTabHeight = Math.Max(16, value); InvalidateLayout(); } }

	public DockablePanel SelectedPanel =>
		(mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count) ? mPanels[mSelectedIndex] : null;

	/// Add a panel as a tab. DockTabGroup does NOT take ownership.
	public void AddPanel(DockablePanel panel)
	{
		mPanels.Add(panel);
		panel.Visibility = .Gone;
		AddView(panel);

		if (mSelectedIndex < 0)
			SelectedIndex = 0;
		else
			InvalidateLayout();
	}

	/// Insert a panel at a specific index.
	public void InsertPanel(int index, DockablePanel panel)
	{
		let idx = Math.Clamp(index, 0, mPanels.Count);
		mPanels.Insert(idx, panel);
		panel.Visibility = .Gone;
		AddView(panel);

		if (mSelectedIndex < 0)
			SelectedIndex = 0;
		else
		{
			if (idx <= mSelectedIndex)
				mSelectedIndex++;
			InvalidateLayout();
		}
	}

	/// Remove a panel from this group. Returns the panel (caller manages lifecycle).
	public DockablePanel RemovePanel(DockablePanel panel)
	{
		let idx = mPanels.IndexOf(panel);
		if (idx < 0) return null;

		mPanels.RemoveAt(idx);
		DetachView(panel);

		if (mSelectedIndex >= mPanels.Count)
			SelectedIndex = mPanels.Count - 1;
		else if (idx <= mSelectedIndex && mSelectedIndex > 0)
			SelectedIndex = mSelectedIndex - 1;
		else
			InvalidateLayout();

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

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		PurgeDeletedPanels();

		let w = wSpec.Resolve(150);
		let h = hSpec.Resolve(100);

		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			let panel = mPanels[mSelectedIndex];
			if (panel.Visibility != .Gone)
				panel.Measure(.Exactly(w), .Exactly(Math.Max(0, h - mTabHeight)));
		}

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		PurgeDeletedPanels();

		let w = right - left;
		let h = bottom - top;
		let contentH = Math.Max(0, h - mTabHeight);

		for (int i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			if (i == mSelectedIndex)
			{
				panel.Visibility = .Visible;
				panel.Measure(.Exactly(w), .Exactly(contentH));
				panel.Layout(0, 0, w, contentH);
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
		let contentH = Height - mTabHeight;

		// Content area.
		let contentBg = ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
		ctx.VG.FillRect(.(0, 0, Width, contentH), contentBg);

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

		// Tab bar background.
		let tabBg = ctx.Theme?.GetColor("DockTabGroup.Background", .(35, 37, 46, 255)) ?? .(35, 37, 46, 255);
		ctx.VG.FillRect(.(0, contentH, Width, mTabHeight), tabBg);

		// Draw tabs.
		mTabRects.Clear();
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(11);
		if (font == null) return;

		let activeTabBg = ctx.Theme?.GetColor("DockTabGroup.ActiveTab") ?? ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
		let activeText = ctx.Theme?.GetColor("DockTabGroup.ActiveText") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
		let inactiveText = ctx.Theme?.GetColor("DockTabGroup.InactiveText", .(180, 185, 200, 153)) ?? .(180, 185, 200, 153);

		float tabX = 2;
		for (int i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			let textW = font.Font.MeasureString(panel.Title);
			let tabW = textW + 16;
			let tabRect = RectangleF(tabX, contentH, tabW, mTabHeight);
			mTabRects.Add(tabRect);

			if (i == mSelectedIndex)
				ctx.VG.FillRect(tabRect, activeTabBg);
			else if (i == mHoveredTabIndex)
				ctx.VG.FillRect(tabRect, Palette.Lighten(tabBg, 0.1f));

			let textColor = (i == mSelectedIndex) ? activeText : inactiveText;
			ctx.VG.DrawText(panel.Title, font, .(tabX + 8, contentH, textW, mTabHeight), .Left, .Middle, textColor);

			tabX += tabW + 2;
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

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
			mHoveredTabIndex = hovered;
	}

	public override void OnMouseLeave()
	{
		mHoveredTabIndex = -1;
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
