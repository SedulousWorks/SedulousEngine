// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ProgressBar tests: clamping and draw.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("progressbar: a range's value, clamped, its fill the value's share; draws track + fill")
{
    auto p = core::MakeRef<ProgressBar>(core::DefaultAllocator());
    p->SetValue(0.5);
    CHECK(p->GetValue() == doctest::Approx(0.5));
    p->SetValue(2.0);
    CHECK(p->GetValue() == doctest::Approx(1.0));
    p->SetValue(-1.0);
    CHECK(p->GetValue() == doctest::Approx(0.0));
    p->SetMax(200.0); // files: 50 of 200
    p->SetValue(50.0);
    CHECK(p->GetRatio() == doctest::Approx(0.25));

    p->SetSize(core::Float2{120.0f, 10.0f});
    foundation::vg::VGContext ctx;
    DrawContext dc{ctx};
    p->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() > 0);
}

TEST_CASE("progressbar: an indeterminate one sweeps on the GUI's clock")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto p = core::MakeRef<ProgressBar>(core::DefaultAllocator());
    p->SetSize(core::Float2{120.0f, 10.0f});
    root->AddChild(p.Get());
    p->SetIndeterminate(true);
    foundation::vg::VGContext ctx;
    DrawContext dc{ctx};
    root->Draw(dc); // shown: the sweep starts
    const float start = p->GetSweepPhase();
    root->GetContext().Update(core::Duration::FromSeconds(0.35));
    CHECK(p->GetSweepPhase() > start);
    CHECK(root->NeedsFrame());
    p->SetIndeterminate(false);
    root->GetContext().Update(core::Duration::FromSeconds(0.1));
    root->GetContext().Update(core::Duration::FromSeconds(0.1));
    CHECK_FALSE(root->GetContext().GetActionManager().AnyAction([&](const Action&, Node& n) { return &n == p.Get(); }));
}
