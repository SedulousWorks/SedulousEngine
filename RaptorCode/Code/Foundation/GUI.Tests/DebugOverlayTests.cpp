// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - debug overlay tests (E8c of Specs/gui-lab-evolution.md): what the input half reads (the
// tab stops in Tab's order, the focus, the node under the pointer) and that it draws each part
// only when asked.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> panel;
        core::Array<core::RefPtr<UIWidget>> stops;

        Bed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            panel = core::MakeRef<UIWidget>(core::DefaultAllocator());
            panel->SetTag(SV(u8"panel"));
            panel->SetPosition(core::Float2{20.0f, 20.0f});
            panel->SetSize(core::Float2{300.0f, 200.0f});
            root->AddChild(panel.Get());
            for (int i = 0; i < 3; ++i)
            {
                auto w = core::MakeRef<UIWidget>(core::DefaultAllocator());
                w->SetTag(SV(u8"stop"));
                w->SetTabFocusable(true);
                w->SetPosition(core::Float2{10.0f + 60.0f * static_cast<f32>(i), 10.0f});
                w->SetSize(core::Float2{50.0f, 20.0f});
                panel->AddChild(w.Get());
                stops.PushBack(w);
            }
            root->UpdateLayout();
        }
        // The vertices a draw makes with `overlay` on.
        usize Draw(const DebugOverlay& overlay)
        {
            root->SetDebugOverlay(overlay);
            vg::VGContext canvas;
            DrawContext dc{canvas};
            root->DrawFrame(dc);
            const vg::VGBatch& batch = canvas.GetBatch();
            return batch.vertices.Size() + batch.boxVertices.Size();
        }
    };
}

TEST_CASE("debug-overlay: the tab stops come in Tab's order, and the overlay numbers and joins them")
{
    Bed bed;
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    const core::Array<Node*> stops = d.TabStops();
    REQUIRE(stops.Size() == 3u);
    for (usize i = 0; i < 3; ++i)
        CHECK(stops[i] == bed.stops[i].Get());
    bed.stops[1]->SetTabFocusable(false); // a stop no longer: not numbered
    CHECK(d.TabStops().Size() == 2u);
    bed.stops[1]->SetTabFocusable(true);

    const usize none = bed.Draw(DebugOverlay{});
    DebugOverlay tabs;
    tabs.TabOrder = true;
    CHECK(bed.Draw(tabs) > none);
}

TEST_CASE("debug-overlay: the focus path and the pointer draw only with something focused and something under the pointer")
{
    Bed bed;
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    DebugOverlay focus;
    focus.FocusPath = true;
    const usize none = bed.Draw(DebugOverlay{});
    CHECK(bed.Draw(focus) == none); // nothing focused
    d.SetFocusNode(bed.stops[2].Get());
    CHECK(bed.Draw(focus) > none);

    DebugOverlay pointer;
    pointer.Pointer = true;
    CHECK(bed.Draw(pointer) == none);
    (void)d.InjectMouseMove(core::Float2{45.0f, 35.0f}); // over the first stop
    CHECK(d.GetOverNode() == bed.stops[0].Get());
    CHECK(bed.Draw(pointer) > none);
}

TEST_CASE("debug-overlay: the layout half and the input half are separate")
{
    const DebugOverlay layout = DebugOverlay::Layout();
    CHECK(layout.AnyLayout());
    CHECK_FALSE(layout.AnyInput());
    const DebugOverlay input = DebugOverlay::Input();
    CHECK(input.AnyInput());
    CHECK_FALSE(input.AnyLayout());
    CHECK_FALSE(DebugOverlay{}.Any());
}

TEST_CASE("debug-overlay: a widget under a node out of the layout is no tab stop and takes no arrow move (found by the overlay)")
{
    Bed bed;
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    bed.stops[1]->SetDisplayed(false); // a page switched away
    const core::Array<Node*> stops = d.TabStops();
    REQUIRE(stops.Size() == 2u);
    CHECK(stops[0] == bed.stops[0].Get());
    CHECK(stops[1] == bed.stops[2].Get());
    d.SetFocusNode(bed.stops[0].Get());
    CHECK(d.MoveFocus(NavDirection::Right));
    CHECK(d.GetFocusNode() == bed.stops[2].Get()); // past the one out of the layout
    bed.panel->SetDisplayed(false);
    CHECK(d.TabStops().IsEmpty());
}

TEST_CASE("debug-overlay: an arrow move keeps what it weighed: the one chosen, those beaten, those behind")
{
    Bed bed;
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    CHECK_FALSE(d.GetLastNavigation().Any);
    d.SetFocusNode(bed.stops[0].Get());
    REQUIRE(d.MoveFocus(NavDirection::Right));
    const NavTrace& trace = d.GetLastNavigation();
    CHECK(trace.Any);
    CHECK(trace.Direction == NavDirection::Right);
    CHECK(trace.From.x == doctest::Approx(30.0f)); // the first stop, in the world
    REQUIRE(trace.Candidates.Size() == 2u);        // the other two
    int chosen = 0, beaten = 0;
    for (const NavCandidate& c : trace.Candidates)
    {
        chosen += c.Verdict == NavVerdict::Chosen ? 1 : 0;
        beaten += c.Verdict == NavVerdict::Beaten ? 1 : 0;
        if (c.Verdict == NavVerdict::Chosen)
            CHECK(c.Bounds.x == doctest::Approx(90.0f)); // the nearest, the second stop
    }
    CHECK(chosen == 1);
    CHECK(beaten == 1);

    // Back left from the second: the first chosen, the third behind.
    REQUIRE(d.MoveFocus(NavDirection::Left));
    int behind = 0;
    for (const NavCandidate& c : d.GetLastNavigation().Candidates)
        behind += c.Verdict == NavVerdict::Behind ? 1 : 0;
    CHECK(behind == 1);

    const usize none = bed.Draw(DebugOverlay{});
    DebugOverlay nav;
    nav.Navigation = true;
    CHECK(bed.Draw(nav) > none);
}

TEST_CASE("debug-overlay: a node that invalidated itself flashes once, and the flashes keep frames coming while they fade")
{
    Bed bed;
    DebugOverlay flash;
    flash.RedrawFlash = true;
    (void)bed.Draw(DebugOverlay{}); // drawn once: nothing new since
    CHECK(bed.root->RedrawFlashCount() == 0u);

    (void)bed.Draw(flash); // turning it on invalidates the root, which never flashes
    CHECK(bed.root->RedrawFlashCount() == 0u);
    bed.stops[1]->SetAlpha(0.5f); // it alone, not the panel holding it
    (void)bed.Draw(flash);
    CHECK(bed.root->RedrawFlashCount() == 1u);
    CHECK(bed.root->NeedsFrame());
    CHECK(bed.root->GetLastFrameStats().Reasons.Overlay);
    (void)bed.Draw(flash); // nothing changed: no new flash (the old one still fades)
    CHECK(bed.root->RedrawFlashCount() == 1u);

    bed.stops[0]->SetAlpha(0.5f);
    (void)bed.Draw(DebugOverlay{}); // off: nothing recorded
    CHECK(bed.root->RedrawFlashCount() == 1u);
}
