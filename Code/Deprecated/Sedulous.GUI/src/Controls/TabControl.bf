using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A control that displays multiple tabs with selectable content.
public class TabControl : Control
{
	// Tab collection (owned)
	private List<TabItem> mTabs = new .() ~ DeleteContainerAndItems!(_);

	// Selection state
	private int mSelectedIndex = -1;
	private int mHoveredTabIndex = -1;

	// Layout configuration
	private TabStripPlacement mTabStripPlacement = .Top;
	private float mTabStripSize = 30;  // Height for horizontal, width for vertical

	// Tab header bounds for hit testing
	private List<RectangleF> mTabHeaderBounds = new .() ~ delete _;

	// Events
	private EventAccessor<delegate void(TabControl)> mSelectionChanged = new .() ~ delete _;

	/// Creates a new TabControl.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
		for (let tab in mTabs)
			tab.OnAttachedToContext(context);
	}

	/// Applies theme defaults for tab control dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mTabStripSize = theme?.TabStripHeight ?? 30;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TabControl";

	/// Number of tabs.
	public int TabCount => mTabs.Count;

	/// The index of the selected tab. -1 if no tab is selected.
	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			var newValue = value;
			if (newValue < -1 || newValue >= mTabs.Count)
				newValue = mTabs.Count > 0 ? 0 : -1;

			if (mSelectedIndex != newValue)
			{
				// Deselect old tab
				if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
					mTabs[mSelectedIndex].IsSelected = false;

				mSelectedIndex = newValue;

				// Select new tab
				if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
					mTabs[mSelectedIndex].IsSelected = true;

				InvalidateLayout();
				mSelectionChanged.[Friend]Invoke(this);
			}
		}
	}

	/// The currently selected tab, or null if none.
	public TabItem SelectedTab
	{
		get
		{
			if (mSelectedIndex < 0 || mSelectedIndex >= mTabs.Count)
				return null;
			return mTabs[mSelectedIndex];
		}
	}

	/// Where the tab strip is positioned.
	public TabStripPlacement TabStripPlacement
	{
		get => mTabStripPlacement;
		set
		{
			if (mTabStripPlacement != value)
			{
				mTabStripPlacement = value;
				InvalidateLayout();
			}
		}
	}

	/// Event fired when selection changes.
	public EventAccessor<delegate void(TabControl)> SelectionChanged => mSelectionChanged;

	// === Tab Management ===

	/// Adds a new tab with the specified header text.
	public TabItem AddTab(StringView header)
	{
		let tab = new TabItem(header);
		AddTab(tab);
		return tab;
	}

	/// Adds a new tab with header text and content.
	public TabItem AddTab(StringView header, UIElement content)
	{
		let tab = new TabItem(header, content);
		AddTab(tab);
		return tab;
	}

	/// Adds an existing TabItem.
	public void AddTab(TabItem tab)
	{
		InsertTab(mTabs.Count, tab);
	}

	/// Inserts a tab at the specified index.
	public void InsertTab(int index, TabItem tab)
	{
		let clampedIndex = Math.Clamp(index, 0, mTabs.Count);

		tab.Index = clampedIndex;
		tab.SetParent(this);
		if (Context != null)
			tab.OnAttachedToContext(Context);

		// Subscribe to close event
		tab.CloseRequested.Subscribe(new => OnTabCloseRequested);

		mTabs.Insert(clampedIndex, tab);

		// Update indices for tabs after insertion
		for (int i = clampedIndex + 1; i < mTabs.Count; i++)
			mTabs[i].Index = i;

		// Adjust selection
		if (mSelectedIndex >= clampedIndex && mSelectedIndex >= 0)
			mSelectedIndex++;

		// Auto-select first tab
		if (mTabs.Count == 1)
			SelectedIndex = 0;

		InvalidateLayout();
	}

	/// Removes a tab.
	public bool RemoveTab(TabItem tab)
	{
		let index = mTabs.IndexOf(tab);
		if (index < 0)
			return false;
		RemoveTabAt(index);
		return true;
	}

	/// Removes the tab at the specified index.
	public void RemoveTabAt(int index)
	{
		if (index < 0 || index >= mTabs.Count)
			return;

		let tab = mTabs[index];
		mTabs.RemoveAt(index);

		// Update indices
		for (int i = index; i < mTabs.Count; i++)
			mTabs[i].Index = i;

		// Adjust selection
		if (mSelectedIndex == index)
		{
			// Select previous or next tab
			if (mTabs.Count == 0)
				mSelectedIndex = -1;
			else if (mSelectedIndex >= mTabs.Count)
				SelectedIndex = mTabs.Count - 1;
			else
				SelectedIndex = mSelectedIndex;  // Re-trigger selection on new tab at same index
		}
		else if (mSelectedIndex > index)
		{
			mSelectedIndex--;
		}

		// Clean up tab
		tab.SetParent(null);
		if (Context != null)
		{
			tab.OnDetachedFromContext();
			Context.MutationQueue.QueueDelete(tab);
		}
		else
		{
			delete tab;
		}

		InvalidateLayout();
	}

	/// Removes all tabs.
	public void ClearTabs()
	{
		for (let tab in mTabs)
		{
			tab.SetParent(null);
			if (Context != null)
			{
				tab.OnDetachedFromContext();
				Context.MutationQueue.QueueDelete(tab);
			}
			else
			{
				delete tab;
			}
		}
		mTabs.Clear();
		mSelectedIndex = -1;
		InvalidateLayout();
	}

	/// Gets the tab at the specified index.
	public TabItem GetTab(int index)
	{
		if (index < 0 || index >= mTabs.Count)
			return null;
		return mTabs[index];
	}

	// === Navigation ===

	/// Selects the next tab (wraps around).
	public void SelectNextTab()
	{
		if (mTabs.Count == 0)
			return;
		SelectedIndex = (mSelectedIndex + 1) % mTabs.Count;
	}

	/// Selects the previous tab (wraps around).
	public void SelectPreviousTab()
	{
		if (mTabs.Count == 0)
			return;
		SelectedIndex = mSelectedIndex <= 0 ? mTabs.Count - 1 : mSelectedIndex - 1;
	}

	// === Internal ===

	private void OnTabCloseRequested(TabItem tab)
	{
		RemoveTab(tab);
	}

	// === Context ===

	public override void OnDetachedFromContext()
	{
		for (let tab in mTabs)
			tab.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float tabStripWidth = 0;
		float tabStripHeight = 0;
		float maxContentWidth = 0;
		float maxContentHeight = 0;

		// Measure all tab headers
		for (let tab in mTabs)
		{
			let headerSize = tab.MeasureHeader(SizeConstraints.Unconstrained);

			if (IsHorizontalStrip)
			{
				tabStripWidth += headerSize.Width + 2;  // Spacing between tabs
				tabStripHeight = Math.Max(tabStripHeight, headerSize.Height);
			}
			else
			{
				tabStripWidth = Math.Max(tabStripWidth, headerSize.Width);
				tabStripHeight += headerSize.Height + 2;
			}

			// Measure tab content
			if (tab.Content != null)
			{
				tab.Content.Measure(constraints);
				let contentSize = tab.Content.DesiredSize;
				maxContentWidth = Math.Max(maxContentWidth, contentSize.Width);
				maxContentHeight = Math.Max(maxContentHeight, contentSize.Height);
			}
		}

		// Calculate total size
		if (IsHorizontalStrip)
		{
			let totalWidth = Math.Max(tabStripWidth, maxContentWidth);
			let totalHeight = tabStripHeight + maxContentHeight;
			return .(totalWidth, totalHeight);
		}
		else
		{
			let totalWidth = tabStripWidth + maxContentWidth;
			let totalHeight = Math.Max(tabStripHeight, maxContentHeight);
			return .(totalWidth, totalHeight);
		}
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mTabHeaderBounds.Clear();

		if (mTabs.Count == 0)
			return;

		// Calculate tab strip and content bounds
		RectangleF tabStripBounds;
		RectangleF contentAreaBounds;

		switch (mTabStripPlacement)
		{
		case .Top:
			tabStripBounds = .(contentBounds.X, contentBounds.Y, contentBounds.Width, mTabStripSize);
			contentAreaBounds = .(contentBounds.X, contentBounds.Y + mTabStripSize,
				contentBounds.Width, contentBounds.Height - mTabStripSize);
		case .Bottom:
			tabStripBounds = .(contentBounds.X, contentBounds.Bottom - mTabStripSize, contentBounds.Width, mTabStripSize);
			contentAreaBounds = .(contentBounds.X, contentBounds.Y,
				contentBounds.Width, contentBounds.Height - mTabStripSize);
		case .Left:
			tabStripBounds = .(contentBounds.X, contentBounds.Y, 100, contentBounds.Height);  // Fixed width for vertical
			contentAreaBounds = .(contentBounds.X + 100, contentBounds.Y,
				contentBounds.Width - 100, contentBounds.Height);
		case .Right:
			tabStripBounds = .(contentBounds.Right - 100, contentBounds.Y, 100, contentBounds.Height);
			contentAreaBounds = .(contentBounds.X, contentBounds.Y,
				contentBounds.Width - 100, contentBounds.Height);
		}

		// Arrange tab headers
		float offset = 0;
		for (let tab in mTabs)
		{
			let headerSize = tab.MeasureHeader(SizeConstraints.Unconstrained);
			RectangleF headerBounds;

			if (IsHorizontalStrip)
			{
				headerBounds = .(tabStripBounds.X + offset, tabStripBounds.Y, headerSize.Width, tabStripBounds.Height);
				offset += headerSize.Width + 2;
			}
			else
			{
				headerBounds = .(tabStripBounds.X, tabStripBounds.Y + offset, tabStripBounds.Width, headerSize.Height);
				offset += headerSize.Height + 2;
			}

			tab.ArrangeHeader(headerBounds);
			mTabHeaderBounds.Add(headerBounds);
		}

		// Arrange selected tab's content
		if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
		{
			let selectedTab = mTabs[mSelectedIndex];
			if (selectedTab.Content != null)
				selectedTab.Content.Arrange(contentAreaBounds);
		}
	}

	private bool IsHorizontalStrip => mTabStripPlacement == .Top || mTabStripPlacement == .Bottom;

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		RenderBackground(ctx);

		// Draw content area background
		RectangleF contentAreaBounds;
		switch (mTabStripPlacement)
		{
		case .Top:
			contentAreaBounds = .(bounds.X, bounds.Y + mTabStripSize, bounds.Width, bounds.Height - mTabStripSize);
		case .Bottom:
			contentAreaBounds = .(bounds.X, bounds.Y, bounds.Width, bounds.Height - mTabStripSize);
		case .Left:
			contentAreaBounds = .(bounds.X + 100, bounds.Y, bounds.Width - 100, bounds.Height);
		case .Right:
			contentAreaBounds = .(bounds.X, bounds.Y, bounds.Width - 100, bounds.Height);
		}

		let palette = Context?.Theme?.Palette ?? Palette();
		let contentBg = Background.A > 0 ? Background : (palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255));
		ctx.FillRect(contentAreaBounds, contentBg);

		// Draw tab strip background
		let stripBg = palette.Background.A > 0 ? palette.Background : Color(35, 35, 35, 255);
		RectangleF tabStripBounds;
		switch (mTabStripPlacement)
		{
		case .Top:
			tabStripBounds = .(bounds.X, bounds.Y, bounds.Width, mTabStripSize);
		case .Bottom:
			tabStripBounds = .(bounds.X, bounds.Bottom - mTabStripSize, bounds.Width, mTabStripSize);
		case .Left:
			tabStripBounds = .(bounds.X, bounds.Y, 100, bounds.Height);
		case .Right:
			tabStripBounds = .(bounds.Right - 100, bounds.Y, 100, bounds.Height);
		}
		ctx.FillRect(tabStripBounds, stripBg);

		// Draw tab headers
		for (int i = 0; i < mTabs.Count && i < mTabHeaderBounds.Count; i++)
		{
			let tab = mTabs[i];
			let headerBounds = mTabHeaderBounds[i];
			let isHovered = (i == mHoveredTabIndex);
			tab.RenderHeader(ctx, headerBounds, isHovered);
		}

		// Draw border between tab strip and content
		let borderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
		switch (mTabStripPlacement)
		{
		case .Top:
			ctx.DrawLine(.(bounds.X, bounds.Y + mTabStripSize), .(bounds.Right, bounds.Y + mTabStripSize), borderColor, 1);
		case .Bottom:
			ctx.DrawLine(.(bounds.X, bounds.Bottom - mTabStripSize), .(bounds.Right, bounds.Bottom - mTabStripSize), borderColor, 1);
		case .Left:
			ctx.DrawLine(.(bounds.X + 100, bounds.Y), .(bounds.X + 100, bounds.Bottom), borderColor, 1);
		case .Right:
			ctx.DrawLine(.(bounds.Right - 100, bounds.Y), .(bounds.Right - 100, bounds.Bottom), borderColor, 1);
		}

		// Draw selected tab's content
		if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
		{
			let selectedTab = mTabs[mSelectedIndex];
			if (selectedTab.Content != null)
				selectedTab.Content.Render(ctx);
		}
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		// Update hovered tab
		let newHovered = GetTabIndexAtPoint(.(e.ScreenX, e.ScreenY));
		if (newHovered != mHoveredTabIndex)
		{
			mHoveredTabIndex = newHovered;
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredTabIndex = -1;
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && !e.Handled)
		{
			let point = Vector2(e.ScreenX, e.ScreenY);
			let tabIndex = GetTabIndexAtPoint(point);

			if (tabIndex >= 0)
			{
				let tab = mTabs[tabIndex];
				let headerBounds = mTabHeaderBounds[tabIndex];

				// Check if close button was clicked
				if (tab.IsCloseable && tab.HitTestCloseButton(point, headerBounds))
				{
					tab.OnCloseButtonClicked();
				}
				else
				{
					// Select the tab
					SelectedIndex = tabIndex;
				}

				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled)
			return;

		// Ctrl+Tab / Ctrl+Shift+Tab for tab cycling
		if (e.Key == .Tab && e.HasModifier(.Ctrl))
		{
			if (e.HasModifier(.Shift))
				SelectPreviousTab();
			else
				SelectNextTab();
			e.Handled = true;
		}
		// Left/Right arrows for horizontal, Up/Down for vertical
		else if (IsHorizontalStrip)
		{
			if (e.Key == .Left)
			{
				SelectPreviousTab();
				e.Handled = true;
			}
			else if (e.Key == .Right)
			{
				SelectNextTab();
				e.Handled = true;
			}
		}
		else
		{
			if (e.Key == .Up)
			{
				SelectPreviousTab();
				e.Handled = true;
			}
			else if (e.Key == .Down)
			{
				SelectNextTab();
				e.Handled = true;
			}
		}
	}

	private int GetTabIndexAtPoint(Vector2 point)
	{
		for (int i = 0; i < mTabHeaderBounds.Count; i++)
		{
			if (mTabHeaderBounds[i].Contains(point.X, point.Y))
				return i;
		}
		return -1;
	}

	// === Visual Children ===

	public override int VisualChildCount => mTabs.Count;

	public override UIElement GetVisualChild(int index)
	{
		if (index >= 0 && index < mTabs.Count)
			return mTabs[index];
		return null;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check if in content area and selected tab has interactive content
		if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
		{
			let selectedTab = mTabs[mSelectedIndex];
			if (selectedTab.Content != null)
			{
				let hit = selectedTab.Content.HitTest(point);
				if (hit != null)
					return hit;
			}
		}

		return this;
	}
}
