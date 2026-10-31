using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.UI;

/// A tabbed container: a strip of headers along one edge, and one page showing at a time.
///
/// Every page is a logical child, so the group owns them all; only the selected one is
/// Visible and the rest are Gone, which keeps the hidden ones out of layout as well as out of
/// sight.
///
/// A strip too long for its edge SCROLLS rather than shrinking its tabs, because tab titles
/// stop being readable long before they stop fitting.
class TabView : ViewGroup
{
	/// Padding either side of a title within its tab.
	private const float TabPadX = 12.0f;
	/// The gap between a title and the close button after it.
	private const float CloseGap = 4.0f;
	/// The stripe marking the selected tab.
	private const float ActiveMarker = 2.0f;
	/// A wheel notch moves the strip this far.
	private const float WheelStep = 40.0f;
	/// The strip width for a vertical placement with no font to measure with.
	private const float FallbackStripWidth = 100.0f;
	/// A tab's width with no font to measure with.
	private const float FallbackTabWidth = 80.0f;

	public Property<float> TabHeight = new .(28.0f) ~ delete _;
	public Property<TabPlacement> Placement = new .(.Top) ~ delete _;
	public Property<bool> TabsClosable = new .(false) ~ delete _;
	public Property<float> CloseButtonSize = new .(12.0f) ~ delete _;
	public Property<float> MinTabWidth = new .(50.0f) ~ delete _;

	public Event<delegate void(TabView, int32)> OnTabChanged ~ _.Dispose();
	/// A close was ASKED FOR. Removing the tab is the consumer's decision, since a page may
	/// have unsaved work to ask about first.
	public Event<delegate void(TabView, int32)> OnTabCloseRequested ~ _.Dispose();

	private List<TabItem> mTabs = new .() ~ DeleteContainerAndItems!(_);
	private int32 mSelectedIndex = -1;
	private int32 mHoveredTabIndex = -1;
	private List<Rectangle> mTabRects = new .() ~ delete _;

	/// Title widths, cached. The rects are rebuilt in BOTH layout and draw, so shaping every
	/// title there meant measuring them all twice a frame for a number that rarely changes.
	///
	/// Keyed on VALUES, never on the font pointer: a freed font's address can come back as a
	/// different font, and a pointer key would then match the wrong thing.
	private List<float> mTitleWidths = new .() ~ delete _;
	private uint32 mTabsGeneration = 0;
	private uint32 mTitleWidthsGeneration = uint32.MaxValue;
	private float mTitleWidthsFontSize = -1.0f;
	private String mTitleWidthsFamily = new .() ~ delete _;

	/// How far the strip is scrolled along its own axis. Clamped on every rebuild.
	private float mTabScroll = 0.0f;
	private bool mTabOverflow = false;
	/// A selection changed, so the next rebuild brings the new tab into view.
	private bool mScrollSelectedIntoView = false;

	public this()
	{
		IsFocusable = true;
		ClipsContent = true;
		// The arrows move between tabs, so focus must not spend them on moving away.
		WantsArrowKeys = true;

		TabHeight.SetOwner(this);
		Placement.SetOwner(this);
		TabsClosable.SetOwner(this, .Visual);
		CloseButtonSize.SetOwner(this, .Visual);
		MinTabWidth.SetOwner(this);
	}

	// ---- Tabs -------------------------------------------------------------------------------

	public int32 TabCount => (int32)mTabs.Count;
	public int32 SelectedIndex => mSelectedIndex;
	/// The tab under the pointer, or -1. What drives the hover state.
	public int32 HoveredTabIndex => mHoveredTabIndex;
	/// Whether the strip is longer than the edge it runs along.
	public bool TabOverflow => mTabOverflow;

	/// Borrowed.
	public TabItem GetTab(int32 index) => mTabs[index];

	/// Adds a tab, CONSUMING the content's reference as AddView does. Answers its index.
	public int32 AddTab(StringView title, View content, bool closable = false)
	{
		let item = new TabItem();
		item.Title.Set(title);
		item.Content = content;
		item.IsClosable = closable || TabsClosable.Value;
		mTabs.Add(item);
		mTabsGeneration++;

		// GONE on the way in, so a page added behind the selected one costs no layout. The
		// selection below makes the first one visible.
		content.Visibility = .Gone;
		AddView(content);

		if (mSelectedIndex < 0)
			SetSelectedIndex(0);

		return (int32)mTabs.Count - 1;
	}

	public void RemoveTab(int32 index)
	{
		if ((index < 0) || (index >= mTabs.Count))
			return;

		RemoveView(mTabs[index].Content);
		delete mTabs[index];
		mTabs.RemoveAt(index);
		mTabsGeneration++;

		// Pulled back into range WITHOUT reporting: closing a tab is not the user choosing a
		// different one.
		if (mSelectedIndex >= mTabs.Count)
			mSelectedIndex = (int32)mTabs.Count - 1;

		if (mSelectedIndex >= 0)
			mTabs[mSelectedIndex].Content.Visibility = .Visible;

		Invalidate();
	}

	public void SetSelectedIndex(int32 value)
	{
		if ((value == mSelectedIndex) || (value < 0) || (value >= mTabs.Count))
			return;

		if ((mSelectedIndex >= 0) && (mSelectedIndex < mTabs.Count))
			mTabs[mSelectedIndex].Content.Visibility = .Gone;

		mSelectedIndex = value;
		// An overflowing strip brings the new tab into view on the next rebuild, so selecting
		// by keyboard cannot land on a tab that is scrolled off.
		mScrollSelectedIntoView = true;
		mTabs[mSelectedIndex].Content.Visibility = .Visible;

		Invalidate();
		OnTabChanged(this, mSelectedIndex);
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		let local = ScreenToLocal(MouseScreenPos());
		let index = TabAt(local);
		if (index < 0)
			return;

		// The close button is tested FIRST, so clicking it does not also select the tab.
		if (mTabs[index].IsClosable && IsCloseButtonHit(mTabRects[index], local))
		{
			OnTabCloseRequested(this, index);
			e.Handled = true;
			return;
		}

		SetSelectedIndex(index);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let newHovered = TabAt(ScreenToLocal(MouseScreenPos()));
		if (newHovered == mHoveredTabIndex)
			return;

		mHoveredTabIndex = newHovered;
		Invalidate();
	}

	/// Hover is tracked in OnMouseMove, which stops arriving once the pointer leaves, so the
	/// last tab would otherwise stay lit.
	public override void OnMouseLeave()
	{
		if (mHoveredTabIndex == -1)
			return;

		mHoveredTabIndex = -1;
		Invalidate();
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mTabs.IsEmpty)
			return;

		// Left and Right regardless of placement: they are the tab ORDER, not a direction on
		// screen, and a vertical strip is still walked with the same keys.
		switch (e.Key)
		{
		case .Left:
			if (mSelectedIndex > 0)
				SetSelectedIndex(mSelectedIndex - 1);
			e.Handled = true;
		case .Right:
			if (mSelectedIndex < mTabs.Count - 1)
				SetSelectedIndex(mSelectedIndex + 1);
			e.Handled = true;
		default:
		}
	}

	/// The wheel scrolls an overflowing strip. There is no room for a scroll bar in a tab
	/// strip, so this is the only way to reach a tab that has been pushed off the end.
	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (!mTabOverflow)
			return;

		// Wheel coordinates arrive in ROOT space, unlike the localised mouse events, so they
		// are converted before being tested against the strip. Without this the check only
		// passed at the window's origin.
		let local = ScreenToLocal(.(e.X, e.Y));
		if (!StripBounds.Contains(local))
			return;

		// Either axis drives it, so a horizontal wheel or a trackpad swipe works too.
		let delta = (e.DeltaY != 0.0f) ? e.DeltaY : e.DeltaX;
		if (delta == 0.0f)
			return;

		mTabScroll -= delta * WheelStep;
		// The tabs moved under a stationary pointer, so the old hover is meaningless.
		mHoveredTabIndex = -1;
		Invalidate();
		e.Handled = true;
	}

	// ---- Geometry ---------------------------------------------------------------------------

	/// The strip's band, whichever edge it is on.
	private Rectangle StripBounds
	{
		get
		{
			let tabHeight = TabHeight.Value;
			switch (Placement.Value)
			{
			case .Top: return .(0, 0, Width, tabHeight);
			case .Bottom: return .(0, Height - tabHeight, Width, tabHeight);
			case .Left: return .(0, 0, ComputeStripWidth(), Height);
			case .Right:
				let stripWidth = ComputeStripWidth();
				return .(Width - stripWidth, 0, stripWidth, Height);
			}
		}
	}

	/// The tab at a local point, or -1.
	private int32 TabAt(Float2 local)
	{
		for (int32 i = 0; i < mTabs.Count; i++)
		{
			if (i >= mTabRects.Count)
				break;

			if (mTabRects[i].Contains(local))
				return i;
		}

		return -1;
	}

	private bool IsCloseButtonHit(Rectangle tabRect, Float2 local)
	{
		let size = CloseButtonSize.Value;
		let x = tabRect.X + tabRect.Width - size - CloseGap;
		let y = tabRect.Y + (tabRect.Height - size) * 0.5f;
		return (local.X >= x) && (local.X <= x + size) && (local.Y >= y) && (local.Y <= y + size);
	}

	private Float2 MouseScreenPos()
	{
		if ((Context == null) || (Context.GetInputManager() == null))
			return .Zero;

		let input = Context.GetInputManager();
		return .(input.MouseX, input.MouseY);
	}

	/// Rebuilds the strip's hit rectangles, and with them the overflow and the scroll clamp.
	///
	/// Run at LAYOUT as well as at draw, so hit testing is valid before the first frame is
	/// painted: a mouse move arriving between the two would otherwise find no rects at all.
	private void RebuildTabRects()
	{
		mTabRects.Clear();

		let fontSize = ResolveStyleFloat(.FontSize, 14.0f);
		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = ((Context != null) && (Context.FontService != null))
			? Context.FontService.GetFont(family, fontSize)
			: null;

		EnsureTitleWidths(font, family, fontSize);

		let placement = Placement.Value;
		let horizontal = (placement == .Top) || (placement == .Bottom);
		let tabHeight = TabHeight.Value;

		// Each tab's extent along the strip's own axis, and the total, so the overflow is
		// known before any rect is placed.
		let extents = scope List<float>();
		var total = 0.0f;
		for (int32 i = 0; i < mTabs.Count; i++)
		{
			var extent = tabHeight;
			if (horizontal)
			{
				extent = (font != null) ? mTitleWidths[i] + TabPadX * 2 : FallbackTabWidth;
				if (mTabs[i].IsClosable)
					extent += CloseButtonSize.Value + CloseGap;

				extent = Max(MinTabWidth.Value, extent);
			}

			extents.Add(extent);
			total += extent;
		}

		let available = horizontal ? Width : Height;
		let maxScroll = Max(0.0f, total - available);
		mTabScroll = Clamp(mTabScroll, 0.0f, maxScroll);

		if (mScrollSelectedIntoView)
			ScrollSelectedIntoView(extents, available, maxScroll);

		mScrollSelectedIntoView = false;
		mTabOverflow = maxScroll > 0.0f;

		EmitTabRects(extents, horizontal, placement, tabHeight);
	}

	private void ScrollSelectedIntoView(List<float> extents, float available, float maxScroll)
	{
		if ((mSelectedIndex < 0) || (mSelectedIndex >= extents.Count))
			return;

		var start = 0.0f;
		for (int32 i = 0; i < mSelectedIndex; i++)
			start += extents[i];

		let extent = extents[mSelectedIndex];
		if (start - mTabScroll < 0.0f)
			mTabScroll = start;
		else if (start + extent - mTabScroll > available)
			mTabScroll = start + extent - available;

		mTabScroll = Clamp(mTabScroll, 0.0f, maxScroll);
	}

	private void EmitTabRects(List<float> extents, bool horizontal, TabPlacement placement,
		float tabHeight)
	{
		if (horizontal)
		{
			let stripY = (placement == .Top) ? 0.0f : Height - tabHeight;
			var x = -mTabScroll;
			for (int32 i = 0; i < mTabs.Count; i++)
			{
				mTabRects.Add(.(x, stripY, extents[i], tabHeight));
				x += extents[i];
			}
			return;
		}

		let stripWidth = ComputeStripWidth();
		let stripX = (placement == .Left) ? 0.0f : Width - stripWidth;
		var y = -mTabScroll;
		for (int32 i = 0; i < mTabs.Count; i++)
		{
			mTabRects.Add(.(stripX, y, stripWidth, tabHeight));
			y += tabHeight;
		}
	}

	/// A vertical strip is as wide as its widest title; a horizontal one has no width of its
	/// own, since it spans the whole edge.
	private float ComputeStripWidth()
	{
		let placement = Placement.Value;
		if ((placement == .Top) || (placement == .Bottom))
			return 0;

		let fontSize = ResolveStyleFloat(.FontSize, 14.0f);
		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = ((Context != null) && (Context.FontService != null))
			? Context.FontService.GetFont(family, fontSize)
			: null;

		if (font == null)
			return FallbackStripWidth;

		EnsureTitleWidths(font, family, fontSize);

		var widest = 0.0f;
		for (let width in mTitleWidths)
			widest = Max(widest, width);

		return widest + TabPadX * 2 + (TabsClosable.Value ? CloseButtonSize.Value + CloseGap : 0);
	}

	private void EnsureTitleWidths(CachedFont font, StringView family, float fontSize)
	{
		if (font == null)
		{
			mTitleWidths.Clear();
			// Recomputed when a font turns up, rather than being left believing it is current.
			mTitleWidthsGeneration = uint32.MaxValue;
			return;
		}

		if ((mTitleWidthsGeneration == mTabsGeneration) && (mTitleWidthsFontSize == fontSize) &&
			(mTitleWidthsFamily == family) && (mTitleWidths.Count == mTabs.Count))
			return;

		mTitleWidths.Clear();
		for (let tab in mTabs)
			mTitleWidths.Add(font.Font.MeasureString(tab.Title));

		mTitleWidthsGeneration = mTabsGeneration;
		mTitleWidthsFontSize = fontSize;
		mTitleWidthsFamily.Set(family);
	}

	// ---- Layout -----------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let placement = Placement.Value;
		let horizontal = (placement == .Top) || (placement == .Bottom);

		let contentConstraints = horizontal
			? constraints.Deflate(Thickness(0, TabHeight.Value, 0, 0))
			: constraints.Deflate(Thickness(ComputeStripWidth(), 0, 0, 0));

		var contentWidth = 0.0f;
		var contentHeight = 0.0f;

		// Only the SELECTED page is measured; the rest are Gone and cost nothing.
		if ((mSelectedIndex >= 0) && (mSelectedIndex < mTabs.Count))
		{
			let content = mTabs[mSelectedIndex].Content;
			if (content.Visibility != .Gone)
			{
				content.Measure(contentConstraints);
				contentWidth = content.MeasuredSize.X;
				contentHeight = content.MeasuredSize.Y;
			}
		}

		if (horizontal)
			MeasuredSize = .(constraints.ConstrainWidth(contentWidth),
				constraints.ConstrainHeight(contentHeight + TabHeight.Value));
		else
			MeasuredSize = .(constraints.ConstrainWidth(contentWidth + ComputeStripWidth()),
				constraints.ConstrainHeight(contentHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		RebuildTabRects();

		if ((mSelectedIndex < 0) || (mSelectedIndex >= mTabs.Count))
			return;

		let content = mTabs[mSelectedIndex].Content;
		if (content.Visibility == .Gone)
			return;

		let tabHeight = TabHeight.Value;
		switch (Placement.Value)
		{
		case .Top:
			content.Layout(0, tabHeight, width, Max(0.0f, height - tabHeight));
		case .Bottom:
			content.Layout(0, 0, width, Max(0.0f, height - tabHeight));
		case .Left:
			let stripWidth = ComputeStripWidth();
			content.Layout(stripWidth, 0, Max(0.0f, width - stripWidth), height);
		case .Right:
			content.Layout(0, 0, Max(0.0f, width - ComputeStripWidth()), height);
		}
	}

	// ---- Draw -------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		RebuildTabRects();

		let state = GetControlState();
		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = (ctx.FontService != null)
			? ctx.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f))
			: null;

		DrawBands(ctx, state);

		// The tabs are clipped to the strip, so a scrolled one does not spill past its edge.
		ctx.PushClip(StripBounds);
		for (int32 i = 0; i < mTabs.Count; i++)
		{
			if (i >= mTabRects.Count)
				break;

			DrawTab(ctx, i, font, state);
		}
		ctx.PopClip();

		DrawChildren(ctx);
	}

	/// The strip band, the content band, and the line between them.
	private void DrawBands(UIDrawContext ctx, ControlState state)
	{
		let strip = ResolvePartDrawable("strip", .Background, state);
		let content = ResolvePartDrawable("content", .Background, state);
		let borderColor = ResolveStyleColor(.BorderColor, Color(60 / 255.0f, 65 / 255.0f, 80 / 255.0f, 1.0f));

		let stripBounds = StripBounds;
		let tabHeight = TabHeight.Value;

		switch (Placement.Value)
		{
		case .Top:
			DrawRegion(ctx, strip, stripBounds, false);
			DrawRegion(ctx, content, .(0, tabHeight, Width, Height - tabHeight), true);
			ctx.VG.DrawLine(.(0, tabHeight), .(Width, tabHeight), borderColor, 1);
		case .Bottom:
			DrawRegion(ctx, content, .(0, 0, Width, Height - tabHeight), true);
			DrawRegion(ctx, strip, stripBounds, false);
			ctx.VG.DrawLine(.(0, Height - tabHeight), .(Width, Height - tabHeight), borderColor, 1);
		case .Left:
			let leftWidth = stripBounds.Width;
			DrawRegion(ctx, strip, stripBounds, false);
			DrawRegion(ctx, content, .(leftWidth, 0, Width - leftWidth, Height), true);
			ctx.VG.DrawLine(.(leftWidth, 0), .(leftWidth, Height), borderColor, 1);
		case .Right:
			let stripX = stripBounds.X;
			DrawRegion(ctx, content, .(0, 0, stripX, Height), true);
			DrawRegion(ctx, strip, stripBounds, false);
			ctx.VG.DrawLine(.(stripX, 0), .(stripX, Height), borderColor, 1);
		}
	}

	private void DrawTab(UIDrawContext ctx, int32 index, CachedFont font, ControlState controlState)
	{
		let rect = mTabRects[index];
		let tab = mTabs[index];
		let isActive = index == mSelectedIndex;
		let isHovered = index == mHoveredTabIndex;

		// Selected reads as Checked, so a theme styles the states as one part rather than as
		// separate drawables.
		var tabState = ControlState.Normal;
		if (isActive)
			tabState |= .Checked;
		if (isHovered)
			tabState |= .Hover;

		if (let tabDrawable = ResolvePartDrawable("tab", .Background, tabState))
			DrawMaskedRegion(ctx, tabDrawable, rect, false);

		if (isActive)
			DrawActiveMarker(ctx, rect);

		if (font != null)
			DrawTitle(ctx, index, rect, font, tabState, isActive, isHovered, controlState);

		if (tab.IsClosable)
			DrawCloseButton(ctx, rect, font, isActive || isHovered);
	}

	/// A stripe along the edge the content is on, so the selected tab reads as joined to it.
	private void DrawActiveMarker(UIDrawContext ctx, Rectangle rect)
	{
		let color = ResolveStyleColor(.AccentColor, Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f));

		switch (Placement.Value)
		{
		case .Top:
			ctx.VG.FillRect(.(rect.X, rect.Y + rect.Height - ActiveMarker, rect.Width, ActiveMarker), color);
		case .Bottom:
			ctx.VG.FillRect(.(rect.X, rect.Y, rect.Width, ActiveMarker), color);
		case .Left:
			ctx.VG.FillRect(.(rect.X + rect.Width - ActiveMarker, rect.Y, ActiveMarker, rect.Height), color);
		case .Right:
			ctx.VG.FillRect(.(rect.X, rect.Y, ActiveMarker, rect.Height), color);
		}
	}

	private void DrawTitle(UIDrawContext ctx, int32 index, Rectangle rect, CachedFont font,
		ControlState tabState, bool isActive, bool isHovered, ControlState controlState)
	{
		// Three shades untheme d, so the selected tab reads as selected and the hovered one as
		// reachable, before any sheet is loaded.
		let fallback = isActive
			? Color(240 / 255.0f, 240 / 255.0f, 245 / 255.0f, 1.0f)
			: (isHovered
				? Color(200 / 255.0f, 205 / 255.0f, 215 / 255.0f, 1.0f)
				: Color(140 / 255.0f, 145 / 255.0f, 160 / 255.0f, 1.0f));

		let color = ResolvePartColor("tab", .TextColor, tabState, fallback);

		var textWidth = rect.Width - TabPadX * 2;
		if (mTabs[index].IsClosable)
			textWidth -= ResolvePartFloat("close-button", .Width, controlState, 12) + CloseGap;

		ctx.VG.DrawText(mTabs[index].Title, font, .(rect.X + 8, rect.Y, textWidth, rect.Height),
			.Left, .Middle, color);
	}

	private void DrawCloseButton(UIDrawContext ctx, Rectangle rect, CachedFont font, bool lit)
	{
		let state = GetControlState();
		let size = ResolvePartFloat("close-button", .Width, state, 12);
		let x = rect.X + rect.Width - size - CloseGap;
		let y = rect.Y + (rect.Height - size) * 0.5f;

		// The button brightens with the TAB, not with itself: it has no hover of its own,
		// since the whole tab is one hit target until the click is resolved.
		var buttonState = ControlState.Normal;
		if (lit)
			buttonState |= .Hover;

		let color = ResolvePartColor("close-button", .TextColor, buttonState,
			Color(120 / 255.0f, 125 / 255.0f, 140 / 255.0f, 1.0f));

		if (let icon = ResolvePartDrawable("close-button", .Background, buttonState))
		{
			// The icon carries its own colours, so the resolved alpha is applied as opacity
			// rather than as a tint.
			ctx.VG.PushOpacity(color.A);
			icon.Draw(ctx, .(x, y, size, size));
			ctx.VG.PopOpacity();
			return;
		}

		if (font != null)
			ctx.VG.DrawText("x", font, .(x, rect.Y, size, rect.Height), .Center, .Middle, color);
	}

	private void DrawRegion(UIDrawContext ctx, Drawable drawable, Rectangle bounds, bool isContent)
	{
		DrawMaskedRegion(ctx, drawable, bounds, isContent);
	}

	/// Draws a themed region with its corners MASKED to the side it meets.
	///
	/// A tab rounds only the outer edge and the content only the edge away from the strip, so
	/// the two meet flush instead of leaving a rounded gap between them. The drawable is
	/// shared, so its radii are put back afterwards.
	private void DrawMaskedRegion(UIDrawContext ctx, Drawable drawable, Rectangle bounds,
		bool isContent)
	{
		if (let rounded = drawable as RoundedRectDrawable)
		{
			let saved = rounded.Radii;
			rounded.Radii = isContent ? MaskRadiiForContent(saved) : MaskRadiiForTab(saved);
			rounded.Draw(ctx, bounds);
			rounded.Radii = saved;
			return;
		}

		if (drawable != null)
		{
			drawable.Draw(ctx, bounds);
			return;
		}

		ctx.VG.FillRect(bounds, Color(42 / 255.0f, 44 / 255.0f, 54 / 255.0f, 1.0f));
	}

	/// A tab keeps the corners on the OUTER edge and squares the ones meeting the content.
	private CornerRadii MaskRadiiForTab(CornerRadii r)
	{
		switch (Placement.Value)
		{
		case .Top: return .(r.TopLeft, r.TopRight, 0, 0);
		case .Bottom: return .(0, 0, r.BottomRight, r.BottomLeft);
		case .Left: return .(r.TopLeft, 0, 0, r.BottomLeft);
		case .Right: return .(0, r.TopRight, r.BottomRight, 0);
		}
	}

	/// The content is the mirror: square where the strip meets it, rounded away from it.
	private CornerRadii MaskRadiiForContent(CornerRadii r)
	{
		switch (Placement.Value)
		{
		case .Top: return .(0, 0, r.BottomRight, r.BottomLeft);
		case .Bottom: return .(r.TopLeft, r.TopRight, 0, 0);
		case .Left: return .(0, r.TopRight, r.BottomRight, 0);
		case .Right: return .(r.TopLeft, 0, 0, r.BottomLeft);
		}
	}
}
