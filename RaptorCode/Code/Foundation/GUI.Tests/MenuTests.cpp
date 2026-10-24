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

// ===================== Depth: separators / checkable / submenus =====================

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
