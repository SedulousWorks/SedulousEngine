// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :combo_box partition
//
// ComboBox: a control that shows the current selection and, when clicked, drops down a list of
// choices. Modeled on eepp's UIDropDownList (role only), built by composition: the dropdown is a
// ListBox opened as an auto popup (E5): it stays the combo box's child while open, in the top
// layer, placed below it (above when there is more room there, shrunk to the room), so a press
// outside or Escape closes it. Picking an item sets the selection and closes the dropdown.
//
// The keyboard and the pad (E5): Return, Space, a pad's South or Alt+Down open it with the list
// focused on the current item, where the arrows move and Return picks; closed, Up and Down step the
// selection (given back past the first and the last, so focus moves on), and a letter or a digit
// selects the next item starting with it.
//
// With nothing selected (-1: none yet, or the values it stands for differ, a property grid's
// mixed state) it shows its placeholder in the placeholder's colour.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:combo_box;

import foundation.core;  // RefPtr, MakeRef, Array, String, Function, Move, Min, Float2
import foundation.fonts; // CachedFont
import foundation.vg;    // PathBuilder
import :rect;
import :event;
import :draw_context;
import :text;
import :node;
import :ui_widget;
import :list_box;
import :event_dispatcher; // the popup stack (E5)
import :popup_placement;
import :reactive; // Observable: a binding follows the selection

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class ComboBox : public UIWidget
    {
        RTTI_OBJECT(ComboBox, UIWidget)
    public:
        ComboBox()
        {
            SetTag(core::StringView(u8"combobox"));
            SetTabFocusable(true);
            m_text.SetAlignment(TextHAlign::Start, TextVAlign::Middle);
        }


        void AddItem(core::StringView text)
        {
            m_items.PushBack(core::String(text));
            if (m_dropdown)
                m_dropdown->AddItem(text);
            RequestLayout(); // as wide as its widest item
        }
        [[nodiscard]] usize ItemCount() const noexcept { return m_items.Size(); }
        /// The items as one text, '|' between them (markup's and a sheet's `items`).
        void SetItemsText(const core::String& text)
        {
            m_items.Clear();
            if (m_dropdown)
                m_dropdown->Clear();
            for (const core::StringView item : SplitItems(text.AsView()))
                AddItem(item);
            // The old selection is gone with its item: none shows.
            if (m_selected != -1)
            {
                m_selected = -1;
                ShowSelection();
                m_selectedChanged.Notify();
                Invalidate();
            }
        }
        [[nodiscard]] core::String GetItemsText() const { return JoinItems(m_items); }

        /// The selected item's index, or -1 (markup's and a sheet's `selected`; a read a binding
        /// follows).
        [[nodiscard]] i32 GetSelectedIndex() const
        {
            m_selectedChanged.Track();
            return m_selected;
        }
        [[nodiscard]] core::StringView GetSelectedText() const
        {
            return (m_selected >= 0 && static_cast<usize>(m_selected) < m_items.Size())
                       ? m_items[static_cast<usize>(m_selected)].AsView()
                       : core::StringView{};
        }
        /// Selects `index`, or none with -1.
        void SetSelectedIndex(i32 index)
        {
            if (index < -1 || index >= static_cast<i32>(m_items.Size()))
                return;
            if (index == m_selected)
                return;
            m_selected = index;
            ShowSelection();
            Invalidate();
            m_selectedChanged.Notify();
            if (m_onChanged)
                m_onChanged(index);
        }
        /// The user picked `index` (the keys, type-ahead, the dropdown): as SetSelectedIndex, and
        /// a `change` event when it changed, as a slider's or a field's.
        void SelectByUser(i32 index)
        {
            const i32 was = m_selected;
            SetSelectedIndex(index);
            if (m_selected != was)
                SendEvent(Event(EventType::Changed, this));
        }
        void SetOnSelectionChanged(core::Function<void(i32)> callback)
        {
            m_onChanged = core::Move(callback);
        }

        [[nodiscard]] bool IsOpen() const
        {
            const EventDispatcher* dispatcher = m_dropdown ? m_dropdown->GetEventDispatcher() : nullptr;
            return dispatcher != nullptr && dispatcher->IsPopupOpen(*m_dropdown);
        }
        /// The dropdown list (built on first open).
        [[nodiscard]] ListBox* GetDropdown() const noexcept { return m_dropdown.Get(); }
        void SetItemHeight(f32 height) { m_itemHeight = height; }

        /// What shows while nothing is selected (`placeholder`).
        void SetPlaceholder(const core::String& text)
        {
            m_placeholder = text;
            ShowSelection();
        }
        [[nodiscard]] core::String GetPlaceholder() const { return m_placeholder; }
        void SetPlaceholderColor(Color color)
        {
            m_placeholderColor = color;
            ShowSelection();
        }

        /// Its widest item and the arrow beside it, one line of its font tall (E2).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            f32 widest = 0.0f;
            if (GetFont() != nullptr)
                for (const core::String& item : m_items)
                    widest = core::Max(widest, GetFont()->font->MeasureString(item.AsView()));
            return core::Float2{widest + 24.0f, GetFont() != nullptr ? GetFont()->font->Metrics().lineHeight : 20.0f};
        }
        /// The selection's baseline, where it draws it.
        [[nodiscard]] f32 BaselineAt(core::Float2 size) const override
        {
            const Thickness c = GetChrome();
            return m_text.FirstBaseline(Rect{c.Left, c.Top, core::Max(0.0f, size.x - c.TotalHorizontal() - 16.0f),
                                             core::Max(0.0f, size.y - c.TotalVertical())});
        }

    protected:
        // Its selection draws in its text style; the arrow is the text's colour; the dropdown
        // takes its font.
        void OnTextStyleChange() override
        {
            m_text.SetFont(GetFont());
            m_text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
            m_text.SetDirection(TextDirectionFor());
            ShowSelection();
            m_arrowColor = GetTextColor();
            if (m_dropdown)
                ShareTextStyle(*m_dropdown, false);
        }

        void OnMouseClick(const MouseEvent& event) override
        {
            event.Handled = true;
            if (IsOpen())
                CloseDropdown();
            else
                OpenDropdown();
        }
        bool OnActivate() override
        {
            OpenDropdown();
            return IsOpen();
        }
        void OnKeyDown(const KeyEvent& event) override
        {
            if (event.Target != this || m_items.IsEmpty())
                return;
            const KeyCode key = static_cast<KeyCode>(event.KeyCode);
            if (key == KeyCode::Down && event.Modifiers == static_cast<u32>(KeyModAlt))
            {
                event.Handled = true;
                OpenDropdown();
                return;
            }
            if (event.Modifiers != 0)
                return;
            const i32 last = static_cast<i32>(m_items.Size()) - 1;
            if (key == KeyCode::Down && m_selected < last)
            {
                SelectByUser(m_selected + 1);
                event.Handled = true;
            }
            else if (key == KeyCode::Up && m_selected > 0)
            {
                SelectByUser(m_selected - 1);
                event.Handled = true;
            }
            else if (KeyTypesText(key))
                event.Handled = true; // its text arrives next, for type-ahead (E12)
        }
        // Typed text (E12: through the keyboard layout and an IME): the next item after the
        // selection starting with its first character, round the end.
        [[nodiscard]] bool WantsTextInput() const override { return IsTreeEnabled() && !m_items.IsEmpty(); }
        void OnTextInput(const TextInputEvent& event) override
        {
            if (event.Target != this || m_items.IsEmpty() || event.Text.Size() == 0)
                return;
            usize end = 0;
            (void)core::DecodeUtf8(event.Text, end);
            const core::StringView typed = event.Text.SubStr(0, end);
            event.Handled = true;
            const i32 count = static_cast<i32>(m_items.Size());
            for (i32 n = 1; n <= count; ++n)
            {
                const i32 i = (m_selected + n + count) % count;
                if (StartsWithIgnoringCase(m_items[static_cast<usize>(i)].AsView(), typed))
                {
                    SelectByUser(i);
                    break;
                }
            }
        }

        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            // A visible box so it reads as a control even unstyled; a sheet's fill (a theme's) replaces it.
            if (!BoxFills())
                ctx.VG().FillRect(Rectangle{localBounds.x, localBounds.y, localBounds.width, localBounds.height}, m_boxColor);
            const Rect b = GetContentBounds();
            const bool rtl = IsRightToLeft(); // the arrow at the inline end
            // Selection text (leaving room for the arrow).
            m_text.Draw(ctx, MirroredIn(Rect{b.x, b.y, core::Max(0.0f, b.width - 16.0f), b.height}, b, rtl));
            // A small down-arrow.
            const f32 aw = 8.0f, ah = 5.0f;
            const f32 ax = MirroredIn(Rect{b.x + b.width - aw - 4.0f, 0.0f, aw, 0.0f}, b, rtl).x;
            const f32 ay = b.y + (b.height - ah) * 0.5f;
            vg::PathBuilder pb;
            pb.MoveTo(ax, ay);
            pb.LineTo(ax + aw, ay);
            pb.LineTo(ax + aw * 0.5f, ay + ah);
            pb.Close();
            ctx.VG().FillPath(pb.ToPath(), m_arrowColor);
        }

    private:
        // The selected item in the text's colour, or the placeholder in its own.
        void ShowSelection()
        {
            const bool none = m_selected < 0 || static_cast<usize>(m_selected) >= m_items.Size();
            m_text.SetString(none ? m_placeholder.AsView() : m_items[static_cast<usize>(m_selected)].AsView());
            m_text.SetColor(none ? m_placeholderColor : GetTextColor());
            Invalidate();
        }

        void BuildDropdown()
        {
            if (m_dropdown)
                return;
            m_dropdown = core::MakeRef<ListBox>(MemoryAllocator());
            ShareTextStyle(*m_dropdown, false);
            m_dropdown->SetItemHeight(m_itemHeight);
            for (const core::String& item : m_items)
                m_dropdown->AddItem(item.AsView());
            ComboBox* self = this;
            m_dropdown->SetOnItemActivated([self](i32 i) { self->OnPicked(i); });
        }

        void OpenDropdown()
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            if (dispatcher == nullptr || m_items.IsEmpty())
                return;
            BuildDropdown();
            const f32 h = core::Min(static_cast<f32>(m_items.Size()) * m_itemHeight, m_dropdownMaxHeight);
            m_dropdown->SetSize(core::Float2{GetSize().x, h});
            if (m_selected >= 0)
                m_dropdown->SetSelectedIndex(m_selected); // the current item lit, in view
            PopupOptions options;
            options.Anchor = this;
            options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 0.0f, true};
            options.TakesFocus = true; // the list: the arrows move, Return picks; focus back on close
            dispatcher->OpenPopup(*this, *m_dropdown, core::Move(options));
        }

        void CloseDropdown()
        {
            if (EventDispatcher* dispatcher = GetEventDispatcher(); dispatcher != nullptr && m_dropdown)
                (void)dispatcher->ClosePopup(*m_dropdown);
        }

        void OnPicked(i32 index)
        {
            SelectByUser(index);
            CloseDropdown();
        }



        Array<core::String> m_items;
        Text m_text;
        RefPtr<ListBox> m_dropdown; // its child while open (E5); kept here while closed
        i32 m_selected = -1;
        f32 m_itemHeight = 24.0f;
        f32 m_dropdownMaxHeight = 160.0f;
        Color m_boxColor{0.18f, 0.20f, 0.25f, 1.0f};
        Color m_arrowColor{0.75f, 0.80f, 0.86f, 1.0f};
        Color m_placeholderColor{0.55f, 0.58f, 0.62f, 1.0f}; // a text field's
        core::String m_placeholder;
        core::Function<void(i32)> m_onChanged;
        mutable Observable m_selectedChanged;
    };

}
