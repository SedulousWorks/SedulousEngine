// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :status_bar partition
//
// The status bar (T0 of Specs/gui-lab-evolution-3.md): items registered by id in a start zone and
// an end zone (zed and Zero register theirs; the start zone takes what is left, so the end zone's
// items keep their place), ordered within their zone, and a message at the start of the start
// zone, held until replaced or for so many seconds on the GUI's clock. An item with a title can be
// hidden: the bar's context menu lists them as checked rows, and an application hears each change
// (to keep it with its settings).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:status_bar;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// Where on the bar an item goes.
    enum class StatusZone : u8
    {
        Start, ///< after the message, taking what is left
        End,   ///< at the bar's end
    };

    /// One item of a status bar: what it shows is its children.
    class StatusItem : public UIWidget
    {
        RTTI_OBJECT(StatusItem, UIWidget)
    public:
        StatusItem()
        {
            SetTag(core::StringView(u8"statusitem"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.AlignItems = Align::Center;
                s.ColumnGap = 4.0f;
                s.Shrink = 0.0f;
            });
        }

        /// Its zone (`zone`: start or end).
        void SetZone(StatusZone zone)
        {
            m_zone = zone;
            Rehome();
        }
        [[nodiscard]] StatusZone GetZone() const noexcept { return m_zone; }
        void SetZoneName(const core::String& name) { SetZone(core::Trim(name.AsView()) == core::StringView(u8"end") ? StatusZone::End : StatusZone::Start); }
        [[nodiscard]] core::String GetZoneName() const
        {
            return core::String(m_zone == StatusZone::End ? core::StringView(u8"end") : core::StringView(u8"start"));
        }
        /// Its place in its zone: lower first, ties in the order they came (the layout's `order`).
        void SetOrder(i32 order)
        {
            EditLayoutStyle([order](LayoutStyle& s) { s.Order = order; });
        }
        [[nodiscard]] i32 GetOrder() const noexcept { return GetLayoutStyle().Order; }
        /// What the bar's menu calls it (`title`); with none it cannot be hidden from there.
        void SetTitle(core::StringView title) { m_title = core::String(title); }
        [[nodiscard]] core::StringView GetTitle() const noexcept { return m_title.AsView(); }
        void SetTitleString(const core::String& title) { m_title = title; }
        [[nodiscard]] core::String GetTitleString() const { return m_title; }

    private:
        friend class StatusBar;
        void Rehome();

        StatusZone m_zone = StatusZone::Start;
        core::String m_title;
        class StatusBar* m_bar = nullptr;
    };

    class StatusBar : public UIWidget
    {
        RTTI_OBJECT(StatusBar, UIWidget)
    public:
        StatusBar()
        {
            SetTag(core::StringView(u8"statusbar"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Row;
                    s.AlignItems = Align::Center;
                    s.ColumnGap = 12.0f;
                });
                SetPadding(Thickness{8.0f, 2.0f, 8.0f, 2.0f});
            }
            m_start = MakeZone(u8"start");
            m_start->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Grow = 1.0f;
                s.Shrink = 1.0f;
                s.MinWidth = LayoutLength::Px(0.0f);
                s.OverflowX = Overflow::Hidden; // a long message gives way to the end zone
            });
            m_end = MakeZone(u8"end");
            m_message = core::MakeRef<Label>(MemoryAllocator());
            m_message->AddClass(core::StringView(u8"message"));
            m_message->SetDisplayed(false);
            m_message->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Shrink = 1.0f;
                s.MinWidth = LayoutLength::Px(0.0f);
                s.Order = -1000000; // before every item
            });
            m_start->AddChild(m_message.Get());
        }

        /// Adds `item` to its zone, in its order. Its id (`SetId`) is what the bar knows it by.
        void AddItem(StatusItem& item)
        {
            item.m_bar = this;
            Place(item);
        }
        /// Takes the item `id` off the bar; false when there is none.
        bool RemoveItem(core::StringView id)
        {
            StatusItem* item = FindItem(id);
            if (item == nullptr)
                return false;
            item->m_bar = nullptr;
            item->RemoveFromParent();
            return true;
        }
        /// The item `id`, or null.
        [[nodiscard]] StatusItem* FindItem(core::StringView id) const
        {
            Node* const zones[] = {m_start.Get(), m_end.Get()};
            for (Node* zone : zones)
                for (usize i = 0; i < zone->ChildCount(); ++i)
                    if (StatusItem* item = Cast<StatusItem>(zone->GetChildAt(i)); item != nullptr && item->GetId() == id)
                        return item;
            return nullptr;
        }
        /// The items of `zone`, in order.
        [[nodiscard]] core::Array<StatusItem*> GetItems(StatusZone zone) const
        {
            core::Array<StatusItem*> out(MemoryAllocator());
            Node* host = zone == StatusZone::End ? m_end.Get() : m_start.Get();
            for (usize i = 0; i < host->ChildCount(); ++i)
                if (StatusItem* item = Cast<StatusItem>(host->GetChildAt(i)))
                {
                    usize at = out.Size();
                    while (at > 0 && out[at - 1]->GetOrder() > item->GetOrder())
                        --at;
                    out.Insert(at, item);
                }
            return out;
        }

        /// Shows or hides the item `id` (what the bar's menu does); false when there is none.
        bool SetItemShown(core::StringView id, bool shown)
        {
            StatusItem* item = FindItem(id);
            if (item == nullptr)
                return false;
            if (item->IsDisplayed() == shown)
                return true;
            item->SetDisplayed(shown);
            if (m_onShownChanged)
                m_onShownChanged(id, shown);
            return true;
        }
        [[nodiscard]] bool IsItemShown(core::StringView id) const
        {
            const StatusItem* item = FindItem(id);
            return item != nullptr && item->IsDisplayed();
        }
        /// Told when the user (or SetItemShown) shows or hides an item, to keep it with the settings.
        void SetOnItemShownChanged(core::Function<void(core::StringView id, bool shown)> changed) { m_onShownChanged = core::Move(changed); }

        /// Shows `text` at the start: until another replaces it or it is cleared (`seconds` 0), or
        /// for `seconds` on the GUI's clock.
        void ShowMessage(core::StringView text, f32 seconds = 0.0f)
        {
            ++m_messageId;
            m_message->SetText(text);
            m_message->SetDisplayed(text.Size() != 0);
            if (seconds <= 0.0f || text.Size() == 0)
                return;
            const u32 shown = m_messageId;
            StatusBar* self = this;
            f32 left = seconds;
            RunAction(core::MakeRef<TickAction>(MemoryAllocator(), [self, shown, left](core::Duration elapsed) mutable
                                                {
                                                    if (self->m_messageId != shown)
                                                        return false; // replaced: its own time counts now
                                                    left -= static_cast<f32>(elapsed.AsSeconds());
                                                    if (left > 0.0f)
                                                        return true;
                                                    self->ClearMessage();
                                                    return false;
                                                }));
        }
        void ClearMessage() { ShowMessage(core::StringView{}); }
        /// The message shown now (empty: none).
        [[nodiscard]] core::StringView GetMessage() const { return m_message->IsDisplayed() ? m_message->GetText() : core::StringView{}; }
        [[nodiscard]] Label* GetMessagePart() const noexcept { return m_message.Get(); }

        /// The menu of the items that can be hidden, while it is open.
        [[nodiscard]] Menu* GetItemsMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }
        /// Lists the items with a title, checked while they show; picking one shows or hides it.
        /// Opens at `position` (in this GUI's root); false when no item can be hidden.
        bool OpenItemsMenu(core::Float2 position)
        {
            m_menu = core::MakeRef<Menu>(MemoryAllocator());
            ShareTextStyle(*m_menu, false);
            m_menu->SetAutoWidth(true);
            bool any = false;
            StatusBar* self = this;
            const StatusZone zones[] = {StatusZone::Start, StatusZone::End};
            for (StatusZone zone : zones)
                for (StatusItem* item : GetItems(zone))
                {
                    if (item->GetTitle().Size() == 0)
                        continue;
                    const core::String id(item->GetId());
                    (void)m_menu->AddCheckItem(item->GetTitle(), item->IsDisplayed(), [self, id](bool shown) { (void)self->SetItemShown(id.AsView(), shown); });
                    any = true;
                }
            if (!any)
                return false;
            m_menu->Open(*this, position);
            return true;
        }

        /// Markup's children are its items (StatusItem), each placed as it arrives.
        [[nodiscard]] Node* GetChildHost() override
        {
            if (!m_markupHost)
            {
                StatusBar* self = this;
                m_markupHost = core::MakeRef<MarkupChildHost>(MemoryAllocator(), [self](Node& host)
                {
                    while (host.ChildCount() != 0)
                    {
                        core::RefPtr<Node> child(host.GetChildAt(0));
                        host.RemoveChild(child.Get());
                        if (StatusItem* item = Cast<StatusItem>(child.Get()))
                            self->AddItem(*item);
                    }
                });
                AddChild(m_markupHost.Get());
            }
            return m_markupHost.Get();
        }

    protected:
        void OnContextMenu(const MouseEvent& event) override
        {
            Node* top = GetRootNode();
            if (top != nullptr && OpenItemsMenu(top->ConvertToNodeSpace(event.Position)))
                event.Handled = true;
        }

    private:
        friend class StatusItem;
        core::RefPtr<Panel> MakeZone(const char8_t* name)
        {
            auto zone = core::MakeRef<Panel>(MemoryAllocator());
            zone->AddClass(core::StringView(name));
            zone->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.AlignItems = Align::Center;
                s.ColumnGap = 12.0f;
                s.Shrink = 0.0f;
            });
            AddChild(zone.Get());
            return zone;
        }
        // Into its zone, last (its order places it among the others there).
        void Place(StatusItem& item)
        {
            core::RefPtr<StatusItem> held(&item);
            item.RemoveFromParent();
            (item.GetZone() == StatusZone::End ? m_end.Get() : m_start.Get())->AddChild(&item);
        }

        core::RefPtr<Panel> m_start;
        core::RefPtr<Panel> m_end;
        core::RefPtr<Label> m_message;
        core::RefPtr<Menu> m_menu;
        core::RefPtr<MarkupChildHost> m_markupHost;
        core::Function<void(core::StringView, bool)> m_onShownChanged;
        u32 m_messageId = 0;
    };

    inline void StatusItem::Rehome()
    {
        if (m_bar != nullptr && GetParent() != nullptr)
            m_bar->Place(*this);
    }
}
