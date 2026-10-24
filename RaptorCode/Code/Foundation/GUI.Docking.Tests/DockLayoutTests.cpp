// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - the dock layout as data (D1 of Specs/gui-lab-evolution-3.md): panels tabbed, docked
// beside a stack and at a surface's edge; moved, floated, closed and shown where they were; shares
// that survive a child going; splits of one axis merged; refusals that change nothing; and a long
// run of random operations after each of which the layout still holds together; a floating surface
// docked whole (D5); a stack moved whole (its strip's grip).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui.docking;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::u32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    void Holds(const DockLayout& layout)
    {
        core::String why;
        const bool holds = layout.CheckInvariants(&why);
        INFO(reinterpret_cast<const char*>(why.CStr()));
        CHECK(holds);
    }
    const DockNode& Root(const DockLayout& layout, DockSurfaceId surface)
    {
        return *layout.FindNode(layout.FindSurface(surface)->Root);
    }
}

TEST_CASE("dock layout: a main surface with its central stack, empty and kept")
{
    DockLayout layout;
    REQUIRE(layout.Surfaces().Size() == 1u);
    const DockNodeId central = layout.CentralStack();
    REQUIRE(central != kNoDock);
    CHECK(layout.FindSurface(layout.MainSurface())->Root == central);
    CHECK(layout.FindNode(central)->Panels.IsEmpty());
    Holds(layout);
}

TEST_CASE("dock layout: tabs, a stack beside, a surface's edge; splits of one axis merged")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    CHECK(layout.InsertTab(SV(u8"scene"), central).Ok());
    CHECK(layout.InsertTab(SV(u8"material"), central).Ok());
    CHECK(layout.FindNode(central)->Active == 1u); // the one tabbed in last
    CHECK(layout.InsertBeside(SV(u8"hierarchy"), central, DockSide::Start, 0.25f).Ok());
    const DockNode* root = &Root(layout, layout.MainSurface());
    REQUIRE_FALSE(root->IsStack());
    CHECK(root->Axis == DockAxis::Horizontal);
    REQUIRE(root->Children.Size() == 2u);
    CHECK(root->Weights[0] == doctest::Approx(0.25f));
    // Another beside the central stack on the same axis joins the same split, parting its share.
    CHECK(layout.InsertBeside(SV(u8"inspector"), central, DockSide::End, 0.4f).Ok());
    root = &Root(layout, layout.MainSurface());
    REQUIRE(root->Children.Size() == 3u);
    CHECK(root->Weights[0] == doctest::Approx(0.25f));
    CHECK(root->Weights[1] == doctest::Approx(0.45f)); // 0.75 less its 0.4
    CHECK(root->Weights[2] == doctest::Approx(0.30f));
    // The console along the whole bottom: a vertical split over all of it.
    CHECK(layout.InsertAtEdge(SV(u8"console"), layout.MainSurface(), DockSide::Bottom, 0.2f).Ok());
    root = &Root(layout, layout.MainSurface());
    CHECK(root->Axis == DockAxis::Vertical);
    CHECK(root->Weights[1] == doctest::Approx(0.2f));
    CHECK(layout.StackOf(SV(u8"console")) == root->Children[1]);
    Holds(layout);
}

TEST_CASE("dock layout: a child that goes gives its share to its neighbours; a split of one gives way")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertBeside(SV(u8"a"), central, DockSide::Start, 0.2f).Ok());
    REQUIRE(layout.InsertBeside(SV(u8"b"), central, DockSide::End, 0.5f).Ok()); // 0.2, 0.4, 0.4
    const f32 shares[3] = {0.2f, 0.3f, 0.5f};
    REQUIRE(layout.SetWeights(Root(layout, layout.MainSurface()).Id, core::Span<const f32>(shares, 3)).Ok());
    CHECK(layout.Close(SV(u8"b")).Ok()); // its 0.5 goes to the central stack, its one neighbour
    const DockNode& root = Root(layout, layout.MainSurface());
    REQUIRE(root.Children.Size() == 2u);
    CHECK(root.Weights[0] == doctest::Approx(0.2f)); // a keeps its own
    CHECK(root.Weights[1] == doctest::Approx(0.8f));
    CHECK(layout.Close(SV(u8"a")).Ok()); // the split of one gives way to the central stack
    CHECK(layout.FindSurface(layout.MainSurface())->Root == central);
    Holds(layout);
}

TEST_CASE("dock layout: moved between stacks, reordered among its own tabs, refused beside itself alone")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertTab(SV(u8"one"), central).Ok());
    REQUIRE(layout.InsertTab(SV(u8"two"), central).Ok());
    REQUIRE(layout.InsertTab(SV(u8"three"), central).Ok());
    CHECK(layout.MoveToTab(SV(u8"three"), central, 0).Ok());
    CHECK(layout.FindNode(central)->Panels[0] == SV(u8"three"));
    REQUIRE(layout.MoveBeside(SV(u8"two"), central, DockSide::Bottom).Ok());
    const DockNodeId two = layout.StackOf(SV(u8"two"));
    CHECK(two != central);
    const DockOutcome alone = layout.MoveBeside(SV(u8"two"), two, DockSide::Top);
    CHECK_FALSE(alone.Ok());
    CHECK(layout.StackOf(SV(u8"two")) == two); // refused: nothing changed
    CHECK(layout.MoveToTab(SV(u8"two"), central).Ok()); // back: its stack goes
    CHECK(layout.FindNode(two) == nullptr);
    Holds(layout);
}

TEST_CASE("dock layout: floating surfaces are whole trees, and go when emptied")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertTab(SV(u8"scene"), central).Ok());
    DockSurfaceId floating = kNoDock;
    REQUIRE(layout.Float(SV(u8"profiler"), core::Rectangle{100.0f, 80.0f, 400.0f, 300.0f}, &floating).Ok());
    REQUIRE(layout.Surfaces().Size() == 2u);
    const DockNodeId stack = layout.StackOf(SV(u8"profiler"));
    CHECK(layout.SurfaceOf(stack) == floating);
    CHECK(layout.FindSurface(floating)->Bounds.width == doctest::Approx(400.0f));
    // Docked into: a tab, and a stack beside.
    CHECK(layout.InsertTab(SV(u8"memory"), stack).Ok());
    CHECK(layout.InsertBeside(SV(u8"counters"), stack, DockSide::Bottom).Ok());
    CHECK(layout.SurfaceOf(layout.StackOf(SV(u8"counters"))) == floating);
    // Everything moved out: the surface goes.
    CHECK(layout.MoveToTab(SV(u8"profiler"), central).Ok());
    CHECK(layout.MoveToTab(SV(u8"memory"), central).Ok());
    CHECK(layout.MoveToEdge(SV(u8"counters"), layout.MainSurface(), DockSide::End).Ok());
    CHECK(layout.FindSurface(floating) == nullptr);
    CHECK(layout.Surfaces().Size() == 1u);
    Holds(layout);
}

TEST_CASE("dock layout: a floating surface docks whole: its panels as tabs, its tree beside a stack or along an edge")
{
    // A float of two stacks side by side: profiler | memory, counters (counters active).
    const auto make = [](DockLayout& layout, DockSurfaceId& floating)
    {
        REQUIRE(layout.InsertTab(SV(u8"scene"), layout.CentralStack()).Ok());
        REQUIRE(layout.Float(SV(u8"profiler"), core::Rectangle{100.0f, 80.0f, 400.0f, 300.0f}, &floating).Ok());
        const DockNodeId first = layout.StackOf(SV(u8"profiler"));
        REQUIRE(layout.InsertBeside(SV(u8"memory"), first, DockSide::End).Ok());
        REQUIRE(layout.InsertTab(SV(u8"counters"), layout.StackOf(SV(u8"memory"))).Ok());
    };
    {
        DockLayout layout;
        DockSurfaceId floating = kNoDock;
        make(layout, floating);
        const DockNodeId central = layout.CentralStack();
        REQUIRE(layout.DockSurfaceInto(floating, central).Ok());
        const DockNode& stack = *layout.FindNode(central);
        REQUIRE(stack.Panels.Size() == 4u);
        CHECK(stack.Panels[1] == SV(u8"profiler"));
        CHECK(stack.Panels[2] == SV(u8"memory"));
        CHECK(stack.Panels[3] == SV(u8"counters"));
        CHECK(stack.Panels[stack.Active] == SV(u8"profiler")); // the float's first stack's active
        CHECK(layout.FindSurface(floating) == nullptr);
        Holds(layout);
    }
    {
        DockLayout layout;
        DockSurfaceId floating = kNoDock;
        make(layout, floating);
        const DockNodeId central = layout.CentralStack();
        REQUIRE(layout.DockSurfaceBeside(floating, central, DockSide::Bottom, 0.4f).Ok());
        CHECK(layout.FindSurface(floating) == nullptr);
        const DockNode& root = Root(layout, layout.MainSurface());
        REQUIRE(root.Axis == DockAxis::Vertical);
        REQUIRE(root.Children.Size() == 2u);
        CHECK(root.Children[0] == central);
        CHECK(root.Weights[1] == doctest::Approx(0.4f));
        const DockNode& moved = *layout.FindNode(root.Children[1]); // the float's own split, kept
        CHECK(moved.Axis == DockAxis::Horizontal);
        CHECK(moved.Children.Size() == 2u);
        CHECK(layout.SurfaceOf(layout.StackOf(SV(u8"counters"))) == layout.MainSurface());
        Holds(layout);
    }
    {
        DockLayout layout;
        DockSurfaceId floating = kNoDock;
        make(layout, floating);
        REQUIRE(layout.InsertBeside(SV(u8"hierarchy"), layout.CentralStack(), DockSide::Start).Ok());
        REQUIRE(layout.DockSurfaceAtEdge(floating, layout.MainSurface(), DockSide::End, 0.3f).Ok());
        const DockNode& root = Root(layout, layout.MainSurface());
        REQUIRE(root.Axis == DockAxis::Horizontal);
        // Same axis as the float's split: merged into one row, hierarchy | scene | profiler | memory.
        REQUIRE(root.Children.Size() == 4u);
        CHECK(layout.FindNode(root.Children[2])->Panels[0] == SV(u8"profiler"));
        Holds(layout);
    }
    {
        // Refusals change nothing.
        DockLayout layout;
        DockSurfaceId floating = kNoDock;
        make(layout, floating);
        const DockNodeId inside = layout.StackOf(SV(u8"memory"));
        CHECK_FALSE(layout.DockSurfaceInto(floating, inside).Ok()); // into itself
        CHECK_FALSE(layout.DockSurfaceBeside(layout.MainSurface(), layout.CentralStack(), DockSide::End).Ok()); // not floating
        CHECK_FALSE(layout.DockSurfaceAtEdge(floating, floating, DockSide::End).Ok());
        REQUIRE(layout.SetStackFlags(layout.CentralStack(), DockStackCentral | DockStackNoTabs).Ok());
        CHECK_FALSE(layout.DockSurfaceInto(floating, layout.CentralStack()).Ok()); // it holds one panel
        REQUIRE(layout.SetStackFlags(inside, DockStackLocked).Ok());
        REQUIRE(layout.SetStackFlags(layout.CentralStack(), DockStackCentral).Ok());
        CHECK_FALSE(layout.DockSurfaceInto(floating, layout.CentralStack()).Ok()); // a locked stack's panels stay
        CHECK(layout.DockSurfaceBeside(floating, layout.CentralStack(), DockSide::End).Ok()); // whole, its stacks kept
        Holds(layout);
    }
}

TEST_CASE("dock layout: a stack moves whole: into another as its tabs, beside one, along an edge, floated")
{
    // hierarchy | scene (central), with the console, log under the scene.
    const auto make = [](DockLayout& layout)
    {
        REQUIRE(layout.InsertTab(SV(u8"scene"), layout.CentralStack()).Ok());
        REQUIRE(layout.InsertBeside(SV(u8"hierarchy"), layout.CentralStack(), DockSide::Start, 0.25f).Ok());
        REQUIRE(layout.InsertBeside(SV(u8"console"), layout.CentralStack(), DockSide::Bottom, 0.3f).Ok());
        REQUIRE(layout.InsertTab(SV(u8"log"), layout.StackOf(SV(u8"console"))).Ok());
        REQUIRE(layout.Activate(SV(u8"console")).Ok());
    };
    {
        DockLayout layout;
        make(layout);
        const DockNodeId bottom = layout.StackOf(SV(u8"console"));
        const DockNodeId hierarchy = layout.StackOf(SV(u8"hierarchy"));
        REQUIRE(layout.MoveStackInto(bottom, hierarchy, 0).Ok());
        const DockNode& into = *layout.FindNode(hierarchy);
        REQUIRE(into.Panels.Size() == 3u);
        CHECK(into.Panels[0] == SV(u8"console"));
        CHECK(into.Panels[1] == SV(u8"log"));
        CHECK(into.Panels[2] == SV(u8"hierarchy"));
        CHECK(into.Panels[into.Active] == SV(u8"console")); // its active panel, active there
        CHECK(layout.FindNode(bottom) == nullptr); // emptied, gone
        Holds(layout);
    }
    {
        DockLayout layout;
        make(layout);
        const DockNodeId bottom = layout.StackOf(SV(u8"console"));
        const DockNodeId hierarchy = layout.StackOf(SV(u8"hierarchy"));
        REQUIRE(layout.MoveStackBeside(bottom, hierarchy, DockSide::Bottom, 0.4f).Ok());
        CHECK(layout.StackOf(SV(u8"log")) == bottom); // the same stack, moved: its id kept
        const DockNode& split = *layout.FindNode(layout.FindNode(bottom)->Parent);
        CHECK(split.Axis == DockAxis::Vertical);
        CHECK(split.Children[0] == hierarchy);
        CHECK(split.Children[1] == bottom);
        CHECK(split.Weights[1] == doctest::Approx(0.4f));
        // The scene, alone where the two were stacked, no longer in a vertical split.
        CHECK(layout.FindNode(layout.FindNode(layout.CentralStack())->Parent)->Axis == DockAxis::Horizontal);
        Holds(layout);
    }
    {
        DockLayout layout;
        make(layout);
        const DockNodeId hierarchy = layout.StackOf(SV(u8"hierarchy"));
        REQUIRE(layout.MoveStackToEdge(hierarchy, layout.MainSurface(), DockSide::End, 0.2f).Ok());
        const DockNode& root = Root(layout, layout.MainSurface());
        REQUIRE(root.Axis == DockAxis::Horizontal);
        CHECK(root.Children.Back() == hierarchy);
        CHECK(root.Weights.Back() == doctest::Approx(0.2f));
        Holds(layout);
    }
    {
        DockLayout layout;
        make(layout);
        const DockNodeId bottom = layout.StackOf(SV(u8"console"));
        DockSurfaceId floating = kNoDock;
        REQUIRE(layout.FloatStack(bottom, core::Rectangle{100.0f, 80.0f, 300.0f, 200.0f}, &floating).Ok());
        const DockSurface* made = layout.FindSurface(floating);
        REQUIRE(made != nullptr);
        CHECK(made->Kind == DockSurfaceKind::Floating);
        CHECK(made->Root == bottom);
        CHECK(made->Bounds.width == doctest::Approx(300.0f));
        CHECK(layout.FindNode(bottom)->Panels.Size() == 2u);
        Holds(layout);
        // Alone in its float: it floats already; docked back beside the scene, the float goes.
        CHECK_FALSE(layout.FloatStack(bottom, core::Rectangle{0.0f, 0.0f, 300.0f, 200.0f}).Ok());
        REQUIRE(layout.MoveStackBeside(bottom, layout.CentralStack(), DockSide::Top).Ok());
        CHECK(layout.FindSurface(floating) == nullptr);
        Holds(layout);
    }
    {
        // The central stack's panels go; it stays, empty, where it was.
        DockLayout layout;
        make(layout);
        REQUIRE(layout.InsertTab(SV(u8"game"), layout.CentralStack()).Ok());
        const DockNodeId central = layout.CentralStack();
        DockSurfaceId floating = kNoDock;
        REQUIRE(layout.FloatStack(central, core::Rectangle{0.0f, 0.0f, 300.0f, 200.0f}, &floating).Ok());
        CHECK(layout.CentralStack() == central);
        CHECK(layout.FindNode(central)->Panels.IsEmpty());
        CHECK(layout.SurfaceOf(layout.StackOf(SV(u8"game"))) == floating);
        CHECK(layout.FindNode(layout.StackOf(SV(u8"scene")))->Panels.Size() == 2u);
        Holds(layout);
        CHECK_FALSE(layout.MoveStackInto(central, layout.StackOf(SV(u8"hierarchy"))).Ok()); // empty now
    }
    {
        // Refusals change nothing.
        DockLayout layout;
        make(layout);
        const DockNodeId bottom = layout.StackOf(SV(u8"console"));
        const DockNodeId hierarchy = layout.StackOf(SV(u8"hierarchy"));
        CHECK_FALSE(layout.MoveStackInto(bottom, bottom).Ok());
        CHECK_FALSE(layout.MoveStackBeside(bottom, bottom, DockSide::End).Ok());
        REQUIRE(layout.SetStackFlags(hierarchy, DockStackNoTabs).Ok());
        CHECK_FALSE(layout.MoveStackInto(bottom, hierarchy).Ok()); // it holds one panel
        REQUIRE(layout.SetStackFlags(hierarchy, DockStackNoSplit).Ok());
        CHECK_FALSE(layout.MoveStackBeside(bottom, hierarchy, DockSide::Top).Ok());
        REQUIRE(layout.SetStackFlags(bottom, DockStackLocked).Ok());
        CHECK_FALSE(layout.FloatStack(bottom, core::Rectangle{0.0f, 0.0f, 300.0f, 200.0f}).Ok());
        CHECK(layout.StackOf(SV(u8"log")) == bottom);
        CHECK(layout.Surfaces().Size() == 1u);
        Holds(layout);
    }
}

TEST_CASE("dock layout: a closed panel is shown where it was, or near its neighbours, or in the centre")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertTab(SV(u8"scene"), central).Ok());
    REQUIRE(layout.InsertBeside(SV(u8"outline"), central, DockSide::Start).Ok());
    const DockNodeId left = layout.StackOf(SV(u8"outline"));
    REQUIRE(layout.InsertTab(SV(u8"assets"), left).Ok());
    REQUIRE(layout.InsertTab(SV(u8"history"), left).Ok());
    // Among its stack's tabs again, at its place.
    REQUIRE(layout.Close(SV(u8"assets")).Ok());
    CHECK(layout.FindHidden(SV(u8"assets")) != nullptr);
    CHECK(layout.StackOf(SV(u8"assets")) == kNoDock);
    REQUIRE(layout.Show(SV(u8"assets")).Ok());
    CHECK(layout.StackOf(SV(u8"assets")) == left);
    CHECK(layout.FindNode(left)->Panels[1] == SV(u8"assets"));
    CHECK(layout.FindHidden(SV(u8"assets")) == nullptr);
    // Its stack gone: beside a panel that was about it.
    REQUIRE(layout.Close(SV(u8"outline")).Ok());
    REQUIRE(layout.Close(SV(u8"assets")).Ok());
    REQUIRE(layout.Close(SV(u8"history")).Ok()); // the stack goes
    CHECK(layout.FindNode(left) == nullptr);
    // Closed alone, its neighbours were those beside its stack (the scene): beside them again.
    REQUIRE(layout.Show(SV(u8"history")).Ok());
    const DockNodeId history = layout.StackOf(SV(u8"history"));
    CHECK(history != central);
    CHECK(layout.FindNode(history)->Parent == layout.FindNode(central)->Parent);
    // Its stack's tabs gone too, outline goes beside one of them (history) docked again.
    REQUIRE(layout.Show(SV(u8"outline")).Ok());
    CHECK(layout.StackOf(SV(u8"outline")) != history);
    CHECK(layout.FindNode(layout.StackOf(SV(u8"outline")))->Parent == layout.FindNode(history)->Parent);
    // None of its neighbours docked: the central stack.
    REQUIRE(layout.Close(SV(u8"history")).Ok());
    REQUIRE(layout.Close(SV(u8"outline")).Ok());
    REQUIRE(layout.Close(SV(u8"scene")).Ok());
    REQUIRE(layout.Show(SV(u8"history")).Ok());
    CHECK(layout.StackOf(SV(u8"history")) == central);
    CHECK(layout.Show(SV(u8"history")).Refused == core::String(u8"it is docked"));
    Holds(layout);
}

TEST_CASE("dock layout: flags refuse, and a refusal changes nothing")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertTab(SV(u8"game"), central).Ok());
    REQUIRE(layout.SetStackFlags(central, DockStackCentral | DockStackLocked | DockStackNoSplit).Ok());
    CHECK_FALSE(layout.InsertTab(SV(u8"x"), central).Ok());
    CHECK_FALSE(layout.InsertBeside(SV(u8"x"), central, DockSide::End).Ok());
    CHECK_FALSE(layout.Close(SV(u8"game")).Ok());
    CHECK_FALSE(layout.MoveToTab(SV(u8"game"), central, 0).Ok()); // its stack is locked: it stays
    CHECK_FALSE(layout.SetStackFlags(central, 0).Ok()); // the central stack stays the central one
    CHECK_FALSE(layout.InsertTab(SV(u8""), central).Ok());
    CHECK(layout.InsertAtEdge(SV(u8"x"), layout.MainSurface(), DockSide::Top).Ok()); // the surface's edge is not beside it
    CHECK_FALSE(layout.InsertTab(SV(u8"x"), layout.StackOf(SV(u8"x"))).Ok()); // docked already
    Holds(layout);
}

TEST_CASE("dock layout: a maximized stack, dropped when it goes")
{
    DockLayout layout;
    const DockNodeId central = layout.CentralStack();
    REQUIRE(layout.InsertBeside(SV(u8"side"), central, DockSide::End).Ok());
    const DockNodeId side = layout.StackOf(SV(u8"side"));
    REQUIRE(layout.Maximize(side).Ok());
    CHECK(layout.FindSurface(layout.MainSurface())->Maximized == side);
    REQUIRE(layout.Close(SV(u8"side")).Ok());
    CHECK(layout.FindSurface(layout.MainSurface())->Maximized == kNoDock);
}

TEST_CASE("dock layout: a long run of random operations, the layout holding together after each")
{
    // A small generator of its own: the same runs every time.
    const u32 seeds[] = {12345u, 1u, 777u, 2026u, 31337u};
    for (const u32 seed : seeds)
    {
        u32 state = seed;
        const auto next = [&state](u32 below)
        {
            state = state * 1664525u + 1013904223u;
            return (state >> 8) % below;
        };
        const char8_t* const names[] = {u8"p0", u8"p1", u8"p2", u8"p3", u8"p4", u8"p5", u8"p6", u8"p7", u8"p8", u8"p9"};
        const DockSide sides[] = {DockSide::Start, DockSide::End, DockSide::Top, DockSide::Bottom};
        DockLayout layout;
        usize done = 0;
        for (int step = 0; step < 4000; ++step)
        {
            const core::StringView panel(names[next(10)]);
            // A stack to act on: one that is there, or the central one.
            DockNodeId stack = layout.CentralStack();
            const core::Array<DockNode>& nodes = layout.Nodes();
            const DockNode& pick = nodes[next(static_cast<u32>(nodes.Size()))];
            if (pick.IsStack())
                stack = pick.Id;
            const DockSurfaceId surface = layout.Surfaces()[next(static_cast<u32>(layout.Surfaces().Size()))].Id;
            const DockSide side = sides[next(4)];
            const f32 share = 0.1f + 0.1f * static_cast<f32>(next(8));
            DockOutcome outcome;
            // A floating surface to dock whole, when there is one.
            DockSurfaceId floating = kNoDock;
            for (const DockSurface& each : layout.Surfaces())
                if (each.Kind == DockSurfaceKind::Floating)
                    floating = each.Id;
            switch (next(17))
            {
            case 0: outcome = layout.InsertTab(panel, stack, static_cast<core::i32>(next(4)) - 1); break;
            case 1: outcome = layout.InsertBeside(panel, stack, side, share); break;
            case 2: outcome = layout.InsertAtEdge(panel, surface, side, share); break;
            case 3: outcome = layout.MoveToTab(panel, stack, static_cast<core::i32>(next(4)) - 1); break;
            case 4: outcome = layout.MoveBeside(panel, stack, side, share); break;
            case 5: outcome = layout.MoveToEdge(panel, surface, side, share); break;
            case 6: outcome = layout.Float(panel, core::Rectangle{0.0f, 0.0f, 300.0f, 200.0f}); break;
            case 7: outcome = layout.Close(panel); break;
            case 8: outcome = layout.Show(panel); break;
            case 9: outcome = layout.DockSurfaceInto(floating, stack); break;
            case 10: outcome = layout.DockSurfaceBeside(floating, stack, side, share); break;
            case 11: outcome = layout.DockSurfaceAtEdge(floating, surface, side, share); break;
            case 12: outcome = layout.MoveStackInto(stack, layout.StackOf(panel), static_cast<core::i32>(next(4)) - 1); break;
            case 13: outcome = layout.MoveStackBeside(stack, layout.StackOf(panel), side, share); break;
            case 14: outcome = layout.MoveStackToEdge(stack, surface, side, share); break;
            case 15: outcome = layout.FloatStack(stack, core::Rectangle{0.0f, 0.0f, 300.0f, 200.0f}); break;
            default: outcome = layout.Maximize(stack); break;
            }
            done += outcome.Ok() ? 1u : 0u;
            core::String why;
            if (!layout.CheckInvariants(&why))
            {
                INFO("seed " << seed << ", step " << step << ": " << reinterpret_cast<const char*>(why.CStr()));
                REQUIRE(false);
            }
        }
        CHECK(done > 1000u); // most did something
    }
}
