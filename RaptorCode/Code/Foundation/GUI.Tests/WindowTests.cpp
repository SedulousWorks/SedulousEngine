// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Window tests: title-bar drag moves the window, the grip resizes it (clamped
// to the minimum), title clicks fall through to the draggable bar, and a press raises the
// window to the front; a move or resize reported when the press lets go, and a title bar handed to a
// drag source.
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

TEST_CASE("window: dragging the title bar moves the window")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{50.0f, 50.0f});
    win->SetTitleBarHeight(28.0f);
    root->AddChild(win.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Press on the title bar (world y ~ 60, within [50,78)), then drag by (+40,+30).
    d->InjectMouseDown(core::Float2{120.0f, 60.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{160.0f, 90.0f});
    CHECK(win->GetPosition().x == doctest::Approx(90.0f));
    CHECK(win->GetPosition().y == doctest::Approx(80.0f));

    // Continue dragging; deltas accumulate.
    d->InjectMouseMove(core::Float2{170.0f, 90.0f});
    CHECK(win->GetPosition().x == doctest::Approx(100.0f));
    d->InjectMouseUp(core::Float2{170.0f, 90.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{300.0f, 300.0f}); // no longer dragging
    CHECK(win->GetPosition().x == doctest::Approx(100.0f));
}

TEST_CASE("window: title clicks fall through the caption to the draggable bar")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{0.0f, 0.0f});
    win->SetTitle(core::StringView(u8"Hello"));
    root->AddChild(win.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Press over where the caption sits (top-left of the title bar) and drag; the hit-test-
    // transparent Label must let the bar receive it, so the window still moves.
    d->InjectMouseDown(core::Float2{20.0f, 12.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{45.0f, 12.0f});
    CHECK(win->GetPosition().x == doctest::Approx(25.0f));
}

TEST_CASE("window: dragging the grip resizes, clamped to the minimum")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{0.0f, 0.0f});
    win->SetMinSize(core::Float2{120.0f, 80.0f});
    root->AddChild(win.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Grip is a 14x14 square at the bottom-right: world ~ [186,200) x [136,150).
    d->InjectMouseDown(core::Float2{193.0f, 143.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{243.0f, 193.0f}); // +50, +50
    CHECK(win->GetSize().x == doctest::Approx(250.0f));
    CHECK(win->GetSize().y == doctest::Approx(200.0f));

    // Shrink far past the minimum -> clamps.
    d->InjectMouseMove(core::Float2{0.0f, 0.0f});
    CHECK(win->GetSize().x == doctest::Approx(120.0f));
    CHECK(win->GetSize().y == doctest::Approx(80.0f));
}

TEST_CASE("window: right to left, its title bar is the mirror of left to right, its grip at the bottom left")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{220.0f, 150.0f});
    win->SetTitleBarHeight(28.0f);
    root->AddChild(win.Get());
    root->UpdateLayout();
    DragHandle* bar = win->GetTitleBar();
    REQUIRE(bar->ChildCount() == 2u); // the title, the close button
    const core::f32 width = bar->GetSize().x;
    core::Float2 at[2];
    core::Float2 size[2];
    for (core::usize i = 0; i < 2; ++i)
    {
        at[i] = bar->GetChildAt(i)->GetPosition();
        size[i] = bar->GetChildAt(i)->GetSize();
    }
    CHECK(at[1].x + size[1].x < width - 1.0f); // the close button kept off the edge

    const Node* grip = win->GetChildAt(win->ChildCount() - 1); // over the content
    CHECK(grip->GetCursor() == Cursor::NwseResize);

    win->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    root->UpdateLayout();
    for (core::usize i = 0; i < 2; ++i)
    {
        CHECK(bar->GetChildAt(i)->GetPosition().x == doctest::Approx(width - at[i].x - size[i].x));
        CHECK(bar->GetChildAt(i)->GetSize().x == doctest::Approx(size[i].x));
    }
    // The grip at its bottom left, its cursor the way that corner resizes.
    CHECK(grip->GetPosition().x == doctest::Approx(0.0f));
    CHECK(grip->GetCursor() == Cursor::NeswResize);
}

TEST_CASE("window: content host is placed below the title bar and add-able")
{
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetTitleBarHeight(30.0f);

    Node* host = win->GetContent();
    REQUIRE(host != nullptr);
    CHECK(host->GetSize().x == doctest::Approx(200.0f));
    CHECK(host->GetSize().y == doctest::Approx(120.0f)); // 150 - 30

    auto child = Make<UIWidget>();
    child->SetSize(core::Float2{40.0f, 40.0f});
    host->AddChild(child.Get());
    CHECK(host->ChildCount() == 1);
}

TEST_CASE("window: pressing the title raises the window to the front")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto a = Make<Window>();
    auto b = Make<Window>();
    a->SetSize(core::Float2{200.0f, 150.0f});
    b->SetSize(core::Float2{200.0f, 150.0f});
    a->SetPosition(core::Float2{0.0f, 0.0f});
    b->SetPosition(core::Float2{300.0f, 0.0f}); // separate, so the click hits only a
    root->AddChild(a.Get());
    root->AddChild(b.Get()); // b is on top (last child)
    CHECK(root->GetChildAt(1) == b.Get());

    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{20.0f, 12.0f}, MouseButton::Left); // press a's title
    CHECK(root->GetChildAt(1) == a.Get());                             // a raised to front
    d->InjectMouseUp(core::Float2{20.0f, 12.0f}, MouseButton::Left);
}

TEST_CASE("window: the right button does not drag the window")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{50.0f, 50.0f});
    root->AddChild(win.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{120.0f, 60.0f}, MouseButton::Right); // right press on title
    d->InjectMouseMove(core::Float2{200.0f, 120.0f});
    CHECK(win->GetPosition().x == doctest::Approx(50.0f)); // did not move
    CHECK(win->GetPosition().y == doctest::Approx(50.0f));
}

TEST_CASE("window: the close button closes a window placed in a tree, which opens again")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{50.0f, 50.0f});
    win->SetTitleBarHeight(28.0f);
    int closed = 0;
    win->SetOnClose([&closed]() { ++closed; });
    root->AddChild(win.Get()); // placed, as a page's markup or a host does, never opened
    (void)root->UpdateLayout();

    Node* close = nullptr;
    for (Node* bar = win->GetFirstChild(); bar != nullptr && close == nullptr; bar = bar->GetNextSibling())
        for (core::usize i = 0; i < bar->ChildCount(); ++i)
            if (core::Cast<WindowCloseButton>(bar->GetChildAt(i)) != nullptr)
                close = bar->GetChildAt(i);
    REQUIRE(close != nullptr);
    const auto middle = [close]() { return close->ConvertToWorldSpace(core::Float2{close->GetSize().x * 0.5f, close->GetSize().y * 0.5f}); };
    const core::Float2 at = middle();
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(at, MouseButton::Left);
    d->InjectMouseUp(at, MouseButton::Left);
    CHECK(win->GetParent() == nullptr);
    CHECK(closed == 1);

    win->Open(*root.Get()); // and opens again where it was asked to
    CHECK(win->GetParent() == root.Get());
    CHECK(win->IsOpen());
    (void)root->UpdateLayout();
    d->InjectMouseDown(middle(), MouseButton::Left);
    d->InjectMouseUp(middle(), MouseButton::Left);
    CHECK(win->GetParent() == nullptr);
    CHECK(closed == 2);
}

TEST_CASE("window: one held by its tree alone closes and calls back, not freed before it does (E16)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    int closed = 0;
    {
        auto win = Make<Window>();
        win->SetSize(core::Float2{200.0f, 150.0f});
        win->SetOnClose([&closed]() { ++closed; });
        root->AddChild(win.Get());
        win->Open(*root.Get());
    } // the tree holds it alone now, as a script's window
    REQUIRE(root->ChildCount() == 1u);
    Window* win = core::Cast<Window>(root->GetChildAt(0));
    REQUIRE(win != nullptr);
    win->Close();
    CHECK(closed == 1);
    CHECK(root->ChildCount() == 0u);
}

TEST_CASE("window: a move or resize the user made is reported once the press lets go; a handed-over title bar starts a drag instead")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{600.0f, 400.0f});
    auto win = Make<Window>();
    win->SetSize(core::Float2{200.0f, 150.0f});
    win->SetPosition(core::Float2{50.0f, 50.0f});
    root->AddChild(win.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    int arranged = 0;
    win->SetOnUserArranged([&arranged]() { ++arranged; });

    d->InjectMouseDown(core::Float2{120.0f, 60.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{140.0f, 70.0f});
    d->InjectMouseMove(core::Float2{160.0f, 80.0f});
    CHECK(arranged == 0); // not each move
    d->InjectMouseUp(core::Float2{160.0f, 80.0f}, MouseButton::Left);
    CHECK(arranged == 1);
    d->InjectMouseDown(core::Float2{160.0f, 80.0f}, MouseButton::Left); // a press that moves nothing
    d->InjectMouseUp(core::Float2{160.0f, 80.0f}, MouseButton::Left);
    CHECK(arranged == 1);
    const Rect grip{win->GetPosition().x + 193.0f, win->GetPosition().y + 143.0f, 0.0f, 0.0f};
    d->InjectMouseDown(core::Float2{grip.x, grip.y}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{grip.x + 30.0f, grip.y + 10.0f});
    d->InjectMouseUp(core::Float2{grip.x + 30.0f, grip.y + 10.0f}, MouseButton::Left);
    CHECK(arranged == 2);
    CHECK(win->GetSize().x == doctest::Approx(230.0f));

    // Handed over: the title bar moves nothing itself; its drag source's drag starts past the threshold.
    DragHandle* bar = win->GetTitleBar();
    REQUIRE(bar != nullptr);
    bar->SetDragsItself(false);
    bool started = false;
    bar->SetDragSource([&started](DragRequest& r)
    {
        r.Payload.Type = core::String(u8"test/window");
        started = true;
        return true;
    });
    const core::Float2 at{win->GetPosition().x + 40.0f, win->GetPosition().y + 10.0f};
    const core::Float2 was = win->GetPosition();
    d->InjectMouseDown(at, MouseButton::Left);
    d->InjectMouseMove(core::Float2{at.x + 20.0f, at.y});
    CHECK(started);
    CHECK(d->IsDragging());
    CHECK(win->GetPosition().x == doctest::Approx(was.x));
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    d->InjectMouseUp(core::Float2{at.x + 20.0f, at.y}, MouseButton::Left);
    CHECK(arranged == 2);
}
