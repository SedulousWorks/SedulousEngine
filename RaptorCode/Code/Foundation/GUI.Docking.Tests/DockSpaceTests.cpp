// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - the DockSpace and its controller (D3 of Specs/gui-lab-evolution-3.md): splits as
// Splitters and stacks as TabViews, kept by node id as the layout changes; a panel's content made
// when its tab is first shown and kept by the controller; closing by the panel's policy; a
// placeholder for a panel not registered, filled when it is; a maximized stack alone; and what the
// user does in the widgets (a separator dragged, a tab chosen, dragged or closed, by its close part
// or a middle click) noted back; a
// panel wider than its stack moves no separator, the stack clipping it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.docking;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        DockController controller{core::DefaultAllocator()};
        core::RefPtr<DockSpace> space = core::MakeRef<DockSpace>(core::DefaultAllocator());
        int made = 0; // contents the factories made

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            space->EditLayoutStyle([](LayoutStyle& s) {
                s.Width = LayoutLength::Px(800.0f);
                s.Height = LayoutLength::Px(600.0f);
            });
            root->AddChild(space.Get());
            const char8_t* const ids[] = {u8"scene", u8"hierarchy", u8"inspector", u8"console", u8"log"};
            const char8_t* const titles[] = {u8"Scene", u8"Hierarchy", u8"Inspector", u8"Console", u8"Log"};
            for (usize i = 0; i < 5; ++i)
                Register(ids[i], titles[i], DockClosePolicy::Hide);
            space->Show(controller, controller.GetLayout().MainSurface());
        }
        void Register(const char8_t* id, const char8_t* title, DockClosePolicy policy)
        {
            DockPanelDescription description;
            description.Id = core::String(id);
            description.Title = core::String(title);
            description.Close = policy;
            Bed* self = this;
            description.Factory = [self]()
            {
                ++self->made;
                return core::RefPtr<Node>(core::MakeRef<Panel>(core::DefaultAllocator()));
            };
            REQUIRE(controller.Register(core::Move(description)));
        }
        DockNodeId Central() const { return controller.GetLayout().CentralStack(); }
        DockNodeId StackOf(const char8_t* panel) const { return controller.GetLayout().StackOf(SV(panel)); }
        void Lay() { root->UpdateLayout(); }
    };
}

TEST_CASE("dock space: splits are Splitters and stacks TabViews, kept by node id as the layout changes")
{
    Bed bed;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"scene"), bed.Central()); }).Ok());
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(u8"hierarchy"), bed.Central(), DockSide::Start, 0.25f); }).Ok());
    bed.Lay();
    REQUIRE(bed.space->ChildCount() == 1u);
    auto* splitter = Cast<Splitter>(bed.space->GetChildAt(0));
    REQUIRE(splitter != nullptr);
    REQUIRE(splitter->GetPaneCount() == 2u);
    auto* central = Cast<TabView>(bed.space->WidgetOf(bed.Central()));
    REQUIRE(central != nullptr);
    CHECK(splitter->GetPane(1) == central);
    CHECK(central->HasClass(SV(u8"dock-central")));
    CHECK(central->GetGroup() == core::String(u8"dock"));
    CHECK(splitter->GetWeights()[0] == doctest::Approx(0.25f));
    CHECK(bed.space->PageOf(SV(u8"hierarchy"))->GetTitle() == SV(u8"Hierarchy"));
    // A tab more: the same widgets, a page more.
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"inspector"), bed.Central()); }).Ok());
    CHECK(bed.space->GetChildAt(0) == splitter);
    CHECK(bed.space->WidgetOf(bed.Central()) == central);
    CHECK(central->GetPageCount() == 2);
    CHECK(central->GetSelectedIndex() == 1); // the one tabbed in last
}

TEST_CASE("dock space: a panel's content is made when its tab is first shown, and kept by the controller")
{
    Bed bed;
    // Both tabbed in at once: the console, tabbed in last, is the one shown.
    REQUIRE(bed.controller.Edit([&](DockLayout& l)
    {
        const DockOutcome first = l.InsertTab(SV(u8"scene"), bed.Central());
        return first.Ok() ? l.InsertTab(SV(u8"console"), bed.Central()) : first;
    }).Ok());
    bed.Lay();
    CHECK(bed.controller.HasContent(SV(u8"console"))); // selected: shown
    CHECK_FALSE(bed.controller.HasContent(SV(u8"scene"))); // not shown yet
    CHECK(bed.made == 1);
    auto* central = Cast<TabView>(bed.space->WidgetOf(bed.Central()));
    central->GetBar()->SelectByUser(0); // the user chose the scene's tab
    bed.Lay();
    CHECK(bed.controller.HasContent(SV(u8"scene")));
    CHECK(bed.controller.GetLayout().FindNode(bed.Central())->Active == 0u); // noted
    // Moved to a stack of its own: the same content.
    const core::RefPtr<Node> scene = bed.controller.Content(SV(u8"scene"));
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.MoveBeside(SV(u8"scene"), bed.Central(), DockSide::End); }).Ok());
    bed.Lay();
    CHECK(bed.controller.Content(SV(u8"scene")) == scene);
    CHECK(scene->GetParent() == bed.space->PageOf(SV(u8"scene")));
    CHECK(bed.made == 2);
}

TEST_CASE("dock space: closing by the panel's policy: hide keeps its content, rebuild makes it again, destroy forgets it")
{
    Bed bed;
    bed.Register(u8"preview", u8"Preview", DockClosePolicy::Rebuild);
    bed.Register(u8"search", u8"Search", DockClosePolicy::Destroy);
    const char8_t* const placed[] = {u8"scene", u8"preview", u8"search"};
    for (const char8_t* panel : placed)
    {
        REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(panel), bed.Central(), DockSide::End); }).Ok());
        bed.Lay();
    }
    const core::RefPtr<Node> scene = bed.controller.Content(SV(u8"scene"));
    const core::RefPtr<Node> preview = bed.controller.Content(SV(u8"preview"));
    // Through the tab's close, as the user would.
    auto* sceneStack = Cast<TabView>(bed.space->WidgetOf(bed.StackOf(u8"scene")));
    sceneStack->GetBar()->RequestClose(0);
    CHECK(bed.StackOf(u8"scene") == kNoDock);
    CHECK(bed.controller.HasContent(SV(u8"scene"))); // hidden, kept
    REQUIRE(bed.controller.Show(SV(u8"scene")).Ok());
    bed.Lay();
    CHECK(bed.controller.Content(SV(u8"scene")) == scene);

    REQUIRE(bed.controller.Close(SV(u8"preview")).Ok());
    CHECK_FALSE(bed.controller.HasContent(SV(u8"preview"))); // let go
    CHECK(bed.controller.GetLayout().FindHidden(SV(u8"preview")) != nullptr); // its place kept
    REQUIRE(bed.controller.Show(SV(u8"preview")).Ok());
    bed.Lay();
    CHECK(bed.controller.Content(SV(u8"preview")) != preview); // made again

    REQUIRE(bed.controller.Close(SV(u8"search")).Ok());
    CHECK_FALSE(bed.controller.HasContent(SV(u8"search")));
    CHECK(bed.controller.GetLayout().FindHidden(SV(u8"search")) == nullptr); // forgotten
    // Shown again, it goes to its default place (the main surface's end).
    REQUIRE(bed.controller.Show(SV(u8"search")).Ok());
    CHECK(bed.StackOf(u8"search") != kNoDock);

    DockPanelDescription fixed;
    fixed.Id = core::String(u8"toolbar");
    fixed.Closable = false;
    REQUIRE(bed.controller.Register(core::Move(fixed)));
    REQUIRE(bed.controller.Show(SV(u8"toolbar")).Ok());
    CHECK_FALSE(bed.controller.Close(SV(u8"toolbar")).Ok());
}

TEST_CASE("dock space: a panel not registered shows a placeholder, filled when it registers")
{
    Bed bed;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"profiler"), bed.Central()); }).Ok());
    bed.Lay();
    TabPage* page = bed.space->PageOf(SV(u8"profiler"));
    REQUIRE(page != nullptr);
    REQUIRE(page->ChildCount() == 1u);
    CHECK(Cast<Label>(page->GetChildAt(0)) != nullptr);
    CHECK(Cast<Label>(page->GetChildAt(0))->HasClass(SV(u8"dock-placeholder")));
    bed.Register(u8"profiler", u8"Profiler", DockClosePolicy::Hide);
    bed.Lay();
    page = bed.space->PageOf(SV(u8"profiler"));
    REQUIRE(page != nullptr);
    CHECK(page->GetTitle() == SV(u8"Profiler"));
    REQUIRE(page->ChildCount() == 1u);
    CHECK(Cast<Label>(page->GetChildAt(0)) == nullptr);
    CHECK(bed.controller.HasContent(SV(u8"profiler")));
}

TEST_CASE("dock space: a separator dragged and a tab dragged are noted; a maximized stack is shown alone, the rest kept")
{
    Bed bed;
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(u8"hierarchy"), bed.Central(), DockSide::Start, 0.5f); }).Ok());
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"log"), bed.Central()); }).Ok());
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"console"), bed.Central()); }).Ok());
    bed.Lay();
    auto* splitter = Cast<Splitter>(bed.space->GetChildAt(0));
    REQUIRE(splitter != nullptr);
    splitter->MoveHandleTo(0, 200.0f);
    bed.Lay();
    const DockNode* root = bed.controller.GetLayout().FindNode(bed.controller.GetLayout().FindSurface(bed.controller.GetLayout().MainSurface())->Root);
    CHECK(root->Weights[0] == doctest::Approx(200.0f / 794.0f).epsilon(0.01)); // 800 less the handle
    CHECK(bed.space->GetChildAt(0) == splitter); // kept, not made again

    auto* central = Cast<TabView>(bed.space->WidgetOf(bed.Central()));
    central->GetBar()->MoveTab(1, 0); // console before log
    CHECK(bed.controller.GetLayout().FindNode(bed.Central())->Panels[0] == SV(u8"console"));
    CHECK(bed.space->WidgetOf(bed.Central()) == central);

    const core::RefPtr<Node> held(splitter); // held, so its address is not reused if it went
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.Maximize(bed.Central()); }).Ok());
    CHECK(bed.space->GetChildAt(0) == central); // alone
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.Restore(l.MainSurface()); }).Ok());
    CHECK(bed.space->GetChildAt(0) == splitter); // kept while out of sight
    CHECK(splitter->GetPane(1) == central);
    CHECK(splitter->GetWeights()[0] == doctest::Approx(200.0f / 794.0f).epsilon(0.01));
}

TEST_CASE("dock space: a tab shown with content wider than its stack moves no separator; the stack clips it")
{
    Bed bed;
    DockPanelDescription description;
    description.Id = core::String(u8"wide");
    description.Factory = []()
    {
        core::RefPtr<Panel> wide = core::MakeRef<Panel>(core::DefaultAllocator());
        wide->EditLayoutStyle([](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(700.0f); });
        return core::RefPtr<Node>(wide);
    };
    REQUIRE(bed.controller.Register(core::Move(description)));
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(u8"hierarchy"), bed.Central(), DockSide::Start, 0.25f); }).Ok());
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"wide"), l.StackOf(SV(u8"hierarchy"))); }).Ok());
    auto* stack = Cast<TabView>(bed.space->WidgetOf(bed.StackOf(u8"hierarchy")));
    REQUIRE(stack != nullptr);
    stack->SetSelectedIndex(0);
    bed.Lay();
    auto* splitter = Cast<Splitter>(bed.space->GetChildAt(0));
    REQUIRE(splitter != nullptr);
    const f32 before = splitter->GetPaneSizes()[0];
    stack->SetSelectedIndex(1); // the wide one
    bed.Lay();
    CHECK(splitter->GetPaneSizes()[0] == doctest::Approx(before));
    CHECK(stack->GetSize().x == doctest::Approx(before).epsilon(0.01)); // snapped to the pixel
    CHECK(stack->GetLayoutStyle().OverflowX == Overflow::Hidden);
    CHECK(stack->GetLayoutStyle().OverflowY == Overflow::Hidden);
}

TEST_CASE("dock space: a closable panel's tab shows its close part, chosen or hovered; it, or a middle click, closes the panel")
{
    Bed bed;
    DockPanelDescription fixed;
    fixed.Id = core::String(u8"fixed");
    fixed.Closable = false;
    fixed.Factory = []() { return core::RefPtr<Node>(core::MakeRef<Panel>(core::DefaultAllocator())); };
    REQUIRE(bed.controller.Register(core::Move(fixed)));
    const char8_t* const tabbed[] = {u8"fixed", u8"hierarchy", u8"inspector"};
    for (const char8_t* id : tabbed)
        REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(id), bed.Central()); }).Ok());
    bed.Lay();
    TabBar& bar = *Cast<TabView>(bed.space->WidgetOf(bed.Central()))->GetBar();
    REQUIRE(bar.GetTabCount() == 3);
    bar.SelectByUser(2); // the inspector
    bed.Lay();
    CHECK(bar.GetCloseDisplay() == TabCloseDisplay::Hover);
    CHECK_FALSE(bar.GetTab(0)->GetClosePart()->IsDisplayed()); // it cannot be closed
    CHECK(bar.GetTab(1)->GetClosePart()->IsDisplayed());       // its room kept, shown when hovered
    CHECK_FALSE(bar.GetTab(1)->GetClosePart()->IsVisible());
    CHECK(bar.GetTab(2)->GetClosePart()->IsVisible()); // the chosen tab's

    EventDispatcher& d = *bed.root->GetEventDispatcher();
    const Rect close = bar.GetTab(2)->GetClosePart()->GetScreenBounds();
    const core::Float2 at{close.x + close.width * 0.5f, close.y + close.height * 0.5f};
    d.InjectMouseMove(at);
    d.InjectMouseDown(at, MouseButton::Left);
    d.InjectMouseUp(at, MouseButton::Left);
    CHECK(bed.StackOf(u8"inspector") == kNoDock);
    bed.Lay();

    REQUIRE(bar.GetTabCount() == 2);
    const auto middleClick = [&](core::i32 index)
    {
        const Rect tab = bar.GetTab(index)->GetScreenBounds();
        const core::Float2 on{tab.x + tab.width * 0.5f, tab.y + tab.height * 0.5f};
        d.InjectMouseMove(on);
        d.InjectMouseDown(on, MouseButton::Middle);
        d.InjectMouseUp(on, MouseButton::Middle);
        bed.Lay();
    };
    middleClick(0); // the fixed panel: nothing
    CHECK(bed.StackOf(u8"fixed") != kNoDock);
    middleClick(1);
    CHECK(bed.StackOf(u8"hierarchy") == kNoDock);
    CHECK(bed.StackOf(u8"fixed") != kNoDock);
}
