// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :rect partition
//
// Rect: 2D float rectangle stored as (x, y, width, height) - matching core::Rectangle
// and the VG render surface, so it converts losslessly for DrawContext. Adapts eepp's
// Rectf (which stores Left/Right/Top/Bottom): the edge accessors Left/Top/Right/Bottom
// reproduce eepp's field reads, while storage stays x/y/w/h for the render path.
//
// Derived from eepp include/eepp/math/rect.hpp; eepp Vector2f -> core::Float2,
// camelCase -> PascalCase.

module;
#include "Core/Prelude.h"

export module foundation.gui:rect;

import foundation.core; // Float2, Rectangle

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    // 2D rectangle. (x, y) is the top-left (min) corner.
    struct Rect
    {
        f32 x = 0.0f;
        f32 y = 0.0f;
        f32 width = 0.0f;
        f32 height = 0.0f;

        constexpr Rect() noexcept = default;
        constexpr Rect(f32 inX, f32 inY, f32 inWidth, f32 inHeight) noexcept
            : x(inX), y(inY), width(inWidth), height(inHeight)
        {
        }
        constexpr Rect(core::Float2 position, core::Float2 size) noexcept
            : x(position.x), y(position.y), width(size.x), height(size.y)
        {
        }

        // Build from edges (eepp Rectf's Left/Top/Right/Bottom layout).
        [[nodiscard]] static constexpr Rect FromLTRB(f32 left, f32 top, f32 right,
                                                     f32 bottom) noexcept
        {
            return Rect{left, top, right - left, bottom - top};
        }
        [[nodiscard]] static constexpr Rect FromMinMax(core::Float2 min, core::Float2 max) noexcept
        {
            return Rect{min.x, min.y, max.x - min.x, max.y - min.y};
        }
        [[nodiscard]] static constexpr Rect FromRectangle(const core::Rectangle& r) noexcept
        {
            return Rect{r.x, r.y, r.width, r.height};
        }

        // Edge accessors (eepp field reads).
        [[nodiscard]] constexpr f32 Left() const noexcept { return x; }
        [[nodiscard]] constexpr f32 Top() const noexcept { return y; }
        [[nodiscard]] constexpr f32 Right() const noexcept { return x + width; }
        [[nodiscard]] constexpr f32 Bottom() const noexcept { return y + height; }

        [[nodiscard]] constexpr core::Float2 Position() const noexcept
        {
            return core::Float2{x, y};
        }
        [[nodiscard]] constexpr core::Float2 Size() const noexcept
        {
            return core::Float2{width, height};
        }
        [[nodiscard]] constexpr core::Float2 Center() const noexcept
        {
            return core::Float2{x + width * 0.5f, y + height * 0.5f};
        }

        [[nodiscard]] constexpr bool IsEmpty() const noexcept
        {
            return width <= 0.0f || height <= 0.0f;
        }

        [[nodiscard]] constexpr bool Contains(core::Float2 p) const noexcept
        {
            return p.x >= x && p.x <= x + width && p.y >= y && p.y <= y + height;
        }
        [[nodiscard]] constexpr bool Contains(const Rect& r) const noexcept
        {
            return r.x >= x && r.y >= y && r.Right() <= Right() && r.Bottom() <= Bottom();
        }

        [[nodiscard]] constexpr bool Intersects(const Rect& other) const noexcept
        {
            return x < other.Right() && Right() > other.x && y < other.Bottom() &&
                   Bottom() > other.y;
        }

        [[nodiscard]] constexpr core::Rectangle ToRectangle() const noexcept
        {
            return core::Rectangle{x, y, width, height};
        }

        // The smallest rect holding both.
        [[nodiscard]] static constexpr Rect Union(const Rect& a, const Rect& b) noexcept
        {
            const f32 x0 = a.x < b.x ? a.x : b.x;
            const f32 y0 = a.y < b.y ? a.y : b.y;
            const f32 x1 = a.Right() > b.Right() ? a.Right() : b.Right();
            const f32 y1 = a.Bottom() > b.Bottom() ? a.Bottom() : b.Bottom();
            return Rect{x0, y0, x1 - x0, y1 - y0};
        }

        // The overlapping rectangle of two rects; empty (zero size) if disjoint.
        [[nodiscard]] static constexpr Rect Intersect(const Rect& a, const Rect& b) noexcept
        {
            const f32 x0 = a.x > b.x ? a.x : b.x;
            const f32 y0 = a.y > b.y ? a.y : b.y;
            const f32 ar = a.Right(), br = b.Right();
            const f32 ab = a.Bottom(), bb = b.Bottom();
            const f32 x1 = ar < br ? ar : br;
            const f32 y1 = ab < bb ? ab : bb;
            const f32 w = (x1 - x0) > 0.0f ? (x1 - x0) : 0.0f;
            const f32 h = (y1 - y0) > 0.0f ? (y1 - y0) : 0.0f;
            return Rect{x0, y0, w, h};
        }

        // The smallest rectangle enclosing both.
        [[nodiscard]] static constexpr Rect Merge(const Rect& a, const Rect& b) noexcept
        {
            const f32 x0 = a.x < b.x ? a.x : b.x;
            const f32 y0 = a.y < b.y ? a.y : b.y;
            const f32 ar = a.Right(), br = b.Right();
            const f32 ab = a.Bottom(), bb = b.Bottom();
            const f32 x1 = ar > br ? ar : br;
            const f32 y1 = ab > bb ? ab : bb;
            return Rect{x0, y0, x1 - x0, y1 - y0};
        }
    };

    /// `x` mirrored across `within` when `mirror`: a widget's own part in right to left (E17a), as
    /// far from the right edge as it was from the left. Its shape mirrors with its points.
    [[nodiscard]] constexpr f32 MirroredX(f32 x, const Rect& within, bool mirror) noexcept
    {
        return mirror ? within.x + within.Right() - x : x;
    }
    /// `r` mirrored across `within` when `mirror`: a part placed from the left, placed from the right.
    [[nodiscard]] constexpr Rect MirroredIn(const Rect& r, const Rect& within, bool mirror) noexcept
    {
        return mirror ? Rect{within.x + within.Right() - r.Right(), r.y, r.width, r.height} : r;
    }

    [[nodiscard]] constexpr bool operator==(const Rect& a, const Rect& b) noexcept
    {
        return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
    }
}
