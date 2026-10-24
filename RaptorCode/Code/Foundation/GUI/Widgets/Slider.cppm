// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :slider partition
//
// Slider: a draggable value over a range (E6 of Specs/gui-lab-evolution.md): a RangeWidget, so
// min, max, step, page, exponential and the rest are its; horizontal or vertical (a vertical one's
// value grows upward). Pressing or dragging sets the value from the pointer, the dispatcher's
// capture keeping a drag that leaves it; a drag reports `input` as it goes and `change` on release.
// The arrows along it step it (and stay its own at its ends: holding the d-pad to reach an end must
// not throw focus off it), Page Up and Down step a page, Home and End go to the ends, and the wheel
// steps it while it is hovered or focused. Ticks, when asked for, mark the track at even steps.
// Modeled on eepp's UISlider (role only).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:slider;

import foundation.core; // Color, Max, Min, Float2, Rectangle, String
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
    class Slider : public RangeWidget
    {
        RTTI_OBJECT(Slider, RangeWidget)
    public:
        Slider()
        {
            SetTag(core::StringView(u8"slider"));
            SetTabFocusable(true);
        }

        /// A page key's step (0: a tenth of the range).
        [[nodiscard]] f64 GetPage() const noexcept { return GetPageSize(); }
        void SetPage(f64 page) { SetPageSize(page); }

        void SetOrientation(Orientation orientation)
        {
            if (orientation == m_orientation)
                return;
            m_orientation = orientation;
            RequestLayout();
            Invalidate();
        }
        [[nodiscard]] Orientation GetOrientation() const noexcept { return m_orientation; }
        /// "horizontal" or "vertical" (markup's and a sheet's `orientation`).
        void SetOrientationName(const core::String& name)
        {
            SetOrientation(name.AsView() == core::StringView(u8"vertical") ? Orientation::Vertical : Orientation::Horizontal);
        }
        [[nodiscard]] core::String GetOrientationName() const
        {
            return core::String(m_orientation == Orientation::Vertical ? core::StringView(u8"vertical") : core::StringView(u8"horizontal"));
        }
        /// How many marks along the track (its ends included; 0 or 1: none).
        void SetTicks(i32 ticks)
        {
            m_ticks = core::Max(0, ticks);
            Invalidate();
        }
        [[nodiscard]] i32 GetTicks() const noexcept { return m_ticks; }

        void SetTrackColor(Color color)
        {
            m_trackColor = color;
            Invalidate();
        }
        void SetFillColor(Color color)
        {
            m_fillColor = color;
            Invalidate();
        }
        void SetHandleColor(Color color)
        {
            m_handleColor = color;
            Invalidate();
        }
        /// The ring and halo around the thumb while it has keyboard or pad focus.
        void SetFocusColor(Color color)
        {
            m_focusColor = color;
            Invalidate();
        }

        // Theming parts: slider::track / ::fill / ::thumb / ::focus (the thumb's ring) / ::tick.
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"track"));
            out.PushBack(core::StringView(u8"fill"));
            out.PushBack(core::StringView(u8"thumb"));
            out.PushBack(core::StringView(u8"focus"));
            out.PushBack(core::StringView(u8"tick"));
        }

        /// A track's length and a thumb's size when nothing sizes it (E2).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            return m_orientation == Orientation::Vertical ? core::Float2{24.0f, 160.0f} : core::Float2{160.0f, 24.0f};
        }

    protected:
        void OnKeyDown(const KeyEvent& event) override
        {
            if (event.Modifiers != 0)
                return;
            const KeyCode key = static_cast<KeyCode>(event.KeyCode);
            const bool vertical = m_orientation == Orientation::Vertical;
            const f64 step = GetRange().KeyStep();
            const f64 v = GetRange().Value;
            // A horizontal one runs from its start: Left raises it in right to left (E9b).
            const KeyCode lower = Reversed() ? KeyCode::Right : KeyCode::Left;
            const KeyCode raise = Reversed() ? KeyCode::Left : KeyCode::Right;
            if ((!vertical && key == lower) || (vertical && key == KeyCode::Down))
                ChangeByUser(v - step, true);
            else if ((!vertical && key == raise) || (vertical && key == KeyCode::Up))
                ChangeByUser(v + step, true);
            else if (key == KeyCode::PageDown)
                ChangeByUser(v - GetRange().PageStep(), true);
            else if (key == KeyCode::PageUp)
                ChangeByUser(v + GetRange().PageStep(), true);
            else if (key == KeyCode::Home)
                ChangeByUser(GetRange().Min, true);
            else if (key == KeyCode::End)
                ChangeByUser(GetRange().Upper(), true);
            else
                return;
            event.Handled = true;
        }
        // The wheel steps it while it is hovered or focused; at an end it goes on to what holds it.
        void OnMouseWheel(const WheelEvent& event) override
        {
            const f32 notches = event.Delta.y != 0.0f ? event.Delta.y : event.Delta.x;
            if (notches == 0.0f)
                return;
            const f64 before = GetRange().Value;
            ChangeByUser(before + GetRange().KeyStep() * static_cast<f64>(notches), true);
            event.Handled = GetRange().Value != before;
        }

        // Its press is its own (E7): a drag from what holds it is not offered.
        [[nodiscard]] bool OwnsPressDrag(core::Float2) const override { return true; }
        void OnMouseDown(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left)
                return;
            m_dragging = true;
            UpdateFromEvent(event);
            event.Handled = true;
        }
        void OnMouseMove(const MouseEvent& event) override
        {
            if (m_dragging)
                UpdateFromEvent(event);
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
            const bool vertical = m_orientation == Orientation::Vertical;
            const f32 across = vertical ? b.width : b.height; // the thumb's diameter
            const f32 handleR = across * 0.5f;
            const f32 trackW = 4.0f;
            const f32 ratio = static_cast<f32>(GetRatio());
            const f32 lo = (vertical ? b.y : b.x) + handleR;
            const f32 hi = (vertical ? b.y + b.height : b.x + b.width) - handleR;
            // Along the track: from its start (left, or right in right to left), or bottom to top.
            const bool reversed = Reversed();
            const f32 along = vertical || reversed ? hi - (hi - lo) * ratio : lo + (hi - lo) * ratio;
            const f32 mid = vertical ? b.x + b.width * 0.5f : b.y + b.height * 0.5f;
            const core::Float2 handle = vertical ? core::Float2{mid, along} : core::Float2{along, mid};
            const vg::CornerRadii round(trackW * 0.5f);

            // Each part its own look with the sheet's over it (slider::track, ::fill, ::tick, ::thumb, ::focus).
            const Rect track = vertical ? Rect{mid - trackW * 0.5f, b.y, trackW, b.height} : Rect{b.x, mid - trackW * 0.5f, b.width, trackW};
            GetPartStyle(u8"track").Draw(ctx, track, FilledBox(m_trackColor, round));
            const Rect fill = vertical   ? Rect{track.x, along, trackW, b.y + b.height - along}
                              : reversed ? Rect{along, track.y, b.x + b.width - along, trackW}
                                         : Rect{b.x, track.y, along - b.x, trackW};
            GetPartStyle(u8"fill").Draw(ctx, fill, FilledBox(m_fillColor, round));
            if (m_ticks >= 2)
            {
                const PartStyle& tick = GetPartStyle(u8"tick");
                for (i32 i = 0; i < m_ticks; ++i)
                {
                    const f32 t = static_cast<f32>(i) / static_cast<f32>(m_ticks - 1);
                    const f32 at = vertical ? hi - (hi - lo) * t : lo + (hi - lo) * t;
                    const Rect mark = vertical ? Rect{mid + trackW, at - 0.5f, 4.0f, 1.0f} : Rect{at - 0.5f, mid + trackW, 1.0f, 4.0f};
                    tick.Draw(ctx, mark, FilledBox(m_trackColor));
                }
            }
            // Focused by the keyboard or a pad, the thumb (the part that moves) is marked: a ring
            // round it with a glow, not a ring around the whole track.
            if (IsFocusVisible())
            {
                // Its glow takes the ring's colour, the sheet's (slider::focus { border-color }) or its own.
                const PartStyle& focus = GetPartStyle(u8"focus");
                const Color ringColor = focus.HasBorderColor || focus.HasBorderWidth ? focus.Box.BorderColors.top : m_focusColor;
                const f32 ringR = handleR + 3.0f;
                NodeBox ring = OutlinedBox(ringColor, 2.0f, vg::CornerRadii(ringR));
                ring.Shadows.PushBack(BoxShadow{core::Float2{0.0f, 0.0f}, 6.0f, 1.0f,
                                                Color{ringColor.r, ringColor.g, ringColor.b, ringColor.a * 0.45f}, false});
                focus.Draw(ctx, Rect{handle.x - ringR, handle.y - ringR, ringR * 2.0f, ringR * 2.0f}, ring);
            }
            GetPartStyle(u8"thumb").Draw(ctx, Rect{handle.x - handleR, handle.y - handleR, handleR * 2.0f, handleR * 2.0f},
                                         FilledBox(m_handleColor, vg::CornerRadii(handleR)));
        }

    private:
        /// A horizontal slider in right to left runs from the right.
        [[nodiscard]] bool Reversed() const { return m_orientation == Orientation::Horizontal && IsRightToLeft(); }

        void UpdateFromEvent(const MouseEvent& event)
        {
            const Rect b = GetContentBounds();
            const bool vertical = m_orientation == Orientation::Vertical;
            const f32 handleR = (vertical ? b.width : b.height) * 0.5f;
            const core::Float2 local = ConvertToNodeSpace(event.Position);
            const f32 lo = (vertical ? b.y : b.x) + handleR;
            const f32 hi = (vertical ? b.y + b.height : b.x + b.width) - handleR;
            const f32 at = vertical ? local.y : local.x;
            f32 ratio = hi > lo ? (at - lo) / (hi - lo) : 0.0f;
            if (vertical || Reversed())
                ratio = 1.0f - ratio;
            ChangeByUser(GetRange().FromRatio(static_cast<f64>(ratio)), false);
        }

        Orientation m_orientation = Orientation::Horizontal;
        i32 m_ticks = 0;
        bool m_dragging = false;
        Color m_trackColor{0.28f, 0.30f, 0.35f, 1.0f};
        Color m_fillColor{0.31f, 0.63f, 0.85f, 1.0f};
        Color m_handleColor{0.86f, 0.89f, 0.93f, 1.0f};
        Color m_focusColor{0.31f, 0.61f, 1.0f, 1.0f};
    };
}
