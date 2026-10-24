// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :menu_bar partition
//
// MenuBar: a horizontal strip of buttons, each opening a Menu below it - the classic
// application menu bar. Modeled on eepp's UIMenuBar (role only). Clicking a button opens its menu,
// a popup of the button (E5); a press on the button again, outside the menu, closes it without
// reopening, as the popup stack consumes it. While a menu is open, hovering a different button
// switches to it: opening that menu closes the other (it does not hold the new one's button), and
// the closed menu's notice clears the bar's state.
//
// The keyboard and the pad (E5): F10 (the `menu.enter-bar` command) focuses the bar's first
// button; Down, Return, Space or a pad's South on a button opens its menu with its first item lit;
// Left and Right move between the buttons, and between the menus while one is open (a submenu's
// item takes Right first, and a submenu Left); Escape closes the menu, focus going back to its
// button.
//
// In markup its children are its menus, each `<Menu text="File">` a button.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:menu_bar;

import foundation.core;  // RefPtr, MakeRef, Array, Function, Move, Max, Float2
import foundation.fonts; // CachedFont
import :event;
import :node;
import :ui_widget;
import :button;
import :menu;
import :event_dispatcher;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    class MenuBar : public UIWidget
    {
        RTTI_OBJECT(MenuBar, UIWidget)
    public:
        MenuBar()
        {
            SetTag(core::StringView(u8"menubar"));
            SetBox(FilledBox(m_barColor)); // its own face, which a sheet's (a theme's) replaces
            // Its keys are bindings in the menu key context (E12): Left and Right from a button or
            // an open menu (which passes them on here) move along the bar, Down opens a button's.
            SetKeyContext(core::StringView(kMenuKeyContext));
            MenuBar* self = this;
            (void)OnCommand(core::StringView(kMenuLeftCommand), [self](CommandEvent&) { self->Along(false); });
            (void)OnCommand(core::StringView(kMenuRightCommand), [self](CommandEvent&) { self->Along(true); });
            (void)OnCommand(core::StringView(kMenuDownCommand), [self](CommandEvent& e)
                            {
                                if (!self->OpenFromButton())
                                    e.Propagate = true;
                            });
        }

        /// F10: its first button takes focus.
        bool EnterFromKeyboard() override
        {
            if (m_entries.IsEmpty() || !IsTreeVisible() || !IsTreeEnabled())
                return false;
            m_entries[0].button->RequestFocus();
            return true;
        }

        void SetBarHeight(f32 height)
        {
            m_barHeight = core::Max(1.0f, height);
            Relayout();
        }
        void SetItemPadding(f32 padding)
        {
            m_hpad = core::Max(0.0f, padding);
            Relayout();
        }

        // Add a top-level menu with its button label; returns the (empty) Menu to populate.
        Menu* AddMenu(core::StringView text) { return AdoptMenu(core::MakeRef<Menu>(MemoryAllocator()), text); }
        /// Takes `menu` (made elsewhere: markup's) under a new button titled `text`.
        Menu* AdoptMenu(core::RefPtr<Menu> menu, core::StringView text)
        {
            auto button = core::MakeRef<Button>(MemoryAllocator());
            button->SetText(text);
            ShareTextStyle(*button, false);
            button->AddClass(
                core::StringView(u8"menubutton")); // flat bar styling (class beats the button tag)
            ShareTextStyle(*menu, false);

            Button* rawButton = button.Get();
            Menu* rawMenu = menu.Get();
            MenuBar* self = this;
            button->SetOnClick([self, rawButton, rawMenu]()
                               { self->ToggleMenu(rawButton, rawMenu); });
            button->AddEventListener(EventType::MouseEnter, [self, rawButton, rawMenu](const Event&)
                                     { self->HoverMenu(rawButton, rawMenu); });
            menu->SetOnClosed([self, rawMenu](PopupCloseReason) { self->OnMenuClosed(rawMenu); });

            AddChild(button.Get());
            m_entries.PushBack(BarEntry{rawButton, core::Move(menu)});
            Relayout();
            return rawMenu;
        }

        /// Markup's children are its menus (each taken as it arrives).
        [[nodiscard]] Node* GetChildHost() override
        {
            if (!m_markupHost)
            {
                MenuBar* self = this;
                m_markupHost = core::MakeRef<MarkupChildHost>(MemoryAllocator(), [self](Node& host)
                {
                    while (host.ChildCount() != 0)
                    {
                        core::RefPtr<Node> child(host.GetChildAt(0));
                        host.RemoveChild(child.Get());
                        if (Menu* menu = core::Cast<Menu>(child.Get()))
                            (void)self->AdoptMenu(core::RefPtr<Menu>(menu), menu->GetTitle());
                    }
                });
            }
            return m_markupHost.Get();
        }

        [[nodiscard]] usize MenuCount() const noexcept { return m_entries.Size(); }
        [[nodiscard]] Menu* CurrentMenu() const noexcept { return m_current; }
        [[nodiscard]] Button* ButtonAt(usize index) const
        {
            return index < m_entries.Size() ? m_entries[index].button : nullptr;
        }
        [[nodiscard]] Menu* MenuAt(usize index) const
        {
            return index < m_entries.Size() ? m_entries[index].menu.Get() : nullptr;
        }

    protected:
        // Its buttons sit where Relayout puts them, left to right; right to left, mirrored (E9b).
        void OnLayout() override
        {
            LayoutChildren();
            if (!IsRightToLeft())
                return;
            for (BarEntry& e : m_entries)
                e.button->SetPosition(core::Float2{GetSize().x - e.button->GetPosition().x - e.button->GetSize().x, e.button->GetPosition().y});
        }

        // Its buttons and their menus take its font.
        void OnTextStyleChange() override
        {
            for (BarEntry& e : m_entries)
            {
                ShareTextStyle(*e.button, false);
                if (e.menu)
                    ShareTextStyle(*e.menu, false);
            }
            Relayout();
        }

        void OnSizeChange() override { Relayout(); }

    private:
        void ToggleMenu(Button* button, Menu* menu)
        {
            if (m_current == menu)
                menu->Close(); // Close -> OnMenuClosed clears the bar state
            else
                OpenMenu(button, menu);
        }
        void HoverMenu(Button* button, Menu* menu)
        {
            // Only switch when a menu is already open (a bare hover must not drop a menu).
            if (m_current != nullptr && m_current != menu)
                OpenMenu(button, menu);
        }
        void OpenMenu(Button* button, Menu* menu)
        {
            const EventDispatcher* d = GetEventDispatcher();
            const bool fromKeys = d != nullptr && d->IsUsingKeyboard();
            menu->OpenBelow(*button, *button);
            if (fromKeys)
                menu->FocusFirstItem();
            // Opening closed any previous menu (its OnMenuClosed cleared m_current + deselected
            // its button); now record the new one.
            m_current = menu;
            m_currentButton = button;
            button->AddClass(core::StringView(u8"selected"));
        }
        // Left or Right along the bar as it runs (right to left, Left goes on to the next menu,
        // E9b): an open menu moves to the next, a focused button to the next button.
        void Along(bool right)
        {
            const i32 at = FocusedEntry();
            if (at < 0 || m_entries.IsEmpty())
                return;
            const i32 count = static_cast<i32>(m_entries.Size());
            const bool onward = right != IsRightToLeft();
            const i32 next = (at + (onward ? 1 : -1) + count) % count;
            BarEntry& e = m_entries[static_cast<usize>(next)];
            if (m_current != nullptr)
            {
                OpenMenu(e.button, e.menu.Get()); // the open one closes: it does not hold this button
                e.menu->FocusFirstItem();
            }
            else
                e.button->RequestFocus();
        }
        // Down on a focused button with no menu open opens its menu and goes in.
        bool OpenFromButton()
        {
            const i32 at = FocusedEntry();
            if (at < 0 || m_current != nullptr || !m_entries[static_cast<usize>(at)].button->IsFocused())
                return false;
            BarEntry& e = m_entries[static_cast<usize>(at)];
            OpenMenu(e.button, e.menu.Get());
            e.menu->FocusFirstItem();
            return true;
        }
        // The entry whose button holds the focus (its open menu too), or -1.
        [[nodiscard]] i32 FocusedEntry() const
        {
            for (usize i = 0; i < m_entries.Size(); ++i)
                if (m_entries[i].button->IsFocusWithin())
                    return static_cast<i32>(i);
            return -1;
        }

        void OnMenuClosed(Menu* menu)
        {
            if (m_current != menu)
                return;
            if (m_currentButton != nullptr)
                m_currentButton->RemoveClass(core::StringView(u8"selected"));
            m_current = nullptr;
            m_currentButton = nullptr;
        }

        void Relayout()
        {
            f32 x = 0.0f;
            for (BarEntry& e : m_entries)
            {
                const f32 w = (e.button->GetTextPart() != nullptr ? e.button->GetTextPart()->MeasureText().x : 0.0f) + m_hpad * 2.0f;
                e.button->SetPosition(core::Float2{x, 0.0f});
                e.button->SetSize(core::Float2{w, m_barHeight});
                x += w;
            }
            // Within a device pixel of its size it is that size: the layout snaps its box to the
            // device grid, and sizing it back to the fraction asked for a layout again, every frame.
            const f32 pixel = 1.0f / core::Max(GetPixelScale(), 0.01f);
            if (core::Abs(GetSize().x - x) >= pixel || core::Abs(GetSize().y - m_barHeight) >= pixel)
                SetSize(core::Float2{x, m_barHeight});
        }

        // Top-left of `node` in root-local space (sum of positions up to, but excluding, the
        // root). Assumes identity scale/rotation on the path, matching the menu popup model.
        struct BarEntry
        {
            Button* button;
            core::RefPtr<Menu> menu;
        };
        Array<BarEntry> m_entries;
        core::RefPtr<Node> m_markupHost; // where markup's menus land, then taken in
        Menu* m_current = nullptr;         // the open menu (non-owning)
        Button* m_currentButton = nullptr; // its button (non-owning)
        f32 m_barHeight = 28.0f;
        f32 m_hpad = 12.0f;
        Color m_barColor{0.13f, 0.15f, 0.18f, 1.0f};
    };

}
