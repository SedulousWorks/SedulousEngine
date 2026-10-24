// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :layout_style partition
//
// What a node asks of layout (E2 of Specs/gui-lab-evolution.md), one record on every node, filled
// from its sheet, its markup or code: how it sizes (width, height, min, max: a length, a
// percentage of its container, or auto), how it lays out its children (display: flex, grid,
// stack, dock or none, with each kind's properties), how its container places it (the flex,
// grid and dock item properties, margin), whether it is out of flow (position and insets), and
// whether it clips or scrolls (overflow). Lengths in em, rem, vw and vh are resolved to pixels
// when the style is applied; percentages and auto wait for layout, which knows the container.

module;
#include "Core/Prelude.h"

export module foundation.gui:layout_style;

import foundation.core; // Array, Float2, Optional
import :thickness;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A length as layout reads it: auto (the content's, or what the container gives), pixels,
    /// a percentage of the container's content box, or one of CSS's content sizes. None is a
    /// max-width or max-height with no bound.
    enum class LayoutLengthKind : u8
    {
        Auto,
        Px,
        Percent,
        FitContent,
        MinContent,
        MaxContent,
        None,
        Calc, ///< Value pixels and Percent of the base (a calc() mixing them, E13)
    };
    struct LayoutLength
    {
        LayoutLengthKind Kind = LayoutLengthKind::Auto;
        f32 Value = 0.0f;
        f32 PercentPart = 0.0f; ///< a Calc's percentage part

        [[nodiscard]] static constexpr LayoutLength Px(f32 v) noexcept { return {LayoutLengthKind::Px, v}; }
        [[nodiscard]] static constexpr LayoutLength Percent(f32 v) noexcept { return {LayoutLengthKind::Percent, v}; }
        [[nodiscard]] static constexpr LayoutLength None() noexcept { return {LayoutLengthKind::None, 0.0f}; }
        [[nodiscard]] static constexpr LayoutLength Calc(f32 px, f32 percent) noexcept { return {LayoutLengthKind::Calc, px, percent}; }
        [[nodiscard]] constexpr bool IsAuto() const noexcept { return Kind == LayoutLengthKind::Auto; }
        /// The length in pixels against `base` (the container's content length, negative when it
        /// is not known yet); none for auto, a content size, or a percentage of an unknown base.
        [[nodiscard]] Optional<f32> Resolve(f32 base) const noexcept
        {
            switch (Kind)
            {
            case LayoutLengthKind::Px: return Value;
            case LayoutLengthKind::Percent:
                if (base >= 0.0f)
                    return Value * base / 100.0f;
                return {};
            case LayoutLengthKind::Calc:
                if (base >= 0.0f)
                    return Value + PercentPart * base / 100.0f;
                return {};
            default: return {};
            }
        }
        [[nodiscard]] constexpr bool operator==(const LayoutLength&) const noexcept = default;
    };

    /// A bar's or a track's direction (a scrollbar, a tab strip).
    enum class Orientation : u8
    {
        Horizontal,
        Vertical
    };

    /// How a node lays out its children (CSS `display`). A plain container is a flex column.
    enum class Display : u8
    {
        Flex,
        Grid,
        Stack, ///< children over each other in the content box, each aligned on its own
        Dock,  ///< children docked to the sides in order, the last filling what remains
        None,  ///< the node and its subtree take no space and draw nothing
    };
    /// In its container's flow, offset after it, or out of it (placed by its insets).
    enum class Position : u8
    {
        Static,
        Relative,
        Absolute,
    };
    enum class FlexDirection : u8
    {
        Row,
        Column,
        RowReverse,
        ColumnReverse,
    };
    enum class FlexWrap : u8
    {
        NoWrap,
        Wrap,
        WrapReverse,
    };
    /// Distribution along an axis (justify-content, align-content).
    enum class Justify : u8
    {
        Start,
        End,
        Center,
        SpaceBetween,
        SpaceAround,
        SpaceEvenly,
        Stretch, ///< align-content's normal: lines share the free space
    };
    /// Placement across an axis (align-items, align-self, justify-items, justify-self). Auto on
    /// an item takes the container's.
    enum class Align : u8
    {
        Auto,
        Start,
        End,
        Center,
        Stretch,
        Baseline,
    };
    enum class Dock : u8
    {
        Fill,
        Left,
        Top,
        Right,
        Bottom,
        Start, ///< the inline start: left, or right in right to left (E9b)
        End,   ///< the inline end
    };
    /// Visible draws children outside the box; hidden clips them; scroll and auto clip and
    /// scroll (scroll always shows its bar, auto when the content overflows).
    enum class Overflow : u8
    {
        Visible,
        Hidden,
        Scroll,
        Auto,
    };
    /// How a scroll moves (CSS's scroll-behavior): at once, or easing to where it is going. A call
    /// may ask for either, or for Auto, the node's own (`scroll-behavior: smooth` opts in).
    enum class ScrollBehavior : u8
    {
        Auto,
        Instant,
        Smooth,
    };
    /// What a scroller at its end does with the wheel (CSS's overscroll-behavior): passes it to the
    /// scroller around it, or keeps it (`contain`, a popup's list that must not scroll the page).
    enum class OverscrollBehavior : u8
    {
        Auto,
        Contain,
    };
    /// How thick a scroller's bars are (CSS's scrollbar-width); `none` hides them, the node still
    /// scrolling by the wheel, the keys and touch.
    enum class ScrollbarWidth : u8
    {
        Auto,
        Thin,
        None,
    };
    /// Whether a scroller's bars stay shown (while it overflows, or always for `overflow:
    /// scroll`) or are an overlay that shows while it scrolls or is hovered and then fades.
    enum class ScrollbarVisibility : u8
    {
        Auto,
        Overlay,
    };
    /// Where a scroll into view puts what it shows: the least move that shows it, or its start,
    /// centre or end at the box's.
    enum class ScrollAlign : u8
    {
        Nearest,
        Start,
        Center,
        End,
    };
    /// Whether width and height include the padding and border (the GUI's default, what a UI
    /// author means by a 120 pixel button) or are the content's alone, CSS's initial value.
    enum class BoxSizing : u8
    {
        BorderBox,
        ContentBox,
    };
    enum class GridAutoFlow : u8
    {
        Row,
        Column,
    };

    /// A grid track's size: from `Min` to `Max`, or a share of the free space (`Fr` > 0, its
    /// minimum `Min`). `120px` is Min = Max = 120; `1fr` is Fr 1; `auto` is Min = Max = auto (the
    /// content's); `minmax(100px, 1fr)` is Min 100 and Fr 1.
    struct GridTrack
    {
        LayoutLength Min{};
        LayoutLength Max{};
        f32 Fr = 0.0f;

        [[nodiscard]] static constexpr GridTrack Fixed(f32 px) noexcept { return {LayoutLength::Px(px), LayoutLength::Px(px), 0.0f}; }
        [[nodiscard]] static constexpr GridTrack Flex(f32 fr) noexcept { return {LayoutLength{}, LayoutLength{}, fr}; }
        [[nodiscard]] constexpr bool operator==(const GridTrack&) const noexcept = default;
    };
    /// Where an item sits on one grid axis: a 1-based start line (0: placed automatically) and
    /// how many tracks it spans.
    struct GridPlacement
    {
        i32 Start = 0;
        i32 Span = 1;
        [[nodiscard]] constexpr bool operator==(const GridPlacement&) const noexcept = default;
    };

    struct LayoutStyle
    {
        // --- The node's own box ---
        LayoutLength Width{};
        LayoutLength Height{};
        LayoutLength MinWidth{}; ///< auto: none, but a flex item's content minimum
        LayoutLength MinHeight{};
        LayoutLength MaxWidth = LayoutLength::None();
        LayoutLength MaxHeight = LayoutLength::None();
        Thickness Margin{};
        /// Percentages of the containing box's width each side adds (CSS's `margin: 5%`), resolved
        /// at layout, where that width is known.
        Thickness MarginPercent{};
        BoxSizing Sizing = BoxSizing::BorderBox;
        Overflow OverflowX = Overflow::Visible;
        Overflow OverflowY = Overflow::Visible;
        ScrollBehavior Scrolling = ScrollBehavior::Auto;
        OverscrollBehavior Overscroll = OverscrollBehavior::Auto;
        ScrollbarWidth BarWidth = ScrollbarWidth::Auto;
        ScrollbarVisibility BarVisibility = ScrollbarVisibility::Auto;

        // --- Out of flow ---
        Position Placement = Position::Static;
        LayoutLength Left{};
        LayoutLength Top{};
        LayoutLength Right{};
        LayoutLength Bottom{};
        i32 ZIndex = 0;

        // --- How it lays out its children ---
        Display Kind = Display::Flex;
        FlexDirection Direction = FlexDirection::Column;
        FlexWrap Wrap = FlexWrap::NoWrap;
        Justify JustifyContent = Justify::Start;
        Align AlignItems = Align::Stretch;
        Justify AlignContent = Justify::Stretch;
        Align JustifyItems = Align::Stretch; ///< grid and stack
        f32 RowGap = 0.0f;
        f32 ColumnGap = 0.0f;
        f32 RowGapPercent = 0.0f;    ///< of the container's content height, resolved at layout
        f32 ColumnGapPercent = 0.0f; ///< of its content width
        Array<GridTrack> Columns;
        Array<GridTrack> Rows;
        GridTrack AutoRows{};
        GridTrack AutoColumns{};
        GridAutoFlow AutoFlow = GridAutoFlow::Row;

        // --- How its container places it ---
        f32 Grow = 0.0f;
        f32 Shrink = 1.0f;
        LayoutLength Basis{};
        Align AlignSelf = Align::Auto;
        Align JustifySelf = Align::Auto;
        i32 Order = 0;
        GridPlacement Column{};
        GridPlacement Row{};
        foundation::gui::Dock DockSide = foundation::gui::Dock::Fill;
    };

    /// The properties a sheet may set through a node's setters, one bit each (E3): code that sets
    /// one makes it its own, as CSS's inline style, and the sheet leaves it be (Node pins it).
    enum StyleSlot : u32
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
    };
    /// A set of StyleSlots: what code pinned, what a change touched. Two words: the slots passed 64
    /// with E11's font-weight, font-style and overflow-wrap.
    struct StyleSlotSet
    {
        static constexpr usize kWords = 2;
        u64 Words[kWords]{};
        [[nodiscard]] constexpr StyleSlotSet operator|(StyleSlotSet o) const noexcept
        {
            return StyleSlotSet{{Words[0] | o.Words[0], Words[1] | o.Words[1]}};
        }
        [[nodiscard]] constexpr StyleSlotSet operator&(StyleSlotSet o) const noexcept
        {
            return StyleSlotSet{{Words[0] & o.Words[0], Words[1] & o.Words[1]}};
        }
        [[nodiscard]] constexpr StyleSlotSet operator~() const noexcept { return StyleSlotSet{{~Words[0], ~Words[1]}}; }
        constexpr StyleSlotSet& operator|=(StyleSlotSet o) noexcept { return *this = *this | o; }
        constexpr StyleSlotSet& operator&=(StyleSlotSet o) noexcept { return *this = *this & o; }
        [[nodiscard]] constexpr bool operator==(const StyleSlotSet&) const noexcept = default;
        /// Whether any slot is in it.
        [[nodiscard]] constexpr bool Any() const noexcept { return (Words[0] | Words[1]) != 0; }
        [[nodiscard]] constexpr bool Has(StyleSlot slot) const noexcept { return (Words[slot / 64] & (u64{1} << (slot % 64))) != 0; }
    };
    static_assert(SlotCount <= StyleSlotSet::kWords * 64, "a bit for every slot");
    [[nodiscard]] constexpr StyleSlotSet SlotBit(StyleSlot slot) noexcept
    {
        StyleSlotSet set;
        set.Words[slot / 64] = u64{1} << (slot % 64);
        return set;
    }
    /// The longhand a slot is, as a sheet names it (the inspector's "set by code").
    [[nodiscard]] constexpr const char8_t* StyleSlotProperty(StyleSlot slot) noexcept
    {
        constexpr const char8_t* kNames[] = {
            u8"opacity",
            u8"padding-top", u8"padding-right", u8"padding-bottom", u8"padding-left",
            u8"margin-top", u8"margin-right", u8"margin-bottom", u8"margin-left",
            u8"width", u8"height", u8"min-width", u8"min-height", u8"max-width", u8"max-height",
            u8"top", u8"right", u8"bottom", u8"left",
            u8"flex-basis", u8"flex-grow", u8"flex-shrink", u8"order", u8"z-index", u8"row-gap", u8"column-gap",
            u8"display", u8"position", u8"box-sizing", u8"overflow-x", u8"overflow-y",
            u8"flex-direction", u8"flex-wrap", u8"justify-content", u8"align-content", u8"align-items",
            u8"justify-items", u8"align-self", u8"justify-self", u8"grid-auto-flow", u8"dock",
            u8"grid-template-columns", u8"grid-template-rows", u8"grid-auto-rows", u8"grid-auto-columns",
            u8"grid-column", u8"grid-row",
            u8"scroll-behavior", u8"overscroll-behavior", u8"scrollbar-width", u8"scrollbar-visibility",
            u8"enabled", u8"visibility",
            u8"color", u8"font-family", u8"font-size", u8"text-align", u8"vertical-align",
            u8"white-space", u8"line-height", u8"letter-spacing",
            u8"direction",
            u8"font-weight", u8"font-style", u8"overflow-wrap",
        };
        static_assert(sizeof(kNames) / sizeof(kNames[0]) == SlotCount, "a name for every slot");
        return kNames[slot];
    }

    /// Calls `f(slot, member)` for each LayoutStyle field a sheet sets as one property (the margin,
    /// four properties in one field, is apart).
    template <typename F>
    constexpr void ForEachLayoutField(F&& f)
    {
        f(SlotWidth, &LayoutStyle::Width);
        f(SlotHeight, &LayoutStyle::Height);
        f(SlotMinWidth, &LayoutStyle::MinWidth);
        f(SlotMinHeight, &LayoutStyle::MinHeight);
        f(SlotMaxWidth, &LayoutStyle::MaxWidth);
        f(SlotMaxHeight, &LayoutStyle::MaxHeight);
        f(SlotTop, &LayoutStyle::Top);
        f(SlotRight, &LayoutStyle::Right);
        f(SlotBottom, &LayoutStyle::Bottom);
        f(SlotLeft, &LayoutStyle::Left);
        f(SlotFlexBasis, &LayoutStyle::Basis);
        f(SlotFlexGrow, &LayoutStyle::Grow);
        f(SlotFlexShrink, &LayoutStyle::Shrink);
        f(SlotOrder, &LayoutStyle::Order);
        f(SlotZIndex, &LayoutStyle::ZIndex);
        f(SlotRowGap, &LayoutStyle::RowGap);
        f(SlotColumnGap, &LayoutStyle::ColumnGap);
        f(SlotDisplay, &LayoutStyle::Kind);
        f(SlotPosition, &LayoutStyle::Placement);
        f(SlotBoxSizing, &LayoutStyle::Sizing);
        f(SlotOverflowX, &LayoutStyle::OverflowX);
        f(SlotOverflowY, &LayoutStyle::OverflowY);
        f(SlotFlexDirection, &LayoutStyle::Direction);
        f(SlotFlexWrap, &LayoutStyle::Wrap);
        f(SlotJustifyContent, &LayoutStyle::JustifyContent);
        f(SlotAlignContent, &LayoutStyle::AlignContent);
        f(SlotAlignItems, &LayoutStyle::AlignItems);
        f(SlotJustifyItems, &LayoutStyle::JustifyItems);
        f(SlotAlignSelf, &LayoutStyle::AlignSelf);
        f(SlotJustifySelf, &LayoutStyle::JustifySelf);
        f(SlotGridAutoFlow, &LayoutStyle::AutoFlow);
        f(SlotDock, &LayoutStyle::DockSide);
        f(SlotGridTemplateColumns, &LayoutStyle::Columns);
        f(SlotGridTemplateRows, &LayoutStyle::Rows);
        f(SlotGridAutoRows, &LayoutStyle::AutoRows);
        f(SlotGridAutoColumns, &LayoutStyle::AutoColumns);
        f(SlotGridColumn, &LayoutStyle::Column);
        f(SlotGridRow, &LayoutStyle::Row);
        f(SlotScrollBehavior, &LayoutStyle::Scrolling);
        f(SlotOverscrollBehavior, &LayoutStyle::Overscroll);
        f(SlotScrollbarWidth, &LayoutStyle::BarWidth);
        f(SlotScrollbarVisibility, &LayoutStyle::BarVisibility);
    }
    namespace detail
    {
        template <typename T>
        [[nodiscard]] constexpr bool SameField(const T& a, const T& b)
        {
            if constexpr (requires { a.Size(); a[0]; })
            {
                if (a.Size() != b.Size())
                    return false;
                for (usize i = 0; i < a.Size(); ++i)
                    if (!(a[i] == b[i]))
                        return false;
                return true;
            }
            else
                return a == b;
        }
    }
    /// The slots whose values differ between two layout styles.
    [[nodiscard]] inline StyleSlotSet ChangedLayoutSlots(const LayoutStyle& a, const LayoutStyle& b)
    {
        StyleSlotSet bits;
        ForEachLayoutField([&](StyleSlot slot, auto member)
        {
            if (!detail::SameField(a.*member, b.*member))
                bits |= SlotBit(slot);
        });
        if (a.Margin.Top != b.Margin.Top || a.MarginPercent.Top != b.MarginPercent.Top) bits |= SlotBit(SlotMarginTop);
        if (a.Margin.Right != b.Margin.Right || a.MarginPercent.Right != b.MarginPercent.Right) bits |= SlotBit(SlotMarginRight);
        if (a.Margin.Bottom != b.Margin.Bottom || a.MarginPercent.Bottom != b.MarginPercent.Bottom) bits |= SlotBit(SlotMarginBottom);
        if (a.Margin.Left != b.Margin.Left || a.MarginPercent.Left != b.MarginPercent.Left) bits |= SlotBit(SlotMarginLeft);
        if (a.RowGapPercent != b.RowGapPercent) bits |= SlotBit(SlotRowGap);
        if (a.ColumnGapPercent != b.ColumnGapPercent) bits |= SlotBit(SlotColumnGap);
        return bits;
    }

    /// A length layout leaves unbounded (an available width with no limit).
    inline constexpr f32 kUnbounded = 1.0e30f;
    [[nodiscard]] constexpr bool IsUnbounded(f32 length) noexcept { return length >= 1.0e29f; }

    /// What a container allows a child when it measures it: the border-box size from `Min` to
    /// `Max` (kUnbounded for none), and the lengths its percentages resolve against (negative when
    /// the container's own size is not known yet). On an axis marked exact the container fixes the
    /// size (Min, a flex item's resolved size, a stretch), which even a size the child's style gives
    /// takes; on any other, that size overflows the room, as in CSS, even when the room is none
    /// (min-content asks with none).
    struct LayoutConstraints
    {
        core::Float2 Min{0.0f, 0.0f};
        core::Float2 Max{kUnbounded, kUnbounded};
        core::Float2 PercentBase{-1.0f, -1.0f};
        bool ExactWidth = false;
        bool ExactHeight = false;

        [[nodiscard]] static LayoutConstraints Tight(core::Float2 size, core::Float2 percentBase) noexcept
        {
            return LayoutConstraints{size, size, percentBase, true, true};
        }
        [[nodiscard]] bool operator==(const LayoutConstraints& o) const noexcept
        {
            return Min.x == o.Min.x && Min.y == o.Min.y && Max.x == o.Max.x && Max.y == o.Max.y &&
                   PercentBase.x == o.PercentBase.x && PercentBase.y == o.PercentBase.y && ExactWidth == o.ExactWidth &&
                   ExactHeight == o.ExactHeight;
        }
    };
}
