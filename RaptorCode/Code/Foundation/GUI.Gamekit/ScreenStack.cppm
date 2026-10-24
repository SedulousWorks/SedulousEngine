// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - :screen_stack partition
//
// A game's screens (K4 of Specs/gui-lab-evolution-3.md): a `screens` element (ScreenStack), placed
// where a game's screens go (any number per root), holding `screen` elements on a stack. Push takes
// a node, or a document loaded fresh each time; pop, replace and clear. A screen says whether it
// covers what is under it (hides it), blocks its input (makes it inert, so a press held there is let
// go) and pauses the game; the stack reports the pause (the game decides what pausing means). A
// screen is a navigation scope and remembers its focus, so a pop refocuses the screen now on top;
// on a push, its `nav-default` or its first focusable, else the screen itself (a HUD: `back` still
// starts there). A press on a screen's empty area leaves the
// focus where it is, so `back` (Escape, the pad's East) still reaches it: the top screen hears
// `back` first (a script's handler may take it; `back="none"` keeps it), else the stack pops, never
// below its last screen and never in the frame that pushed. A screen popped leaves through the
// core's Leave (its sheet's exit plays, K5), out of the stack, its focus and its input at once; one
// pushed enters through the core's Enter (`:entering` while its sheet's entrance plays), and a pop
// during its entrance leaves from where it is. The screens under a covering one show again as it
// starts leaving, not once it has gone. A game that may hitch caps the GUI's clock step
// (GUIContext::SetMaxClockStep) so an entrance or exit is slowed rather than skipped.
// Lifecycle as named events on the screen: `screenenter`, `screenshown`, `screenleave`,
// `screenhidden` (covered) and `screenrevealed`; the stack tells `pausechange`.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.gamekit:screen_stack;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class ScreenStack;

    /// One of a game's screens: its content, and how it sits over the screens under it.
    class Screen : public UIWidget
    {
        RTTI_OBJECT(Screen, UIWidget)
    public:
        Screen()
        {
            SetTag(core::StringView(u8"screen"));
            SetNavScope(NavScope::Contain); // Tab and the arrows stay in it; it remembers its focus
            SetKeepsFocus(true);            // a press on its empty area keeps the focus (and `back`) here
            // Its entrance over (K5: the core's Enter), it is shown, while it is still on its stack.
            Screen* self = this;
            (void)AddEventListener(EventType::Entered, [self](const Event&)
                                   {
                                       if (self->m_stack != nullptr)
                                           self->SendNamedEvent(core::StringView(u8"screenshown"));
                                   });
        }

        /// It hides the screens under it (a full-screen menu over the game).
        [[nodiscard]] bool GetCovers() const noexcept { return m_covers; }
        void SetCovers(bool covers);
        /// The screens under it take no input (a pause menu); off, they do (a HUD over the game).
        [[nodiscard]] bool GetBlocks() const noexcept { return m_blocks; }
        void SetBlocks(bool blocks);
        /// The game pauses while it is on the stack (the stack reports it).
        [[nodiscard]] bool GetPauses() const noexcept { return m_pauses; }
        void SetPauses(bool pauses);
        /// What `back` does on it: "pop" (the default) or "none" (it keeps its back: a title screen).
        [[nodiscard]] core::String GetBack() const { return core::String(m_popsOnBack ? core::StringView(u8"pop") : core::StringView(u8"none")); }
        void SetBack(const core::String& back) { m_popsOnBack = back.AsView() != core::StringView(u8"none"); }
        [[nodiscard]] bool PopsOnBack() const noexcept { return m_popsOnBack; }

        /// The stack it is on, or null (not pushed, or popped and leaving).
        [[nodiscard]] ScreenStack* GetStack() const noexcept { return m_stack; }
        /// Hidden by a covering screen above it.
        [[nodiscard]] bool IsCovered() const noexcept { return m_covered; }

        /// The script surface: its stack (null when on none).
        [[nodiscard]] core::Variant StackElement();

    private:
        friend class ScreenStack;
        ScreenStack* m_stack = nullptr;
        bool m_covers = false;
        bool m_blocks = true;
        bool m_pauses = false;
        bool m_popsOnBack = true;
        bool m_covered = false;
    };

    /// A stack of screens: the top one shows, takes the input and hears `back` first.
    class ScreenStack : public UIWidget
    {
        RTTI_OBJECT(ScreenStack, UIWidget)
    public:
        ScreenStack()
        {
            SetTag(core::StringView(u8"screens"));
            {
                StyleWriteScope defaults(*this); // the sheet may lay it out otherwise
                EditLayoutStyle([](LayoutStyle& s) { s.Kind = Display::Stack; }); // each screen fills it
            }
            ScreenStack* self = this;
            (void)OnCommand(core::StringView(kBackCommand), [self](CommandEvent&) { (void)self->Back(); });
        }

        /// A screen markup (or code) adds as a child is pushed, in order: `<Screens>` holding
        /// `<Screen>`s starts with them on its stack, the last on top.
        Node* AddChild(Node* child) override
        {
            Screen* screen = child != nullptr && !m_adding ? Cast<Screen>(child) : nullptr;
            if (screen != nullptr && screen->m_stack == nullptr && !screen->IsLeaving())
            {
                (void)Push(*screen);
                return this;
            }
            return UIWidget::AddChild(child);
        }

        /// Pushes `content`: a Screen as it is, anything else in a new screen; it shows on top, takes
        /// the focus (its remembered, its `nav-default`, else its first focusable) and hears
        /// `screenenter`. The screen, or null when `content` is a screen already on a stack.
        Screen* Push(Node& content)
        {
            RefPtr<Screen> screen(Cast<Screen>(&content));
            if (screen && screen->m_stack != nullptr)
                return nullptr;
            if (!screen)
            {
                screen = core::MakeRef<Screen>(MemoryAllocator());
                screen->AddChild(&content);
            }
            if (screen->GetParent() == this && screen->IsLeaving())
                RemoveChild(screen.Get()); // one leaving, pushed again: whole again
            screen->m_stack = this;
            screen->m_covered = false;
            screen->SetInert(false);
            screen->SetVisible(true);
            m_screens.PushBack(screen);
            m_adding = true;
            AddChild(screen.Get());
            m_adding = false;
            NoteJustPushed();
            Settle();
            FocusScreen(*screen);
            screen->SendNamedEvent(core::StringView(u8"screenenter"));
            screen->Enter(); // :entering for the sheet's entrance; `screenshown` once it has played (K5)
            return screen.Get();
        }
        /// Pushes the document at `path` (its markup, loaded fresh through the GUI's resources, its
        /// `{{values}}` bound to the GUI's data). Null when it cannot be read or made.
        Screen* PushDocument(core::StringView path)
        {
            RefPtr<Node> content = LoadDocument(path);
            return content ? Push(*content) : nullptr;
        }
        /// Takes the top screen off: it leaves (its exit plays, out of input at once), the screens
        /// under it show and take input as the new top says, and the new top takes the focus it
        /// had. False when the stack is empty.
        bool Pop()
        {
            if (m_screens.IsEmpty())
                return false;
            TakeOffTop();
            Settle();
            if (Screen* top = Top())
                FocusScreen(*top);
            return true;
        }
        /// Swaps the top screen for `content` (pushed as Push does); with none, pushes it.
        Screen* Replace(Node& content)
        {
            if (Cast<Screen>(&content) != nullptr && Cast<Screen>(&content)->m_stack != nullptr)
                return nullptr;
            if (!m_screens.IsEmpty())
                TakeOffTop();
            return Push(content);
        }
        Screen* ReplaceDocument(core::StringView path)
        {
            RefPtr<Node> content = LoadDocument(path);
            return content ? Replace(*content) : nullptr;
        }
        /// Takes every screen off, the top first.
        void Clear()
        {
            while (!m_screens.IsEmpty())
                TakeOffTop();
            Settle();
        }
        /// What `back` does when the top screen did not take it: pops it, unless it keeps its back,
        /// it is the last, or it was pushed this frame (the Back that pushed it). Whether it popped.
        bool Back()
        {
            Screen* top = Top();
            if (top == nullptr || !top->PopsOnBack() || m_screens.Size() <= 1 || m_justPushed)
                return false;
            return Pop();
        }

        [[nodiscard]] Screen* Top() const noexcept { return m_screens.IsEmpty() ? nullptr : m_screens[m_screens.Size() - 1].Get(); }
        [[nodiscard]] usize Count() const noexcept { return m_screens.Size(); }
        [[nodiscard]] Screen* At(usize index) const noexcept { return index < m_screens.Size() ? m_screens[index].Get() : nullptr; }
        /// Whether a screen on the stack pauses the game.
        [[nodiscard]] bool IsPaused() const noexcept { return m_paused; }
        /// Whether the game should take the input: no screen on top that blocks it, and the pointer
        /// at `position` (device pixels) over nothing of the GUI that takes it.
        [[nodiscard]] bool WantsGameInput(core::Float2 position) const
        {
            if (const Screen* top = Top(); top != nullptr && top->GetBlocks())
                return false;
            const EventDispatcher* dispatcher = GetEventDispatcher();
            return dispatcher == nullptr || !dispatcher->IsPointerOver(position);
        }
        /// Told when the pause starts or ends (as `pausechange` is, with "paused" or "running").
        void SetOnPausedChanged(core::Function<void(bool)> callback) { m_onPausedChanged = core::Move(callback); }

        /// How the screens sit, after one of them changed how it covers, blocks or pauses.
        void Settle()
        {
            bool blocked = false;
            bool covered = false;
            bool paused = false;
            for (usize i = m_screens.Size(); i-- > 0;)
            {
                Screen& screen = *m_screens[i];
                screen.SetInert(blocked);
                if (covered != screen.m_covered)
                {
                    screen.m_covered = covered;
                    screen.SetVisible(!covered);
                    screen.SendNamedEvent(covered ? core::StringView(u8"screenhidden") : core::StringView(u8"screenrevealed"));
                }
                blocked = blocked || screen.m_blocks;
                covered = covered || screen.m_covers;
                paused = paused || screen.m_pauses;
            }
            if (paused != m_paused)
            {
                m_paused = paused;
                if (m_onPausedChanged)
                    m_onPausedChanged(paused);
                SendNamedEvent(core::StringView(u8"pausechange"), paused ? core::StringView(u8"paused") : core::StringView(u8"running"));
            }
        }

        // === The script surface (reflected in GamekitReflection.cpp) ===
        core::Variant PushScript(core::StringView path) { return HandleOf(PushDocument(path)); }
        core::Variant PushNodeScript(core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            return node != nullptr ? HandleOf(Push(*node)) : core::Variant{};
        }
        core::Variant ReplaceScript(core::StringView path) { return HandleOf(ReplaceDocument(path)); }
        core::Variant ReplaceNodeScript(core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            return node != nullptr ? HandleOf(Replace(*node)) : core::Variant{};
        }
        [[nodiscard]] core::Variant TopScript() const { return HandleOf(Top()); }
        [[nodiscard]] i32 CountScript() const noexcept { return static_cast<i32>(m_screens.Size()); }

    private:
        // Its remembered focus, its `nav-default` or its first focusable; with nothing focusable
        // (a HUD), the screen itself, so `back` and its commands still start in it.
        void FocusScreen(Screen& screen)
        {
            if (screen.FocusElement())
                return;
            if (EventDispatcher* dispatcher = GetEventDispatcher())
                dispatcher->SetFocusNode(&screen);
        }
        [[nodiscard]] static core::Variant HandleOf(Screen* screen)
        {
            return screen != nullptr ? screen->HandleAs(Screen::StaticType()) : core::Variant{};
        }
        // The top screen leaves: off the stack and out of input now, its exit still to play.
        void TakeOffTop()
        {
            RefPtr<Screen> top = m_screens[m_screens.Size() - 1];
            m_screens.RemoveAt(m_screens.Size() - 1);
            top->m_stack = nullptr;
            top->SendNamedEvent(core::StringView(u8"screenleave"));
            top->Leave();
        }
        // The frame that pushed may not pop (the Back that pushed it): marked until the GUI's next drain.
        void NoteJustPushed()
        {
            m_justPushed = true;
            if (MutationQueue* queue = GetMutationQueue())
            {
                RefPtr<ScreenStack> self(this);
                queue->Enqueue([self]() { self->m_justPushed = false; });
            }
            else
            {
                m_justPushed = false;
            }
        }
        [[nodiscard]] RefPtr<Node> LoadDocument(core::StringView path)
        {
            IResourceProvider* resources = GetResourceProvider();
            const ElementSet* elements = GetElementSet();
            core::String text;
            if (resources == nullptr || elements == nullptr || !resources->LoadText(path, text))
                return {};
            MarkupLoader loader(*elements, MemoryAllocator(), resources, GetFontService());
            if (SceneRoot* root = GetSceneRoot())
                loader.SetDataModel(root->GetContext().GetDataRef());
            return loader.LoadFromString(text.AsView());
        }

        Array<RefPtr<Screen>> m_screens; // bottom first
        bool m_paused = false;
        bool m_justPushed = false;
        bool m_adding = false; // Push adding its screen as a child
        core::Function<void(bool)> m_onPausedChanged;
    };

    inline void Screen::SetCovers(bool covers)
    {
        m_covers = covers;
        if (m_stack != nullptr)
            m_stack->Settle();
    }
    inline void Screen::SetBlocks(bool blocks)
    {
        m_blocks = blocks;
        if (m_stack != nullptr)
            m_stack->Settle();
    }
    inline void Screen::SetPauses(bool pauses)
    {
        m_pauses = pauses;
        if (m_stack != nullptr)
            m_stack->Settle();
    }
    inline core::Variant Screen::StackElement()
    {
        return m_stack != nullptr ? m_stack->HandleAs(ScreenStack::StaticType()) : core::Variant{};
    }
}
