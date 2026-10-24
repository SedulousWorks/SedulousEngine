// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - RadioButton tests: the button core as a toggle a click never unchecks, alone or grouped
// (the groups themselves are ButtonTests'), and its ring and dot.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{100.0f, 100.0f});
        return root;
    }
}

TEST_CASE("radio: a click checks it, and a second leaves it checked")
{
    auto root = MakeRoot();
    auto r = Make<RadioButton>();
    root->AddChild(r.Get());
    (void)root->UpdateLayout();
    core::i32 changes = 0;
    r->SetOnToggled([&](bool) { ++changes; });
    EventDispatcher* d = root->GetEventDispatcher();
    CHECK(r->GetTag() == core::StringView(u8"radio"));

    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(r->IsChecked());
    CHECK((r->GetWidgetStates() & WidgetStateChecked) != 0);
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(r->IsChecked());
    CHECK(changes == 1);

    r->SetChecked(false); // code may clear it
    CHECK_FALSE(r->IsChecked());
}

TEST_CASE("radio: draws its ring, plus the dot when checked")
{
    auto root = MakeRoot();
    auto r = Make<RadioButton>();
    root->AddChild(r.Get());
    const auto draw = [&]()
    {
        (void)root->UpdateLayout();
        vg::VGContext ctx;
        DrawContext dc{ctx};
        root->Draw(dc);
        return ctx.GetBatch().vertices.Size();
    };
    const core::usize ring = draw();
    CHECK(ring > 0);
    r->SetChecked(true);
    CHECK(draw() > ring);
}
