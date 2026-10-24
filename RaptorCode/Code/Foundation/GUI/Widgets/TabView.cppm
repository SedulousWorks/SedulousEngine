// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tab_view partition
//
// TabView: a TabBar over the pages its tabs show (E6 of Specs/gui-lab-evolution.md), Godot's
// TabContainer. Its pages are its children (markup's `<tabpage title="...">`, or AddPage), each
// with a tab in the bar that follows its title, icon and `closable`. Only the selected page is
// shown; the others stay alive, as they are (Godot's way), unless a page builds itself the first
// time it is shown (a content factory). A close request reports `tabclose` at the view, and unless
// a listener takes it, the page and its tab go. Ctrl+Tab and Ctrl+Shift+Tab cycle the pages with
// the focus anywhere inside the view.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:tab_view;

import foundation.core; // Function, Move, RefPtr, String
import :event;
import :layout_style;
import :ui_widget;
import :panel;
import :tab_bar;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// One page of a TabView: its tab's title, icon and closable, and what it holds.
    class TabPage : public Panel
    {
        RTTI_OBJECT(TabPage, Panel)
    public:
        TabPage()
        {
            SetTag(core::StringView(u8"tabpage"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s) { s.Grow = 1.0f; });
        }

        /// Its tab's text.
        void SetTitle(core::StringView title)
        {
            m_title = core::String(title);
            if (m_tab != nullptr)
                m_tab->SetText(title);
        }
        [[nodiscard]] core::StringView GetTitle() const noexcept { return m_title.AsView(); }
        void SetTitleString(const core::String& title) { SetTitle(title.AsView()); }
        [[nodiscard]] core::String GetTitleString() const { return m_title; }

        /// Its tab's icon, by path (loaded through the GUI's resource provider).
        void SetIconSource(const core::String& path)
        {
            m_icon = path;
            if (m_tab != nullptr)
                m_tab->SetIconSource(path);
        }
        [[nodiscard]] core::String GetIconSource() const { return m_icon; }

        /// Its tab can be closed.
        void SetClosable(bool closable)
        {
            m_closable = closable;
            if (m_tab != nullptr)
                m_tab->SetClosable(closable);
        }
        [[nodiscard]] bool IsClosable() const noexcept { return m_closable; }

        /// Builds what it holds the first time it is shown (a heavy page left unbuilt until wanted).
        void SetContentFactory(core::Function<void(TabPage& page)> factory) { m_factory = core::Move(factory); }
        /// Its tab (null while it is in no view).
        [[nodiscard]] Tab* GetTab() const noexcept { return m_tab; }

    private:
        friend class TabView;
        // Its tab, which then takes its title, icon and closable.
        void Attach(Tab* tab)
        {
            m_tab = tab;
            if (tab == nullptr)
                return;
            tab->SetText(m_title.AsView());
            if (!m_icon.IsEmpty())
                tab->SetIconSource(m_icon);
            tab->SetClosable(m_closable);
        }
        void Realize()
        {
            if (!m_factory)
                return;
            core::Function<void(TabPage&)> factory = core::Move(m_factory);
            factory(*this);
        }

        core::String m_title;
        core::String m_icon;
        bool m_closable = true;
        Tab* m_tab = nullptr; // owned by the view's bar
        core::Function<void(TabPage&)> m_factory;
    };

    class TabView;

    // What holds the pages: it tells its view when they change.
    class TabPageHost : public Panel
    {
        RTTI_OBJECT(TabPageHost, Panel)
    public:
        explicit TabPageHost(TabView& view) : m_view(view)
        {
            SetTag(core::StringView(u8"tabpages"));
            SetClipChildren(true);
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Grow = 1.0f;
                s.MinHeight = LayoutLength::Px(0.0f);
            });
        }
        void OnChildrenChanged() override;

    private:
        TabView& m_view; // its parent, which owns it
    };

    class TabView : public UIWidget
    {
        RTTI_OBJECT(TabView, UIWidget)
    public:
        TabView()
        {
            SetTag(core::StringView(u8"tabview"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.AlignItems = Align::Stretch;
                });
            }
            m_bar = core::MakeRef<TabBar>(MemoryAllocator());
            AddChild(m_bar.Get());
            m_host = core::MakeRef<TabPageHost>(MemoryAllocator(), *this);
            AddChild(m_host.Get());

            TabView* self = this;
            m_bar->SetOnSelectionChanged([self](i32) { self->ShowSelected(); });
            m_bar->SetOnSelected([self](i32 index)
            {
                if (self->m_onSelected)
                    self->m_onSelected(index);
                self->SendEvent(Event(EventType::Changed, self));
            });
            m_bar->SetOnTabMoved([self](i32, i32 to)
            {
                // The pages keep the tabs' order (a script's children read as the strip does).
                if (Node* page = self->m_bar->GetTab(to)->GetPage())
                    self->m_host->SetChildIndex(page, static_cast<usize>(to));
                if (self->m_onPageMoved)
                    self->m_onPageMoved(to);
            });
            m_bar->SetOnTabRemoved([self](Tab& tab)
            {
                // Code removed the tab from the bar: its page goes with it.
                if (Node* page = tab.GetPage(); page != nullptr && page->GetParent() == self->m_host.Get())
                    self->m_host->RemoveChild(page);
            });
            m_bar->SetCloseHandler([self](i32 index) { self->RequestClose(index); });
            // A tab dropped here from another view brings its page (E7).
            m_bar->SetPageAdopter([self](Node& page, i32 index)
            {
                self->m_host->AddChildAt(&page, static_cast<usize>(core::Max(0, index)));
            });
        }

        // === Pages ===
        /// Adds a page titled `title` at the end and returns it to fill.
        TabPage* AddPage(core::StringView title)
        {
            auto page = core::MakeRef<TabPage>(MemoryAllocator());
            page->SetTitle(title);
            m_host->AddChild(page.Get());
            return page.Get();
        }
        /// Adds a page made elsewhere (any node: one not a TabPage has an empty tab).
        void AddPage(Node& page) { m_host->AddChild(&page); }
        void RemovePage(i32 index)
        {
            if (Node* page = GetPage(index))
                m_host->RemoveChild(page);
        }
        [[nodiscard]] i32 GetPageCount() const noexcept { return m_bar->GetTabCount(); }
        /// A page by its tab's index (the tabs' order, which a drag changes).
        [[nodiscard]] Node* GetPage(i32 index) const
        {
            const Tab* tab = m_bar->GetTab(index);
            return tab != nullptr ? tab->GetPage() : nullptr;
        }

        // === Selection (the bar's) ===
        [[nodiscard]] i32 GetSelectedIndex() const { return m_bar->GetSelectedIndex(); }
        void SetSelectedIndex(i32 index) { m_bar->SetSelectedIndex(index); }
        [[nodiscard]] Node* GetSelectedPage() const { return GetPage(m_bar->GetSelectedIndex()); }
        /// The user selected a page (the `change` event's).
        void SetOnSelected(core::Function<void(i32)> callback) { m_onSelected = core::Move(callback); }
        /// The user dragged a page's tab to another place in the strip; `to` is where it is now.
        void SetOnPageMoved(core::Function<void(i32 to)> callback) { m_onPageMoved = core::Move(callback); }

        // === The bar's settings, from markup ===
        void SetCloseDisplayName(const core::String& name) { m_bar->SetCloseDisplayName(name); }
        [[nodiscard]] core::String GetCloseDisplayName() const { return m_bar->GetCloseDisplayName(); }
        void SetListDisplayName(const core::String& name) { m_bar->SetListDisplayName(name); }
        [[nodiscard]] core::String GetListDisplayName() const { return m_bar->GetListDisplayName(); }
        void SetCloseAll(bool shown) { m_bar->SetCloseAll(shown); }
        [[nodiscard]] bool HasCloseAll() const noexcept { return m_bar->HasCloseAll(); }
        void SetReorderable(bool reorderable) noexcept { m_bar->SetReorderable(reorderable); }
        [[nodiscard]] bool IsReorderable() const noexcept { return m_bar->IsReorderable(); }
        void SetGroup(const core::String& group) { m_bar->SetGroup(group); }
        [[nodiscard]] core::String GetGroup() const { return m_bar->GetGroup(); }

        /// Asks to close a page, as its tab's close part does: `tabclose` is reported here, and
        /// unless a listener takes it, the page goes.
        void RequestClose(i32 index)
        {
            const Tab* tab = m_bar->GetTab(index);
            if (tab == nullptr || !tab->IsClosable())
                return;
            const TabEvent request(EventType::TabClose, this, index);
            SendEvent(request);
            if (!request.Handled)
                RemovePage(index);
        }

        [[nodiscard]] TabBar* GetBar() const noexcept { return m_bar.Get(); }
        /// Markup's children are its pages.
        [[nodiscard]] Node* GetChildHost() override { return m_host.Get(); }

    protected:
        // A torn-out tab of its group dropped anywhere over the view (not only its strip) goes
        // last; over the strip, the strip places it.
        void OnDragQuery(DropQuery& query) override { (void)m_bar->OfferTab(query, m_bar->GetTabCount()); }
        void OnDragLeave(const DragEvent&) override { m_bar->ClearTabMark(); }
        void OnDrop(const DragEvent& event) override { m_bar->DropTab(event.Payload); }
        // Its bar writes in its font (and the bar's tabs).
        void OnTextStyleChange() override { ShareTextStyle(*m_bar, false); }
        void OnKeyDown(const KeyEvent& event) override
        {
            const i32 step = TabBar::CycleStep(event);
            if (step == 0)
                return;
            m_bar->CycleSelection(step);
            event.Handled = true;
        }

    private:
        friend class TabPageHost;

        // The pages changed: a tab for each new one (in the pages' order), none for one gone.
        void SyncPages()
        {
            for (i32 i = m_bar->GetTabCount(); i-- > 0;)
            {
                Tab* tab = m_bar->GetTab(i);
                Node* page = tab->GetPage();
                if (page != nullptr && page->GetParent() == m_host.Get())
                    continue;
                if (TabPage* tp = core::Cast<TabPage>(page))
                    tp->Attach(nullptr);
                tab->SetPage(nullptr);
                m_bar->RemoveTab(i);
            }
            for (usize i = 0; i < m_host->ChildCount(); ++i)
            {
                Node* page = m_host->GetChildAt(i);
                if (TabOf(*page) != nullptr)
                    continue;
                Tab* tab = m_bar->InsertTab(static_cast<i32>(i), core::StringView{});
                tab->SetPage(page);
                if (TabPage* tp = core::Cast<TabPage>(page))
                    tp->Attach(tab);
            }
            ShowSelected();
        }
        [[nodiscard]] Tab* TabOf(const Node& page) const
        {
            for (i32 i = 0; i < m_bar->GetTabCount(); ++i)
                if (m_bar->GetTab(i)->GetPage() == &page)
                    return m_bar->GetTab(i);
            return nullptr;
        }
        // The selected tab's page alone is shown (built now if it builds itself).
        void ShowSelected()
        {
            const Tab* selected = m_bar->GetSelectedTab();
            for (usize i = 0; i < m_host->ChildCount(); ++i)
            {
                Node* page = m_host->GetChildAt(i);
                const bool shown = selected != nullptr && selected->GetPage() == page;
                if (shown)
                    if (TabPage* tp = core::Cast<TabPage>(page))
                        tp->Realize();
                page->SetDisplayed(shown);
            }
        }

        core::RefPtr<TabBar> m_bar;
        core::RefPtr<TabPageHost> m_host;
        core::Function<void(i32)> m_onPageMoved;
        core::Function<void(i32)> m_onSelected;
    };

    inline void TabPageHost::OnChildrenChanged() { m_view.SyncPages(); }
}
