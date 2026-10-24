// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :check_box partition
//
// CheckBox: the button core (E6 of Specs/gui-lab-evolution.md) as a toggle with a box for its
// indicator, its text beside it. It is tri-state: checked, unchecked, or indeterminate (a parent
// of mixed children, CSS's :indeterminate), drawn as a dash until it is set or clicked; a click
// on an indeterminate box checks it. Its parts: checkbox::box (the outline) and ::mark (the
// dash, or the tick's colour).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:check_box;

import foundation.core; // Color, Max, Min
import foundation.vg;   // CornerRadii, PathBuilder, StrokeStyle
import :rect;
import :draw_context;
import :button_base;
import :text; // TextHAlign

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class CheckBox : public ButtonBase
    {
        RTTI_OBJECT(CheckBox, ButtonBase)
    public:
        CheckBox()
        {
            SetTag(core::StringView(u8"checkbox"));
            {
                StyleWriteScope defaults(*this);
                SetTextAlignment(TextHAlign::Start, TextVAlign::Middle); // its text beside its indicator
            }
            SetToggle(true);
            MakeIndicator();
        }

        void Toggle() { SetChecked(!IsChecked()); }
        /// Neither checked nor unchecked, until it is set or clicked.
        void SetIndeterminate(bool indeterminate) { SetIndeterminateState(indeterminate); }
        [[nodiscard]] bool IsIndeterminate() const noexcept { return IsIndeterminateState(); }

        void SetBoxColor(Color color)
        {
            m_boxColor = color;
            Invalidate();
        }
        void SetCheckColor(Color color)
        {
            m_checkColor = color;
            Invalidate();
        }

        // Theming parts: checkbox::box (outline) / ::mark (inner fill).
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"box"));
            out.PushBack(core::StringView(u8"mark"));
        }

    protected:
        void DrawIndicator(DrawContext& ctx, const Rect& box) const override
        {
            GetPartStyle(u8"box").Draw(ctx, box, OutlinedBox(m_boxColor, 2.0f, vg::CornerRadii(3.0f)));
            if (IsIndeterminateState())
            {
                const f32 h = core::Max(2.0f, box.height * 0.18f);
                const Rect dash{box.x + 4.0f, box.y + (box.height - h) * 0.5f, core::Max(0.0f, box.width - 8.0f), h};
                GetPartStyle(u8"mark").Draw(ctx, dash, FilledBox(m_checkColor, vg::CornerRadii(1.0f)));
            }
            else if (IsChecked())
            {
                // A tick, not a filled square, so checked never reads as the mixed state's bar.
                // Its colour is checkbox::mark's background, a sheet's or its own.
                const PartStyle& mark = GetPartStyle(u8"mark");
                Color color = mark.HasBackground ? mark.Box.BackgroundColor : m_checkColor;
                color.a *= mark.Opacity;
                const f32 side = core::Min(box.width, box.height);
                const f32 x = box.x + (box.width - side) * 0.5f;
                const f32 y = box.y + (box.height - side) * 0.5f;
                vg::PathBuilder tick;
                tick.MoveTo(x + side * 0.24f, y + side * 0.52f);
                tick.LineTo(x + side * 0.43f, y + side * 0.70f);
                tick.LineTo(x + side * 0.77f, y + side * 0.31f);
                ctx.VG().StrokePath(tick.ToPath(), color,
                                    vg::StrokeStyle(core::Max(2.0f, side * 0.12f), vg::VGLineCap::Round, vg::VGLineJoin::Round));
            }
        }

    private:
        Color m_boxColor{0.60f, 0.65f, 0.72f, 1.0f};
        Color m_checkColor{0.31f, 0.63f, 0.85f, 1.0f};
    };
}
