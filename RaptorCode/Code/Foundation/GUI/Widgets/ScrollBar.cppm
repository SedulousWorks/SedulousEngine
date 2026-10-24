// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :scroll_bar partition
//
// ScrollBar: a draggable scroll position over a range (E6 of Specs/gui-lab-evolution.md): a
// RangeWidget whose value is the offset and whose page is the visible part, so the value goes no
// further than the maximum less the page and the thumb's length is the page's share of the range.
// Modeled on eepp's UIScrollBar (role, not a line-for-line port). Horizontal or vertical. A drag of
// the thumb keeps its grab point under the pointer and reports `input` as it goes and `change` on
// release; a press on the track pages toward it.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:scroll_bar;

import foundation.core; // Color, Function, Move, Max, Min, Float2, Rectangle, RefPtr, MakeRef
import foundation.vg;   // CornerRadii
import :rect;
import :event;
import :draw_context;
import :ui_widget;
import :layout_style; // Orientation
import :range_value;
import :range_widget;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class ScrollBar : public RangeWidget
    {
        RTTI_OBJECT(ScrollBar, RangeWidget)
    public:
        ScrollBar()
        {
            SetTag(core::StringView(u8"scrollbar"));
            SetPageShown(true); // its page is the visible part
            // The track is the node background so the theme's background-color styles it.
            SetBox(FilledBox(m_trackColor)); // its own track, which a sheet's (a theme's) replaces
        }

        void SetOrientation(Orientation orientation)
        {
            m_orientation = orientation;
            Invalidate();
        }
        [[nodiscard]] Orientation GetOrientation() const noexcept { return m_orientation; }
        /// "horizontal" or "vertical" (markup's `orientation`).
        void SetOrientationName(const core::String& name)
        {
            SetOrientation(core::Trim(name.AsView()) == core::StringView(u8"vertical") ? Orientation::Vertical : Orientation::Horizontal);
        }
        [[nodiscard]] core::String GetOrientationName() const
        {
            return core::String(m_orientation == Orientation::Vertical ? core::StringView(u8"vertical") : core::StringView(u8"horizontal"));
        }

        /// The visible part: the thumb's share of the range, and a track press's step.
        [[nodiscard]] f64 GetPage() const noexcept { return GetPageSize(); }
        void SetPage(f64 page) { SetPageSize(page); }
        /// The thumb's share of the track: the page over the range.
        [[nodiscard]] f32 GetThumbProportion() const
        {
            const f64 span = GetRange().Max - GetRange().Min;
            return span > 0.0 ? static_cast<f32>(core::Min(1.0, GetRange().Page / span)) : 1.0f;
        }

        void SetTrackColor(Color color)
        {
            m_trackColor = color;
            SetBox(FilledBox(color));
        }
        void SetThumbColor(Color color)
        {
            m_thumbColor = color;
            Invalidate();
        }

        // Theming: track = background-color (node background); thumb = scrollbar::thumb part.
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"thumb"));
        }

        /// A bar's thickness and length when nothing sizes it (E2).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            return m_orientation == Orientation::Vertical ? core::Float2{12.0f, 120.0f} : core::Float2{120.0f, 12.0f};
        }

    protected:
        // Press on the thumb starts a grab-drag (the thumb keeps its offset under the cursor,
        // so it doesn't jump); press on the track above/below the thumb pages toward the click
        // by one visible proportion (eepp-style), no drag.
        // Its press is its own (E7): a drag from what holds it is not offered.
        [[nodiscard]] bool OwnsPressDrag(core::Float2) const override { return true; }
        void OnMouseDown(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left)
                return; // only the left button drags/pages
            event.Handled = true;
            const Rect b = GetContentBounds();
            const f32 track = TrackLength(b);
            const f32 thumbLen = ThumbLength(track);
            const f32 travel = core::Max(0.0f, track - thumbLen);
            const f32 thumbStart = travel * static_cast<f32>(GetRatio());
            const f32 along = AlongAxis(event, b);

            if (along >= thumbStart && along <= thumbStart + thumbLen)
            {
                m_dragging = true;
                m_grabOffset = along - thumbStart; // keep the grab point fixed under the cursor
            }
            else
            {
                const f64 page = GetRange().PageStep();
                ChangeByUser(GetRange().Value + (along < thumbStart ? -page : page), true);
            }
        }
        void OnMouseMove(const MouseEvent& event) override
        {
            if (!m_dragging)
                return;
            const Rect b = GetContentBounds();
            const f32 track = TrackLength(b);
            const f32 thumbLen = ThumbLength(track);
            const f32 travel = core::Max(0.0f, track - thumbLen);
            if (travel <= 0.0f)
                return;
            ChangeByUser(GetRange().FromRatio(static_cast<f64>((AlongAxis(event, b) - m_grabOffset) / travel)), false);
        }
        void OnMouseUp(const MouseEvent& event) override
        {
            (void)event;
            if (m_dragging)
                Commit();
            m_dragging = false;
        }
        void OnPointerCancel(const MouseEvent&) override
        {
            if (m_dragging)
                Commit();
            m_dragging = false;
        }

        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            const Rect b = GetContentBounds();
            const f32 track = TrackLength(b);
            const f32 thumbLen = ThumbLength(track);
            const f32 travel = core::Max(0.0f, track - thumbLen);
            const f32 pos = travel * static_cast<f32>(GetRatio());

            // The track is painted by the node background (themable via background-color); we
            // draw only the thumb here.
            // Across, its start is the inline start: the right in right to left.
            const Rect thumb = (m_orientation == Orientation::Vertical)
                                   ? Rect{b.x, b.y + pos, b.width, thumbLen}
                                   : MirroredIn(Rect{b.x + pos, b.y, thumbLen, b.height}, b, IsRightToLeft());
            GetPartStyle(u8"thumb").Draw(ctx, thumb, FilledBox(m_thumbColor, Radii(thumb)));
        }

    private:
        [[nodiscard]] f32 TrackLength(const Rect& b) const
        {
            return (m_orientation == Orientation::Vertical) ? b.height : b.width;
        }
        [[nodiscard]] f32 ThumbLength(f32 track) const
        {
            return core::Min(track, core::Max(kMinThumb, track * GetThumbProportion()));
        }
        [[nodiscard]] static vg::CornerRadii Radii(const Rect& r)
        {
            return vg::CornerRadii(core::Min(r.width, r.height) * 0.5f);
        }

        // Cursor position along the bar's axis, relative to the track start (the inline start across).
        [[nodiscard]] f32 AlongAxis(const MouseEvent& event, const Rect& b) const
        {
            const core::Float2 local = ConvertToNodeSpace(event.Position);
            if (m_orientation == Orientation::Vertical)
                return local.y - b.y;
            return IsRightToLeft() ? b.Right() - local.x : local.x - b.x;
        }

        Orientation m_orientation = Orientation::Vertical;
        bool m_dragging = false;
        f32 m_grabOffset = 0.0f;
        Color m_trackColor{0.18f, 0.19f, 0.23f, 1.0f};
        Color m_thumbColor{0.42f, 0.45f, 0.52f, 1.0f};
        static constexpr f32 kMinThumb = 16.0f;
    };

}
