namespace Sedulous.GUI;

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
	public float TabHeight = 28;

	/// Where the tab strip appears.
	public TabPlacement Placement = .Top;

	/// Whether tabs can be closed.
	public bool TabsClosable = false;

	/// Size of close button icon.
	public float CloseButtonSize = 12;

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
	public float MinTabWidth = 50;

	public this()
	{
		IsFocusable = true;
		ClipsContent = true;
	}

	/// Add a tab with title and content view. Returns the index of the added tab.
	public int32 AddTab(StringView title, View content, bool closable = false)
	{
		var item = TabItem();
		item.Title = new String(title);
		item.Content = content;
		item.IsClosable = closable || TabsClosable;
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
		if (Placement == .Top || Placement == .Bottom)
			contentConstraints = constraints.Deflate(.(0, TabHeight, 0, 0));
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

		if (Placement == .Top || Placement == .Bottom)
			MeasuredSize = .(constraints.ConstrainWidth(contentW), constraints.ConstrainHeight(contentH + TabHeight));
		else
			MeasuredSize = .(constraints.ConstrainWidth(contentW + ComputeStripWidth()), constraints.ConstrainHeight(contentH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mSelectedIndex < 0 || mSelectedIndex >= mTabs.Count) return;

		let content = mTabs[mSelectedIndex].Content;
		if (content.Visibility == .Gone) return;

		switch (Placement)
		{
		case .Top:
			content.Layout(0, TabHeight, width, Math.Max(0, height - TabHeight));
		case .Bottom:
			content.Layout(0, 0, width, Math.Max(0, height - TabHeight));
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
		let font = ctx.FontService?.GetFont(fontSize);

		// Resolve drawables for visual regions, colors for text/strokes
		let stripDrawable = ResolveStyleDrawable(.StripDrawable);
		let contentDrawable = ResolveStyleDrawable(.ContentDrawable);
		let activeTabDrawable = ResolveStyleDrawable(.ActiveTabDrawable);
		let hoverTabDrawable = ResolveStyleDrawable(.HoverTabDrawable);
		let borderColor = ResolveStyleColor(.BorderColor, .(60, 65, 80, 255));
		let accentColor = ResolveStyleColor(.AccentColor, .(80, 150, 240, 255));
		let activeTextColor = ResolveStyleColor(.ActiveTabTextColor, .(240, 240, 245, 255));
		let inactiveTextColor = ResolveStyleColor(.InactiveTabTextColor, .(140, 145, 160, 255));
		let hoverTextColor = ResolveStyleColor(.HoverTabTextColor, .(200, 205, 215, 255));
		let cbActiveColor = ResolveStyleColor(.CloseButtonHoverColor, .(200, 200, 210, 255));
		let cbInactiveColor = ResolveStyleColor(.CloseButtonColor, .(120, 125, 140, 255));

		// Draw strip and content backgrounds using drawables
		// Content uses placement-aware corner masking so rounding only appears on outer edges.
		switch (Placement)
		{
		case .Top:
			DrawRegion(ctx, stripDrawable, .(0, 0, Width, TabHeight));
			DrawContentRegion(ctx, contentDrawable, .(0, TabHeight, Width, Height - TabHeight));
			ctx.VG.DrawLine(.(0, TabHeight), .(Width, TabHeight), borderColor, 1);
		case .Bottom:
			DrawContentRegion(ctx, contentDrawable, .(0, 0, Width, Height - TabHeight));
			DrawRegion(ctx, stripDrawable, .(0, Height - TabHeight, Width, TabHeight));
			ctx.VG.DrawLine(.(0, Height - TabHeight), .(Width, Height - TabHeight), borderColor, 1);
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

			// Tab background - corners adjusted for placement
			if (isActive)
				DrawTabRegion(ctx, activeTabDrawable, rect);
			else if (isHovered)
				DrawTabRegion(ctx, hoverTabDrawable, rect);

			// Active indicator bar
			if (isActive)
			{
				switch (Placement)
				{
				case .Top:    ctx.VG.FillRect(.(rect.X, rect.Y + rect.Height - 2, rect.Width, 2), accentColor);
				case .Bottom: ctx.VG.FillRect(.(rect.X, rect.Y, rect.Width, 2), accentColor);
				case .Left:   ctx.VG.FillRect(.(rect.X + rect.Width - 2, rect.Y, 2, rect.Height), accentColor);
				case .Right:  ctx.VG.FillRect(.(rect.X, rect.Y, 2, rect.Height), accentColor);
				}
			}

			// Tab text
			if (font != null)
			{
				let textColor = isActive ? activeTextColor : (isHovered ? hoverTextColor : inactiveTextColor);
				var textRect = rect;
				textRect.X += 8;
				textRect.Width -= 16;
				if (mTabs[i].IsClosable)
					textRect.Width -= CloseButtonSize + 4;
				ctx.VG.DrawText(mTabs[i].Title, font, textRect, .Left, .Middle, textColor);
			}

			// Close button
			if (mTabs[i].IsClosable)
			{
				let cbSize = CloseButtonSize;
				let cbX = rect.X + rect.Width - cbSize - 4;
				let cbY = rect.Y + (rect.Height - cbSize) * 0.5f;
				let cbColor = (isActive || isHovered) ? cbActiveColor : cbInactiveColor;
				let closeIcon = ResolveStyleDrawable(.CloseIcon);
				if (closeIcon != null)
				{
					ctx.VG.PushOpacity(cbColor.A / 255.0f);
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
					let cbSize = CloseButtonSize;
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
		case .Left, .Up:
			if (mSelectedIndex > 0) SelectedIndex = mSelectedIndex - 1;
			e.Handled = true;
		case .Right, .Down:
			if (mSelectedIndex < mTabs.Count - 1) SelectedIndex = mSelectedIndex + 1;
			e.Handled = true;
		default:
		}
	}

	// === Internal ===

	private void RebuildTabRects()
	{
		mTabRects.Clear();

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context?.FontService?.GetFont(fontSize);

		if (Placement == .Top || Placement == .Bottom)
		{
			let stripY = (Placement == .Top) ? 0.0f : Height - TabHeight;
			float xPos = 0;
			for (let tab in mTabs)
			{
				float tabW = 80; // default width
				if (font != null)
					tabW = font.Font.MeasureString(tab.Title) + 24;
				if (tab.IsClosable)
					tabW += CloseButtonSize + 4;
				tabW = Math.Max(MinTabWidth, tabW);
				mTabRects.Add(.(xPos, stripY, tabW, TabHeight));
				xPos += tabW;
			}
		}
		else
		{
			let stripW = ComputeStripWidth();
			let stripX = (Placement == .Left) ? 0.0f : Width - stripW;
			float yPos = 0;
			for (let tab in mTabs)
			{
				mTabRects.Add(.(stripX, yPos, stripW, TabHeight));
				yPos += TabHeight;
			}
		}
	}

	private float ComputeStripWidth()
	{
		if (Placement == .Top || Placement == .Bottom) return 0;

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context?.FontService?.GetFont(fontSize);
		if (font == null) return 100;

		float maxW = 0;
		for (let tab in mTabs)
		{
			let w = font.Font.MeasureString(tab.Title);
			maxW = Math.Max(maxW, w);
		}
		return maxW + 24 + (TabsClosable ? CloseButtonSize + 4 : 0);
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
		switch (Placement)
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
		switch (Placement)
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
