using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// What a node asks of layout, one record on every node, filled from its sheet, its markup or
// code: how it sizes (width, height, min, max: a length, a percentage of its container, or auto),
// how it lays out its children (display: flex, grid, stack, dock or none, with each kind's
// properties), how its container places it (the flex, grid and dock item properties, margin),
// whether it is out of flow (position and insets), and whether it clips or scrolls (overflow).
// Lengths in em, rem, vw and vh are resolved to pixels when the style is applied; percentages and
// auto wait for layout, which knows the container.

/// A length as layout reads it: auto (the content's, or what the container gives), pixels, a
/// percentage of the container's content box, or one of CSS's content sizes. None is a max-width
/// or max-height with no bound.
enum LayoutLengthKind : uint8
{
	Auto,
	Px,
	Percent,
	FitContent,
	MinContent,
	MaxContent,
	None,
	/// Value pixels and PercentPart of the base (a calc() mixing them).
	Calc,
}

struct LayoutLength : IEquatable<LayoutLength>
{
	public LayoutLengthKind Kind = .Auto;
	public float Value = 0.0f;
	/// A Calc's percentage part.
	public float PercentPart = 0.0f;

	public this() { }

	public this(LayoutLengthKind kind, float value, float percentPart = 0.0f)
	{
		Kind = kind;
		Value = value;
		PercentPart = percentPart;
	}

	public static LayoutLength Px(float v) => .(.Px, v);
	public static LayoutLength Percent(float v) => .(.Percent, v);
	public static LayoutLength None() => .(.None, 0.0f);
	public static LayoutLength Calc(float px, float percent) => .(.Calc, px, percent);

	public bool IsAuto => Kind == .Auto;

	/// The length in pixels against `baseLength` (the container's content length, negative when
	/// it is not known yet); none for auto, a content size, or a percentage of an unknown base.
	public float? Resolve(float baseLength)
	{
		switch (Kind)
		{
		case .Px:
			return Value;
		case .Percent:
			if (baseLength >= 0.0f)
				return Value * baseLength / 100.0f;
			return null;
		case .Calc:
			if (baseLength >= 0.0f)
				return Value + PercentPart * baseLength / 100.0f;
			return null;
		default:
			return null;
		}
	}

	public bool Equals(LayoutLength other) => this == other;

	[Commutable]
	public static bool operator==(LayoutLength a, LayoutLength b) =>
		(a.Kind == b.Kind) && (a.Value == b.Value) && (a.PercentPart == b.PercentPart);
}

/// A bar's or a track's direction (a scrollbar, a tab strip).
enum Orientation : uint8
{
	Horizontal,
	Vertical
}

/// How a node lays out its children (CSS `display`). A plain container is a flex column.
enum Display : uint8
{
	Flex,
	Grid,
	/// Children over each other in the content box, each aligned on its own.
	Stack,
	/// Children docked to the sides in order, the last filling what remains.
	Dock,
	/// The node and its subtree take no space and draw nothing.
	None,
}

/// In its container's flow, offset after it, or out of it (placed by its insets).
enum Position : uint8
{
	Static,
	Relative,
	Absolute,
}

enum FlexDirection : uint8
{
	Row,
	Column,
	RowReverse,
	ColumnReverse,
}

enum FlexWrap : uint8
{
	NoWrap,
	Wrap,
	WrapReverse,
}

/// Distribution along an axis (justify-content, align-content).
enum Justify : uint8
{
	Start,
	End,
	Center,
	SpaceBetween,
	SpaceAround,
	SpaceEvenly,
	/// align-content's normal: lines share the free space.
	Stretch,
}

/// Placement across an axis (align-items, align-self, justify-items, justify-self). Auto on an
/// item takes the container's.
enum Align : uint8
{
	Auto,
	Start,
	End,
	Center,
	Stretch,
	Baseline,
}

enum Dock : uint8
{
	Fill,
	Left,
	Top,
	Right,
	Bottom,
	/// The inline start: left, or right in right to left.
	Start,
	/// The inline end.
	End,
}

/// Visible draws children outside the box; hidden clips them; scroll and auto clip and scroll
/// (scroll always shows its bar, auto when the content overflows).
enum Overflow : uint8
{
	Visible,
	Hidden,
	Scroll,
	Auto,
}

/// How a scroll moves (CSS's scroll-behavior): at once, or easing to where it is going. A call
/// may ask for either, or for Auto, the node's own (`scroll-behavior: smooth` opts in).
enum ScrollBehavior : uint8
{
	Auto,
	Instant,
	Smooth,
}

/// What a scroller at its end does with the wheel (CSS's overscroll-behavior): passes it to the
/// scroller around it, or keeps it (`contain`, a popup's list that must not scroll the page).
enum OverscrollBehavior : uint8
{
	Auto,
	Contain,
}

/// How thick a scroller's bars are (CSS's scrollbar-width); `none` hides them, the node still
/// scrolling by the wheel, the keys and touch.
enum ScrollbarWidth : uint8
{
	Auto,
	Thin,
	None,
}

/// Whether a scroller's bars stay shown (while it overflows, or always for `overflow: scroll`)
/// or are an overlay that shows while it scrolls or is hovered and then fades.
enum ScrollbarVisibility : uint8
{
	Auto,
	Overlay,
}

/// Where a scroll into view puts what it shows: the least move that shows it, or its start,
/// centre or end at the box's.
enum ScrollAlign : uint8
{
	Nearest,
	Start,
	Center,
	End,
}

/// Whether width and height include the padding and border (the GUI's default, what a UI author
/// means by a 120 pixel button) or are the content's alone, CSS's initial value.
enum BoxSizing : uint8
{
	BorderBox,
	ContentBox,
}

enum GridAutoFlow : uint8
{
	Row,
	Column,
}

/// A grid track's size: from `Min` to `Max`, or a share of the free space (`Fr` > 0, its minimum
/// `Min`). `120px` is Min = Max = 120; `1fr` is Fr 1; `auto` is Min = Max = auto (the
/// content's); `minmax(100px, 1fr)` is Min 100 and Fr 1.
struct GridTrack : IEquatable<GridTrack>
{
	public LayoutLength Min = .();
	public LayoutLength Max = .();
	public float Fr = 0.0f;

	public this() { }

	public this(LayoutLength min, LayoutLength max, float fr)
	{
		Min = min;
		Max = max;
		Fr = fr;
	}

	public static GridTrack Fixed(float px) => .(LayoutLength.Px(px), LayoutLength.Px(px), 0.0f);
	public static GridTrack Flex(float fr) => .(LayoutLength(), LayoutLength(), fr);

	public bool Equals(GridTrack other) => this == other;

	[Commutable]
	public static bool operator==(GridTrack a, GridTrack b) => (a.Min == b.Min) && (a.Max == b.Max) && (a.Fr == b.Fr);
}

/// Where an item sits on one grid axis: a 1-based start line (0: placed automatically) and how
/// many tracks it spans.
struct GridPlacement : IEquatable<GridPlacement>
{
	public int32 Start = 0;
	public int32 Span = 1;

	public this() { }

	public this(int32 start, int32 span)
	{
		Start = start;
		Span = span;
	}

	public bool Equals(GridPlacement other) => this == other;

	[Commutable]
	public static bool operator==(GridPlacement a, GridPlacement b) => (a.Start == b.Start) && (a.Span == b.Span);
}

/// A class, not a struct: it owns its grid track lists, which a struct copy would share. Set
/// copies another one deeply.
class LayoutStyle
{
	// --- The node's own box ---
	public LayoutLength Width = .();
	public LayoutLength Height = .();
	/// Auto: none, but a flex item's content minimum.
	public LayoutLength MinWidth = .();
	public LayoutLength MinHeight = .();
	public LayoutLength MaxWidth = LayoutLength.None();
	public LayoutLength MaxHeight = LayoutLength.None();
	public Thickness Margin = .();
	/// Percentages of the containing box's width each side adds (CSS's `margin: 5%`), resolved at
	/// layout, where that width is known.
	public Thickness MarginPercent = .();
	public BoxSizing Sizing = .BorderBox;
	public Overflow OverflowX = .Visible;
	public Overflow OverflowY = .Visible;
	public ScrollBehavior Scrolling = .Auto;
	public OverscrollBehavior Overscroll = .Auto;
	public ScrollbarWidth BarWidth = .Auto;
	public ScrollbarVisibility BarVisibility = .Auto;

	// --- Out of flow ---
	public Position Placement = .Static;
	public LayoutLength Left = .();
	public LayoutLength Top = .();
	public LayoutLength Right = .();
	public LayoutLength Bottom = .();
	public int32 ZIndex = 0;

	// --- How it lays out its children ---
	public Display Kind = .Flex;
	public FlexDirection Direction = .Column;
	public FlexWrap Wrap = .NoWrap;
	public Justify JustifyContent = .Start;
	public Align AlignItems = .Stretch;
	public Justify AlignContent = .Stretch;
	/// Grid and stack.
	public Align JustifyItems = .Stretch;
	public float RowGap = 0.0f;
	public float ColumnGap = 0.0f;
	/// Of the container's content height, resolved at layout.
	public float RowGapPercent = 0.0f;
	/// Of its content width.
	public float ColumnGapPercent = 0.0f;
	public List<GridTrack> Columns = new .() ~ delete _;
	/// `repeat(auto-fill, <tracks>)` among the columns: the ColumnsRepeatSize tracks of Columns from
	/// ColumnsRepeatAt repeat as often as the grid's width holds them, at least once
	/// (ColumnsRepeatAt -1: none).
	public int32 ColumnsRepeatAt = -1;
	public int32 ColumnsRepeatSize = 0;
	public List<GridTrack> Rows = new .() ~ delete _;
	public GridTrack AutoRows = .();
	public GridTrack AutoColumns = .();
	public GridAutoFlow AutoFlow = .Row;

	// --- How its container places it ---
	public float Grow = 0.0f;
	public float Shrink = 1.0f;
	public LayoutLength Basis = .();
	public Align AlignSelf = .Auto;
	public Align JustifySelf = .Auto;
	public int32 Order = 0;
	public GridPlacement Column = .();
	public GridPlacement Row = .();
	public Dock DockSide = .Fill;

	/// Makes this a copy of `other`, its track lists included.
	public void Set(LayoutStyle other)
	{
		if (other === this)
			return;
		Width = other.Width;
		Height = other.Height;
		MinWidth = other.MinWidth;
		MinHeight = other.MinHeight;
		MaxWidth = other.MaxWidth;
		MaxHeight = other.MaxHeight;
		Margin = other.Margin;
		MarginPercent = other.MarginPercent;
		Sizing = other.Sizing;
		OverflowX = other.OverflowX;
		OverflowY = other.OverflowY;
		Scrolling = other.Scrolling;
		Overscroll = other.Overscroll;
		BarWidth = other.BarWidth;
		BarVisibility = other.BarVisibility;
		Placement = other.Placement;
		Left = other.Left;
		Top = other.Top;
		Right = other.Right;
		Bottom = other.Bottom;
		ZIndex = other.ZIndex;
		Kind = other.Kind;
		Direction = other.Direction;
		Wrap = other.Wrap;
		JustifyContent = other.JustifyContent;
		AlignItems = other.AlignItems;
		AlignContent = other.AlignContent;
		JustifyItems = other.JustifyItems;
		RowGap = other.RowGap;
		ColumnGap = other.ColumnGap;
		RowGapPercent = other.RowGapPercent;
		ColumnGapPercent = other.ColumnGapPercent;
		Columns.Clear();
		Columns.AddRange(other.Columns);
		ColumnsRepeatAt = other.ColumnsRepeatAt;
		ColumnsRepeatSize = other.ColumnsRepeatSize;
		Rows.Clear();
		Rows.AddRange(other.Rows);
		AutoRows = other.AutoRows;
		AutoColumns = other.AutoColumns;
		AutoFlow = other.AutoFlow;
		Grow = other.Grow;
		Shrink = other.Shrink;
		Basis = other.Basis;
		AlignSelf = other.AlignSelf;
		JustifySelf = other.JustifySelf;
		Order = other.Order;
		Column = other.Column;
		Row = other.Row;
		DockSide = other.DockSide;
	}
}

/// The properties a sheet may set through a node's setters, one bit each: code that sets one
/// makes it its own, as CSS's inline style, and the sheet leaves it be (Node pins it).
enum StyleSlot : uint32
{
	SlotOpacity,
	SlotPaddingTop, SlotPaddingRight, SlotPaddingBottom, SlotPaddingLeft,
	SlotMarginTop, SlotMarginRight, SlotMarginBottom, SlotMarginLeft,
	SlotWidth, SlotHeight, SlotMinWidth, SlotMinHeight, SlotMaxWidth, SlotMaxHeight,
	SlotTop, SlotRight, SlotBottom, SlotLeft,
	SlotFlexBasis, SlotFlexGrow, SlotFlexShrink, SlotOrder, SlotZIndex, SlotRowGap, SlotColumnGap,
	SlotDisplay, SlotPosition, SlotBoxSizing, SlotOverflowX, SlotOverflowY,
	SlotFlexDirection, SlotFlexWrap, SlotJustifyContent, SlotAlignContent, SlotAlignItems,
	SlotJustifyItems, SlotAlignSelf, SlotJustifySelf, SlotGridAutoFlow, SlotDock,
	SlotGridTemplateColumns, SlotGridTemplateRows, SlotGridAutoRows, SlotGridAutoColumns,
	SlotGridColumn, SlotGridRow,
	SlotScrollBehavior, SlotOverscrollBehavior, SlotScrollbarWidth, SlotScrollbarVisibility,
	SlotEnabled, SlotVisibility,
	SlotColor, SlotFontFamily, SlotFontSize, SlotTextAlign, SlotVerticalAlign,
	SlotWhiteSpace, SlotLineHeight, SlotLetterSpacing,
	SlotDirection,
	SlotFontWeight, SlotFontStyle, SlotOverflowWrap,
	SlotCount,
}

/// A set of StyleSlots: what code pinned, what a change touched. Two words: the slots pass 64.
struct StyleSlotSet : IEquatable<StyleSlotSet>
{
	public const int cWords = 2;
	public uint64[cWords] Words = default;

	public this() { }

	public this(uint64 low, uint64 high)
	{
		Words[0] = low;
		Words[1] = high;
	}

	public static StyleSlotSet operator|(StyleSlotSet a, StyleSlotSet b) => .(a.Words[0] | b.Words[0], a.Words[1] | b.Words[1]);
	public static StyleSlotSet operator&(StyleSlotSet a, StyleSlotSet b) => .(a.Words[0] & b.Words[0], a.Words[1] & b.Words[1]);
	public static StyleSlotSet operator~(StyleSlotSet a) => .(~a.Words[0], ~a.Words[1]);

	public bool Equals(StyleSlotSet other) => this == other;

	[Commutable]
	public static bool operator==(StyleSlotSet a, StyleSlotSet b) => (a.Words[0] == b.Words[0]) && (a.Words[1] == b.Words[1]);

	/// Whether any slot is in it.
	public bool Any => (Words[0] | Words[1]) != 0;

	public bool Has(StyleSlot slot) => (Words[(int)slot / 64] & ((uint64)1 << ((int)slot % 64))) != 0;
}

/// What LayoutStyle.bf keeps out of the public surface.
internal static class LayoutStyleDetail
{
	/// The longhand each slot is, in slot order.
	public static String[(int)StyleSlot.SlotCount] sSlotNames = .(
		"opacity",
		"padding-top", "padding-right", "padding-bottom", "padding-left",
		"margin-top", "margin-right", "margin-bottom", "margin-left",
		"width", "height", "min-width", "min-height", "max-width", "max-height",
		"top", "right", "bottom", "left",
		"flex-basis", "flex-grow", "flex-shrink", "order", "z-index", "row-gap", "column-gap",
		"display", "position", "box-sizing", "overflow-x", "overflow-y",
		"flex-direction", "flex-wrap", "justify-content", "align-content", "align-items",
		"justify-items", "align-self", "justify-self", "grid-auto-flow", "dock",
		"grid-template-columns", "grid-template-rows", "grid-auto-rows", "grid-auto-columns",
		"grid-column", "grid-row",
		"scroll-behavior", "overscroll-behavior", "scrollbar-width", "scrollbar-visibility",
		"enabled", "visibility",
		"color", "font-family", "font-size", "text-align", "vertical-align",
		"white-space", "line-height", "letter-spacing",
		"direction",
		"font-weight", "font-style", "overflow-wrap");

	public static bool SameTracks(List<GridTrack> a, List<GridTrack> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i = 0; i < a.Count; i++)
			if (!(a[i] == b[i]))
				return false;
		return true;
	}
}

/// What a container allows a child when it measures it: the border-box size from `Min` to `Max`
/// (cUnbounded for none), and the lengths its percentages resolve against (negative when the
/// container's own size is not known yet). On an axis marked exact the container fixes the size
/// (Min, a flex item's resolved size, a stretch), which even a size the child's style gives
/// takes; on any other, that size overflows the room, as in CSS, even when the room is none
/// (min-content asks with none).
struct LayoutConstraints : IEquatable<LayoutConstraints>
{
	public Float2 Min = .(0.0f, 0.0f);
	public Float2 Max = .(cUnbounded, cUnbounded);
	public Float2 PercentBase = .(-1.0f, -1.0f);
	public bool ExactWidth = false;
	public bool ExactHeight = false;

	public this() { }

	public this(Float2 min, Float2 max, Float2 percentBase, bool exactWidth, bool exactHeight)
	{
		Min = min;
		Max = max;
		PercentBase = percentBase;
		ExactWidth = exactWidth;
		ExactHeight = exactHeight;
	}

	public static LayoutConstraints Tight(Float2 size, Float2 percentBase) => .(size, size, percentBase, true, true);

	public bool Equals(LayoutConstraints other) => this == other;

	[Commutable]
	public static bool operator==(LayoutConstraints a, LayoutConstraints o) =>
		(a.Min.X == o.Min.X) && (a.Min.Y == o.Min.Y) && (a.Max.X == o.Max.X) && (a.Max.Y == o.Max.Y) &&
		(a.PercentBase.X == o.PercentBase.X) && (a.PercentBase.Y == o.PercentBase.Y) && (a.ExactWidth == o.ExactWidth) &&
		(a.ExactHeight == o.ExactHeight);
}

static
{
	/// A length layout leaves unbounded (an available width with no limit).
	public const float cUnbounded = 1.0e30f;

	public static bool IsUnbounded(float length) => length >= 1.0e29f;

	/// The set holding `slot` alone.
	public static StyleSlotSet SlotBit(StyleSlot slot)
	{
		var set = StyleSlotSet();
		set.Words[(int)slot / 64] = (uint64)1 << ((int)slot % 64);
		return set;
	}

	/// The longhand a slot is, as a sheet names it (the inspector's "set by code").
	public static StringView StyleSlotProperty(StyleSlot slot) => LayoutStyleDetail.sSlotNames[(int)slot];

	/// The slots whose values differ between two layout styles: each field a sheet sets as one
	/// property, then the margin (four properties in one field) and the gaps' percentages.
	public static StyleSlotSet ChangedLayoutSlots(LayoutStyle a, LayoutStyle b)
	{
		var bits = StyleSlotSet();
		if (a.Width != b.Width) bits |= SlotBit(.SlotWidth);
		if (a.Height != b.Height) bits |= SlotBit(.SlotHeight);
		if (a.MinWidth != b.MinWidth) bits |= SlotBit(.SlotMinWidth);
		if (a.MinHeight != b.MinHeight) bits |= SlotBit(.SlotMinHeight);
		if (a.MaxWidth != b.MaxWidth) bits |= SlotBit(.SlotMaxWidth);
		if (a.MaxHeight != b.MaxHeight) bits |= SlotBit(.SlotMaxHeight);
		if (a.Top != b.Top) bits |= SlotBit(.SlotTop);
		if (a.Right != b.Right) bits |= SlotBit(.SlotRight);
		if (a.Bottom != b.Bottom) bits |= SlotBit(.SlotBottom);
		if (a.Left != b.Left) bits |= SlotBit(.SlotLeft);
		if (a.Basis != b.Basis) bits |= SlotBit(.SlotFlexBasis);
		if (a.Grow != b.Grow) bits |= SlotBit(.SlotFlexGrow);
		if (a.Shrink != b.Shrink) bits |= SlotBit(.SlotFlexShrink);
		if (a.Order != b.Order) bits |= SlotBit(.SlotOrder);
		if (a.ZIndex != b.ZIndex) bits |= SlotBit(.SlotZIndex);
		if (a.RowGap != b.RowGap) bits |= SlotBit(.SlotRowGap);
		if (a.ColumnGap != b.ColumnGap) bits |= SlotBit(.SlotColumnGap);
		if (a.Kind != b.Kind) bits |= SlotBit(.SlotDisplay);
		if (a.Placement != b.Placement) bits |= SlotBit(.SlotPosition);
		if (a.Sizing != b.Sizing) bits |= SlotBit(.SlotBoxSizing);
		if (a.OverflowX != b.OverflowX) bits |= SlotBit(.SlotOverflowX);
		if (a.OverflowY != b.OverflowY) bits |= SlotBit(.SlotOverflowY);
		if (a.Direction != b.Direction) bits |= SlotBit(.SlotFlexDirection);
		if (a.Wrap != b.Wrap) bits |= SlotBit(.SlotFlexWrap);
		if (a.JustifyContent != b.JustifyContent) bits |= SlotBit(.SlotJustifyContent);
		if (a.AlignContent != b.AlignContent) bits |= SlotBit(.SlotAlignContent);
		if (a.AlignItems != b.AlignItems) bits |= SlotBit(.SlotAlignItems);
		if (a.JustifyItems != b.JustifyItems) bits |= SlotBit(.SlotJustifyItems);
		if (a.AlignSelf != b.AlignSelf) bits |= SlotBit(.SlotAlignSelf);
		if (a.JustifySelf != b.JustifySelf) bits |= SlotBit(.SlotJustifySelf);
		if (a.AutoFlow != b.AutoFlow) bits |= SlotBit(.SlotGridAutoFlow);
		if (a.DockSide != b.DockSide) bits |= SlotBit(.SlotDock);
		if (!LayoutStyleDetail.SameTracks(a.Columns, b.Columns)) bits |= SlotBit(.SlotGridTemplateColumns);
		if ((a.ColumnsRepeatAt != b.ColumnsRepeatAt) || (a.ColumnsRepeatSize != b.ColumnsRepeatSize)) bits |= SlotBit(.SlotGridTemplateColumns);
		if (!LayoutStyleDetail.SameTracks(a.Rows, b.Rows)) bits |= SlotBit(.SlotGridTemplateRows);
		if (a.AutoRows != b.AutoRows) bits |= SlotBit(.SlotGridAutoRows);
		if (a.AutoColumns != b.AutoColumns) bits |= SlotBit(.SlotGridAutoColumns);
		if (a.Column != b.Column) bits |= SlotBit(.SlotGridColumn);
		if (a.Row != b.Row) bits |= SlotBit(.SlotGridRow);
		if (a.Scrolling != b.Scrolling) bits |= SlotBit(.SlotScrollBehavior);
		if (a.Overscroll != b.Overscroll) bits |= SlotBit(.SlotOverscrollBehavior);
		if (a.BarWidth != b.BarWidth) bits |= SlotBit(.SlotScrollbarWidth);
		if (a.BarVisibility != b.BarVisibility) bits |= SlotBit(.SlotScrollbarVisibility);
		if ((a.Margin.Top != b.Margin.Top) || (a.MarginPercent.Top != b.MarginPercent.Top)) bits |= SlotBit(.SlotMarginTop);
		if ((a.Margin.Right != b.Margin.Right) || (a.MarginPercent.Right != b.MarginPercent.Right)) bits |= SlotBit(.SlotMarginRight);
		if ((a.Margin.Bottom != b.Margin.Bottom) || (a.MarginPercent.Bottom != b.MarginPercent.Bottom)) bits |= SlotBit(.SlotMarginBottom);
		if ((a.Margin.Left != b.Margin.Left) || (a.MarginPercent.Left != b.MarginPercent.Left)) bits |= SlotBit(.SlotMarginLeft);
		if (a.RowGapPercent != b.RowGapPercent) bits |= SlotBit(.SlotRowGap);
		if (a.ColumnGapPercent != b.ColumnGapPercent) bits |= SlotBit(.SlotColumnGap);
		return bits;
	}
}
