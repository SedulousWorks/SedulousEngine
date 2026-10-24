// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - EventDispatcher tests: hover enter/leave, click, focus (click + program-
// matic), key/text routing to the focus node, and interaction-ref cleanup. Input is
// injected as abstract events (the shell bridge's job), hit-tested via the tree's OverFind.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<SceneRoot> MakeScene(core::Float2 size)
    {
        auto s = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        s->SetSize(size);
        return s;
    }
    core::RefPtr<Node> MakePanel(core::Float2 pos, core::Float2 size)
    {
        auto n = core::MakeRef<Node>(core::DefaultAllocator());
        n->SetSize(size);
        n->SetPosition(pos);
        return n;
    }
}

TEST_CASE("dispatch: a disabled widget, or one inside a disabled panel, takes no pointer input")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto backdrop = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 200.0f});
    auto panel = MakePanel(core::Float2{100.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    auto button = core::MakeRef<Button>(core::DefaultAllocator());
    auto inner = core::MakeRef<Button>(core::DefaultAllocator());
    button->SetSize(core::Float2{50.0f, 20.0f});
    inner->SetSize(core::Float2{50.0f, 20.0f});
    root->AddChild(backdrop.Get());
    root->AddChild(button.Get());
    root->AddChild(panel.Get());
    panel->AddChild(inner.Get());
    int clicks = 0, innerClicks = 0, behind = 0, enters = 0;
    button->SetOnClick([&] { ++clicks; });
    inner->SetOnClick([&] { ++innerClicks; });
    (void)backdrop->AddEventListener(EventType::MouseDown, [&](const Event&) { ++behind; });
    (void)button->AddEventListener(EventType::MouseEnter, [&](const Event&) { ++enters; });
    EventDispatcher* d = root->GetEventDispatcher();
    auto click = [d](core::Float2 at)
    {
        d->InjectMouseMove(at);
        d->InjectMouseDown(at, MouseButton::Left);
        d->InjectMouseUp(at, MouseButton::Left);
    };

    button->SetEnabled(false);
    click(core::Float2{10.0f, 10.0f});
    CHECK(clicks == 0);
    CHECK(behind == 0);        // it still covers what lies behind it
    CHECK(enters == 1);        // and is still hovered (a tooltip says why it is disabled)
    CHECK(d->GetFocusNode() == nullptr);
    button->SetEnabled(true);
    click(core::Float2{10.0f, 10.0f});
    CHECK(clicks == 1);

    panel->SetEnabled(false);
    CHECK_FALSE(inner->IsTreeEnabled());
    click(core::Float2{110.0f, 10.0f});
    CHECK(innerClicks == 0);
    d->SetFocusNode(inner.Get());
    CHECK_FALSE(d->Activate()); // nor by the keyboard
    CHECK(innerClicks == 0);
}

