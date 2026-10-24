// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - MenuBar tests: a horizontal strip of buttons, each opening a Menu below it.
// Clicking a button toggles its menu; while one is open, hovering another button switches to
// it; an outside click dismisses and clears the bar's state. No font is set, so each button is
// 2*padding (24px) wide and the bar is `barHeight` tall - giving a deterministic layout.
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

    // A menu bar (2 menus) under a scene root, ready to receive input.
    struct BarFixture
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<MenuBar> bar = Make<MenuBar>();
        Menu* fileMenu = nullptr;
        Menu* editMenu = nullptr;

        BarFixture()
        {
            root->SetSize(core::Float2{600.0f, 400.0f});
            bar->SetBarHeight(28.0f);
            bar->SetItemPadding(12.0f); // each button is 24px wide with no font
            root->AddChild(bar.Get());
            fileMenu = bar->AddMenu(core::StringView(u8"File"));
            fileMenu->AddItem(core::StringView(u8"Open"), [] {});
            editMenu = bar->AddMenu(core::StringView(u8"Edit"));
            editMenu->AddItem(core::StringView(u8"Copy"), [] {});
        }
        EventDispatcher* d() { return root->GetEventDispatcher(); }
    };
}

TEST_CASE("menubar: builds a button per menu and lays them out horizontally")
{
    BarFixture fx;
    CHECK(fx.bar->MenuCount() == 2);
    CHECK(fx.bar->ButtonAt(0)->GetPosition().x == doctest::Approx(0.0f));
    CHECK(fx.bar->ButtonAt(0)->GetSize().x == doctest::Approx(24.0f)); // 2 * padding
    CHECK(fx.bar->ButtonAt(1)->GetPosition().x == doctest::Approx(24.0f));
    CHECK(fx.bar->GetSize().y == doctest::Approx(28.0f));
}

TEST_CASE("menubar: clicking a button opens its menu below the button")
{
    BarFixture fx;
    EventDispatcher* d = fx.d();

    // Click "File" (button 0, centered at x=12, y=14).
    d->InjectMouseDown(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{12.0f, 14.0f}, MouseButton::Left);

    CHECK(fx.bar->CurrentMenu() == fx.fileMenu);
    CHECK(fx.fileMenu->IsOpen());
    CHECK(fx.fileMenu->GetParent() == fx.bar->ButtonAt(0)); // a popup of its button
    CHECK(fx.fileMenu->GetPosition().x == doctest::Approx(0.0f));
    CHECK(fx.fileMenu->GetPosition().y == doctest::Approx(28.0f)); // below the bar
}

TEST_CASE("menubar: clicking the open button again toggles the menu closed")
{
    BarFixture fx;
    EventDispatcher* d = fx.d();

    d->InjectMouseDown(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    REQUIRE(fx.bar->CurrentMenu() == fx.fileMenu);

    // A second click on the same button closes it (the button is the popup owner, so the
    // press does not dismiss before the toggle runs).
    d->InjectMouseDown(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    CHECK(fx.bar->CurrentMenu() == nullptr);
    CHECK_FALSE(fx.fileMenu->IsOpen());
}

TEST_CASE("menubar: with a menu open, hovering another button switches to it")
{
    BarFixture fx;
    EventDispatcher* d = fx.d();

    d->InjectMouseDown(core::Float2{12.0f, 14.0f}, MouseButton::Left); // open File
    d->InjectMouseUp(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    REQUIRE(fx.bar->CurrentMenu() == fx.fileMenu);

    // Hover "Edit" (button 1, centered at x=36) - switches without a click.
    d->InjectMouseMove(core::Float2{36.0f, 14.0f});
    CHECK(fx.bar->CurrentMenu() == fx.editMenu);
    CHECK(fx.editMenu->IsOpen());
    CHECK_FALSE(fx.fileMenu->IsOpen());
    CHECK(fx.fileMenu->GetParent() == nullptr);
}

TEST_CASE("menubar: hovering a button with nothing open does not open a menu")
{
    BarFixture fx;
    fx.d()->InjectMouseMove(core::Float2{12.0f, 14.0f}); // bare hover over "File"
    CHECK(fx.bar->CurrentMenu() == nullptr);
    CHECK_FALSE(fx.fileMenu->IsOpen());
}

TEST_CASE("menubar: an outside click dismisses the open menu and clears the bar state")
{
    BarFixture fx;
    EventDispatcher* d = fx.d();

    d->InjectMouseDown(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{12.0f, 14.0f}, MouseButton::Left);
    REQUIRE(fx.fileMenu->IsOpen());

    d->InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left); // far outside
    CHECK(fx.bar->CurrentMenu() == nullptr);
    CHECK_FALSE(fx.fileMenu->IsOpen());
    CHECK(fx.fileMenu->GetParent() == nullptr);
}
