// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Menu tests: opening at a position as a popup, activating an item (runs the
// action + closes), and dismissal (outside click / Escape) via the dispatcher popup support.
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
}

TEST_CASE("menu: sizes to its items")
{
    auto menu = Make<Menu>();
    menu->SetWidth(140.0f);
    menu->SetItemHeight(25.0f);
    menu->AddItem(core::StringView(u8"Cut"), [] {});
    menu->AddItem(core::StringView(u8"Copy"), [] {});
    menu->AddItem(core::StringView(u8"Paste"), [] {});

    CHECK(menu->ItemCount() == 3);
    CHECK(menu->GetSize().x == doctest::Approx(140.0f));
    CHECK(menu->GetSize().y == doctest::Approx(75.0f)); // 3 * 25
}

TEST_CASE("menu: Open shows it as the dispatcher popup at the given position")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    anchor->SetSize(core::Float2{10.0f, 10.0f});
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"One"), [] {});
    menu->AddItem(core::StringView(u8"Two"), [] {});

    menu->Open(*anchor, core::Float2{100.0f, 80.0f});
    CHECK(menu->IsOpen());
    CHECK(d->TopPopup() == menu.Get());
    CHECK(menu->GetPosition().x == doctest::Approx(100.0f));
    CHECK(menu->GetPosition().y == doctest::Approx(80.0f));
    CHECK(menu->GetParent() == anchor.Get()); // a popup of what opened it
}

TEST_CASE("menu: activating an item runs its action and closes")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int cut = 0, paste = 0;
    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"Cut"), [&] { ++cut; });
    menu->AddItem(core::StringView(u8"Paste"), [&] { ++paste; });
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    // Item 1 (Paste) spans y in [50 + 26, 50 + 52) = [76, 102); click it.
    d->InjectMouseDown(core::Float2{60.0f, 88.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{60.0f, 88.0f}, MouseButton::Left);
    CHECK(paste == 1);
    CHECK(cut == 0);
    CHECK_FALSE(menu->IsOpen());
    CHECK(d->PopupCount() == 0u);
    CHECK(menu->GetParent() == nullptr); // removed from the tree
}

TEST_CASE("menu: an item whose action lets go of its menu (and what held it) outlives the action")
{
    // The menu's only owner is let go by its item's own action, as a dock float's Move to menu is
    // when the move ends the float.
    core::RefPtr<Menu> menu = Make<Menu>();
    int ran = 0;
    MenuItem* item = menu->AddItem(core::StringView(u8"End"), [&] { ++ran; menu = nullptr; });
    CHECK(item->HandleActivate());
    CHECK(ran == 1);
    CHECK(menu.Get() == nullptr);
}

TEST_CASE("menu: outside click and Escape dismiss it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->AddItem(core::StringView(u8"One"), [] {});
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});
    REQUIRE(menu->IsOpen());

    d->InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left); // outside
    CHECK_FALSE(menu->IsOpen());

    // Reopen and dismiss with Escape.
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});
    REQUIRE(menu->IsOpen());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(menu->IsOpen());
}

TEST_CASE("menu: an outside click dismisses even when the opener covers the click point")
{
    // Regression: the context menu was opened with the full-window panel as its popup owner,
    // so clicks anywhere on the panel counted as "on the owner" and never dismissed. A menu
    // has no persistent owner - any press outside the menu itself must close it.
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto panel = Make<UIWidget>();
    panel->SetSize(core::Float2{400.0f, 400.0f}); // covers the whole area (like the sandbox panel)
    root->AddChild(panel.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"One"), [] {});
    menu->Open(*panel, core::Float2{50.0f, 50.0f});
    REQUIRE(menu->IsOpen());

    // Left-click on the panel, well away from the menu -> dismissed.
    d->InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left);
    CHECK_FALSE(menu->IsOpen());
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("menu: can be reopened after being dismissed")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto panel = Make<UIWidget>();
    panel->SetSize(core::Float2{400.0f, 400.0f});
    root->AddChild(panel.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->AddItem(core::StringView(u8"One"), [] {});

    menu->Open(*panel, core::Float2{40.0f, 40.0f});
    REQUIRE(menu->IsOpen());
    d->InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left); // dismiss
    REQUIRE_FALSE(menu->IsOpen());

    // Reopen at a new position - must work and re-register as the popup.
    menu->Open(*panel, core::Float2{120.0f, 90.0f});
    CHECK(menu->IsOpen());
    CHECK(d->TopPopup() == menu.Get());
    CHECK(menu->GetParent() == panel.Get()); // a popup of what opened it
    CHECK(menu->GetPosition().x == doctest::Approx(120.0f));
}

// ===================== Depth: separators / checkable / submenus =====================

TEST_CASE("menu: separators are non-selectable rows that add height")
{
    auto menu = Make<Menu>();
    menu->SetWidth(140.0f);
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"Open"), [] {});
    menu->AddSeparator();
    menu->AddItem(core::StringView(u8"Quit"), [] {});

    CHECK(menu->RowCount() == 3);
    CHECK(menu->ItemCount() == 2); // the separator is not counted as an item
    CHECK(menu->GetSize().y == doctest::Approx(26.0f + 9.0f + 26.0f)); // item + separator + item
}

TEST_CASE("menu: a checkable item toggles, fires its callback, and closes the menu")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    bool state = false;
    int toggles = 0;
    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    MenuItem* check = menu->AddCheckItem(core::StringView(u8"Bold"), false,
                                         [&](bool on)
                                         {
                                             state = on;
                                             ++toggles;
                                         });
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    CHECK_FALSE(check->IsChecked());
    // Row 0 spans y in [50, 76); click it.
    d->InjectMouseDown(core::Float2{60.0f, 60.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{60.0f, 60.0f}, MouseButton::Left);
    CHECK(check->IsChecked());
    CHECK(state == true);
    CHECK(toggles == 1);
    CHECK_FALSE(menu->IsOpen()); // menus close on activation
}

TEST_CASE("menu: a submenu opens to the right of its item on hover")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 600.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->SetWidth(160.0f);
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"Top"), [] {});
    Menu* sub = menu->AddSubMenu(core::StringView(u8"More"));
    sub->AddItem(core::StringView(u8"Deep"), [] {});
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    CHECK(menu->CurrentSubMenu() == nullptr);
    // Hover the "More" row (row 1: y in [76, 102)).
    d->InjectMouseMove(core::Float2{60.0f, 88.0f});
    CHECK(menu->CurrentSubMenu() == sub);
    CHECK(sub->IsOpen());
    CHECK(sub->GetParent()->GetParent() == menu.Get());     // a popup of its item, in the menu
    CHECK(sub->GetPosition().x == doctest::Approx(210.0f)); // menu.x(50) + menu.width(160)
    CHECK(sub->GetPosition().y == doctest::Approx(76.0f));  // menu.y(50) + item.y(26)
}

TEST_CASE("menu: hovering a different row closes the open submenu")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 600.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->SetWidth(160.0f);
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"Top"), [] {});          // row 0
    Menu* sub = menu->AddSubMenu(core::StringView(u8"More")); // row 1
    sub->AddItem(core::StringView(u8"Deep"), [] {});
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    d->InjectMouseMove(core::Float2{60.0f, 88.0f}); // open submenu (hover "More")
    REQUIRE(menu->CurrentSubMenu() == sub);
    d->InjectMouseMove(core::Float2{60.0f, 60.0f}); // hover "Top" (row 0)
    CHECK(menu->CurrentSubMenu() == nullptr);
    CHECK(sub->GetParent() == nullptr); // submenu removed from the tree
}

TEST_CASE(
    "menu: clicking inside an open submenu does not dismiss; activating closes the whole chain")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 600.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int deep = 0;
    auto menu = Make<Menu>();
    menu->SetWidth(160.0f);
    menu->SetItemHeight(26.0f);
    menu->AddItem(core::StringView(u8"Top"), [] {});
    Menu* sub = menu->AddSubMenu(core::StringView(u8"More"));
    sub->AddItem(core::StringView(u8"Deep"), [&] { ++deep; });
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    d->InjectMouseMove(core::Float2{60.0f, 88.0f}); // open submenu
    REQUIRE(sub->IsOpen());

    // The submenu sits at x in [210, 370], its "Deep" row at y in [76, 102). A press there is
    // inside the chain -> the root menu must stay open (the popup 'contains' predicate).
    d->InjectMouseDown(core::Float2{260.0f, 88.0f}, MouseButton::Left);
    CHECK(menu->IsOpen());
    d->InjectMouseUp(core::Float2{260.0f, 88.0f}, MouseButton::Left);
    CHECK(deep == 1);
    CHECK_FALSE(menu->IsOpen()); // the whole chain closed
    CHECK(menu->GetParent() == nullptr);
    CHECK(sub->GetParent() == nullptr);
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("menu: an outside click dismisses the whole open submenu chain")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 600.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    auto menu = Make<Menu>();
    menu->SetWidth(160.0f);
    menu->SetItemHeight(26.0f);
    Menu* sub = menu->AddSubMenu(core::StringView(u8"More"));
    sub->AddItem(core::StringView(u8"Deep"), [] {});
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});

    d->InjectMouseMove(core::Float2{60.0f, 60.0f}); // "More" is row 0 (y in [50,76)) -> open sub
    REQUIRE(sub->IsOpen());

    d->InjectMouseDown(core::Float2{500.0f, 500.0f}, MouseButton::Left); // outside everything
    CHECK_FALSE(menu->IsOpen());
    CHECK(menu->GetParent() == nullptr);
    CHECK(sub->GetParent() == nullptr);
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("menu: a submenu stays open while the pointer heads for it across another row, then gives way")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    Menu* sub = menu->AddSubMenu(core::StringView(u8"More"));
    sub->AddItem(core::StringView(u8"A"), [] {});
    sub->AddItem(core::StringView(u8"B"), [] {});
    sub->AddItem(core::StringView(u8"C"), [] {});
    MenuItem* next = menu->AddItem(core::StringView(u8"Next"), [] {});
    menu->AddItem(core::StringView(u8"Last"), [] {});
    menu->Open(*anchor, core::Float2{50.0f, 50.0f}); // rows at y 50, 76, 102; 160 wide
    d->InjectMouseMove(core::Float2{100.0f, 60.0f}); // on "More": its submenu opens at x 210, y 50
    REQUIRE(sub->IsOpen());
    auto* more = core::Cast<MenuItem>(sub->GetParent());
    REQUIRE(more != nullptr);
    d->InjectMouseMove(core::Float2{150.0f, 70.0f});
    // Down and right toward the submenu, over "Next": the submenu stays, and only "More" is lit.
    d->InjectMouseMove(core::Float2{190.0f, 80.0f});
    CHECK(sub->IsOpen());
    CHECK(more->IsLit());
    CHECK_FALSE(next->IsLit());
    // Resting on "Next" a moment: it takes over.
    for (int i = 0; i < 5; ++i)
        root->GetContext().Update(core::Duration::FromSeconds(0.1));
    CHECK_FALSE(sub->IsOpen());
    CHECK(next->IsLit());
    CHECK_FALSE(more->IsLit());

    // Straight down, away from it: the submenu closes at once.
    d->InjectMouseMove(core::Float2{100.0f, 60.0f});
    REQUIRE(sub->IsOpen());
    d->InjectMouseMove(core::Float2{100.0f, 110.0f}); // onto "Last", heading away
    CHECK_FALSE(sub->IsOpen());
}

TEST_CASE("menu: one row is lit at a time: the pointer and the keys move the same highlight")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto anchor = Make<UIWidget>();
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    auto menu = Make<Menu>();
    menu->SetItemHeight(26.0f);
    MenuItem* a = menu->AddItem(core::StringView(u8"A"), [] {});
    MenuItem* b = menu->AddItem(core::StringView(u8"B"), [] {});
    MenuItem* c = menu->AddItem(core::StringView(u8"C"), [] {});
    menu->AddSeparator();
    MenuItem* off = menu->AddItem(core::StringView(u8"Off"), [] {});
    off->SetEnabled(false);
    menu->Open(*anchor, core::Float2{50.0f, 50.0f});
    root->GetContext().Update(core::Duration{}); // a frame: the popup placed
    const auto centre = [](const Node& n)
    {
        const Rect r = n.GetScreenBounds();
        return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
    };
    const auto lit = [&]()
    {
        const MenuItem* items[] = {a, b, c, off};
        int n = 0;
        for (const MenuItem* item : items)
            n += item->IsLit() ? 1 : 0;
        return n;
    };

    d->InjectMouseMove(centre(*b));
    CHECK(b->IsLit());
    CHECK(lit() == 1);
    // A key moves on from the pointer's row, the pointer resting where it was: one lit, the keys'.
    (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    CHECK(c->IsLit());
    CHECK(b->IsHovered());
    CHECK(lit() == 1);
    // Onto the separator, then the disabled item: neither can be lit, and nothing else stays lit.
    const Rect cb = c->GetScreenBounds();
    const Rect ob = off->GetScreenBounds();
    REQUIRE(ob.y > cb.y + cb.height + 1.0f);
    d->InjectMouseMove(core::Float2{cb.x + cb.width * 0.5f, (cb.y + cb.height + ob.y) * 0.5f});
    CHECK(lit() == 0);
    (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // from none, round to the first
    CHECK(a->IsLit());
    d->InjectMouseMove(centre(*off));
    CHECK(lit() == 0);
    d->InjectMouseMove(centre(*a));
    CHECK(a->IsLit());
    CHECK(lit() == 1);
}

TEST_CASE("menu: in markup, items, separators and nested menus; an item reports activate")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto page = loader.LoadFromString(core::StringView(u8R"(<Panel width="600" height="400">
        <Label id="target" text="Right-click me" width="200" height="40" context-menu="ctx"/>
        <Menu id="ctx">
            <MenuItem id="cut" text="Cut" shortcut="Ctrl+X"/>
            <MenuItem id="grid" text="Show grid" checkable="true" checked="true"/>
            <MenuSeparator/>
            <Menu text="More">
                <MenuItem id="rename" text="Rename"/>
            </Menu>
        </Menu>
    </Panel>)"));
    REQUIRE(page.Get() != nullptr);
    root->AddChild(page.Get());
    (void)root->UpdateLayout();

    Menu* menu = core::Cast<Menu>(page->GetChildAt(1));
    REQUIRE(menu != nullptr);
    CHECK_FALSE(menu->IsDisplayed()); // waits in the page, unseen
    CHECK(menu->RowCount() == 4);     // cut, grid, the separator, More
    CHECK(menu->ItemCount() == 3);
    auto* cut = core::Cast<MenuItem>(menu->GetChildAt(0));
    REQUIRE(cut != nullptr);
    CHECK(cut->GetText() == core::StringView(u8"Cut"));
    CHECK(cut->GetShortcut() == core::StringView(u8"Ctrl+X"));
    auto* grid = core::Cast<MenuItem>(menu->GetChildAt(1));
    REQUIRE(grid != nullptr);
    CHECK(grid->IsCheckable());
    CHECK(grid->IsChecked());

    // A context menu asked for over the label opens it at the pointer.
    int activations = 0;
    (void)cut->AddEventListener(EventType::ItemActivate, [&](const Event&) { ++activations; });
    // It bubbles through the menu to what opened it, and on up: one listener hears every item.
    Node* heardFrom = nullptr;
    (void)page->AddEventListener(EventType::ItemActivate, [&](const Event& e) { heardFrom = e.Target; });
    EventDispatcher& d = *root->GetEventDispatcher();
    d.InjectMouseDown(core::Float2{50.0f, 20.0f}, MouseButton::Right);
    d.InjectMouseUp(core::Float2{50.0f, 20.0f}, MouseButton::Right);
    REQUIRE(menu->IsOpen());
    CHECK(menu->IsDisplayed());
    (void)root->UpdateLayout();
    const Rect at = cut->GetScreenBounds();
    d.InjectMouseMove(core::Float2{at.x + 10.0f, at.y + at.height * 0.5f});
    d.InjectMouseDown(core::Float2{at.x + 10.0f, at.y + at.height * 0.5f}, MouseButton::Left);
    d.InjectMouseUp(core::Float2{at.x + 10.0f, at.y + at.height * 0.5f}, MouseButton::Left);
    CHECK(activations == 1);
    CHECK(heardFrom == cut);
    CHECK_FALSE(menu->IsOpen());
    // Closed, it left the page; the label keeps it, and it opens again.
    d.InjectMouseDown(core::Float2{50.0f, 20.0f}, MouseButton::Right);
    d.InjectMouseUp(core::Float2{50.0f, 20.0f}, MouseButton::Right);
    CHECK(menu->IsOpen());
}

TEST_CASE("menubar: in markup, its children are its menus, each a button")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<MenuBar>
        <Menu text="File"><MenuItem text="Open"/><MenuItem text="Save"/></Menu>
        <Menu text="Edit"><MenuItem text="Undo"/></Menu>
    </MenuBar>)"));
    auto* bar = core::Cast<MenuBar>(tree.Get());
    REQUIRE(bar != nullptr);
    CHECK(bar->MenuCount() == 2);
    CHECK(bar->ButtonAt(0)->GetText() == core::StringView(u8"File"));
    CHECK(bar->ButtonAt(1)->GetText() == core::StringView(u8"Edit"));
    CHECK(bar->MenuAt(0)->ItemCount() == 2);
}

TEST_CASE("menu: a markup context menu opens again after an item is picked and after a press outside")
{
    RegisterGuiElements();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    MarkupLoader loader(*root->GetElementSet(), core::DefaultAllocator());
    auto page = loader.LoadFromString(core::StringView(u8R"(<Panel width="600" height="400">
        <Panel width="400" height="90" context-menu="ctx" display="stack"><Label text="Right-click" width="400" height="90"/></Panel>
        <Menu id="ctx"><MenuItem text="Copy"/><MenuItem text="Paste"/></Menu>
    </Panel>)"));
    root->AddChild(page.Get());
    (void)root->UpdateLayout();
    Menu* menu = core::Cast<Menu>(page->GetChildAt(1));
    REQUIRE(menu != nullptr);
    // As the sandbox's script does: a listener up the page takes the bubbling activate.
    (void)page->AddEventListener(EventType::ItemActivate, [](const Event& e) { e.Handled = true; });
    EventDispatcher& d = *root->GetEventDispatcher();
    const auto rclick = [&](core::Float2 at)
    {
        d.InjectMouseMove(at);
        d.InjectMouseDown(at, MouseButton::Right);
        d.InjectMouseUp(at, MouseButton::Right);
        root->GetContext().Update(core::Duration::FromSeconds(0.016));
    };
    const auto click = [&](core::Float2 at)
    {
        d.InjectMouseMove(at);
        d.InjectMouseDown(at, MouseButton::Left);
        d.InjectMouseUp(at, MouseButton::Left);
        root->GetContext().Update(core::Duration::FromSeconds(0.016));
    };
    rclick(core::Float2{100.0f, 40.0f});
    REQUIRE(menu->IsOpen());
    const Rect copy = menu->GetChildAt(0)->GetScreenBounds();
    click(core::Float2{copy.x + 10.0f, copy.y + copy.height * 0.5f});
    CHECK_FALSE(menu->IsOpen());
    // The style pass writes the attribute again at every restyle (as the sandbox's does).
    core::Cast<UIWidget>(page->GetChildAt(0))->SetContextMenuId(core::String(u8"ctx"));
    rclick(core::Float2{200.0f, 40.0f});
    CHECK(menu->IsOpen());
    (void)root->UpdateLayout();
    CHECK(menu->IsDisplayed());
    CHECK(menu->IsVisible());
    CHECK(menu->GetSize().x > 20.0f);
    CHECK(menu->GetSize().y > 20.0f);
    CHECK(menu->GetScreenBounds().Contains(core::Float2{210.0f, 50.0f}));
    click(core::Float2{500.0f, 300.0f}); // a press outside closes it
    CHECK_FALSE(menu->IsOpen());
    rclick(core::Float2{150.0f, 50.0f});
    CHECK(menu->IsOpen());
}

TEST_CASE("menu: a submenu added before its title is set (a script's add, then title) names its row")
{
    auto menu = core::MakeRef<Menu>(core::DefaultAllocator());
    auto sub = core::MakeRef<Menu>(core::DefaultAllocator());
    menu->GetChildHost()->AddChild(sub.Get()); // taken in at once, with no title yet
    sub->SetTitle(core::StringView(u8"Recent"));
    REQUIRE(menu->RowCount() == 1u);
    const auto named = [](auto& self, Node& node) -> bool
    {
        if (const MenuItem* item = core::Cast<MenuItem>(&node); item != nullptr && item->GetText() == core::StringView(u8"Recent"))
            return true;
        for (core::usize i = 0; i < node.ChildCount(); ++i)
            if (Node* child = node.GetChildAt(i); child != nullptr && self(self, *child))
                return true;
        return false;
    };
    CHECK(named(named, *menu.Get()));
}

TEST_CASE("menu: taller than the window, it keeps to it and scrolls by wheel, arrow and key (E16)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto anchor = Make<UIWidget>();
    anchor->SetSize(core::Float2{10.0f, 10.0f});
    root->AddChild(anchor.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    auto menu = Make<Menu>();
    menu->SetItemHeight(25.0f);
    for (int i = 0; i < 40; ++i)
        menu->AddItem(core::StringView(u8"Item"), [] {});
    menu->Open(*anchor, core::Float2{20.0f, 20.0f});
    root->GetContext().Update(core::Duration{}); // a frame: the popup placed
    REQUIRE(d->IsPopupOpen(*menu));
    CHECK(menu->Scrolls());
    CHECK(menu->GetSize().y <= 300.0f);
    const core::Float2 at = menu->ConvertToWorldSpace(core::Float2{0.0f, 0.0f});
    CHECK(at.y >= 0.0f);
    CHECK(at.y + menu->GetSize().y <= 300.0f + 0.5f); // kept to the window
    CHECK(menu->GetItemScroll() == doctest::Approx(0.0f));

    // The wheel, over its items.
    const core::Float2 middle = menu->ConvertToWorldSpace(core::Float2{50.0f, menu->GetSize().y * 0.5f});
    (void)d->InjectMouseWheel(middle, core::Float2{0.0f, -2.0f});
    CHECK(menu->GetItemScroll() > 0.0f);
    const float wheeled = menu->GetItemScroll();

    // The pointer resting on the down arrow, half a second.
    const core::Float2 bottom = menu->ConvertToWorldSpace(core::Float2{50.0f, menu->GetSize().y - 4.0f});
    d->InjectMouseMove(bottom);
    root->GetContext().Update(core::Duration::FromSeconds(0.25));
    root->GetContext().Update(core::Duration::FromSeconds(0.25));
    CHECK(menu->GetItemScroll() > wheeled + 100.0f);
    d->InjectMouseMove(core::Float2{390.0f, 290.0f}); // off it: it stops
    const float rested = menu->GetItemScroll();
    root->GetContext().Update(core::Duration::FromSeconds(0.5));
    CHECK(menu->GetItemScroll() == doctest::Approx(rested));

    // The keys: up from no item goes round to the last, which scrolls into view at the end.
    menu->RequestFocus();
    (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Up));
    const float end = 40.0f * 25.0f - (menu->GetSize().y - 32.0f);
    CHECK(menu->GetItemScroll() == doctest::Approx(end));
    (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // round to the first
    CHECK(menu->GetItemScroll() == doctest::Approx(0.0f));
}

TEST_CASE("menu: opening one in a scrolled page leaves the page where it was (E16)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    EventDispatcher* d = root->GetEventDispatcher();
    // A page that scrolls, a button half way down it, the button's menu inside it (a script's).
    auto page = Make<UIWidget>();
    page->SetSize(core::Float2{400.0f, 200.0f}); // shorter than the window, as a page under a header is
    page->EditLayoutStyle([](LayoutStyle& s) { s.OverflowY = Overflow::Auto; s.Direction = FlexDirection::Column; });
    root->AddChild(page.Get());
    auto spacer = Make<UIWidget>();
    spacer->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(1000.0f); s.Shrink = 0.0f; });
    page->AddChild(spacer.Get());
    auto button = Make<UIWidget>();
    button->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(30.0f); s.Shrink = 0.0f; });
    page->AddChild(button.Get());
    auto tail = Make<UIWidget>();
    tail->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(1000.0f); s.Shrink = 0.0f; });
    page->AddChild(tail.Get());
    auto menu = Make<Menu>();
    button->AddChild(menu.Get());
    for (int i = 0; i < 60; ++i)
        menu->AddItem(core::StringView(u8"Item"), [] {});
    (void)root->UpdateLayout();
    page->SetScrollOffset(core::Float2{0.0f, 900.0f}); // the button in view
    (void)root->UpdateLayout();
    const float scrolled = page->GetScrollOffset().y;
    for (int round = 0; round < 3; ++round)
    {
        CAPTURE(round);
        REQUIRE(menu->OpenAtPoint(10.0f, 140.0f));
        menu->FocusFirstItem(); // focus goes into it, as from the keys
        root->GetContext().Update(core::Duration{});
        CHECK(page->GetScrollOffset().y == doctest::Approx(scrolled)); // a popup is not the page's to scroll to
        (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
        root->GetContext().Update(core::Duration{});
    }
}

TEST_CASE("menu bar: at a scale its width does not land on the device grid, it settles (no layout every frame)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetDisplayScale(1.3f); // its buttons' widths snap to the grid at a fraction of a unit
    root->SetViewportSize(core::Float2{520.0f, 390.0f});
    auto host = Make<UIWidget>();
    host->EditLayoutStyle([](LayoutStyle& s) { s.Kind = Display::Stack; });
    host->SetSize(core::Float2{300.0f, 40.0f});
    root->AddChild(host.Get());
    auto bar = Make<MenuBar>();
    bar->SetSize(core::Float2{290.0f, 28.0f});
    (void)bar->AddMenu(core::StringView(u8"File"));
    (void)bar->AddMenu(core::StringView(u8"Edit"));
    host->AddChild(bar.Get());
    for (int i = 0; i < 4; ++i)
        (void)root->UpdateLayout();
    // Laid out again on its own (its text changed, a font came): it settles, rather than sizing
    // itself back to the fraction and asking for another pass, each pass.
    bar->RequestLayout();
    for (int i = 0; i < 4; ++i)
        (void)root->UpdateLayout();
    CHECK_FALSE(root->IsLayoutDirty());
    CHECK_FALSE(root->HasLayoutDirtyDescendant());
    CHECK_FALSE(bar->IsLayoutDirty());
}
