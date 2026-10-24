// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :radio partition
//
// RadioButton: the button core (E6 of Specs/gui-lab-evolution.md) as a toggle with a ring for its
// indicator, its text beside it. A click checks it and never unchecks it; the radios of one group
// (a `name` in markup, or a ButtonGroup from code) are exclusive, and the arrows move round them.
// Its parts: radio::ring (the outline) and ::dot (the choice).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:radio;

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
    class RadioButton : public ButtonBase
    {
        RTTI_OBJECT(RadioButton, ButtonBase)
    public:
        RadioButton()
        {
            SetTag(core::StringView(u8"radio"));
            {
                StyleWriteScope defaults(*this);
                SetTextAlignment(TextHAlign::Start, TextVAlign::Middle); // its text beside its indicator
            }
            SetToggle(true);
            SetKeepsChecked(true);
            MakeIndicator();
        }

        void SetRingColor(Color color)
        {
            m_ringColor = color;
            Invalidate();
        }
        void SetDotColor(Color color)
        {
            m_dotColor = color;
            Invalidate();
        }

        // Theming parts: radio::ring (outline) / ::dot (inner fill).
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"ring"));
            out.PushBack(core::StringView(u8"dot"));
        }

    protected:
        void DrawIndicator(DrawContext& ctx, const Rect& box) const override
        {
            const f32 r = core::Min(box.width, box.height) * 0.5f;
            const core::Float2 c{box.x + box.width * 0.5f, box.y + box.height * 0.5f};
            GetPartStyle(u8"ring").Draw(ctx, Rect{c.x - r, c.y - r, r * 2.0f, r * 2.0f}, OutlinedBox(m_ringColor, 2.0f, vg::CornerRadii(r)));
            if (IsChecked())
            {
                const f32 d = r * 0.5f;
                GetPartStyle(u8"dot").Draw(ctx, Rect{c.x - d, c.y - d, d * 2.0f, d * 2.0f}, FilledBox(m_dotColor, vg::CornerRadii(d)));
            }
        }

    private:
        Color m_ringColor{0.60f, 0.65f, 0.72f, 1.0f};
        Color m_dotColor{0.31f, 0.63f, 0.85f, 1.0f};
    };
}
