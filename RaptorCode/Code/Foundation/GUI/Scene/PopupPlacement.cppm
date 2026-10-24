// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :popup_placement partition
//
// Where a popup goes (E5 of Specs/gui-lab-evolution.md): one helper every popup places itself with,
// a combo box's list, a menu and its submenus, a tooltip and a context menu. A size goes against an
// anchor rectangle on a preferred side (below, above, or at the anchor's inline end or start),
// aligned along that side (start, centre or end) and a gap away; when it does not fit there it flips to the other side if
// that side has more room, shrinks to the room on the side it goes (a list then scrolls), and is
// clamped into the bounds (the root's), all in the root's units. The sides across the line and the
// alignment along it are logical (E17a): in right to left the inline end is the left, and a
// dropdown's start lines up the right edges, as CSS's logical properties and Godot's and eepp's
// right-to-left menus place them.
// After Godot's popup clamping, GPUI's `anchored` and foundation.ui's PopupPositioner.

module;
#include "Core/Prelude.h"

export module foundation.gui:popup_placement;

import foundation.core; // Float2, Max, Min
import :rect;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// The side of the anchor a popup goes on: below or above it, or at its inline end or start
    /// (right or left in left to right, left or right in right to left).
    enum class PopupSide : u8
    {
        Below,
        Above,
        InlineEnd,
        InlineStart,
    };
    /// How a popup lines up along the side it goes on: its start with the anchor's start (a
    /// dropdown's inline-start edges, a submenu's tops), centred on it, or its end with the
    /// anchor's end.
    enum class PopupAlign : u8
    {
        Start,
        Center,
        End,
    };

    struct PopupPlacement
    {
        PopupSide Side = PopupSide::Below;
        PopupAlign Align = PopupAlign::Start;
        f32 Gap = 0.0f;      ///< between the anchor and the popup
        bool Shrink = true;  ///< made smaller to fit the room on its side, rather than covering the anchor
    };

    /// Where it went, and on which side (after a flip, the other one).
    struct PlacedPopup
    {
        core::Float2 Position{0.0f, 0.0f};
        core::Float2 Size{0.0f, 0.0f}; ///< what it was given, its own or shrunk to fit
        PopupSide Side = PopupSide::Below;
    };

    [[nodiscard]] constexpr PopupSide OppositeSide(PopupSide side) noexcept
    {
        switch (side)
        {
        case PopupSide::Below: return PopupSide::Above;
        case PopupSide::Above: return PopupSide::Below;
        case PopupSide::InlineEnd: return PopupSide::InlineStart;
        default: return PopupSide::InlineEnd;
        }
    }

    namespace detail
    {
        // The sides as they fall on the screen.
        enum class ScreenSide : u8
        {
            Below,
            Above,
            Right,
            Left,
        };
        [[nodiscard]] constexpr ScreenSide OnScreen(PopupSide side, bool rightToLeft) noexcept
        {
            switch (side)
            {
            case PopupSide::Below: return ScreenSide::Below;
            case PopupSide::Above: return ScreenSide::Above;
            case PopupSide::InlineEnd: return rightToLeft ? ScreenSide::Left : ScreenSide::Right;
            default: return rightToLeft ? ScreenSide::Right : ScreenSide::Left;
            }
        }
        // The room between the anchor and the bounds' edge on `side`.
        [[nodiscard]] constexpr f32 RoomOn(ScreenSide side, const Rect& anchor, const Rect& bounds, f32 gap) noexcept
        {
            switch (side)
            {
            case ScreenSide::Below: return bounds.y + bounds.height - (anchor.y + anchor.height) - gap;
            case ScreenSide::Above: return anchor.y - bounds.y - gap;
            case ScreenSide::Right: return bounds.x + bounds.width - (anchor.x + anchor.width) - gap;
            default: return anchor.x - bounds.x - gap;
            }
        }
        // Lined up along a side: from `start` (the anchor's) over `length`, a popup `extent` long.
        [[nodiscard]] constexpr f32 Aligned(PopupAlign align, f32 start, f32 length, f32 extent) noexcept
        {
            switch (align)
            {
            case PopupAlign::Center: return start + (length - extent) * 0.5f;
            case PopupAlign::End: return start + length - extent;
            default: return start;
            }
        }
        // Into [low, low + room]: a popup longer than the room starts at its low edge.
        [[nodiscard]] constexpr f32 Clamped(f32 at, f32 extent, f32 low, f32 room) noexcept
        {
            if (at + extent > low + room)
                at = low + room - extent;
            return at < low ? low : at;
        }
    }

    /// Places `size` against `anchor` within `bounds` as `placement` prefers, its logical side and
    /// alignment taken in the direction `rightToLeft` says (the anchor's).
    [[nodiscard]] constexpr PlacedPopup PlacePopup(const Rect& anchor, core::Float2 size, const Rect& bounds,
                                                   const PopupPlacement& placement, bool rightToLeft) noexcept
    {
        using detail::ScreenSide;
        PopupSide side = placement.Side;
        const bool vertical = side == PopupSide::Below || side == PopupSide::Above;
        const f32 need = vertical ? size.y : size.x;
        const f32 room = detail::RoomOn(detail::OnScreen(side, rightToLeft), anchor, bounds, placement.Gap);
        if (room < need &&
            detail::RoomOn(detail::OnScreen(OppositeSide(side), rightToLeft), anchor, bounds, placement.Gap) > room)
            side = OppositeSide(side);
        const ScreenSide screen = detail::OnScreen(side, rightToLeft);

        PlacedPopup out;
        out.Side = side;
        // Shrunk to the room on its side (along it) and to the bounds (across).
        if (placement.Shrink)
        {
            const f32 sideRoom = core::Max(0.0f, detail::RoomOn(screen, anchor, bounds, placement.Gap));
            if (vertical)
            {
                size.y = core::Min(size.y, sideRoom);
                size.x = core::Min(size.x, bounds.width);
            }
            else
            {
                size.x = core::Min(size.x, sideRoom);
                size.y = core::Min(size.y, bounds.height);
            }
        }
        out.Size = size;
        const f32 gap = placement.Gap;
        switch (screen)
        {
        case ScreenSide::Below: out.Position.y = anchor.y + anchor.height + gap; break;
        case ScreenSide::Above: out.Position.y = anchor.y - gap - size.y; break;
        case ScreenSide::Right: out.Position.x = anchor.x + anchor.width + gap; break;
        case ScreenSide::Left: out.Position.x = anchor.x - gap - size.x; break;
        }
        if (vertical)
        {
            // Along the line: the start is the right in right to left.
            PopupAlign align = placement.Align;
            if (rightToLeft && align != PopupAlign::Center)
                align = align == PopupAlign::Start ? PopupAlign::End : PopupAlign::Start;
            out.Position.x = detail::Aligned(align, anchor.x, anchor.width, size.x);
        }
        else
            out.Position.y = detail::Aligned(placement.Align, anchor.y, anchor.height, size.y);
        out.Position.x = detail::Clamped(out.Position.x, size.x, bounds.x, bounds.width);
        out.Position.y = detail::Clamped(out.Position.y, size.y, bounds.y, bounds.height);
        return out;
    }

    /// A popup at a point (a context menu at the pointer): below it and toward the inline end,
    /// above it where it does not fit below, slid back in from the edges.
    [[nodiscard]] constexpr PlacedPopup PlaceAtPoint(core::Float2 point, core::Float2 size, const Rect& bounds,
                                                     bool rightToLeft) noexcept
    {
        return PlacePopup(Rect{point.x, point.y, 0.0f, 0.0f}, size, bounds, PopupPlacement{}, rightToLeft);
    }
}
