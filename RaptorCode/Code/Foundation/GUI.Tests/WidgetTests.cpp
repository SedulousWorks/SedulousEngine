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

TEST_CASE("uinode: padding insets the content bounds")
{
    auto n = Make<UINode>();
    n->SetSize(core::Float2{100.0f, 80.0f});
    n->SetPadding(Thickness{5.0f, 10.0f, 15.0f, 20.0f});
    Rect content = n->GetContentBounds();
    CHECK(content == Rect{5.0f, 10.0f, 80.0f, 50.0f}); // 100-5-15, 80-10-20
}

TEST_CASE("uinode: over-large padding clamps to zero, not negative")
{
    auto n = Make<UINode>();
    n->SetSize(core::Float2{20.0f, 20.0f});
    n->SetPadding(Thickness{30.0f});
    Rect content = n->GetContentBounds();
    CHECK(content.width == 0.0f);
    CHECK(content.height == 0.0f);
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

TEST_CASE("uiwidget: tag and id")
{
    auto w = Make<UIWidget>();
    CHECK(w->GetTag().Size() == 0);
    w->SetTag(core::StringView(u8"button"));
    w->SetId(core::StringView(u8"ok"));
    CHECK(w->GetTag() == core::StringView(u8"button"));
    CHECK(w->GetId() == core::StringView(u8"ok"));
}

TEST_CASE("uiwidget: style classes add/remove/toggle")
{
    auto w = Make<UIWidget>();
    CHECK(w->ClassCount() == 0);

    w->AddClass(core::StringView(u8"primary"));
    w->AddClass(core::StringView(u8"large"));
    w->AddClass(core::StringView(u8"primary")); // duplicate ignored
    CHECK(w->ClassCount() == 2);
    CHECK(w->HasClass(core::StringView(u8"primary")));
    CHECK(w->HasClass(core::StringView(u8"large")));
    CHECK_FALSE(w->HasClass(core::StringView(u8"small")));

    w->RemoveClass(core::StringView(u8"large"));
    CHECK_FALSE(w->HasClass(core::StringView(u8"large")));
    CHECK(w->ClassCount() == 1);

    w->ToggleClass(core::StringView(u8"active"));
    CHECK(w->HasClass(core::StringView(u8"active")));
    w->ToggleClass(core::StringView(u8"active"));
    CHECK_FALSE(w->HasClass(core::StringView(u8"active")));
}

TEST_CASE("uiwidget: margin and inherited padding")
{
    auto w = Make<UIWidget>();
    w->SetMargin(Thickness{4.0f});
    CHECK(w->GetMargin().Left == 4.0f);
    w->SetPadding(Thickness{2.0f}); // inherited from UINode
    CHECK(w->GetPadding().Top == 2.0f);
}
