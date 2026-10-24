// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - tabs (E6): a TabBar of real tab elements and a TabView pairing it with pages. Selection by
// the press, the keys and Ctrl+Tab; closing as a request with a display policy; reordering by a
// drag across a neighbour's midpoint; an overflowing strip that scrolls and lists every tab (or
// always lists them), and a part that closes them all; pages kept alive, or built on first show;
// markup's pages.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    core::RefPtr<SceneRoot> MakeRoot(float width = 400.0f)
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{width, 300.0f});
        return root;
    }

    // Tabs of a known width (the tests have no font to size their text).
    Tab* AddSizedTab(TabBar& bar, const char8_t* text, float width = 80.0f)
    {
        Tab* tab = bar.AddTab(core::StringView(text));
        tab->EditLayoutStyle([width](LayoutStyle& s)
        {
            s.Width = LayoutLength::Px(width);
            s.Height = LayoutLength::Px(24.0f);
        });
        return tab;
    }

    core::Float2 CentreOf(const Node& node)
    {
        const Rect r = node.GetScreenBounds();
        return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
    }

    void Press(EventDispatcher& d, core::Float2 at, MouseButton button = MouseButton::Left)
    {
        d.InjectMouseDown(at, button);
        d.InjectMouseUp(at, button);
    }
}

TEST_CASE("tabs: the first tab is selected; a press selects, reporting change, while code's selection reports nothing")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    Tab* a = AddSizedTab(*bar, u8"One");
    Tab* b = AddSizedTab(*bar, u8"Two");
    AddSizedTab(*bar, u8"Three");
    (void)root->UpdateLayout();
    CHECK(bar->GetTabCount() == 3);
    CHECK(bar->GetSelectedIndex() == 0);
    CHECK(a->IsSelected());
    CHECK((a->GetWidgetStates() & WidgetStateChecked) != 0); // `tab:checked`

    int changes = 0;
    int selectedByUser = -1;
    int anyChange = 0;
    (void)bar->AddEventListener(EventType::Changed, [&](const Event&) { ++changes; });
    bar->SetOnSelected([&](core::i32 index) { selectedByUser = index; });
    bar->SetOnSelectionChanged([&](core::i32) { ++anyChange; });

    EventDispatcher& d = *root->GetEventDispatcher();
    d.InjectMouseDown(CentreOf(*b), MouseButton::Left); // a tab selects on the press
    CHECK(bar->GetSelectedIndex() == 1);
    d.InjectMouseUp(CentreOf(*b), MouseButton::Left);
    CHECK(changes == 1);
    CHECK(selectedByUser == 1);
    CHECK(b->IsFocused());
    CHECK_FALSE(a->IsSelected());

    bar->SetSelectedIndex(2);
    CHECK(bar->GetSelectedIndex() == 2);
    CHECK(changes == 1); // code's selection: no change event
    CHECK(anyChange == 2); // but what shows a page follows both
}

TEST_CASE("tabs: the arrows, Home and End move along the strip; Ctrl+Tab and Ctrl+Shift+Tab cycle round it")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    const char8_t* const names[] = {u8"A", u8"B", u8"C", u8"D"};
    for (const char8_t* t : names)
        AddSizedTab(*bar, t, 60.0f);
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    bar->GetTab(0)->RequestFocus();

    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(bar->GetSelectedIndex() == 1);
    CHECK(bar->GetTab(1)->IsFocused());
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::End));
    CHECK(bar->GetSelectedIndex() == 3);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Home));
    CHECK(bar->GetSelectedIndex() == 0);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left)); // at the start the arrow is navigation's
    CHECK(bar->GetSelectedIndex() == 0);

    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModCtrl | KeyModShift); // back, round to the last
    CHECK(bar->GetSelectedIndex() == 3);
    CHECK(bar->GetTab(3)->IsFocused());
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModCtrl); // on, round to the first
    CHECK(bar->GetSelectedIndex() == 0);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::PageDown), KeyModCtrl);
    CHECK(bar->GetSelectedIndex() == 1);
}

TEST_CASE("tabs: the close display policy shows the close part on never, the selected, the hovered and every tab")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    Tab* a = AddSizedTab(*bar, u8"A");
    Tab* b = AddSizedTab(*bar, u8"B");
    (void)root->UpdateLayout();

    CHECK_FALSE(a->GetClosePart()->IsDisplayed()); // never, by default: no room for it either
    bar->SetCloseDisplay(TabCloseDisplay::Selected);
    CHECK(a->GetClosePart()->IsDisplayed());
    CHECK(a->GetClosePart()->IsVisible());
    CHECK(b->GetClosePart()->IsDisplayed()); // its room is kept, so showing it grows nothing
    CHECK_FALSE(b->GetClosePart()->IsVisible());

    bar->SetCloseDisplay(TabCloseDisplay::Hover);
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    CHECK_FALSE(b->GetClosePart()->IsVisible());
    d.InjectMouseMove(CentreOf(*b));
    CHECK(b->GetClosePart()->IsVisible());
    d.InjectMouseMove(core::Float2{390.0f, 290.0f});
    CHECK_FALSE(b->GetClosePart()->IsVisible());

    bar->SetCloseDisplay(TabCloseDisplay::Always);
    CHECK(b->GetClosePart()->IsVisible());
    b->SetClosable(false);
    CHECK_FALSE(b->GetClosePart()->IsDisplayed());

    bar->SetCloseDisplayName(core::String(u8"hover"));
    CHECK(bar->GetCloseDisplay() == TabCloseDisplay::Hover);
    CHECK(bar->GetCloseDisplayName() == core::StringView(u8"hover"));
}

TEST_CASE("tabs: closing is a request: tabclose is reported, and the tab goes unless a listener takes it")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    bar->SetCloseDisplay(TabCloseDisplay::Always);
    AddSizedTab(*bar, u8"A");
    Tab* b = AddSizedTab(*bar, u8"B");
    AddSizedTab(*bar, u8"C");
    bar->SetSelectedIndex(1);
    (void)root->UpdateLayout();

    bool keep = true;
    int requests = 0;
    core::i32 asked = -1;
    (void)bar->AddEventListener(EventType::TabClose, [&](const Event& e)
    {
        ++requests;
        asked = static_cast<const TabEvent&>(e).Index;
        if (keep)
            e.Handled = true; // taken: the tab stays (an unsaved document asks first)
    });
    core::i32 removed = 0;
    bar->SetOnTabRemoved([&](Tab&) { ++removed; });

    EventDispatcher& d = *root->GetEventDispatcher();
    Press(d, CentreOf(*b->GetClosePart()));
    CHECK(requests == 1);
    CHECK(asked == 1);
    CHECK(bar->GetTabCount() == 3);
    CHECK(bar->GetSelectedIndex() == 1); // the close part's press does not select either

    keep = false;
    Press(d, CentreOf(*b->GetClosePart()));
    CHECK(requests == 2);
    CHECK(bar->GetTabCount() == 2);
    CHECK(removed == 1);
    // The selected tab went: the one after it takes its place.
    CHECK(bar->GetSelectedIndex() == 1);
    CHECK(bar->GetSelectedTab()->GetText() == core::StringView(u8"C"));

    // A middle click closes too; a tab not closable ignores both.
    Tab* a = bar->GetTab(0);
    a->SetClosable(false);
    (void)root->UpdateLayout();
    Press(d, CentreOf(*a), MouseButton::Middle);
    CHECK(bar->GetTabCount() == 2);
    (void)root->UpdateLayout();
    Press(d, CentreOf(*bar->GetTab(1)), MouseButton::Middle);
    CHECK(bar->GetTabCount() == 1);
    CHECK(bar->GetSelectedIndex() == 0);
}

TEST_CASE("tabs: reorderable, a tab dragged across a neighbour's midpoint changes places with it")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    Tab* a = AddSizedTab(*bar, u8"A");
    AddSizedTab(*bar, u8"B");
    AddSizedTab(*bar, u8"C");
    core::i32 movedFrom = -1, movedTo = -1;
    bar->SetOnTabMoved([&](core::i32 from, core::i32 to)
    {
        movedFrom = from;
        movedTo = to;
    });
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    const core::Float2 start = CentreOf(*a);

    // Not reorderable: a drag moves nothing.
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x + 100.0f, start.y});
    d.InjectMouseUp(core::Float2{start.x + 100.0f, start.y}, MouseButton::Left);
    CHECK(bar->IndexOf(a) == 0);

    bar->SetReorderable(true);
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x + 30.0f, start.y}); // short of B's midpoint (82 + 40 from A's left)
    CHECK(bar->IndexOf(a) == 0);
    d.InjectMouseMove(core::Float2{start.x + 90.0f, start.y}); // past it
    CHECK(bar->IndexOf(a) == 1);
    CHECK(movedFrom == 0);
    CHECK(movedTo == 1);
    CHECK(a->HasClass(core::StringView(u8"dragging")));
    (void)root->UpdateLayout();
    d.InjectMouseMove(core::Float2{start.x + 180.0f, start.y}); // past C's
    CHECK(bar->IndexOf(a) == 2);
    (void)root->UpdateLayout();
    d.InjectMouseMove(core::Float2{start.x + 60.0f, start.y}); // back past C's again (now before it)
    CHECK(bar->IndexOf(a) == 1);
    d.InjectMouseUp(core::Float2{start.x + 60.0f, start.y}, MouseButton::Left);
    CHECK_FALSE(a->HasClass(core::StringView(u8"dragging")));
    CHECK(a->IsSelected()); // it stays the selected tab wherever it goes
}

TEST_CASE("tabs: tabs past the strip's end scroll it, a selected one is scrolled to, and a button lists them all")
{
    auto root = MakeRoot(300.0f);
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    AddSizedTab(*bar, u8"A");
    AddSizedTab(*bar, u8"B");
    (void)root->UpdateLayout();
    CHECK_FALSE(bar->GetListButton()->IsDisplayed()); // they fit

    const char8_t* const more[] = {u8"C", u8"D", u8"E", u8"F"};
    for (const char8_t* t : more)
        AddSizedTab(*bar, t);
    (void)root->UpdateLayout();
    CHECK(bar->GetListButton()->IsDisplayed());
    CHECK(bar->GetStrip()->GetScrollRange().x > 0.0f);

    bar->SetSelectedIndex(5);
    (void)root->UpdateLayout();
    const Rect strip = bar->GetStrip()->GetScreenBounds();
    const Rect last = bar->GetTab(5)->GetScreenBounds();
    CHECK(last.x + last.width <= strip.x + strip.width + 0.5f);

    // The wheel turns the strip across (it scrolls on one axis only).
    bar->SetSelectedIndex(0);
    bar->GetStrip()->SetScrollOffset(core::Float2{0.0f, 0.0f});
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    d.InjectMouseWheel(CentreOf(*bar->GetTab(0)), core::Float2{0.0f, -1.0f});
    CHECK(bar->GetStrip()->GetScrollOffset().x > 0.0f);

    // The list: every tab, the selected one checked; picking one selects it.
    Press(d, CentreOf(*bar->GetListButton()));
    Menu* menu = bar->GetTabListMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->ItemCount() == 6);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(bar->GetSelectedIndex() == 2);
    CHECK(bar->GetTabListMenu() == nullptr);
}

TEST_CASE("tabs: the list button shows always when asked; close-all asks to close every closable tab, last first")
{
    auto root = MakeRoot();
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    AddSizedTab(*bar, u8"A");
    AddSizedTab(*bar, u8"B");
    Tab* fixed = AddSizedTab(*bar, u8"C");
    fixed->SetClosable(false);
    (void)root->UpdateLayout();
    CHECK_FALSE(bar->GetListButton()->IsDisplayed()); // they fit
    CHECK_FALSE(bar->GetCloseAllPart()->IsDisplayed()); // not asked for
    bar->SetListDisplay(TabListDisplay::Always);
    bar->SetCloseAll(true);
    (void)root->UpdateLayout();
    CHECK(bar->GetListButton()->IsDisplayed());
    REQUIRE(bar->GetCloseAllPart()->IsDisplayed());
    // Past the list button, both past the strip.
    const Rect list = bar->GetListButton()->GetScreenBounds();
    const Rect all = bar->GetCloseAllPart()->GetScreenBounds();
    CHECK(all.x >= list.x + list.width - 0.5f);
    CHECK(list.x >= bar->GetStrip()->GetScreenBounds().x + bar->GetStrip()->GetScreenBounds().width - 0.5f);

    core::Array<core::String> asked;
    (void)bar->AddEventListener(EventType::TabClose, [&](const Event& e)
    {
        asked.PushBack(core::String(bar->GetTab(static_cast<const TabEvent&>(e).Index)->GetText()));
    });
    EventDispatcher& d = *root->GetEventDispatcher();
    Press(d, CentreOf(*bar->GetCloseAllPart()));
    REQUIRE(asked.Size() == 2);
    CHECK(asked[0] == core::StringView(u8"B"));
    CHECK(asked[1] == core::StringView(u8"A"));
    REQUIRE(bar->GetTabCount() == 1);
    CHECK(bar->GetTab(0) == fixed);
    CHECK_FALSE(bar->GetCloseAllPart()->IsDisplayed()); // none closable is left
    fixed->SetClosable(true);
    CHECK(bar->GetCloseAllPart()->IsDisplayed());

    // An owner that makes its tabs again after each close (docking does): every one still closes.
    auto owned = Make<TabBar>();
    root->AddChild(owned.Get());
    const char8_t* const names[] = {u8"P", u8"Q", u8"R"};
    for (const char8_t* t : names)
        AddSizedTab(*owned, t);
    owned->SetCloseHandler([&](core::i32 index)
    {
        core::Array<core::String> rest;
        for (core::i32 i = 0; i < owned->GetTabCount(); ++i)
            if (i != index)
                rest.PushBack(core::String(owned->GetTab(i)->GetText()));
        while (owned->GetTabCount() > 0)
            owned->RemoveTab(0);
        for (const core::String& t : rest)
            (void)owned->AddTab(t.AsView());
    });
    owned->CloseAll();
    CHECK(owned->GetTabCount() == 0);
}

TEST_CASE("tabview: close-all closes every closable page through the view's own request")
{
    auto root = MakeRoot();
    auto view = Make<TabView>();
    root->AddChild(view.Get());
    view->SetCloseAll(true);
    const char8_t* const titles[] = {u8"A", u8"B", u8"C"};
    for (const char8_t* t : titles)
        (void)view->AddPage(core::StringView(t));
    int requests = 0;
    (void)view->AddEventListener(EventType::TabClose, [&](const Event& e)
    {
        ++requests;
        if (static_cast<const TabEvent&>(e).Index == 0)
            e.Handled = true; // the first is kept (an unsaved document asks first)
    });
    view->GetBar()->CloseAll();
    CHECK(requests == 3);
    REQUIRE(view->GetPageCount() == 1);
    CHECK(view->GetBar()->GetTab(0)->GetText() == core::StringView(u8"A"));
}

TEST_CASE("tabview: pages pair with tabs; only the selected one shows; hidden ones stay alive; Ctrl+Tab from inside a page")
{
    auto root = MakeRoot();
    auto view = Make<TabView>();
    view->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(200.0f); });
    root->AddChild(view.Get());
    TabPage* first = view->AddPage(core::StringView(u8"First"));
    TabPage* second = view->AddPage(core::StringView(u8"Second"));
    auto field = Make<TextField>();
    second->AddChild(field.Get());
    for (core::i32 i = 0; i < 2; ++i)
        view->GetBar()->GetTab(i)->EditLayoutStyle([](LayoutStyle& s)
        {
            s.Width = LayoutLength::Px(80.0f);
            s.Height = LayoutLength::Px(24.0f);
        });
    (void)root->UpdateLayout();

    CHECK(view->GetPageCount() == 2);
    CHECK(view->GetBar()->GetTab(1)->GetText() == core::StringView(u8"Second"));
    CHECK(first->GetTab() == view->GetBar()->GetTab(0));
    CHECK(first->IsDisplayed());
    CHECK_FALSE(second->IsDisplayed());
    CHECK(first->GetSize().y > 100.0f); // a page fills what the bar leaves

    second->SetTitle(core::StringView(u8"Renamed")); // its tab follows it
    CHECK(view->GetBar()->GetTab(1)->GetText() == core::StringView(u8"Renamed"));

    int changes = 0;
    (void)view->AddEventListener(EventType::Changed, [&](const Event&) { ++changes; });
    EventDispatcher& d = *root->GetEventDispatcher();
    Press(d, CentreOf(*view->GetBar()->GetTab(1)));
    CHECK(view->GetSelectedIndex() == 1);
    CHECK(changes == 1);
    CHECK_FALSE(first->IsDisplayed());
    CHECK(second->IsDisplayed());
    CHECK(first->GetParent() != nullptr); // kept alive

    // Ctrl+Tab with the focus in a page.
    field->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModCtrl);
    CHECK(view->GetSelectedIndex() == 0);
    CHECK(changes == 2);
}

TEST_CASE("tabs: in right to left a tab dragged toward the left passes the next one")
{
    auto root = MakeRoot();
    root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto bar = Make<TabBar>();
    root->AddChild(bar.Get());
    bar->SetReorderable(true);
    Tab* a = AddSizedTab(*bar, u8"A");
    Tab* b = AddSizedTab(*bar, u8"B");
    AddSizedTab(*bar, u8"C");
    (void)root->UpdateLayout();
    REQUIRE(CentreOf(*a).x > CentreOf(*b).x); // the first tab at the right
    EventDispatcher& d = *root->GetEventDispatcher();
    const core::Float2 start = CentreOf(*a);
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x - 30.0f, start.y}); // short of B's midpoint
    CHECK(bar->IndexOf(a) == 0);
    d.InjectMouseMove(core::Float2{start.x - 90.0f, start.y}); // past it, toward the inline end
    CHECK(bar->IndexOf(a) == 1);
    d.InjectMouseUp(core::Float2{start.x - 90.0f, start.y}, MouseButton::Left);
    (void)root->UpdateLayout();
    d.InjectMouseDown(CentreOf(*a), MouseButton::Left);
    d.InjectMouseMove(core::Float2{CentreOf(*a).x + 90.0f, start.y}); // back toward the inline start
    CHECK(bar->IndexOf(a) == 0);
    d.InjectMouseUp(core::Float2{CentreOf(*a).x, start.y}, MouseButton::Left);
}

TEST_CASE("tabview: a close request reaches the view, and unless taken, the page and its tab go; a drag moves the page too")
{
    auto root = MakeRoot();
    auto view = Make<TabView>();
    root->AddChild(view.Get());
    view->GetBar()->SetCloseDisplay(TabCloseDisplay::Always);
    view->SetReorderable(true);
    const char8_t* const names[] = {u8"A", u8"B", u8"C"};
    for (const char8_t* t : names)
        view->AddPage(core::StringView(t))->GetTab()->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(80.0f); });
    Node* pageA = view->GetPage(0);
    (void)root->UpdateLayout();

    bool keep = false;
    core::i32 asked = -1;
    (void)view->AddEventListener(EventType::TabClose, [&](const Event& e)
    {
        asked = static_cast<const TabEvent&>(e).Index;
        e.Handled = keep;
    });
    EventDispatcher& d = *root->GetEventDispatcher();
    Press(d, CentreOf(*view->GetBar()->GetTab(1)->GetClosePart()));
    CHECK(asked == 1);
    CHECK(view->GetPageCount() == 2);
    CHECK(view->GetChildHost()->ChildCount() == 2);
    CHECK(static_cast<TabPage*>(view->GetPage(1))->GetTitle() == core::StringView(u8"C"));

    keep = true;
    (void)root->UpdateLayout();
    Press(d, CentreOf(*view->GetBar()->GetTab(1)->GetClosePart()));
    CHECK(view->GetPageCount() == 2);

    // A drag of A past C: the pages keep the tabs' order.
    (void)root->UpdateLayout();
    const core::Float2 start = CentreOf(*view->GetBar()->GetTab(0));
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x + 90.0f, start.y});
    d.InjectMouseUp(core::Float2{start.x + 90.0f, start.y}, MouseButton::Left);
    CHECK(view->GetPage(1) == pageA);
    CHECK(view->GetChildHost()->GetChildAt(1) == pageA);
    CHECK(view->GetSelectedPage() == pageA);

    // Code removing a page takes its tab.
    view->RemovePage(0);
    CHECK(view->GetPageCount() == 1);
    CHECK(view->GetBar()->GetTabCount() == 1);
    CHECK(view->GetSelectedPage() == pageA);
}

TEST_CASE("tabview: a page with a content factory is built the first time it is shown")
{
    auto root = MakeRoot();
    auto view = Make<TabView>();
    root->AddChild(view.Get());
    view->AddPage(core::StringView(u8"Light"));
    TabPage* heavy = view->AddPage(core::StringView(u8"Heavy"));
    int built = 0;
    heavy->SetContentFactory([&](TabPage& page)
    {
        ++built;
        page.AddChild(Make<Label>().Get());
    });
    CHECK(built == 0);
    view->SetSelectedIndex(1);
    CHECK(built == 1);
    CHECK(heavy->ChildCount() == 1);
    view->SetSelectedIndex(0);
    view->SetSelectedIndex(1);
    CHECK(built == 1);
}

TEST_CASE("tabview: markup's pages are its children, with title, icon and closable; its bar's settings are attributes")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<TabView close-display="hover" reorderable="true" selected="1" list-display="always" close-all="true">
        <TabPage title="General"><Label text="one"/></TabPage>
        <TabPage title="Advanced" closable="false" icon="ui/icons/gear.png"/>
    </TabView>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* view = core::Cast<TabView>(tree.Get());
    REQUIRE(view != nullptr);
    CHECK(view->GetPageCount() == 2);
    CHECK(view->GetBar()->GetTab(0)->GetText() == core::StringView(u8"General"));
    CHECK_FALSE(view->GetBar()->GetTab(1)->IsClosable());
    CHECK(view->GetBar()->GetTab(1)->GetIconSource() == core::StringView(u8"ui/icons/gear.png"));
    CHECK(view->GetBar()->GetCloseDisplay() == TabCloseDisplay::Hover);
    CHECK(view->IsReorderable());
    CHECK(view->GetSelectedIndex() == 1);
    CHECK(view->GetBar()->GetListDisplay() == TabListDisplay::Always);
    CHECK(view->HasCloseAll());

    // A bar alone: markup's children are its tabs.
    auto barTree = loader.LoadFromString(core::StringView(u8R"(<TabBar><Tab text="One"/><Tab text="Two" icon="a.png"/></TabBar>)"));
    auto* bar = core::Cast<TabBar>(barTree.Get());
    REQUIRE(bar != nullptr);
    CHECK(bar->GetTabCount() == 2);
    CHECK(bar->GetSelectedIndex() == 0);
    CHECK(bar->GetTab(1)->GetIconSource() == core::StringView(u8"a.png"));
}

namespace
{
    core::RefPtr<TabBar> BarAt(SceneRoot& root, float y, const char8_t* group)
    {
        auto bar = Make<TabBar>();
        bar->EditLayoutStyle([y](LayoutStyle& s)
        {
            s.Placement = Position::Absolute;
            s.Left = LayoutLength::Px(10.0f);
            s.Top = LayoutLength::Px(y);
            s.Width = LayoutLength::Px(380.0f);
        });
        bar->SetReorderable(true);
        bar->SetGroup(core::String(group));
        root.AddChild(bar.Get());
        return bar;
    }
}

TEST_CASE("tabs: in a group's strip a tab moved past the threshold, any way, is a drag that a strip of its group takes, where the mark is")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    auto bottom = BarAt(*root, 150.0f, u8"docs");
    auto other = BarAt(*root, 250.0f, u8"tools");
    AddSizedTab(*top, u8"A");
    Tab* b = AddSizedTab(*top, u8"B");
    AddSizedTab(*bottom, u8"X");
    AddSizedTab(*bottom, u8"Y");
    AddSizedTab(*other, u8"T");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();

    const core::Float2 start = CentreOf(*b);
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x + 3.0f, start.y}); // within the threshold (6)
    CHECK_FALSE(d.IsDragging());
    d.InjectMouseMove(core::Float2{start.x + 8.0f, start.y}); // along the strip: a drag at once
    REQUIRE(d.IsDragging());
    CHECK(d.GetDragPayload().Type == core::StringView(u8"gui/tab"));
    CHECK(d.GetDragPayload().Label == core::StringView(u8"B"));

    // Over the other group's strip: nothing takes it.
    d.InjectMouseMove(CentreOf(*other->GetTab(0)));
    CHECK(d.GetDropTarget() == nullptr);
    // Over the bottom strip, left of Y's middle: between X and Y.
    const Rect y = bottom->GetTab(1)->GetScreenBounds();
    d.InjectMouseMove(core::Float2{y.x + 10.0f, y.y + 10.0f});
    CHECK(d.GetDropTarget() == bottom.Get());
    CHECK(bottom->GetDropIndex() == 1);
    d.InjectMouseUp(core::Float2{y.x + 10.0f, y.y + 10.0f}, MouseButton::Left);
    CHECK(top->GetTabCount() == 1);
    REQUIRE(bottom->GetTabCount() == 3);
    CHECK(bottom->GetTab(1) == b); // the tab itself moved
    CHECK(bottom->GetSelectedTab() == b);
    CHECK(bottom->GetDropIndex() == -1);
}

TEST_CASE("tabs: in a group's strip a tab dropped back into it reorders it; not reorderable, its strip does not take it")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    Tab* a = AddSizedTab(*top, u8"A");
    AddSizedTab(*top, u8"B");
    Tab* c = AddSizedTab(*top, u8"C");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();

    // A along the strip past C's middle: no slide on the way, then last at the drop.
    const core::Float2 start = CentreOf(*a);
    d.InjectMouseDown(start, MouseButton::Left);
    const Rect cr = c->GetScreenBounds();
    const core::Float2 end{cr.x + cr.width - 4.0f, start.y};
    d.InjectMouseMove(core::Float2{start.x + 10.0f, start.y});
    REQUIRE(d.IsDragging());
    d.InjectMouseMove(end);
    CHECK(top->GetTab(0) == a); // nothing slid
    CHECK(d.GetDropTarget() == top.Get());
    CHECK(top->GetDropIndex() == 3);
    d.InjectMouseUp(end, MouseButton::Left);
    CHECK(top->GetTab(2) == a);
    CHECK(top->GetSelectedTab() == a);

    top->SetReorderable(false);
    const core::Float2 again = CentreOf(*a);
    d.InjectMouseDown(again, MouseButton::Left);
    d.InjectMouseMove(core::Float2{again.x - 10.0f, again.y});
    REQUIRE(d.IsDragging()); // its group still takes it elsewhere
    d.InjectMouseMove(CentreOf(*top->GetTab(0)));
    CHECK(d.GetDropTarget() != top.Get());
    d.InjectMouseUp(CentreOf(*top->GetTab(0)), MouseButton::Left);
    CHECK(top->GetTab(2) == a);
}

TEST_CASE("tabs: an owner answers a tab offered to a strip (a refusal with its reason, or passed on) and takes a dropped one over")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    auto bottom = BarAt(*root, 150.0f, u8"docs");
    Tab* a = AddSizedTab(*top, u8"A");
    AddSizedTab(*top, u8"B");
    AddSizedTab(*bottom, u8"X");
    AddSizedTab(*bottom, u8"Y");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    bool refuse = true;
    Tab* offered = nullptr;
    bottom->SetOnTabOffered([&](DropQuery& query, Tab& tab, core::i32 index)
    {
        offered = &tab;
        if (refuse)
            query.Refuse(core::StringView(u8"no room"));
        else
            query.Reason = core::Format(u8"to {}", index);
    });
    Tab* taken = nullptr;
    core::i32 takenAt = -1;
    bottom->SetTabTaker([&](Tab& tab, core::i32 index)
    {
        taken = &tab;
        takenAt = index;
    });

    const core::Float2 start = CentreOf(*a);
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x, start.y + 60.0f});
    REQUIRE(d.IsDragging());
    const Rect y = bottom->GetTab(1)->GetScreenBounds();
    const core::Float2 at{y.x + 10.0f, y.y + 10.0f};
    d.InjectMouseMove(at);
    CHECK(offered == a);
    CHECK(d.GetDropTarget() == nullptr);
    CHECK(d.GetDropReason() == core::StringView(u8"no room"));
    CHECK(bottom->GetDropIndex() == -1); // no mark where it may not go
    refuse = false;
    d.InjectMouseMove(core::Float2{at.x + 1.0f, at.y});
    CHECK(d.GetDropTarget() == bottom.Get());
    CHECK(d.GetDropReason() == core::StringView(u8"to 1"));
    CHECK(bottom->GetDropIndex() == 1);
    d.InjectMouseUp(core::Float2{at.x + 1.0f, at.y}, MouseButton::Left);
    CHECK(taken == a);
    CHECK(takenAt == 1);
    CHECK(top->GetTabCount() == 2); // the bar moved nothing
    CHECK(bottom->GetTabCount() == 2);
    CHECK(bottom->GetDropIndex() == -1);

    // Passed on (its effect set back to none): no mark, and what holds the strip is asked.
    bool askedAbove = false;
    bottom->SetOnTabOffered([](DropQuery& query, Tab&, core::i32) { query.Effect = DropEffect::None; });
    root->SetOnDragQuery([&askedAbove](DropQuery& query)
    {
        askedAbove = true;
        query.Accept(DropEffect::Move);
    });
    const core::Float2 b = CentreOf(*top->GetTab(1));
    d.InjectMouseDown(b, MouseButton::Left);
    d.InjectMouseMove(core::Float2{b.x, b.y + 60.0f});
    REQUIRE(d.IsDragging());
    d.InjectMouseMove(at);
    CHECK(askedAbove);
    CHECK(d.GetDropTarget() == root.Get());
    CHECK(bottom->GetDropIndex() == -1);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
}

TEST_CASE("tabs: a torn tab's ghost is the tab, held where it was grabbed; its bar hears it torn and the drag over; a hidden tab is no place")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    Tab* a = AddSizedTab(*top, u8"A");
    Tab* b = AddSizedTab(*top, u8"B");
    Tab* c = AddSizedTab(*top, u8"C");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    core::Array<core::String> heard;
    top->SetOnTabTorn([&](Tab& tab, bool torn) { heard.PushBack(core::Format(u8"{} {}", tab.GetText(), torn ? u8"torn" : u8"back")); });

    const Rect from = b->GetScreenBounds();
    const core::Float2 press{from.x + 7.0f, from.y + 5.0f};
    d.InjectMouseDown(press, MouseButton::Left);
    const core::Float2 out{press.x + 3.0f, press.y + 60.0f};
    d.InjectMouseMove(out);
    REQUIRE(d.IsDragging());
    REQUIRE(heard.Size() == 1u);
    CHECK(heard[0] == core::StringView(u8"B torn"));
    auto* ghost = Cast<DragPreview>(d.GetDragPreview());
    REQUIRE(ghost != nullptr);
    CHECK(ghost->HasClass(core::StringView(u8"tab")));
    CHECK(ghost->GetText() == core::StringView(u8"B"));
    (void)root->UpdateLayout();
    CHECK(ghost->GetSize().x == doctest::Approx(from.width));
    CHECK(ghost->GetSize().y == doctest::Approx(from.height));
    const Rect held = ghost->GetScreenBounds();
    CHECK(held.x == doctest::Approx(out.x - 7.0f)); // the press's place on it, under the pointer
    CHECK(held.y == doctest::Approx(out.y - 5.0f));

    // Hidden (as an owner may while it is torn): counted, but no place of its own. Left of C's
    // middle is before C (2), past the hidden B.
    b->SetDisplayed(false);
    (void)root->UpdateLayout();
    const Rect cr = c->GetScreenBounds();
    d.InjectMouseMove(core::Float2{cr.x + 3.0f, cr.y + 5.0f});
    CHECK(top->GetDropIndex() == 2);
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(d.IsDragging());
    REQUIRE(heard.Size() == 2u);
    CHECK(heard[1] == core::StringView(u8"B back"));
    (void)a;
}

TEST_CASE("tabs: the bar a tab was torn from hears how its drag ended: cancelled, or let go outside the window")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    AddSizedTab(*top, u8"A");
    Tab* b = AddSizedTab(*top, u8"B");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    int ends = 0;
    DragResult last;
    const Tab* whose = nullptr;
    top->SetOnTabDragEnded([&](Tab& tab, const DragResult& result)
    {
        ++ends;
        last = result;
        whose = &tab;
    });
    const Rect from = b->GetScreenBounds();
    const core::Float2 press{from.x + 7.0f, from.y + 5.0f};
    d.InjectMouseDown(press, MouseButton::Left);
    d.InjectMouseMove(core::Float2{press.x, press.y + 60.0f});
    REQUIRE(d.IsDragging());
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    REQUIRE(ends == 1);
    CHECK(whose == b);
    CHECK(last.Cancelled);
    CHECK_FALSE(last.Outside);

    d.InjectMouseDown(press, MouseButton::Left);
    d.InjectMouseMove(core::Float2{press.x, press.y + 60.0f});
    d.InjectMouseMove(core::Float2{-40.0f, press.y}); // past the root's edge
    d.InjectMouseUp(core::Float2{-40.0f, press.y}, MouseButton::Left);
    REQUIRE(ends == 2);
    CHECK(last.Outside);
    CHECK(last.Target == nullptr);
}

TEST_CASE("tabs: a tab of a group is picked up from the keyboard and dropped on a strip's tab it is moved to")
{
    auto root = MakeRoot();
    auto top = BarAt(*root, 10.0f, u8"docs");
    auto bottom = BarAt(*root, 150.0f, u8"docs");
    auto alone = BarAt(*root, 250.0f, u8"");
    Tab* a = AddSizedTab(*top, u8"A");
    AddSizedTab(*top, u8"B");
    AddSizedTab(*bottom, u8"X");
    Tab* y = AddSizedTab(*bottom, u8"Y");
    Tab* t = AddSizedTab(*alone, u8"T");
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    t->RequestFocus();
    CHECK_FALSE(d.PickDrag()); // a strip of no group: nowhere for it to go
    a->RequestFocus();
    REQUIRE(d.PickDrag());
    CHECK(d.IsKeyboardDrag());
    CHECK(d.GetDragPayload().Type == core::StringView(u8"gui/tab"));
    y->RequestFocus(); // the focus moves as ever; the strip asked is the focused tab's
    CHECK(d.GetDropTarget() == bottom.Get());
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK_FALSE(d.IsDragging());
    CHECK(top->GetTabCount() == 1);
    REQUIRE(bottom->GetTabCount() == 3);
    CHECK(bottom->IndexOf(a) >= 1);
}

TEST_CASE("tabs: a tab torn out of one tab view and dropped on another of its group brings its page")
{
    auto root = MakeRoot();
    const auto place = [](TabView& v, float y)
    {
        v.EditLayoutStyle([y](LayoutStyle& s)
        {
            s.Placement = Position::Absolute;
            s.Left = LayoutLength::Px(10.0f);
            s.Top = LayoutLength::Px(y);
            s.Width = LayoutLength::Px(380.0f);
            s.Height = LayoutLength::Px(100.0f);
        });
    };
    auto left = Make<TabView>();
    auto right = Make<TabView>();
    place(*left, 10.0f);
    place(*right, 160.0f);
    root->AddChild(left.Get());
    root->AddChild(right.Get());
    TabView* const views[] = {left.Get(), right.Get()};
    for (TabView* v : views)
    {
        v->SetReorderable(true);
        v->SetGroup(core::String(u8"docs"));
    }
    left->AddPage(core::StringView(u8"One"));
    TabPage* two = left->AddPage(core::StringView(u8"Two"));
    auto label = Make<Label>();
    two->AddChild(label.Get());
    right->AddPage(core::StringView(u8"Three"));
    for (TabView* v : views)
        for (core::i32 i = 0; i < v->GetPageCount(); ++i)
            v->GetBar()->GetTab(i)->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(80.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();

    const core::Float2 start = CentreOf(*left->GetBar()->GetTab(1));
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x, start.y + 80.0f});
    REQUIRE(d.IsDragging());
    const Rect three = right->GetBar()->GetTab(0)->GetScreenBounds();
    d.InjectMouseMove(core::Float2{three.x + three.width - 5.0f, three.y + 10.0f}); // after Three
    CHECK(right->GetBar()->GetDropIndex() == 1);
    d.InjectMouseUp(core::Float2{three.x + three.width - 5.0f, three.y + 10.0f}, MouseButton::Left);
    CHECK(left->GetPageCount() == 1);
    REQUIRE(right->GetPageCount() == 2);
    CHECK(right->GetPage(1) == two); // the page itself, what it holds with it
    CHECK(two->ChildCount() == 1);
    CHECK(right->GetSelectedPage() == two);
    CHECK(right->GetBar()->GetTab(1)->GetText() == core::StringView(u8"Two"));
}

TEST_CASE("tabs: a torn-out tab dropped on another view's page area (not its strip) goes last there")
{
    auto root = MakeRoot();
    auto left = Make<TabView>();
    auto right = Make<TabView>();
    const auto place = [](TabView& v, float y)
    {
        v.EditLayoutStyle([y](LayoutStyle& s)
        {
            s.Placement = Position::Absolute;
            s.Left = LayoutLength::Px(10.0f);
            s.Top = LayoutLength::Px(y);
            s.Width = LayoutLength::Px(380.0f);
            s.Height = LayoutLength::Px(120.0f);
        });
    };
    place(*left, 10.0f);
    place(*right, 160.0f);
    root->AddChild(left.Get());
    root->AddChild(right.Get());
    TabView* const views[] = {left.Get(), right.Get()};
    for (TabView* v : views)
    {
        v->SetReorderable(true);
        v->SetGroup(core::String(u8"docs"));
    }
    left->AddPage(core::StringView(u8"One"));
    TabPage* two = left->AddPage(core::StringView(u8"Two"));
    right->AddPage(core::StringView(u8"Three"));
    for (TabView* v : views)
        for (core::i32 i = 0; i < v->GetPageCount(); ++i)
            v->GetBar()->GetTab(i)->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(80.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
    (void)root->UpdateLayout();
    EventDispatcher& d = *root->GetEventDispatcher();
    const core::Float2 start = CentreOf(*left->GetBar()->GetTab(1));
    d.InjectMouseDown(start, MouseButton::Left);
    d.InjectMouseMove(core::Float2{start.x, start.y + 80.0f});
    REQUIRE(d.IsDragging());
    d.InjectMouseMove(core::Float2{200.0f, 240.0f}); // the middle of the right view's page
    CHECK(d.GetDropTarget() == right.Get());
    CHECK(right->GetBar()->GetDropIndex() == 1);
    d.InjectMouseUp(core::Float2{200.0f, 240.0f}, MouseButton::Left);
    REQUIRE(right->GetPageCount() == 2);
    CHECK(right->GetPage(1) == two);
}

TEST_CASE("tabview: a page asked for before it is there waits; the first is not shown, nor built, on the way; a page moved is reported")
{
    auto root = MakeRoot();
    auto view = Make<TabView>();
    root->AddChild(view.Get());
    int built = 0;
    view->SetSelectedIndex(1); // the second, which is not there yet
    auto first = Make<TabPage>();
    first->SetContentFactory([&built](TabPage&) { ++built; });
    view->AddPage(*first);
    CHECK(view->GetSelectedIndex() == -1); // waiting, the first not selected meanwhile
    CHECK(built == 0);
    auto second = Make<TabPage>();
    second->SetContentFactory([&built](TabPage&) { built += 10; });
    view->AddPage(*second);
    CHECK(view->GetSelectedIndex() == 1);
    CHECK(built == 10); // the second alone shown, and built

    core::i32 movedTo = -1;
    view->SetOnPageMoved([&movedTo](core::i32 to) { movedTo = to; });
    view->GetBar()->MoveTab(1, 0);
    CHECK(movedTo == 0);
    CHECK(view->GetPage(0) == second.Get());
}
