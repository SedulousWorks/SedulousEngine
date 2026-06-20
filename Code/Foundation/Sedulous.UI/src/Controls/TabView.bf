namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Tab header placement.
public enum TabPlacement { Top, Bottom, Left, Right }

/// Tabbed container with clickable tab headers and switchable content.
public class TabView : ViewGroup
{
	private struct TabItem
	{
		public String Title;
		public View Content;
		public bool IsClosable;
	}

	private List<TabItem> mTabs = new .();
	private int32 mSelectedIndex = -1;
	private int32 mHoveredTabIndex = -1;
	private List<RectangleF> mTabRects = new .() ~ delete _;

	/// Height of tab headers (horizontal placement) or width (vertical).
	public Property<float> TabHeight = new .(28) ~ delete _;

	/// Where the tab strip appears.
	public Property<TabPlacement> Placement = new .(.Top) ~ delete _;

	/// Whether tabs can be closed.
	public Property<bool> TabsClosable = new .(false) ~ delete _;

	/// Size of close button icon.
	public Property<float> CloseButtonSize = new .(12) ~ delete _;

	/// Currently selected tab index.
	public int32 SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			if (value == mSelectedIndex) return;
			if (value < 0 || value >= mTabs.Count) return;

			// Hide old, show new
			if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
				mTabs[mSelectedIndex].Content.Visibility = .Gone;

			mSelectedIndex = value;
			mTabs[mSelectedIndex].Content.Visibility = .Visible;
			Invalidate();
			OnTabChanged(this, mSelectedIndex);
		}
	}

	public int TabCount => mTabs.Count;

	/// Fired when selected tab changes.
	public Event<delegate void(TabView, int32)> OnTabChanged ~ _.Dispose();

	/// Fired when a tab's close button is clicked. Handler should call RemoveTab.
	public Event<delegate void(TabView, int32)> OnTabCloseRequested ~ _.Dispose();

	/// Minimum width for each tab header.
	public Property<float> MinTabWidth = new .(50) ~ delete _;

	public this()
	{
		IsFocusable = true;
		ClipsContent = true;
		TabHeight.SetOwner(this);
		Placement.SetOwner(this);
		TabsClosable.SetOwner(this, .Visual);
		CloseButtonSize.SetOwner(this, .Visual);
		MinTabWidth.SetOwner(this);
		WantsArrowKeys = true;
	}

	/// Add a tab with title and content view. Returns the index of the added tab.
	public int32 AddTab(StringView title, View content, bool closable = false)
	{
		var item = TabItem();
		item.Title = new String(title);
		item.Content = content;
		item.IsClosable = closable || TabsClosable.Value;
		mTabs.Add(item);

		let index = (int32)(mTabs.Count - 1);
		content.Visibility = .Gone;
		AddView(content);

		if (mSelectedIndex < 0)
			SelectedIndex = 0;

		return index;
	}

	/// Remove a tab by index.
	public void RemoveTab(int32 index)
	{
		if (index < 0 || index >= mTabs.Count) return;

		let item = mTabs[index];
		RemoveView(item.Content, true);
		delete item.Title;
		mTabs.RemoveAt(index);

		if (mSelectedIndex >= mTabs.Count)
			mSelectedIndex = (int32)mTabs.Count - 1;
		if (mSelectedIndex >= 0)
			mTabs[mSelectedIndex].Content.Visibility = .Visible;

		Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Compute space available for content after tab strip
		BoxConstraints contentConstraints;
		if (Placement.Value == .Top || Placement.Value == .Bottom)
			contentConstraints = constraints.Deflate(.(0, TabHeight.Value, 0, 0));
		else
			contentConstraints = constraints.Deflate(.(ComputeStripWidth(), 0, 0, 0));

		// Measure selected content with correct available space
		float contentW = 0, contentH = 0;
		if (mSelectedIndex >= 0 && mSelectedIndex < mTabs.Count)
		{
			let content = mTabs[mSelectedIndex].Content;
			if (content.Visibility != .Gone)
			{
				content.Measure(contentConstraints);
				contentW = content.MeasuredSize.X;
				contentH = content.MeasuredSize.Y;
			}
		}

		if (Placement.Value == .Top || Placement.Value == .Bottom)
			MeasuredSize = .(constraints.ConstrainWidth(contentW), constraints.ConstrainHeight(contentH + TabHeight.Value));
		else
			MeasuredSize = .(constraints.ConstrainWidth(contentW + ComputeStripWidth()), constraints.ConstrainHeight(contentH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mSelectedIndex < 0 || mSelectedIndex >= mTabs.Count) return;

		let content = mTabs[mSelectedIndex].Content;
		if (content.Visibility == .Gone) return;

		switch (Placement.Value)
		{
		case .Top:
			content.Layout(0, TabHeight.Value, width, Math.Max(0, height - TabHeight.Value));
		case .Bottom:
			content.Layout(0, 0, width, Math.Max(0, height - TabHeight.Value));
		case .Left:
			let stripW = ComputeStripWidth();
			content.Layout(stripW, 0, Math.Max(0, width - stripW), height);
		case .Right:
			let stripW = ComputeStripWidth();
			content.Layout(0, 0, Math.Max(0, width - stripW), height);
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		RebuildTabRects();

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);

		let controlState = GetControlState();

		// Resolve pseudo-element drawables for visual regions
		let stripDrawable = ResolvePartDrawable("strip", .Background, controlState);
		let contentDrawable = ResolvePartDrawable("content", .Background, controlState);

		// Element-level colors
		let borderColor = ResolveStyleColor(.BorderColor, .(60, 65, 80, 255));
		let accentColor = ResolveStyleColor(.AccentColor, .(80, 150, 240, 255));

		// Draw strip and content backgrounds using drawables
		// Content uses placement-aware corner masking so rounding only appears on outer edges.
		switch (Placement.Value)
		{
		case .Top:
			DrawRegion(ctx, stripDrawable, .(0, 0, Width, TabHeight.Value));
			DrawContentRegion(ctx, contentDrawable, .(0, TabHeight.Value, Width, Height - TabHeight.Value));
			ctx.VG.DrawLine(.(0, TabHeight.Value), .(Width, TabHeight.Value), borderColor, 1);
		case .Bottom:
			DrawContentRegion(ctx, contentDrawable, .(0, 0, Width, Height - TabHeight.Value));
			DrawRegion(ctx, stripDrawable, .(0, Height - TabHeight.Value, Width, TabHeight.Value));
			ctx.VG.DrawLine(.(0, Height - TabHeight.Value), .(Width, Height - TabHeight.Value), borderColor, 1);
		case .Left:
			let stripW = ComputeStripWidth();
			DrawRegion(ctx, stripDrawable, .(0, 0, stripW, Height));
			DrawContentRegion(ctx, contentDrawable, .(stripW, 0, Width - stripW, Height));
			ctx.VG.DrawLine(.(stripW, 0), .(stripW, Height), borderColor, 1);
		case .Right:
			let stripW = ComputeStripWidth();
			let stripX = Width - stripW;
			DrawContentRegion(ctx, contentDrawable, .(0, 0, stripX, Height));
			DrawRegion(ctx, stripDrawable, .(stripX, 0, stripW, Height));
			ctx.VG.DrawLine(.(stripX, 0), .(stripX, Height), borderColor, 1);
		}

		// Draw tab headers
		for (int i = 0; i < mTabs.Count; i++)
		{
			if (i >= mTabRects.Count) break;
			let rect = mTabRects[i];
			let isActive = i == mSelectedIndex;
			let isHovered = i == mHoveredTabIndex;

			// Tab background via pseudo-element: selected=Checked, hovered=Hover
			{
				var tabState = ControlState.Normal;
				if (isActive) tabState |= .Checked;
				if (isHovered) tabState |= .Hover;
				let tabDrawable = ResolvePartDrawable("tab", .Background, tabState);
				if (tabDrawable != null)
					DrawTabRegion(ctx, tabDrawable, rect);
			}

			// Active indicator bar
			if (isActive)
			{
				switch (Placement.Value)
				{
				case .Top:    ctx.VG.FillRect(.(rect.X, rect.Y + rect.Height - 2, rect.Width, 2), accentColor);
				case .Bottom: ctx.VG.FillRect(.(rect.X, rect.Y, rect.Width, 2), accentColor);
				case .Left:   ctx.VG.FillRect(.(rect.X + rect.Width - 2, rect.Y, 2, rect.Height), accentColor);
				case .Right:  ctx.VG.FillRect(.(rect.X, rect.Y, 2, rect.Height), accentColor);
				}
			}

			// Tab text — resolve color from pseudo-element
			if (font != null)
			{
				var tabState = ControlState.Normal;
				if (isActive) tabState |= .Checked;
				if (isHovered) tabState |= .Hover;
				let textColor = ResolvePartColor("tab", .TextColor, tabState,
					isActive ? .(240, 240, 245, 255) : (isHovered ? .(200, 205, 215, 255) : .(140, 145, 160, 255)));
				var textRect = rect;
				textRect.X += 8;
				textRect.Width -= 16;
				if (mTabs[i].IsClosable)
					textRect.Width -= ResolvePartFloat("close-button", .Width, controlState, 12) + 4;
				ctx.VG.DrawText(mTabs[i].Title, font, textRect, .Left, .Middle, textColor);
			}

			// Close button
			if (mTabs[i].IsClosable)
			{
				let cbSize = ResolvePartFloat("close-button", .Width, controlState, 12);
				let cbX = rect.X + rect.Width - cbSize - 4;
				let cbY = rect.Y + (rect.Height - cbSize) * 0.5f;
				var cbState = ControlState.Normal;
				if (isActive || isHovered) cbState |= .Hover;
				let cbColor = ResolvePartColor("close-button", .TextColor, cbState, .(120, 125, 140, 255));
				let closeIcon = ResolvePartDrawable("close-button", .Background, cbState);
				if (closeIcon != null)
				{
					ctx.VG.PushOpacity(cbColor.A);
					closeIcon.Draw(ctx, .(cbX, cbY, cbSize, cbSize));
					ctx.VG.PopOpacity();
				}
				else if (font != null)
				{
					// VG fallback
					ctx.VG.DrawText("x", font, .(cbX, rect.Y, cbSize, rect.Height), .Center, .Middle, cbColor);
				}
			}
		}

		// Draw selected content
		DrawChildren(ctx);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left) return;

		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		for (int i = 0; i < mTabs.Count; i++)
		{
			if (i >= mTabRects.Count) break;
			let rect = mTabRects[i];
			if (local.X >= rect.X && local.X < rect.X + rect.Width &&
				local.Y >= rect.Y && local.Y < rect.Y + rect.Height)
			{
				// Check close button
				if (mTabs[i].IsClosable)
				{
					let cbSize = CloseButtonSize.Value;
					let cbX = rect.X + rect.Width - cbSize - 4;
					let cbY = rect.Y + (rect.Height - cbSize) * 0.5f;
					if (local.X >= cbX && local.X <= cbX + cbSize &&
						local.Y >= cbY && local.Y <= cbY + cbSize)
					{
						OnTabCloseRequested(this, (int32)i);
						e.Handled = true;
						return;
					}
				}

				SelectedIndex = (int32)i;
				e.Handled = true;
				return;
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		int32 newHovered = -1;
		for (int i = 0; i < mTabs.Count; i++)
		{
			if (i >= mTabRects.Count) break;
			let rect = mTabRects[i];
			if (local.X >= rect.X && local.X < rect.X + rect.Width &&
				local.Y >= rect.Y && local.Y < rect.Y + rect.Height)
			{
				newHovered = (int32)i;
				break;
			}
		}

		if (newHovered != mHoveredTabIndex)
		{
			mHoveredTabIndex = newHovered;
			Invalidate();
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mTabs.Count == 0) return;

		switch (e.Key)
		{
		case .Left:
			if (mSelectedIndex > 0) SelectedIndex = mSelectedIndex - 1;
			e.Handled = true;
		case .Right:
			if (mSelectedIndex < mTabs.Count - 1) SelectedIndex = mSelectedIndex + 1;
			e.Handled = true;
		default:
			// Up/Down not handled — falls through to directional focus navigation
		}
	}

	// === Internal ===

	private void RebuildTabRects()
	{
		mTabRects.Clear();

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context?.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);

		if (Placement.Value == .Top || Placement.Value == .Bottom)
		{
			let stripY = (Placement.Value == .Top) ? 0.0f : Height - TabHeight.Value;
			float xPos = 0;
			for (let tab in mTabs)
			{
				float tabW = 80; // default width
				if (font != null)
					tabW = font.Font.MeasureString(tab.Title) + 24;
				if (tab.IsClosable)
					tabW += CloseButtonSize.Value + 4;
				tabW = Math.Max(MinTabWidth.Value, tabW);
				mTabRects.Add(.(xPos, stripY, tabW, TabHeight.Value));
				xPos += tabW;
			}
		}
		else
		{
			let stripW = ComputeStripWidth();
			let stripX = (Placement.Value == .Left) ? 0.0f : Width - stripW;
			float yPos = 0;
			for (let tab in mTabs)
			{
				mTabRects.Add(.(stripX, yPos, stripW, TabHeight.Value));
				yPos += TabHeight.Value;
			}
		}
	}

	private float ComputeStripWidth()
	{
		if (Placement.Value == .Top || Placement.Value == .Bottom) return 0;

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context?.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null) return 100;

		float maxW = 0;
		for (let tab in mTabs)
		{
			let w = font.Font.MeasureString(tab.Title);
			maxW = Math.Max(maxW, w);
		}
		return maxW + 24 + (TabsClosable.Value ? CloseButtonSize.Value + 4 : 0);
	}

	/// Draw a visual region with a drawable. Falls back to a dark rect if null.
	private static void DrawRegion(UIDrawContext ctx, Drawable drawable, RectangleF bounds)
	{
		if (drawable != null)
			drawable.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, .(42, 44, 54, 255)); // fallback
	}

	/// Draw a drawable with adjusted corner radii for tab placement.
	/// For RoundedRectDrawable, zeroes corners on the edge facing the content.
	private void DrawTabRegion(UIDrawContext ctx, Drawable drawable, RectangleF bounds)
	{
		if (drawable == null)
		{
			ctx.VG.FillRect(bounds, .(42, 44, 54, 255));
			return;
		}

		if (let rrd = drawable as RoundedRectDrawable)
		{
			let saved = rrd.Radii;
			rrd.Radii = MaskRadiiForTab(saved);
			rrd.Draw(ctx, bounds);
			rrd.Radii = saved;
		}
		else
		{
			drawable.Draw(ctx, bounds);
		}
	}

	/// Draw a drawable with adjusted corner radii for the content area.
	/// Zeroes corners on the edge adjacent to the tab strip.
	private void DrawContentRegion(UIDrawContext ctx, Drawable drawable, RectangleF bounds)
	{
		if (drawable == null)
		{
			ctx.VG.FillRect(bounds, .(42, 44, 54, 255));
			return;
		}

		if (let rrd = drawable as RoundedRectDrawable)
		{
			let saved = rrd.Radii;
			rrd.Radii = MaskRadiiForContent(saved);
			rrd.Draw(ctx, bounds);
			rrd.Radii = saved;
		}
		else
		{
			drawable.Draw(ctx, bounds);
		}
	}

	/// Zero out corners on the side where tabs meet content.
	private CornerRadii MaskRadiiForTab(CornerRadii radii)
	{
		switch (Placement.Value)
		{
		case .Top:    return .(radii.TopLeft, radii.TopRight, 0, 0);
		case .Bottom: return .(0, 0, radii.BottomRight, radii.BottomLeft);
		case .Left:   return .(radii.TopLeft, 0, 0, radii.BottomLeft);
		case .Right:  return .(0, radii.TopRight, radii.BottomRight, 0);
		}
	}

	/// Zero out corners on the side adjacent to the tab strip.
	private CornerRadii MaskRadiiForContent(CornerRadii radii)
	{
		switch (Placement.Value)
		{
		case .Top:    return .(0, 0, radii.BottomRight, radii.BottomLeft);
		case .Bottom: return .(radii.TopLeft, radii.TopRight, 0, 0);
		case .Left:   return .(0, radii.TopRight, radii.BottomRight, 0);
		case .Right:  return .(radii.TopLeft, 0, 0, radii.BottomLeft);
		}
	}

	public ~this()
	{
		for (var tab in mTabs)
			delete tab.Title;
		delete mTabs;
	}
}
