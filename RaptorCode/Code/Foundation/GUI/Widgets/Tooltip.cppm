// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tooltip partition
//
// Tooltip: a small text panel, what a node's tooltip shows by default (Node::CreateTooltipContent).
// The dispatcher shows it (E5): the nearest tooltip text up the parent chain from the hovered node,
// after a delay on the GUI's clock, as a hint popup placed by the pointer; any press or key hides
// it. Styled as `tooltip`.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:tooltip;

import foundation.core;  // RefPtr, MakeRef, String, StringView, Float2, Max
import foundation.fonts; // CachedFont
import :rect;
import :draw_context;
import :text;
import :node;
import :ui_widget;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    class Tooltip : public UIWidget
    {
        RTTI_OBJECT(Tooltip, UIWidget)
    public:
        Tooltip()
        {
            SetTag(core::StringView(u8"tooltip"));
            SetHitTestVisible(false); // never steals pointer events
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetPadding(Thickness{6.0f, 3.0f, 6.0f, 3.0f});
            SetBox(FilledBox(m_bgColor)); // its own face, which a sheet's (a theme's) replaces
            m_text.SetAlignment(TextHAlign::Start, TextVAlign::Middle);
        }

        void SetText(core::StringView text)
        {
            m_text.SetString(text);
            Invalidate();
        }
        [[nodiscard]] core::StringView GetText() const { return m_text.GetString(); }

        // Natural size for the text plus padding.
        [[nodiscard]] core::Float2 MeasureText() const
        {
            const core::Float2 t = m_text.Measure();
            const Thickness pad = GetPadding();
            return core::Float2{t.x + pad.TotalHorizontal(), t.y + pad.TotalVertical()};
        }
        /// Its text on one line (its padding is added around it).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override { return m_text.Measure(); }

    protected:
        // Its text draws in its text style.
        void OnTextStyleChange() override
        {
            m_text.SetFont(GetFont());
            m_text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
            m_text.SetDirection(TextDirectionFor());
            m_text.SetColor(GetTextColor());
        }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            m_text.Draw(ctx, GetContentBounds());
        }

    private:
        Text m_text;
        Color m_bgColor{0.10f, 0.11f, 0.14f, 0.96f};
    };

    RTTI_DEFINE_OBJECT(Tooltip, "rtti::gui")
}
