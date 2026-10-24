// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :drag_preview partition
//
// DragPreview: what follows the pointer while something is dragged and its source gave no preview
// of its own (E7): the payload's label (`dragpreview`), with a badge (`dragpreview::effect`) saying
// what a drop would do now: a plus for a copy, an arrow for a link, a barred circle where nothing
// takes it, nothing for a move.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:drag_preview;

import foundation.core; // Min, Max
import foundation.vg;   // PathBuilder, StrokeStyle
import :rect;
import :event; // DropEffect
import :draw_context;
import :label;
import :text; // TextHAlign

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class DragPreview : public Label
    {
        RTTI_OBJECT(DragPreview, Label)
    public:
        DragPreview()
        {
            SetTag(core::StringView(u8"dragpreview"));
            StyleWriteScope defaults(*this);
            SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            SetPadding(Thickness{8.0f, 4.0f, 24.0f, 4.0f}); // room for the badge at its right
        }
        [[nodiscard]] DropEffect GetEffect() const noexcept { return m_effect; }
        void OnDragPreviewEffect(DropEffect effect) override
        {
            if (effect == m_effect)
                return;
            m_effect = effect;
            Invalidate();
        }
        void CollectStyleParts(core::Array<core::StringView>& out) const override { out.PushBack(core::StringView(u8"effect")); }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            Label::OnDraw(ctx, localBounds);
            if (m_effect == DropEffect::Move)
                return;
            const PartStyle& part = GetPartStyle(u8"effect");
            Color color = part.HasBackground ? part.Box.BackgroundColor : GetTextColor();
            color.a *= part.Opacity;
            const Rect b = GetLocalBounds();
            const f32 r = 6.0f;
            const f32 cx = b.x + b.width - 8.0f - r;
            const f32 cy = b.y + b.height * 0.5f;
            vg::PathBuilder pb;
            if (m_effect == DropEffect::Copy)
            {
                pb.MoveTo(cx - r, cy);
                pb.LineTo(cx + r, cy);
                pb.MoveTo(cx, cy - r);
                pb.LineTo(cx, cy + r);
            }
            else if (m_effect == DropEffect::Link)
            {
                pb.MoveTo(cx - r, cy + r);
                pb.LineTo(cx + r, cy - r);
                pb.MoveTo(cx + r - 5.0f, cy - r);
                pb.LineTo(cx + r, cy - r);
                pb.LineTo(cx + r, cy - r + 5.0f);
            }
            else // none takes it
            {
                pb.MoveTo(cx - r * 0.7f, cy - r * 0.7f);
                pb.LineTo(cx + r * 0.7f, cy + r * 0.7f);
                for (i32 i = 0; i <= 24; ++i)
                {
                    const f32 a = static_cast<f32>(i) / 24.0f * 6.2831853f;
                    const core::Float2 p{cx + r * core::Cos(a), cy + r * core::Sin(a)};
                    if (i == 0)
                        pb.MoveTo(p.x, p.y);
                    else
                        pb.LineTo(p.x, p.y);
                }
            }
            ctx.VG().StrokePath(pb.ToPath(), color, vg::StrokeStyle(1.8f, vg::VGLineCap::Round, vg::VGLineJoin::Round));
        }

    private:
        DropEffect m_effect = DropEffect::Move;
    };
}
