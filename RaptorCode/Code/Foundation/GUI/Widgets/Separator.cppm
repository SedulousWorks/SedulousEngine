// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :separator partition
//
// Separator and Spacer (E6 of Specs/gui-lab-evolution.md): the two pieces a row or a column of
// controls is spaced with. Each takes its orientation from its parent's flex direction, so the
// same element is a vertical rule in a toolbar's row and a horizontal one in a menu's column.
// A separator is a line as thick as its `thickness` and the colour of its background (a sheet's
// `separator { background-color }`, else a quiet grey of its own), stretched across the line it
// is in. A spacer takes the room left (flexible, the default) or a fixed `size` along the line.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:separator;

import foundation.core; // Color, Float2, Max
import :rect;
import :draw_context;
import :node_box;
import :layout_style;
import :ui_widget;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    namespace detail
    {
        // Along a row (its parent lays out across): a separator stands up, a spacer runs across.
        [[nodiscard]] inline bool InRow(const Node& node) noexcept
        {
            const Node* parent = node.GetParent();
            if (parent == nullptr)
                return false;
            const FlexDirection d = parent->GetLayoutStyle().Direction;
            return d == FlexDirection::Row || d == FlexDirection::RowReverse;
        }
    }

    class Separator : public UIWidget
    {
        RTTI_OBJECT(Separator, UIWidget)
    public:
        Separator()
        {
            SetTag(core::StringView(u8"separator"));
            SetHitTestVisible(false);
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.AlignSelf = Align::Stretch; // across the whole line, even in a centred row
                s.Shrink = 0.0f;
            });
        }

        /// How thick its line is (the sheet's `thickness`).
        void SetThickness(f32 thickness)
        {
            m_thickness = core::Max(0.0f, thickness);
            RequestLayout();
        }
        [[nodiscard]] f32 GetThickness() const noexcept { return m_thickness; }
        /// Whether it stands up (in a row) or lies across (in a column).
        [[nodiscard]] bool IsVertical() const noexcept { return detail::InRow(*this); }

        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            return IsVertical() ? core::Float2{m_thickness, 0.0f} : core::Float2{0.0f, m_thickness};
        }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            if (GetBox().BackgroundColor.a > 0.0f || !GetBox().Layers.IsEmpty())
                return; // the sheet's background is the line, drawn as its box
            const Rect line = GetContentBounds();
            FilledBox(m_color).DrawUnder(ctx, line);
        }

    private:
        f32 m_thickness = 1.0f;
        Color m_color{0.50f, 0.54f, 0.60f, 0.35f};
    };

    class Spacer : public UIWidget
    {
        RTTI_OBJECT(Spacer, UIWidget)
    public:
        Spacer()
        {
            SetTag(core::StringView(u8"spacer"));
            SetHitTestVisible(false);
            StyleWriteScope defaults(*this);
            ApplySize();
        }

        /// A fixed length along the line (0: it takes the room left).
        void SetSpace(f32 size)
        {
            m_size = core::Max(0.0f, size);
            StyleWriteScope defaults(*this);
            ApplySize();
        }
        [[nodiscard]] f32 GetSpace() const noexcept { return m_size; }

        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            return detail::InRow(*this) ? core::Float2{m_size, 0.0f} : core::Float2{0.0f, m_size};
        }

    private:
        void ApplySize()
        {
            const bool flexible = m_size <= 0.0f;
            EditLayoutStyle([flexible](LayoutStyle& s)
            {
                s.Grow = flexible ? 1.0f : 0.0f;
                s.Shrink = flexible ? 1.0f : 0.0f;
            });
            RequestLayout();
        }

        f32 m_size = 0.0f;
    };
}
