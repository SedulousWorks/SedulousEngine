// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - services a library finds through its GUI (K6 of Specs/gui-lab-evolution-3.md: the
// gamekit's InputPrompts): set, replaced and cleared by key, borrowed, and followed by bindings.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("services: set, replaced and cleared by key; a binding that read one runs again when it changes")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    GUIContext& gui = root->GetContext();
    int first = 1;
    int second = 2;
    CHECK(gui.GetService(core::StringView(u8"test.thing")) == nullptr);
    auto node = core::MakeRef<UIWidget>(core::DefaultAllocator());
    root->AddChild(node.Get());
    int seen = 0;
    node->Bind([&]()
               {
                   const int* thing = static_cast<const int*>(gui.GetService(core::StringView(u8"test.thing")));
                   seen = thing != nullptr ? *thing : 0;
               });
    gui.SetService(core::StringView(u8"test.thing"), &first);
    gui.Update(core::Duration{});
    CHECK(seen == 1);
    gui.SetService(core::StringView(u8"test.thing"), &second);
    gui.Update(core::Duration{});
    CHECK(seen == 2);
    CHECK(gui.GetService(core::StringView(u8"test.other")) == nullptr);
    gui.SetService(core::StringView(u8"test.thing"), nullptr);
    gui.Update(core::Duration{});
    CHECK(seen == 0);
}
