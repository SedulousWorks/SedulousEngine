// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :graph_node_picker partition
//
// The node picker of a graph view (T6 of Specs/gui-lab-evolution-3.md): the kinds of node a source
// makes, under their categories, with a search over their names. A graph view opens it from its menu
// over nothing and when a link is dropped on nothing (then only the kinds with a pin that fits). Typing
// filters it; Up and Down move along it, Enter or a click chooses.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:graph_node_picker;

import foundation.core;
import foundation.gui;
import :graph_source;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class GraphNodePicker;

    /// A row of a node picker: a kind of node, or a category's heading.
    class GraphPickerRow : public UIWidget
    {
        RTTI_OBJECT(GraphPickerRow, UIWidget)
    public:
        explicit GraphPickerRow(GraphNodePicker& picker);

        void Show(core::StringView text, i32 shown)
        {
            m_shown = shown;
            m_label->SetText(text);
            if (shown < 0)
                AddClass(core::StringView(u8"category"));
            else
                RemoveClass(core::StringView(u8"category"));
        }
        /// Its place among the kinds shown; -1 for a heading.
        [[nodiscard]] i32 GetShown() const noexcept { return m_shown; }
        [[nodiscard]] Label& GetLabel() noexcept { return *m_label; }

    protected:
        void OnMouseEnter(const MouseEvent& event) override;
        void OnMouseClick(const MouseEvent& event) override;

    private:
        GraphNodePicker& m_picker;
        core::RefPtr<Label> m_label;
        i32 m_shown = -1;
    };

    class GraphNodePicker : public UIWidget
    {
        RTTI_OBJECT(GraphNodePicker, UIWidget)
    public:
        static constexpr f32 kWidth = 240.0f;
        static constexpr f32 kListHeight = 280.0f;

        GraphNodePicker()
        {
            SetTag(core::StringView(u8"graphnodepicker"));
            {
                StyleWriteScope defaults(*this);
                SetPadding(Thickness{6.0f, 6.0f, 6.0f, 6.0f});
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.RowGap = 4.0f;
                    s.Width = LayoutLength::Px(kWidth);
                });
            }
            m_search = core::MakeRef<TextField>(MemoryAllocator());
            m_search->SetPlaceholder(core::StringView(u8"Search"));
            GraphNodePicker* self = this;
            m_search->SetOnTextChanging([self](core::StringView text) { self->Filter(text); });
            AddChild(m_search.Get());
            m_list = core::MakeRef<UIWidget>(MemoryAllocator());
            m_list->SetTag(core::StringView(u8"graphpickerlist"));
            {
                StyleWriteScope defaults(*m_list);
                m_list->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.MaxHeight = LayoutLength::Px(kListHeight);
                    s.OverflowY = Overflow::Auto;
                });
            }
            AddChild(m_list.Get());
            // Up, Down and Enter before the search field takes them.
            (void)AddEventListener(EventType::KeyDown, [self](const Event& e)
                                   {
                                       const KeyEvent& key = static_cast<const KeyEvent&>(e);
                                       const KeyCode code = static_cast<KeyCode>(key.KeyCode);
                                       if (key.Modifiers != 0)
                                           return;
                                       if (code == KeyCode::Down || code == KeyCode::Up)
                                       {
                                           self->Step(code == KeyCode::Down ? 1 : -1);
                                           e.Handled = true;
                                       }
                                       else if (code == KeyCode::Return || code == KeyCode::KeypadEnter)
                                       {
                                           (void)self->ChooseCurrent();
                                           e.Handled = true;
                                       }
                                   },
                                   true);
        }

        /// The kinds it offers, in the source's order (a category's kinds together under it).
        void SetTypes(core::Span<const GraphNodeType> types)
        {
            m_types.Clear();
            for (const GraphNodeType& type : types)
                m_types.PushBack(type);
            m_search->SetText(core::StringView{});
            Filter(core::StringView{});
        }
        /// Searches for `text`, as typing it in the field does.
        void SetQuery(core::StringView text)
        {
            m_search->SetText(text);
            Filter(text);
        }
        /// Told the kind chosen.
        void SetOnChosen(core::Function<void(const GraphNodeType&)> callback) { m_onChosen = core::Move(callback); }

        /// The kinds shown now, in their order, and which is current (lit; Enter's).
        [[nodiscard]] usize ShownCount() const noexcept { return m_shown.Size(); }
        [[nodiscard]] const GraphNodeType& ShownAt(usize index) const noexcept { return m_types[m_shown[index]]; }
        [[nodiscard]] i32 GetCurrent() const noexcept { return m_current; }
        void SetCurrent(i32 shown)
        {
            if (m_shown.IsEmpty())
                shown = -1;
            else
                shown = core::Clamp(shown, 0, static_cast<i32>(m_shown.Size()) - 1);
            m_current = shown;
            for (const core::RefPtr<GraphPickerRow>& row : m_rows)
            {
                if (row->GetShown() >= 0 && row->GetShown() == shown)
                {
                    row->AddClass(core::StringView(u8"current"));
                    m_list->ScrollIntoView(*row);
                }
                else
                    row->RemoveClass(core::StringView(u8"current"));
            }
        }
        void Step(i32 by) { SetCurrent(m_current + by); }
        /// Chooses the current kind; false when none is shown.
        bool ChooseCurrent() { return Choose(m_current); }
        bool Choose(i32 shown)
        {
            if (shown < 0 || static_cast<usize>(shown) >= m_shown.Size())
                return false;
            const GraphNodeType chosen = m_types[m_shown[static_cast<usize>(shown)]];
            if (m_onChosen)
                m_onChosen(chosen);
            return true;
        }
        [[nodiscard]] TextField& GetSearchField() noexcept { return *m_search; }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            if (!BoxFills())
                ctx.VG().FillRect(localBounds.ToRectangle(), Color{0.18f, 0.20f, 0.25f, 1.0f});
            UIWidget::OnDraw(ctx, localBounds);
        }

    private:
        // Whether `text` holds `part`, ignoring the case of ASCII letters.
        [[nodiscard]] static bool Holds(core::StringView text, core::StringView part) noexcept
        {
            const auto lower = [](char8_t c) { return c >= u8'A' && c <= u8'Z' ? static_cast<char8_t>(c - u8'A' + u8'a') : c; };
            if (part.Size() == 0)
                return true;
            for (usize i = 0; i + part.Size() <= text.Size(); ++i)
            {
                usize n = 0;
                while (n < part.Size() && lower(text[i + n]) == lower(part[n]))
                    ++n;
                if (n == part.Size())
                    return true;
            }
            return false;
        }
        void Filter(core::StringView query)
        {
            m_shown.Clear();
            usize count = 0;
            const auto row = [this, &count](core::StringView text, i32 shown)
            {
                while (m_rows.Size() <= count)
                {
                    m_rows.PushBack(core::MakeRef<GraphPickerRow>(MemoryAllocator(), *this));
                    m_list->AddChild(m_rows.Back().Get());
                }
                m_rows[count++]->Show(text, shown);
            };
            if (query.Size() == 0)
            {
                // Under their categories, each once, in the order they first come.
                core::Array<core::String> categories;
                for (const GraphNodeType& type : m_types)
                {
                    bool seen = false;
                    for (const core::String& at : categories)
                        seen = seen || at == type.Category;
                    if (!seen)
                        categories.PushBack(type.Category);
                }
                for (const core::String& category : categories)
                {
                    if (!category.IsEmpty())
                        row(category.AsView(), -1);
                    for (usize i = 0; i < m_types.Size(); ++i)
                        if (m_types[i].Category == category)
                        {
                            row(m_types[i].Name.AsView(), static_cast<i32>(m_shown.Size()));
                            m_shown.PushBack(i);
                        }
                }
            }
            else
                for (usize i = 0; i < m_types.Size(); ++i)
                    if (Holds(m_types[i].Name.AsView(), query))
                    {
                        row(m_types[i].Name.AsView(), static_cast<i32>(m_shown.Size()));
                        m_shown.PushBack(i);
                    }
            while (m_rows.Size() > count)
            {
                m_list->RemoveChild(m_rows.Back().Get());
                m_rows.RemoveAt(m_rows.Size() - 1);
            }
            m_current = -2; // shown again below
            SetCurrent(0);
        }

        core::RefPtr<TextField> m_search;
        core::RefPtr<UIWidget> m_list;
        core::Array<core::RefPtr<GraphPickerRow>> m_rows;
        core::Array<GraphNodeType> m_types;
        core::Array<usize> m_shown; // the kinds shown, by their place in m_types
        i32 m_current = -1;
        core::Function<void(const GraphNodeType&)> m_onChosen;
    };

    inline GraphPickerRow::GraphPickerRow(GraphNodePicker& picker) : m_picker(picker)
    {
        SetTag(core::StringView(u8"graphpickerrow"));
        {
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.AlignItems = Align::Center;
                s.MinHeight = LayoutLength::Px(20.0f);
                s.Shrink = 0.0f;
            });
            SetPadding(Thickness{12.0f, 1.0f, 8.0f, 1.0f});
        }
        m_label = core::MakeRef<Label>(MemoryAllocator());
        m_label->SetHitTestVisible(false);
        AddChild(m_label.Get());
    }
    inline void GraphPickerRow::OnMouseEnter(const MouseEvent&)
    {
        if (m_shown >= 0)
            m_picker.SetCurrent(m_shown);
    }
    inline void GraphPickerRow::OnMouseClick(const MouseEvent& event)
    {
        if (m_shown < 0 || event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        (void)m_picker.Choose(m_shown);
    }
}
