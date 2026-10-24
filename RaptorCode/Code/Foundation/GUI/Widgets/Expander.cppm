// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :expander partition
//
// Expander: a header that shows or hides its content (E6 of Specs/gui-lab-evolution.md), HTML's
// <details>. Its header is a button (the button core's) with a disclosure chevron for its
// indicator and the expander's `title` for its text; activating it toggles `open`, and each
// change reports `toggle` (a ToggleEvent). Expanders of one `name` in one GUI are exclusive, as
// HTML's are: opening one closes the others. Content can be built on first open (a factory),
// and with `animate` it opens and closes by easing its height through a clip. Markup's children
// are its content.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:expander;

import foundation.core; // Function, Move, String, RefPtr, Array, Duration, Min, Max
import :rect;
import :event;
import :draw_context;
import :node_box;
import :layout_style;
import :ui_widget;
import :panel;
import :reactive; // Observable (what bindings follow)
import :button_base;
import :text; // TextHAlign
import :disclosure;
import :actions; // TickAction (the height animation)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// An expander's header: a button whose indicator is the disclosure chevron
    /// (`expanderheader::chevron` its colour), pointing down while its expander is open.
    class ExpanderHeader : public ButtonBase
    {
        RTTI_OBJECT(ExpanderHeader, ButtonBase)
    public:
        ExpanderHeader()
        {
            SetTag(core::StringView(u8"expanderheader"));
            {
                StyleWriteScope defaults(*this);
                SetTextAlignment(TextHAlign::Start, TextVAlign::Middle); // its text beside its indicator
            }
            MakeIndicator();
        }
        void SetOpenShown(bool open)
        {
            m_open = open;
            if (Node* indicator = GetIndicatorPart())
                indicator->Invalidate();
        }
        void CollectStyleParts(core::Array<core::StringView>& out) const override { out.PushBack(core::StringView(u8"chevron")); }
        // A drag resting on a closed header opens its expander (E7).
        bool OnDragHoverOpen(core::Float2) override
        {
            if (m_open)
                return false;
            (void)ActivateAsClick();
            return true;
        }

    protected:
        [[nodiscard]] core::Float2 IndicatorSize() const override { return core::Float2{12.0f, 12.0f}; }
        void DrawIndicator(DrawContext& ctx, const Rect& box) const override
        {
            const PartStyle& chevron = GetPartStyle(u8"chevron");
            Color color = chevron.HasBackground ? chevron.Box.BackgroundColor : Color{0.80f, 0.84f, 0.90f, 1.0f};
            color.a *= chevron.Opacity;
            DrawDisclosure(ctx, box, m_open, color, IsRightToLeft());
        }

    private:
        bool m_open = false;
    };

    class Expander : public UIWidget
    {
        RTTI_OBJECT(Expander, UIWidget)
    public:
        Expander()
        {
            SetTag(core::StringView(u8"expander"));
            Expander* self = this;
            m_header = core::MakeRef<ExpanderHeader>(MemoryAllocator());
            m_header->SetOnClick([self]() { self->SetOpen(!self->m_open); });
            AddChild(m_header.Get());
            // The content sits in a clip, which an animation sizes; the content keeps its own height.
            m_clip = core::MakeRef<Panel>(MemoryAllocator());
            m_clip->SetClipChildren(true);
            m_clip->SetDisplayed(false);
            AddChild(m_clip.Get());
            m_content = core::MakeRef<Panel>(MemoryAllocator());
            m_content->SetTag(core::StringView(u8"expandercontent")); // a sheet's `expander > * > expandercontent`
            m_content->EditLayoutStyle([](LayoutStyle& s) { s.Shrink = 0.0f; });
            m_clip->AddChild(m_content.Get());
        }

        /// Its header's text.
        void SetTitle(core::StringView title) { m_header->SetText(title); }
        [[nodiscard]] core::StringView GetTitle() const { return m_header->GetText(); }
        void SetTitleString(const core::String& title) { SetTitle(title.AsView()); }
        [[nodiscard]] core::String GetTitleString() const { return core::String(GetTitle()); }

        /// Open, its content shown; each change, the user's or code's, reports `toggle`, as
        /// <details> does.
        void SetOpen(bool open);
        [[nodiscard]] bool IsOpen() const
        {
            m_openChanged.Track(); // a read a binding records
            return m_open;
        }
        void Toggle() { SetOpen(!m_open); }

        /// Its group's name: expanders of one name in one GUI open one at a time.
        void SetName(const core::String& name) { m_name = name; }
        [[nodiscard]] core::String GetName() const { return m_name; }

        /// Opens and closes by easing its height (instead of at once).
        void SetAnimated(bool animated) noexcept { m_animated = animated; }
        [[nodiscard]] bool IsAnimated() const noexcept { return m_animated; }

        /// Builds the content the first time it opens (a heavy panel left unbuilt until wanted).
        void SetContentFactory(core::Function<void(Node& content)> factory) { m_factory = core::Move(factory); }
        /// Each change of `open` (the user's or code's).
        void SetOnToggled(core::Function<void(bool)> callback) { m_onToggled = core::Move(callback); }

        [[nodiscard]] ExpanderHeader* GetHeader() const noexcept { return m_header.Get(); }
        /// What holds its content (markup's children go here).
        [[nodiscard]] Node* GetContent() const noexcept { return m_content.Get(); }
        [[nodiscard]] Node* GetChildHost() override { return m_content.Get(); }
        /// How far open its height is, 0 to 1 (1 when not animating).
        [[nodiscard]] f32 GetReveal() const noexcept { return m_reveal; }
        [[nodiscard]] u32 GetWidgetStates() const override { return m_open ? WidgetStateChecked : WidgetStateNone; } // :checked when open

    private:
        void CloseNamed(const Node& node)
        {
            for (usize i = 0; i < node.ChildCount(); ++i)
            {
                Node* child = node.GetChildAt(i);
                if (Expander* other = core::Cast<Expander>(child); other != nullptr && other != this && other->m_open && other->m_name == m_name)
                    other->SetOpen(false);
                CloseNamed(*child);
            }
        }
        // The clip's height eases from where it is toward the content's (open) or nothing
        // (closed); open, the clip then gives the content its own height again.
        void Animate()
        {
            m_clip->SetDisplayed(true);
            if (m_animating)
                return;
            m_animating = true;
            Expander* self = this;
            RunAction(core::MakeRef<TickAction>(MemoryAllocator(), [self](core::Duration elapsed)
            {
                constexpr f32 kSeconds = 0.18f;
                const f32 step = static_cast<f32>(elapsed.AsSecondsF()) / kSeconds;
                self->m_reveal = self->m_open ? core::Min(1.0f, self->m_reveal + step) : core::Max(0.0f, self->m_reveal - step);
                const f32 eased = self->m_reveal * self->m_reveal * (3.0f - 2.0f * self->m_reveal); // smoothstep
                const f32 full = self->m_content->GetSize().y;
                const bool done = self->m_open ? self->m_reveal >= 1.0f : self->m_reveal <= 0.0f;
                self->m_clip->EditLayoutStyle([&](LayoutStyle& s) { s.Height = done && self->m_open ? LayoutLength{} : LayoutLength::Px(full * eased); });
                if (!done)
                    return true;
                if (!self->m_open)
                    self->m_clip->SetDisplayed(false);
                self->m_animating = false;
                return false;
            }));
        }

        core::RefPtr<ExpanderHeader> m_header;
        core::RefPtr<Panel> m_clip;
        core::RefPtr<Panel> m_content;
        core::String m_name;
        bool m_open = false;
        Observable m_openChanged; // what bindings reading `open` follow
        bool m_animated = false;
        bool m_animating = false;
        f32 m_reveal = 0.0f;
        core::Function<void(Node&)> m_factory;
        core::Function<void(bool)> m_onToggled;
    };

    inline void Expander::SetOpen(bool open)
    {
        if (open == m_open)
            return;
        m_open = open;
        m_openChanged.Notify();
        m_header->SetOpenShown(open);
        MarkStyleStateDirty(StateChecked); // `expander:checked` styles an open one
        if (open)
        {
            if (m_factory)
            {
                core::Function<void(Node&)> factory = core::Move(m_factory);
                factory(*m_content);
            }
            // One of a named group open: the others close.
            if (!m_name.IsEmpty())
            {
                const Node* top = this;
                while (top->GetParent() != nullptr)
                    top = top->GetParent();
                CloseNamed(*top);
            }
        }
        if (m_animated && GetActionManager() != nullptr)
            Animate();
        else
        {
            m_reveal = open ? 1.0f : 0.0f;
            m_clip->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength{}; });
            m_clip->SetDisplayed(open);
        }
        if (m_onToggled)
            m_onToggled(open);
        SendEvent(ToggleEvent(this, open, PopupCloseReason::Code));
    }
}
