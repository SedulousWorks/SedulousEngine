// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - inert subtrees (K4 of Specs/gui-lab-evolution-3.md, HTML's `inert`): an inert node and
// what it holds draw but take no pointer, focus, navigation, keys or commands, and let go of what
// the dispatcher held in them; made live again, they take input again.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    // A "lower" screen with a button, and an "upper" one with another, side by side.
    struct InertBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> lower = core::MakeRef<UIWidget>(core::DefaultAllocator());
        core::RefPtr<Button> lowerButton = core::MakeRef<Button>(core::DefaultAllocator());
        core::RefPtr<Button> upperButton = core::MakeRef<Button>(core::DefaultAllocator());

        InertBed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            lower->SetSize(core::Float2{200.0f, 300.0f});
            root->AddChild(lower.Get());
            lowerButton->SetSize(core::Float2{80.0f, 30.0f});
            lower->AddChild(lowerButton.Get());
            upperButton->SetPosition(core::Float2{0.0f, 100.0f});
            upperButton->SetSize(core::Float2{80.0f, 30.0f});
            root->AddChild(upperButton.Get());
            (void)root->UpdateLayout();
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
    };
}

TEST_CASE("inert: what it holds takes no pointer, focus or navigation, and lets go of the focus and a press")
{
    InertBed bed;
    bed.d().SetFocusNode(bed.lowerButton.Get());
    bed.d().InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left); // a press held on it
    int clicks = 0;
    bed.lowerButton->SetOnClick([&clicks]() { ++clicks; });
    bed.lower->SetInert(true);
    CHECK(bed.lowerButton->IsTreeInert());
    CHECK(bed.d().GetFocusNode() == nullptr);
    bed.d().InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 0); // the press it held was let go
    CHECK(bed.root->OverFind(core::Float2{10.0f, 10.0f}) != bed.lowerButton.Get());
    bed.lowerButton->RequestFocus();
    CHECK(bed.d().GetFocusNode() == nullptr);
    (void)bed.d().MoveFocus(NavDirection::Down);
    CHECK(bed.d().GetFocusNode() == bed.upperButton.Get()); // navigation finds only what is live
    (void)bed.d().MoveFocus(NavDirection::Up);
    CHECK(bed.d().GetFocusNode() == bed.upperButton.Get());

    bed.lower->SetInert(false);
    bed.d().InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    bed.d().InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1);
}

TEST_CASE("inert: commands and bindings on the focus path skip it")
{
    InertBed bed;
    int ran = 0;
    (void)bed.lower->OnCommand(core::StringView(u8"test.cmd"), [&ran](CommandEvent&) { ++ran; });
    bed.d().SetFocusNode(bed.lowerButton.Get());
    CHECK(bed.root->RunCommand(core::StringView(u8"test.cmd")));
    CHECK(ran == 1);
    bed.lower->SetInert(true);
    CHECK_FALSE(bed.root->RunCommand(core::StringView(u8"test.cmd")));
    CHECK(ran == 1);
}
