// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :toggle_switch partition
//
// ToggleSwitch: the button core (E6 of Specs/gui-lab-evolution.md) as a toggle with a track and a
// knob for its indicator, its text beside it: a check box for a setting that takes effect at
// once. Its parts: switch::track (filled when it is on) and ::knob.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:toggle_switch;

import foundation.core; // Color, Min
import foundation.vg;   // CornerRadii
import :rect;
import :draw_context;
import :button_base;
import :text; // TextHAlign

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class ToggleSwitch : public ButtonBase
    {
        RTTI_OBJECT(ToggleSwitch, ButtonBase)
    public:
        ToggleSwitch()
        {
            SetTag(core::StringView(u8"switch"));
            {
                StyleWriteScope defaults(*this);
                SetTextAlignment(TextHAlign::Start, TextVAlign::Middle); // its text beside its indicator
            }
            SetToggle(true);
            MakeIndicator();
        }

        void SetTrackColor(Color off, Color on)
        {
            m_trackOff = off;
            m_trackOn = on;
            Invalidate();
        }
        void SetKnobColor(Color color)
        {
            m_knobColor = color;
            Invalidate();
        }

        // Theming parts: switch::track / ::knob.
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"track"));
            out.PushBack(core::StringView(u8"knob"));
        }

    protected:
        [[nodiscard]] core::Float2 IndicatorSize() const override { return core::Float2{36.0f, 20.0f}; }
        void DrawIndicator(DrawContext& ctx, const Rect& box) const override
        {
            const bool on = IsChecked();
            const f32 r = box.height * 0.5f;
            GetPartStyle(u8"track").Draw(ctx, box, FilledBox(on ? m_trackOn : m_trackOff, vg::CornerRadii(r)));
            const f32 knobR = core::Max(0.0f, r - 3.0f);
            // On at the inline end.
            const f32 cx = MirroredX(on ? box.x + box.width - r : box.x + r, box, IsRightToLeft());
            const f32 cy = box.y + r;
            GetPartStyle(u8"knob").Draw(ctx, Rect{cx - knobR, cy - knobR, knobR * 2.0f, knobR * 2.0f},
                                        FilledBox(m_knobColor, vg::CornerRadii(knobR)));
        }

    private:
        Color m_trackOff{0.32f, 0.35f, 0.40f, 1.0f};
        Color m_trackOn{0.31f, 0.63f, 0.85f, 1.0f};
        Color m_knobColor{0.94f, 0.96f, 0.98f, 1.0f};
    };
}
