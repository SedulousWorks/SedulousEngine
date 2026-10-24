// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - :code_find_bar partition
//
// The code editor's find, replace and go-to-line bar (C4 of Specs/gui-lab-evolution-3.md), of the
// core's widgets (foundation.ui's editor drew its own and took its keys before the editor did): a
// field for what to find, toggles for matching case and whole words, how many matches and which,
// the previous and next, a close; replacing, a second field and Replace and Replace all; going to a
// line, one field (`line` or `line:column`). Return finds the next (Shift+Return the previous),
// replaces, or goes; Escape closes it, the focus back in the editor. The editor does the searching.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.code:code_find_bar;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class CodeFindBar : public UIWidget
    {
        RTTI_OBJECT(CodeFindBar, UIWidget)
    public:
        enum class Mode : u8
        {
            Find,
            Replace,
            GoToLine,
        };

        CodeFindBar()
        {
            SetTag(core::StringView(u8"codefindbar"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Placement = Position::Absolute; // over the editor, which places it
                    s.Direction = FlexDirection::Column;
                    s.RowGap = 4.0f;
                });
                SetPadding(Thickness{6.0f, 4.0f, 6.0f, 4.0f});
            }
            CodeFindBar* self = this;
            m_findRow = Row();
            m_query = Field(*m_findRow, u8"query", u8"Find", 180.0f);
            m_query->SetOnTextChanging([self](core::StringView) { self->Changed(); });
            m_case = Toggle(*m_findRow, u8"case", u8"Aa", u8"Match case");
            m_word = Toggle(*m_findRow, u8"word", u8"W", u8"Whole word");
            m_count = core::MakeRef<Label>(MemoryAllocator());
            m_count->AddClass(core::StringView(u8"count"));
            m_findRow->AddChild(m_count.Get());
            m_previous = Action(*m_findRow, u8"previous", u8"Prev", u8"Previous match (Shift+F3)", [self]() { self->Next(true); });
            m_next = Action(*m_findRow, u8"next", u8"Next", u8"Next match (F3)", [self]() { self->Next(false); });
            m_close = Action(*m_findRow, u8"close", u8"×", u8"Close (Escape)", [self]() { self->Close(); });
            m_replaceRow = Row();
            m_replacement = Field(*m_replaceRow, u8"replacement", u8"Replace", 180.0f);
            m_replaceOne = Action(*m_replaceRow, u8"replace", u8"Replace", u8"Replace this match", [self]() { self->Replace(false); });
            m_replaceAll = Action(*m_replaceRow, u8"replace-all", u8"All", u8"Replace every match", [self]() { self->Replace(true); });
            m_lineRow = Row();
            m_line = Field(*m_lineRow, u8"line", u8"Line, or line:column", 180.0f);
            (void)Action(*m_lineRow, u8"close", u8"×", u8"Close (Escape)", [self]() { self->Close(); });
            m_query->SetOnSubmit([self](core::StringView) { self->Next(self->m_shiftHeld); });
            m_replacement->SetOnSubmit([self](core::StringView) { self->Replace(false); });
            m_line->SetOnSubmit([self](core::StringView text)
            {
                if (self->m_onGoTo)
                    self->m_onGoTo(text);
            });
            // Return with Shift finds the previous; Escape closes, from any of its fields.
            (void)AddEventListener(EventType::KeyDown, [self](const Event& e)
                                   {
                                       const KeyEvent& key = static_cast<const KeyEvent&>(e);
                                       self->m_shiftHeld = (key.Modifiers & KeyModShift) != 0;
                                       if (static_cast<KeyCode>(key.KeyCode) == KeyCode::Escape && key.Modifiers == 0)
                                       {
                                           self->Close();
                                           e.Handled = true;
                                       }
                                   },
                                   true);
            Show(Mode::Find, core::StringView{});
            SetDisplayed(false);
        }

        /// Shows it in `mode`, its field holding `text` (all selected) and focused.
        void Show(Mode mode, core::StringView text)
        {
            m_mode = mode;
            SetDisplayed(true);
            m_findRow->SetDisplayed(mode != Mode::GoToLine);
            m_replaceRow->SetDisplayed(mode == Mode::Replace);
            m_lineRow->SetDisplayed(mode == Mode::GoToLine);
            TextField& field = mode == Mode::GoToLine ? *m_line : *m_query;
            if (text.Size() != 0 || mode == Mode::GoToLine)
                field.SetText(text);
            field.GetModel().SelectAll();
            field.RequestFocus();
            Changed();
        }
        void Close()
        {
            if (!IsDisplayed())
                return;
            SetDisplayed(false);
            if (m_onClose)
                m_onClose();
        }
        [[nodiscard]] Mode GetMode() const noexcept { return m_mode; }
        [[nodiscard]] core::StringView GetQuery() const { return m_query->GetText(); }
        [[nodiscard]] core::StringView GetReplacement() const { return m_replacement->GetText(); }
        [[nodiscard]] bool MatchCase() const { return m_case->IsChecked(); }
        [[nodiscard]] bool WholeWord() const { return m_word->IsChecked(); }
        /// Shows which match is current (from 1; 0: none) of how many.
        void SetCount(usize current, usize total)
        {
            if (m_query->GetText().Size() == 0)
                m_count->SetText(core::StringView{});
            else if (total == 0)
                m_count->SetText(core::StringView(u8"No results"));
            else
                m_count->SetText(core::Format(u8"{} of {}", current, total).AsView());
        }
        [[nodiscard]] TextField& GetQueryField() const noexcept { return *m_query; }
        [[nodiscard]] TextField& GetReplacementField() const noexcept { return *m_replacement; }
        [[nodiscard]] TextField& GetLineField() const noexcept { return *m_line; }
        [[nodiscard]] Button& GetCaseToggle() const noexcept { return *m_case; }
        [[nodiscard]] Button& GetWordToggle() const noexcept { return *m_word; }
        [[nodiscard]] Label& GetCountLabel() const noexcept { return *m_count; }

        // The editor's: what it does for each.
        void SetOnChanged(core::Function<void()> callback) { m_onChanged = core::Move(callback); }
        void SetOnNext(core::Function<void(bool backwards)> callback) { m_onNext = core::Move(callback); }
        void SetOnReplace(core::Function<void(bool all)> callback) { m_onReplace = core::Move(callback); }
        void SetOnGoTo(core::Function<void(core::StringView)> callback) { m_onGoTo = core::Move(callback); }
        void SetOnClose(core::Function<void()> callback) { m_onClose = core::Move(callback); }

    private:
        core::RefPtr<UIWidget> Row()
        {
            auto row = core::MakeRef<UIWidget>(MemoryAllocator());
            row->AddClass(core::StringView(u8"row"));
            row->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.AlignItems = Align::Center;
                s.ColumnGap = 4.0f;
            });
            AddChild(row.Get());
            return row;
        }
        core::RefPtr<TextField> Field(UIWidget& row, const char8_t* cls, const char8_t* placeholder, f32 width)
        {
            auto field = core::MakeRef<TextField>(MemoryAllocator());
            field->AddClass(core::StringView(cls));
            field->SetPlaceholder(core::StringView(placeholder));
            field->EditLayoutStyle([width](LayoutStyle& s) { s.Width = LayoutLength::Px(width); });
            row.AddChild(field.Get());
            return field;
        }
        core::RefPtr<Button> Toggle(UIWidget& row, const char8_t* cls, const char8_t* text, const char8_t* tip)
        {
            auto button = core::MakeRef<Button>(MemoryAllocator());
            button->AddClass(core::StringView(cls));
            button->SetText(core::StringView(text));
            button->SetTooltip(core::StringView(tip));
            button->SetToggle(true);
            CodeFindBar* self = this;
            button->SetOnToggled([self](bool) { self->Changed(); });
            row.AddChild(button.Get());
            return button;
        }
        core::RefPtr<Button> Action(UIWidget& row, const char8_t* cls, const char8_t* text, const char8_t* tip, core::Function<void()> click)
        {
            auto button = core::MakeRef<Button>(MemoryAllocator());
            button->AddClass(core::StringView(cls));
            button->SetText(core::StringView(text));
            button->SetTooltip(core::StringView(tip));
            button->SetOnClick(core::Move(click));
            row.AddChild(button.Get());
            return button;
        }
        void Changed()
        {
            if (m_onChanged)
                m_onChanged();
        }
        void Next(bool backwards)
        {
            if (m_onNext)
                m_onNext(backwards);
        }
        void Replace(bool all)
        {
            if (m_onReplace)
                m_onReplace(all);
        }

        Mode m_mode = Mode::Find;
        bool m_shiftHeld = false;
        core::RefPtr<UIWidget> m_findRow, m_replaceRow, m_lineRow;
        core::RefPtr<TextField> m_query, m_replacement, m_line;
        core::RefPtr<Button> m_case, m_word, m_previous, m_next, m_close, m_replaceOne, m_replaceAll;
        core::RefPtr<Label> m_count;
        core::Function<void()> m_onChanged;
        core::Function<void(bool)> m_onNext;
        core::Function<void(bool)> m_onReplace;
        core::Function<void(core::StringView)> m_onGoTo;
        core::Function<void()> m_onClose;
    };
}
