// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - UINode / UIWidget tests: padding + content bounds, input-driven control
// state (hover/press/focus/disabled), and the CSS identity surface (tag/id/classes).
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

TEST_CASE("uinode: its states follow the pointer, the focus, and being enabled")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto w = Make<UINode>();
    w->SetSize(core::Float2{100.0f, 100.0f});
    w->SetTabFocusable(true); // a click focuses what takes focus
    root->AddChild(w.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Hover then leave (before any click, so no focus yet).
    d->InjectMouseMove(core::Float2{50.0f, 50.0f}); // over w
    CHECK(w->IsHovered());
    d->InjectMouseMove(core::Float2{150.0f, 150.0f}); // off w
    CHECK_FALSE(w->IsHovered());

    // Press and release (a click focuses the node).
    d->InjectMouseMove(core::Float2{50.0f, 50.0f});
    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    CHECK(w->IsPressed());
    d->InjectMouseUp(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    CHECK_FALSE(w->IsPressed());
    CHECK(w->IsHovered());

    // Leave while focused, from the click.
    d->InjectMouseMove(core::Float2{150.0f, 150.0f});
    CHECK_FALSE(w->IsHovered());
    CHECK(w->IsFocused());

    w->SetEnabled(false);
    CHECK_FALSE(w->IsTreeEnabled());
}
