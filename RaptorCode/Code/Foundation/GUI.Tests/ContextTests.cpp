// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - GUIContext: one GUI of several roots (windows, render targets). Its roots share the clock
// (each may pause or slow its own time), the deferred edits, one bindings flush a frame, the data,
// the commands and keymap, and the element table; the active root (the one last given input) takes
// keystrokes and decides command availability; every root is made in one.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T, typename... A>
    core::RefPtr<T> Make(A&&... args)
    {
        return core::MakeRef<T>(core::DefaultAllocator(), static_cast<A&&>(args)...);
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Frame() { return core::Duration::FromSeconds(0.016); }

    struct TwoRoots
    {
        core::RefPtr<GUIContext> gui = Make<GUIContext>();
        core::RefPtr<SceneRoot> hud = Make<SceneRoot>(gui);
        core::RefPtr<SceneRoot> menu = Make<SceneRoot>(gui);
        TwoRoots()
        {
            hud->SetSize(core::Float2{200.0f, 200.0f});
            menu->SetSize(core::Float2{200.0f, 200.0f});
        }
    };
}

TEST_CASE("context: a GUI of one root is a context with one")
{
    auto gui = Make<GUIContext>();
    CHECK(gui->RootCount() == 0u);
    CHECK(gui->GetActiveRoot() == nullptr);
    auto root = Make<SceneRoot>(gui);
    CHECK(gui->RootCount() == 1u);
    CHECK(gui->GetActiveRoot() == root.Get()); // the first, until input picks another
    CHECK(&root->GetContext() == gui.Get());
}

TEST_CASE("context: two roots share data, one flush a frame runs a binding in either")
{
    TwoRoots t;
    CHECK(t.gui->RootCount() == 2u);
    CHECK(&t.hud->GetContext() == &t.menu->GetContext());
    auto score = Make<Label>();
    t.hud->AddChild(score.Get());
    REQUIRE(score->BindProperty(SV(u8"text"), [&t] { return t.gui->GetData().Get(SV(u8"score")); }));
    t.menu->GetContext().GetData().Set(SV(u8"score"), core::Variant::From<core::i32>(7)); // written from the other root
    t.gui->Update(Frame());
    CHECK(score->GetText() == SV(u8"7"));
    CHECK(t.gui->LastBindingCount() == 1u);
}

TEST_CASE("context: one update advances every root, and drains their deferred edits")
{
    struct Counting : SceneRoot
    {
        explicit Counting(core::RefPtr<GUIContext> gui) : SceneRoot(core::Move(gui)) {}
        int ticks = 0;
        void OnUpdate(core::Duration) override { ++ticks; }
    };
    auto gui = Make<GUIContext>();
    auto a = Make<Counting>(gui);
    auto b = Make<Counting>(gui);
    auto doomed = Make<Node>();
    b->AddChild(doomed.Get());
    doomed->Close();
    gui->Update(Frame()); // the GUI's one update
    CHECK(a->ticks == 1);
    CHECK(b->ticks == 1);
    CHECK(b->ChildCount() == 0u);
}

TEST_CASE("context: a handle survives its node moving between roots")
{
    TwoRoots t;
    auto panel = Make<UIWidget>();
    t.hud->AddChild(panel.Get());
    const Node::ElementRef before = panel->TakeElementRef();
    t.hud->RemoveChild(panel.Get());
    t.menu->AddChild(panel.Get()); // docked into the other window
    const Node::ElementRef after = panel->TakeElementRef();
    CHECK(before.table == after.table);
    CHECK(before.slot == after.slot);
    CHECK(after.table->Resolve(after.slot, after.generation) == panel.Get());
}

TEST_CASE("context: a root's animations pause or slow on the shared clock")
{
    TwoRoots t;
    auto a = Make<Node>();
    auto b = Make<Node>();
    t.hud->AddChild(a.Get());
    t.menu->AddChild(b.Get());
    a->Animate(core::StringView(u8"x"), core::StringView(u8"100"), 1.0f, core::StringView(u8"linear"));
    b->Animate(core::StringView(u8"x"), core::StringView(u8"100"), 1.0f, core::StringView(u8"linear"));
    t.menu->SetPaused(true); // the game paused under its menu: the menu's own root keeps going
    t.gui->Update(core::Duration::FromSeconds(0.5));
    CHECK(a->GetPosition().x == doctest::Approx(50.0f));
    CHECK(b->GetPosition().x == doctest::Approx(0.0f));
    t.menu->SetPaused(false);
    t.menu->SetTimeScale(0.5f);
    t.gui->Update(core::Duration::FromSeconds(0.5));
    CHECK(b->GetPosition().x == doctest::Approx(25.0f)); // half speed
}

TEST_CASE("context: the active root follows input, and takes commands and keystrokes")
{
    TwoRoots t;
    auto inHud = Make<Button>();
    auto inMenu = Make<Button>();
    inHud->SetSize(core::Float2{40.0f, 20.0f});
    inMenu->SetSize(core::Float2{40.0f, 20.0f});
    t.hud->AddChild(inHud.Get());
    t.menu->AddChild(inMenu.Get());
    t.hud->GetEventDispatcher()->SetFocusNode(inHud.Get());
    t.menu->GetEventDispatcher()->SetFocusNode(inMenu.Get());
    int menuBacks = 0, hudBacks = 0;
    (void)inMenu->OnCommand(SV(u8"back"), [&](CommandEvent&) { ++menuBacks; });
    (void)inHud->OnCommand(SV(u8"back"), [&](CommandEvent&) { ++hudBacks; });
    REQUIRE(t.gui->GetKeymap().Bind(SV(u8"escape"), SV(u8"back")));

    // A toolbar button in the HUD bound to "back" follows the active root's focus path.
    auto toolbar = Make<Button>();
    t.hud->AddChild(toolbar.Get());
    toolbar->SetCommand(SV(u8"back"));
    t.menu->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape)); // input in the menu
    CHECK(t.gui->GetActiveRoot() == t.menu.Get());
    CHECK(menuBacks == 1);
    CHECK(hudBacks == 0);
    CHECK(t.gui->RunCommand(SV(u8"back")));
    CHECK(menuBacks == 2);

    t.hud->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(t.gui->GetActiveRoot() == t.hud.Get());
    CHECK(hudBacks == 1);

    // A root going away leaves the context; the active root falls back to the first.
    t.hud.Reset();
    CHECK(t.gui->RootCount() == 1u);
    CHECK(t.gui->GetActiveRoot() == t.menu.Get());
}
