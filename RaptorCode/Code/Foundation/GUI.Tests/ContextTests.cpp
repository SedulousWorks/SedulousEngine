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
