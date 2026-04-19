namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Where the tab headers are placed relative to content.
public enum TabPlacement { Top, Bottom, Left, Right }

/// Tabbed container. Tab headers drawn as a strip; only the selected
/// tab's content is visible. Supports Top/Bottom/Left/Right placement.
public class TabView : ViewGroup
{
	private struct TabItem
	{
		public String Title;
		public View Content;
		public bool IsClosable;
	}

	private List<TabItem> mTabs = new .() ~ {
		for (var tab in _) delete tab.Title;
		delete _;
	};
	private int mSelectedIndex = -1;
	private int mHoveredTabIndex = -1;
	private List<RectangleF> mTabRects = new .() ~ delete _;

	public TabPlacement Placement = .Top;
	public float TabHeight = 32;
	public float TabFontSize = 14;
	public float TabPadding = 16;
	public float MinTabWidth = 50;

	public Event<delegate void(TabView, int)> OnTabChanged ~ _.Dispose();

	/// Fired when a closable tab's close button is clicked. Args: (tabView, index).
	/// The handler should call RemoveTab(index) to actually close it.
	public Event<delegate void(TabView, int)> OnTabCloseRequested ~ _.Dispose();

	/// Size of the close button in the tab header.
	public float CloseButtonSize = 14;

	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			var val = Math.Clamp(value, -1, mTabs.Count - 1);
			if (mSelectedIndex != val)
			{
				if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
					mTabs[mSelectedIndex].Content.Visibility = .Gone;
				mSelectedIndex = val;
				if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
					mTabs[mSelectedIndex].Content.Visibility = .Visible;
				InvalidateLayout();
				OnTabChanged(this, val);
			}
		}
	}

	public int TabCount => mTabs.Count;

	public this()
	{
		IsFocusable = true;
		ClipsContent = true;
	}

	/// Add a tab with title and content view. Returns the tab index.
	public int AddTab(StringView title, View content, bool closable = false)
	{
		TabItem tab;
		tab.Title = new String(title);
		tab.Content = content;
		tab.IsClosable = closable;

		let index = mTabs.Count;
		mTabs.Add(tab);

		content.Visibility = .Gone;
		AddView(content);

		if (mSelectedIndex == -1)
			SelectedIndex = 0;

		return index;
	}

	/// Remove a tab by index.
	public void RemoveTab(int index)
	{
		if (index < 0 || index >= mTabs.Count) return;

		let tab = mTabs[index];
		RemoveView(tab.Content);
		delete tab.Title;
		mTabs.RemoveAt(index);

		if (mSelectedIndex >= mTabs.Count)
			SelectedIndex = mTabs.Count - 1;
		else if (mSelectedIndex == index)
		{
			mSelectedIndex = -1;
			SelectedIndex = Math.Min(index, mTabs.Count - 1);
		}
	}

	private bool IsHorizontalStrip => Placement == .Top || Placement == .Bottom;

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float contentW = 0, contentH = 0;

		if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
		{
			let content = mTabs[mSelectedIndex].Content;
			if (content.Visibility != .Gone)
			{
				if (IsHorizontalStrip)
				{
					let childH = (hSpec.Mode == .Exactly || hSpec.Mode == .AtMost)
						? MeasureSpec.AtMost(Math.Max(0, hSpec.Size - TabHeight))
						: MeasureSpec.Unspecified();
					content.Measure(wSpec, childH);
				}
				else
				{
					let stripW = ComputeVerticalStripWidth();
					let childW = (wSpec.Mode == .Exactly || wSpec.Mode == .AtMost)
						? MeasureSpec.AtMost(Math.Max(0, wSpec.Size - stripW))
						: MeasureSpec.Unspecified();
					content.Measure(childW, hSpec);
				}
				contentW = content.MeasuredSize.X;
				contentH = content.MeasuredSize.Y;
			}
		}

		if (IsHorizontalStrip)
			MeasuredSize = .(wSpec.Resolve(contentW), hSpec.Resolve(TabHeight + contentH));
		else
		{
			let stripW = ComputeVerticalStripWidth();
			MeasuredSize = .(wSpec.Resolve(stripW + contentW), hSpec.Resolve(contentH));
		}
	}

	private float ComputeVerticalStripWidth()
	{
		float maxTextW = 0;
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(TabFontSize);
			if (font != null)
			{
				for (let tab in mTabs)
				{
					let tw = font.Font.MeasureString(tab.Title);
					if (tw > maxTextW) maxTextW = tw;
				}
			}
		}
		return Math.Max(MinTabWidth, maxTextW + TabPadding * 2);
	}

	// === Layout ===

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (mSelectedIndex < 0 || mSelectedIndex >= mTabs.Count) return;
		let content = mTabs[mSelectedIndex].Content;
		if (content.Visibility == .Gone) return;

		let w = right - left;
		let h = bottom - top;

		switch (Placement)
		{
		case .Top:
			content.Measure(.Exactly(w), .Exactly(Math.Max(0, h - TabHeight)));
			content.Layout(0, TabHeight, w, Math.Max(0, h - TabHeight));
		case .Bottom:
			content.Measure(.Exactly(w), .Exactly(Math.Max(0, h - TabHeight)));
			content.Layout(0, 0, w, Math.Max(0, h - TabHeight));
		case .Left:
			let sw = ComputeVerticalStripWidth();
			let cw = Math.Max(0, w - sw);
			content.Measure(.Exactly(cw), .Exactly(h));
			content.Layout(sw, 0, cw, h);
		case .Right:
			let sw2 = ComputeVerticalStripWidth();
			let cw2 = Math.Max(0, w - sw2);
			content.Measure(.Exactly(cw2), .Exactly(h));
			content.Layout(0, 0, cw2, h);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		RebuildTabRects(ctx);

		let palette = ctx.Theme?.Palette ?? Palette();
		let stripBg = ctx.Theme?.GetColor("TabView.StripBackground") ?? Palette.Darken(palette.Surface, 0.15f);
		let contentBg = ctx.Theme?.GetColor("TabView.ContentBackground") ?? palette.Surface;
		let activeTabBg = ctx.Theme?.GetColor("TabView.ActiveTabBackground") ?? palette.Surface;
		let activeTabText = ctx.Theme?.GetColor("TabView.ActiveTabText") ?? palette.Text;
		let inactiveTabText = ctx.Theme?.GetColor("TabView.InactiveTabText") ?? .(palette.Text.R, palette.Text.G, palette.Text.B, 153);
		let hoverTabText = ctx.Theme?.GetColor("TabView.HoverTabText") ?? palette.Text;
		let hoverBg = ctx.Theme?.GetColor("TabView.TabHover") ?? .(palette.PrimaryAccent.R, palette.PrimaryAccent.G, palette.PrimaryAccent.B, 30);
		let accentColor = palette.PrimaryAccent;
		let borderColor = ctx.Theme?.GetColor("TabView.Border") ?? palette.Border;

		// Content area background.
		RectangleF contentRect;
		float stripSize = IsHorizontalStrip ? TabHeight : ComputeVerticalStripWidth();
		switch (Placement)
		{
		case .Top:    contentRect = .(0, TabHeight, Width, Height - TabHeight);
		case .Bottom: contentRect = .(0, 0, Width, Height - TabHeight);
		case .Left:   contentRect = .(stripSize, 0, Width - stripSize, Height);
		case .Right:  contentRect = .(0, 0, Width - stripSize, Height);
		}
		if (!ctx.TryDrawDrawable("TabView.ContentBackground", contentRect, GetControlState()))
			ctx.VG.FillRect(contentRect, contentBg);

		// Strip background.
		RectangleF stripRect;
		switch (Placement)
		{
		case .Top:    stripRect = .(0, 0, Width, TabHeight);
		case .Bottom: stripRect = .(0, Height - TabHeight, Width, TabHeight);
		case .Left:   stripRect = .(0, 0, stripSize, Height);
		case .Right:  stripRect = .(Width - stripSize, 0, stripSize, Height);
		}
		if (!ctx.TryDrawDrawable("TabView.StripBackground", stripRect, GetControlState()))
			ctx.VG.FillRect(stripRect, stripBg);

		// Border between strip and content.
		switch (Placement)
		{
		case .Top:    ctx.VG.FillRect(.(0, TabHeight - 1, Width, 1), borderColor);
		case .Bottom: ctx.VG.FillRect(.(0, Height - TabHeight, Width, 1), borderColor);
		case .Left:   ctx.VG.FillRect(.(stripSize - 1, 0, 1, Height), borderColor);
		case .Right:  ctx.VG.FillRect(.(Width - stripSize, 0, 1, Height), borderColor);
		}

		// Draw tabs.
		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(TabFontSize);
			if (font != null)
			{
				for (int i = 0; i < mTabs.Count && i < mTabRects.Count; i++)
				{
					let tab = mTabs[i];
					let rect = mTabRects[i];
					let isActive = (i == mSelectedIndex);
					let isHover = (i == mHoveredTabIndex && !isActive);

					// Tab background.
					if (isActive)
					{
						if (!ctx.TryDrawDrawable("TabView.ActiveTab", rect, .Normal))
						{
							ctx.VG.FillRect(rect, activeTabBg);
							// Accent indicator (only in color fallback — drawable handles its own styling).
							switch (Placement)
							{
							case .Top:    ctx.VG.FillRect(.(rect.X, rect.Y + rect.Height - 2, rect.Width, 2), accentColor);
							case .Bottom: ctx.VG.FillRect(.(rect.X, rect.Y, rect.Width, 2), accentColor);
							case .Left:   ctx.VG.FillRect(.(rect.X + rect.Width - 2, rect.Y, 2, rect.Height), accentColor);
							case .Right:  ctx.VG.FillRect(.(rect.X, rect.Y, 2, rect.Height), accentColor);
							}
						}
					}
					else if (isHover)
					{
						if (!ctx.TryDrawDrawable("TabView.InactiveTab", rect, .Hover))
							ctx.VG.FillRect(rect, hoverBg);
					}

					// Tab text (shift left if closable to make room for X button).
					let textColor = isActive ? activeTabText : (isHover ? hoverTabText : inactiveTabText);
					var textRect = rect;
					if (tab.IsClosable)
						textRect.Width -= CloseButtonSize + 4;
					ctx.VG.DrawText(tab.Title, font, textRect, .Center, .Middle, textColor);

					// Close button (X).
					if (tab.IsClosable)
					{
						let btnSize = CloseButtonSize;
						let btnX = rect.X + rect.Width - btnSize - 4;
						let btnY = rect.Y + (rect.Height - btnSize) * 0.5f;
						let closeRect = RectangleF(btnX, btnY, btnSize, btnSize);
						let closeState = (isHover && i == mHoveredTabIndex) ? ControlState.Hover : ControlState.Normal;

						if (!ctx.TryDrawDrawable("TabView.CloseIcon", closeRect, closeState))
						{
							let cx = btnX + btnSize * 0.5f;
							let cy = btnY + btnSize * 0.5f;
							let sz = btnSize * 0.25f;
							let closeColor = isHover ? activeTabText : inactiveTabText;
							ctx.VG.DrawLine(.(cx - sz, cy - sz), .(cx + sz, cy + sz), closeColor, 1.5f);
							ctx.VG.DrawLine(.(cx + sz, cy - sz), .(cx - sz, cy + sz), closeColor, 1.5f);
						}
					}
				}
			}
		}

		// Draw selected content.
		DrawChildren(ctx);
	}

	private void RebuildTabRects(UIDrawContext ctx)
	{
		mTabRects.Clear();

		if (IsHorizontalStrip)
		{
			let stripY = (Placement == .Top) ? 0 : Height - TabHeight;
			float x = 0;

			if (ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(TabFontSize);
				if (font != null)
				{
					for (let tab in mTabs)
					{
						let textW = font.Font.MeasureString(tab.Title);
						var tabW = textW + TabPadding * 2;
						if (tab.IsClosable) tabW += CloseButtonSize + 4;
						tabW = Math.Max(MinTabWidth, tabW);
						mTabRects.Add(.(x, stripY, tabW, TabHeight));
						x += tabW;
					}
				}
			}
		}
		else
		{
			let stripW = ComputeVerticalStripWidth();
			let stripX = (Placement == .Left) ? 0 : Width - stripW;
			float y = 0;

			for (int i = 0; i < mTabs.Count; i++)
			{
				mTabRects.Add(.(stripX, y, stripW, TabHeight));
				y += TabHeight;
			}
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		let tabIndex = GetTabIndexAtPoint(e.X, e.Y);
		if (tabIndex >= 0)
		{
			// Check close button first.
			if (tabIndex < mTabs.Count && mTabs[tabIndex].IsClosable &&
				HitTestCloseButton(tabIndex, e.X, e.Y))
			{
				OnTabCloseRequested(this, tabIndex);
				e.Handled = true;
				return;
			}

			SelectedIndex = tabIndex;
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		mHoveredTabIndex = GetTabIndexAtPoint(e.X, e.Y);
	}

	public override void OnMouseLeave()
	{
		mHoveredTabIndex = -1;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled || mTabs.Count == 0) return;

		bool prev = IsHorizontalStrip ? (e.Key == .Left) : (e.Key == .Up);
		bool next = IsHorizontalStrip ? (e.Key == .Right) : (e.Key == .Down);

		if (prev && mSelectedIndex > 0) { SelectedIndex = mSelectedIndex - 1; e.Handled = true; }
		else if (next && mSelectedIndex < mTabs.Count - 1) { SelectedIndex = mSelectedIndex + 1; e.Handled = true; }
	}

	private bool HitTestCloseButton(int tabIndex, float localX, float localY)
	{
		if (tabIndex < 0 || tabIndex >= mTabRects.Count) return false;
		let r = mTabRects[tabIndex];
		let btnSize = CloseButtonSize;
		let btnX = r.X + r.Width - btnSize - 4;
		let btnY = r.Y + (r.Height - btnSize) * 0.5f;
		return localX >= btnX && localX <= btnX + btnSize &&
			localY >= btnY && localY <= btnY + btnSize;
	}

	private int GetTabIndexAtPoint(float localX, float localY)
	{
		for (int i = 0; i < mTabRects.Count; i++)
		{
			let r = mTabRects[i];
			if (localX >= r.X && localX < r.X + r.Width &&
				localY >= r.Y && localY < r.Y + r.Height)
				return i;
		}
		return -1;
	}
}
