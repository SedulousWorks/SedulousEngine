using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Toolkit;

/// [[DockTabGroup]]: the strip, its overflow scrolling, and the selected panel under it.
extension DockTabGroup
{
	public override void OnDraw(UIDrawContext ctx)
	{
		DrawGrounds(ctx);
		DrawSelectedPanel(ctx);
		DrawTabStrip(ctx);
	}

	private void DrawGrounds(UIDrawContext ctx)
	{
		if (let strip = ResolvePartDrawable("strip", .Background, .Normal))
			strip.Draw(ctx, .(0, 0, Width, mTabHeight));
		else
			ctx.VG.FillRect(.(0, 0, Width, mTabHeight), Color.Rgb(35, 37, 46));

		let contentHeight = Height - mTabHeight;
		if (let content = ResolvePartDrawable("content", .Background, .Normal))
			content.Draw(ctx, .(0, mTabHeight, Width, contentHeight));
		else
			ctx.VG.FillRect(.(0, mTabHeight, Width, contentHeight), Color.Rgb(42, 44, 54));
	}

	/// Drawn DIRECTLY rather than through DrawChildren, because only one panel is visible and
	/// the group draws its own chrome around it.
	private void DrawSelectedPanel(UIDrawContext ctx)
	{
		let panel = SelectedPanel;
		if ((panel == null) || (panel.Visibility == .Gone))
			return;

		ctx.VG.PushState();
		ctx.VG.Translate(panel.Bounds.X, panel.Bounds.Y);
		panel.OnDraw(ctx);
		ctx.VG.PopState();
	}

	private void DrawTabStrip(UIDrawContext ctx)
	{
		mTabRects.Clear();
		mCloseRects.Clear();

		if (ctx.FontService == null)
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = ctx.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f));
		if (font == null)
			return;

		// The whole strip is measured FIRST, so the scroll can be clamped and the selected tab
		// brought into view before anything is drawn. Hit testing then reuses the rectangles
		// this pass produces, and clicks stay aligned with what is on screen for free.
		let tabWidths = scope List<float>();
		let stripWidth = MeasureTabs(font, tabWidths);
		let maxScroll = Max(0.0f, stripWidth - Width);
		mTabScroll = Clamp(mTabScroll, 0.0f, maxScroll);

		if (mScrollSelectedIntoView)
			ScrollSelectedIntoView(tabWidths, maxScroll);

		mScrollSelectedIntoView = false;
		mTabOverflow = maxScroll > 0.0f;

		ctx.PushClip(Rectangle(0, 0, Width, mTabHeight));
		DrawTabs(ctx, font, tabWidths);
		ctx.PopClip();
	}

	private float MeasureTabs(CachedFont font, List<float> outWidths)
	{
		var stripWidth = 2.0f;
		for (let panel in mPanels)
		{
			// ROUNDED to a whole pixel. Glyph advances are fractional, and accumulating them
			// puts every later tab, and its close icon, on a different subpixel phase: exactly
			// the per tab shimmer the baked icons exist to prevent.
			var width = Round(font.Font.MeasureString(panel.Title) + 16);
			if (panel.Closable)
				width += CloseButtonWidth;

			outWidths.Add(width);
			stripWidth += width + 2;
		}

		return stripWidth;
	}

	private void ScrollSelectedIntoView(List<float> tabWidths, float maxScroll)
	{
		if ((mSelectedIndex < 0) || (mSelectedIndex >= tabWidths.Count))
			return;

		var x = 2.0f;
		for (int32 i = 0; i < mSelectedIndex; i++)
			x += tabWidths[i] + 2;

		let width = tabWidths[mSelectedIndex];
		if ((x - mTabScroll) < 0.0f)
			mTabScroll = x - 2.0f;
		else if (((x + width) - mTabScroll) > Width)
			mTabScroll = (x + width) - Width;

		mTabScroll = Clamp(mTabScroll, 0.0f, maxScroll);
	}

	private void DrawTabs(UIDrawContext ctx, CachedFont font, List<float> tabWidths)
	{
		let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);
		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(35, 37, 46));
		let closeColor = ResolvePartColor("close-button", .TextColor, .Normal,
			.(180 / 255.0f, 185 / 255.0f, 200 / 255.0f, 150 / 255.0f));

		var x = 2.0f - mTabScroll;
		for (int32 i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			let width = tabWidths[i];
			let rect = Rectangle(x, 0, width, mTabHeight);
			mTabRects.Add(rect);

			DrawTabBackground(ctx, i, rect, cornerRadius, borderColor);
			DrawTabText(ctx, font, panel, i, x, width);
			DrawTabCloseButton(ctx, panel, i, x, width, closeColor);

			x += width + 2;
		}
	}

	private void DrawTabBackground(UIDrawContext ctx, int32 index, Rectangle rect,
		float cornerRadius, Color borderColor)
	{
		if (index == mSelectedIndex)
		{
			FillTab(ctx, ResolvePartDrawable("tab", .Background, .Checked), rect, cornerRadius,
				Color.Rgb(42, 44, 54));

			// The same two pixel accent a regular tab view draws, so a dock tab reads as active
			// the way an ordinary tab does.
			ctx.VG.FillRect(.(rect.X, rect.Y + rect.Height - 2.0f, rect.Width, 2.0f),
				ResolveStyleColor(.AccentColor, Color.Rgb(80, 150, 240)));
			return;
		}

		if (index == mHoveredTabIndex)
			FillTab(ctx, ResolvePartDrawable("tab", .Background, .Hover), rect, cornerRadius,
				Palette.Lighten(borderColor, 0.1f));
	}

	/// Rounded at the TOP only, at the theme's own radius, so a tab meets the content below it
	/// flush rather than floating above it as a separate rounded box.
	private void FillTab(UIDrawContext ctx, Drawable drawable, Rectangle rect, float cornerRadius,
		Color fallback)
	{
		if (let rounded = drawable as RoundedRectDrawable)
		{
			let saved = rounded.Radii;
			rounded.Radii = .(cornerRadius, cornerRadius, 0.0f, 0.0f);
			rounded.Draw(ctx, rect);
			rounded.Radii = saved;
			return;
		}

		if (drawable != null)
		{
			drawable.Draw(ctx, rect);
			return;
		}

		ctx.VG.FillRect(rect, fallback);
	}

	private void DrawTabText(UIDrawContext ctx, CachedFont font, DockablePanel panel, int32 index,
		float x, float width)
	{
		let textWidth = width - 16 - (panel.Closable ? CloseButtonWidth : 0.0f);
		let color = (index == mSelectedIndex)
			? ResolvePartColor("tab", .TextColor, .Checked, Color.Rgb(220, 225, 235))
			: ResolvePartColor("tab", .TextColor, .Normal,
				.(180 / 255.0f, 185 / 255.0f, 200 / 255.0f, 153 / 255.0f));

		ctx.VG.DrawText(panel.Title, font, .(x + 8, 0, textWidth, mTabHeight), .Left, .Middle,
			color);
	}

	/// SHOWN on the active tab always, and on a hovered inactive one. A cross on every tab makes
	/// a busy strip look like a row of buttons, and one that appears only on hover is unfindable
	/// on the tab you are already using.
	private void DrawTabCloseButton(UIDrawContext ctx, DockablePanel panel, int32 index, float x,
		float width, Color color)
	{
		if (!panel.Closable)
		{
			// A placeholder, so the close rectangles stay index aligned with the tabs.
			mCloseRects.Add(.());
			return;
		}

		mCloseRects.Add(.(x + width - CloseButtonWidth, 0, CloseButtonWidth, mTabHeight));

		if ((index != mSelectedIndex) && (index != mHoveredTabIndex))
			return;

		let iconX = x + width - CloseButtonPadding - CloseButtonSize;
		let iconY = (mTabHeight - CloseButtonSize) * 0.5f;

		if (let icon = ResolvePartDrawable("close-button", .Background, .Normal))
		{
			ctx.VG.PushOpacity(color.A);
			icon.Draw(ctx, .(iconX, iconY, CloseButtonSize, CloseButtonSize));
			ctx.VG.PopOpacity();
			return;
		}

		let centerX = iconX + (CloseButtonSize * 0.5f);
		let centerY = iconY + (CloseButtonSize * 0.5f);
		let arm = 3.0f;
		ctx.VG.DrawLine(.(centerX - arm, centerY - arm), .(centerX + arm, centerY + arm), color, 1.5f);
		ctx.VG.DrawLine(.(centerX + arm, centerY - arm), .(centerX - arm, centerY + arm), color, 1.5f);
	}
}
