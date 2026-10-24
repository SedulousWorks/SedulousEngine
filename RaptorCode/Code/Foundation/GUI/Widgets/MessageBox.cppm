// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :message_box partition
//
// MessageBox: a modal dialog with a message and a row of standard buttons (OK / OK-Cancel /
// Yes-No). Modeled on eepp's UIMessageBox (role only) - a Window subclass whose content is a
// word-wrapped message plus bottom-right buttons. Pressing a button fires the result callback
// and closes the dialog. Shown via Window::OpenModal, a modal popup (E5): what is behind it is
// inert and its backdrop dims it. Its default button (the rightmost, OK or Yes) has focus when it
// opens, so Return or a pad's South picks it; `back` (Escape, a pad's East) picks the cancel one
// (Cancel, No, or OK when it is the only one), as its close button does. Its message wraps and
// its height fits it; it is not resizable unless asked.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:message_box;

import foundation.core;  // RefPtr, MakeRef, Array, Function, Move, Max, Float2
import foundation.fonts; // CachedFont
import :rect;
import :node;
import :label;
import :button;
import :text;
import :ui_widget;
import :window;
import :panel;
import :layout_style;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    class MessageBox : public Window
    {
        RTTI_OBJECT(MessageBox, Window)
    public:
        enum class Buttons
        {
            Ok,
            OkCancel,
            YesNo
        };
        enum class Result
        {
            Ok,
            Cancel,
            Yes,
            No
        };

        MessageBox()
        {
            SetTag(core::StringView(u8"messagebox"));

            // The content flows: the message (wrapping) above a row of buttons at the right.
            {
                StyleWriteScope hostDefaults(*GetContent());
                GetContent()->EditLayoutStyle([](LayoutStyle& st)
                {
                    st.Direction = FlexDirection::Column;
                    st.AlignItems = Align::Stretch;
                    st.RowGap = kGap;
                });
                static_cast<UIWidget*>(GetContent())->SetPadding(Thickness{kPad});
            }
            m_message = core::MakeRef<Label>(MemoryAllocator());
            m_message->AddClass(core::StringView(u8"dialogmessage")); // white-space inherits under a sheet: the theme wraps it
            {
                StyleWriteScope messageDefaults(*m_message); // its own values, which a sheet returns to
                m_message->SetWhiteSpace(TextWhiteSpace::Normal); // a message wraps
                m_message->SetTextAlignment(TextHAlign::Start, TextVAlign::Top);
                m_message->EditLayoutStyle([](LayoutStyle& st) { st.Grow = 1.0f; });
            }
            GetContent()->AddChild(m_message.Get());
            m_buttonRow = core::MakeRef<Panel>(MemoryAllocator());
            m_buttonRow->SetTag(core::StringView(u8"dialogbuttons"));
            {
                StyleWriteScope rowDefaults(*m_buttonRow);
                m_buttonRow->EditLayoutStyle([](LayoutStyle& st)
                {
                    st.Direction = FlexDirection::Row;
                    st.JustifyContent = Justify::End;
                    st.ColumnGap = kButtonGap;
                    st.Shrink = 0.0f;
                });
            }
            GetContent()->AddChild(m_buttonRow.Get());

            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetResizable(false);
            SetSize(core::Float2{kWidth, 180.0f});
            LayoutContent();
            // Open, the default button takes focus.
            MessageBox* self = this;
            (void)AddEventListener(EventType::Toggle, [self](const Event& e)
                                   {
                                       if (e.Target == self && static_cast<const ToggleEvent&>(e).Open && !self->m_buttons.IsEmpty())
                                           self->m_buttons.Back()->RequestFocus();
                                   });
        }

        // Set the title, message, and which buttons to show.
        void Configure(core::StringView title, core::StringView message, Buttons buttons)
        {
            SetTitle(title);
            m_message->SetText(message);
            BuildButtons(buttons);
            LayoutContent();
        }

        void SetOnResult(core::Function<void(Result)> callback)
        {
            m_onResult = core::Move(callback);
        }
        /// Adds a button of its own after the standard ones: `text` its label, `resultName` what
        /// GetResultName reads (and the change event reports) when it is pressed.
        void AddButton(core::StringView text, core::StringView resultName)
        {
            Button& button = MakeButton(core::String(resultName));
            button.SetText(text);
            LayoutContent();
        }

        void SetMessageColor(Color color) { m_message->SetTextColor(color); }

        // === Markup ===
        // `<MessageBox id="confirm" title="Delete?" text="..." buttons="ok-cancel"/>` waits in its
        // page, unseen, until shown (Show, a script's show()); answered, it goes back there, its
        // `result` the answer, reported as `change`.
        bool SetMarkupAttribute(core::StringView name, core::StringView value) override
        {
            if (name == core::StringView(u8"text"))
            {
                m_message->SetText(value);
                LayoutContent();
                return true;
            }
            if (name == core::StringView(u8"buttons"))
            {
                const core::StringView v = core::Trim(value);
                BuildButtons(v == core::StringView(u8"ok-cancel") ? Buttons::OkCancel : v == core::StringView(u8"yes-no") ? Buttons::YesNo : Buttons::Ok);
                LayoutContent();
                if (!IsOpen())
                    SetDisplayed(false); // written in a page: unseen until shown
                return true;
            }
            return Window::SetMarkupAttribute(name, value);
        }
        /// Shows it as a modal dialog over the GUI it is in (it comes back to where it was).
        /// Opens it, modal, in the GUI it is in; false when it is in none (a box shows over a
        /// tree: one with no parent has nothing to show over).
        bool Show()
        {
            if (IsOpen())
                return true;
            Node* root = GetRootNode();
            if (root == nullptr || root == this)
                return false;
            if (Node* home = GetParent())
            {
                m_home = core::RefPtr<Node>(home);
                m_homeIndex = home->GetChildIndex(this);
            }
            SetDisplayed(true);
            OpenModal(*root);
            return true;
        }
        /// The last answer: "ok", "cancel", "yes" or "no" (empty: none yet).
        [[nodiscard]] core::String GetResultName() const { return m_resultName; }

        [[nodiscard]] core::StringView GetMessage() const { return m_message->GetText(); }
        [[nodiscard]] usize ButtonCount() const noexcept { return m_buttons.Size(); }
        [[nodiscard]] Button* ButtonAt(usize index) const
        {
            return index < m_buttons.Size() ? m_buttons[index].Get() : nullptr;
        }

    public:
        // Its close button and `back` (Escape, a pad's East) pick the cancel button's result: the
        // leftmost, Cancel or No, or the only one.
        [[nodiscard]] bool AnswersBack() const override { return true; }
        void RequestClose() override
        {
            if (m_results.IsEmpty())
                Close();
            else
                Finish(m_results[0].AsView());
        }

    protected:
        // Its title (the window's), message and buttons take its font.
        void OnTextStyleChange() override
        {
            Window::OnTextStyleChange();
            ShareTextStyle(*m_message, false);
            for (const RefPtr<Button>& b : m_buttons)
                ShareTextStyle(*b, false);
            LayoutContent(); // the font sizes the message
        }

    private:
        void BuildButtons(Buttons buttons)
        {
            for (const RefPtr<Button>& b : m_buttons)
                b->RemoveFromParent();
            m_buttons.Clear();
            m_results.Clear();

            switch (buttons)
            {
            case Buttons::Ok:
                AddStandard(Result::Ok);
                break;
            case Buttons::OkCancel:
                AddStandard(Result::Cancel);
                AddStandard(Result::Ok); // primary rightmost
                break;
            case Buttons::YesNo:
                AddStandard(Result::No);
                AddStandard(Result::Yes); // primary rightmost
                break;
            }
        }

        // A standard button: its label translated (gui.ok, ...) where the GUI's tables have it,
        // else English.
        void AddStandard(Result result)
        {
            static constexpr core::StringView kKeys[] = {u8"gui.ok", u8"gui.cancel", u8"gui.yes", u8"gui.no"};
            static constexpr core::StringView kEnglish[] = {u8"OK", u8"Cancel", u8"Yes", u8"No"};
            const usize i = static_cast<usize>(result);
            Button& button = MakeButton(core::String(kNames[i]));
            button.SetText(kEnglish[i]);
            (void)button.BindTranslation(core::StringView(u8"text"), kKeys[i], {}, {}, {}, kEnglish[i]);
        }

        static constexpr core::StringView kNames[] = {u8"ok", u8"cancel", u8"yes", u8"no"};

        Button& MakeButton(core::String resultName)
        {
            auto button = core::MakeRef<Button>(MemoryAllocator());
            ShareTextStyle(*button, false);
            button->AddClass(core::StringView(u8"dialogbutton"));
            MessageBox* self = this;
            button->SetOnClick([self, resultName]() { self->Finish(resultName.AsView()); });
            {
                StyleWriteScope buttonDefaults(*button);
                button->EditLayoutStyle([](LayoutStyle& st)
                {
                    st.MinWidth = LayoutLength::Px(kButtonWidth);
                    st.Height = LayoutLength::Px(kButtonHeight);
                });
            }
            m_buttonRow->AddChild(button.Get());
            Button& made = *button;
            m_buttons.PushBack(core::Move(button));
            m_results.PushBack(core::Move(resultName));
            return made;
        }

        void Finish(core::StringView resultName)
        {
            m_resultName = core::String(resultName);
            for (usize i = 0; i < 4; ++i) // a standard one also answers as its Result
                if (kNames[i] == resultName && m_onResult)
                    m_onResult(static_cast<Result>(i));
            Close();
            SendEvent(Event(EventType::Changed, this));
        }
        // Shown from a page: back there, unseen.
        void OnWindowClosed() override
        {
            if (!m_home)
                return;
            core::RefPtr<Node> home = core::Move(m_home);
            core::RefPtr<Node> keep(this);
            SetDisplayed(false);
            if (GetParent() != home.Get())
                home->AddChildAt(this, core::Min(m_homeIndex, home->ChildCount()));
        }

        // Its height fits its message, wrapped at its width, and its buttons (the flow places them).
        void LayoutContent()
        {
            if (!m_message || !m_buttonRow)
                return; // may run mid-construction
            const f32 inner = core::Max(0.0f, GetSize().x - 2.0f * kPad);
            const f32 text = m_message->Measure(LayoutConstraints{core::Float2{inner, 0.0f}, core::Float2{inner, kUnbounded}, core::Float2{inner, -1.0f}, true, false}).y;
            const f32 height = GetTitleBarHeight() + kPad + text + kGap + kButtonHeight + kPad;
            if (core::Abs(height - GetSize().y) > 0.5f)
            {
                StyleWriteScope own(*this);
                SetSize(core::Float2{GetSize().x, height});
            }
        }

        RefPtr<Label> m_message;
        RefPtr<Panel> m_buttonRow;
        Array<RefPtr<Button>> m_buttons;
        Array<core::String> m_results; // each button's result name, in order
        core::Function<void(Result)> m_onResult;
        core::String m_resultName;
        core::RefPtr<Node> m_home; // the page it was shown from, while it is open
        usize m_homeIndex = 0;

        static constexpr f32 kPad = 16.0f;
        static constexpr f32 kGap = 14.0f;
        static constexpr f32 kWidth = 380.0f;
        static constexpr f32 kButtonWidth = 84.0f;
        static constexpr f32 kButtonHeight = 30.0f;
        static constexpr f32 kButtonGap = 10.0f;
    };

}
