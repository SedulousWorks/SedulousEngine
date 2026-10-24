// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - drag to dock within one window (D4 of Specs/gui-lab-evolution-3.md): a tab torn
// from a stack's strip carries its panel; over a strip it goes in at a tab's place, over a stack's
// middle into it, over its edge band beside it, over the surface's band along the whole edge. Each
// drop is the layout's move, tried on a copy first: the preview is where the panel would be, and a
// move the layout refuses shows its reason and does nothing. Meanwhile the torn tab dims (or its
// strip closes up, as the theme says), shown again as the layout has it when the drag ends. A
// stack's grip (its strip's list button) carries the whole stack the same ways, and lists its tabs
// when clicked; the cross past it closes every closable panel of the stack.
#include "DockingTestBed.h"

using namespace foundation::gui;
using namespace dockbed;

TEST_CASE("dock drop: over a stack's middle the panel tabs into it; the preview is the stack")
{
    Bed bed;
    const DockNodeId hierarchy = bed.StackOf(u8"hierarchy");
    bed.Tear(u8"inspector");
    const Rect stack = Bed::Bounds(*bed.space->WidgetOf(hierarchy));
    const core::Float2 middle = Bed::Centre(stack);
    bed.Over(middle);
    CHECK(bed.D().GetDropTarget() == bed.space->WidgetOf(hierarchy));
    Rect preview;
    REQUIRE(bed.Preview(preview));
    CHECK(preview.x == doctest::Approx(stack.x).epsilon(0.02));
    CHECK(preview.width == doctest::Approx(stack.width).epsilon(0.05));
    CHECK(bed.controller.GetLayout().StackOf(SV(u8"inspector")) != hierarchy); // nothing moved yet
    bed.Release(middle);
    CHECK(bed.StackOf(u8"inspector") == hierarchy);
    CHECK_FALSE(bed.Preview(preview));
    CHECK(bed.space->PageOf(SV(u8"inspector")) != nullptr);
}

TEST_CASE("dock drop: over a stack's edge band the panel goes beside it, the preview its half")
{
    Bed bed;
    const DockNodeId console = bed.StackOf(u8"console");
    bed.Tear(u8"inspector");
    const Rect stack = Bed::Bounds(*bed.space->WidgetOf(console));
    const core::Float2 right{stack.x + stack.width - 30.0f, stack.y + stack.height * 0.5f}; // in its band (64)
    bed.Over(right);
    Rect preview;
    REQUIRE(bed.Preview(preview));
    CHECK(preview.x == doctest::Approx(stack.x + stack.width * 0.5f).epsilon(0.03));
    CHECK(preview.width == doctest::Approx(stack.width * 0.5f).epsilon(0.05));
    bed.Release(right);
    const DockNodeId inspector = bed.StackOf(u8"inspector");
    REQUIRE(inspector != kNoDock);
    CHECK(inspector != console);
    const DockNode* split = bed.controller.GetLayout().FindNode(bed.controller.GetLayout().FindNode(inspector)->Parent);
    REQUIRE(split != nullptr);
    CHECK(split->Axis == DockAxis::Horizontal);
    CHECK(split->Children[0] == console);
    CHECK(split->Children[1] == inspector);
}

TEST_CASE("dock drop: over the surface's band the panel goes along the whole edge")
{
    Bed bed;
    bed.Tear(u8"inspector");
    const core::Float2 top{400.0f, 4.0f}; // over the central strip, in the band's outer third (20 / 3)
    // Down the left side, over the hierarchy's body: the surface's band too.
    bed.Over(core::Float2{6.0f, 300.0f});
    CHECK(bed.D().GetDropTarget() == bed.space.Get());
    bed.Over(top);
    CHECK(bed.D().GetDropTarget() != nullptr); // the strip under it, which leaves the band its due
    Rect preview;
    REQUIRE(bed.Preview(preview));
    CHECK(preview.y == doctest::Approx(0.0f));
    CHECK(preview.width == doctest::Approx(800.0f));
    CHECK(preview.height == doctest::Approx(150.0f).epsilon(0.05)); // a quarter
    bed.Release(top);
    const DockLayout& layout = bed.controller.GetLayout();
    const DockNode* root = layout.FindNode(layout.FindSurface(layout.MainSurface())->Root);
    REQUIRE(root != nullptr);
    CHECK(root->Axis == DockAxis::Vertical);
    CHECK(root->Children[0] == bed.StackOf(u8"inspector"));
}

TEST_CASE("dock drop: over a strip the panel goes in at a tab's place, counted as the tabs are")
{
    Bed bed;
    // Into the console's strip, before the console.
    bed.Tear(u8"scene");
    const Rect consoleTab = Bed::Bounds(*bed.TabOf(u8"console"));
    const core::Float2 before{consoleTab.x + 10.0f, consoleTab.y + 10.0f};
    bed.Over(before);
    CHECK(bed.D().GetDropTarget() == bed.ViewOf(u8"console")->GetBar());
    bed.Release(before);
    const DockNode* stack = bed.controller.GetLayout().FindNode(bed.StackOf(u8"console"));
    REQUIRE(stack->Panels.Size() == 2u);
    CHECK(stack->Panels[0] == SV(u8"scene"));
    CHECK(stack->Panels[1] == SV(u8"console"));
    bed.Lay();
    // Within its own strip, torn and dropped after the console: last.
    bed.Tear(u8"scene");
    const Rect after = Bed::Bounds(*bed.TabOf(u8"console"));
    const core::Float2 end{after.x + after.width - 5.0f, after.y + 10.0f};
    bed.Over(end);
    bed.Release(end);
    stack = bed.controller.GetLayout().FindNode(bed.StackOf(u8"console"));
    CHECK(stack->Panels[0] == SV(u8"console"));
    CHECK(stack->Panels[1] == SV(u8"scene"));
}

TEST_CASE("dock drop: a move the layout refuses shows its reason, no preview, and does nothing; Escape leaves it as it was")
{
    Bed bed;
    const DockNodeId hierarchy = bed.StackOf(u8"hierarchy");
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.SetStackFlags(hierarchy, DockStackNoTabs); }).Ok());
    bed.Lay();
    bed.Tear(u8"inspector");
    const core::Float2 middle = Bed::Centre(Bed::Bounds(*bed.space->WidgetOf(hierarchy)));
    bed.Over(middle);
    CHECK(bed.D().GetDropTarget() == nullptr);
    CHECK_FALSE(bed.D().GetDropReason().IsEmpty());
    Rect preview;
    CHECK_FALSE(bed.Preview(preview));
    bed.Release(middle);
    CHECK(bed.StackOf(u8"inspector") == bed.controller.GetLayout().CentralStack());

    bed.Tear(u8"inspector");
    const core::Float2 console = Bed::Centre(Bed::Bounds(*bed.space->WidgetOf(bed.StackOf(u8"console"))));
    bed.Over(console);
    REQUIRE(bed.Preview(preview));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(bed.D().IsDragging());
    CHECK_FALSE(bed.Preview(preview));
    CHECK(bed.StackOf(u8"inspector") == bed.controller.GetLayout().CentralStack());
}

TEST_CASE("dock drop: the bands are the sheet's, through the theme's tokens")
{
    Bed bed;
    StyleManager styles;
    const core::String css = core::Format(u8"{} :root {{ --dock-edge: 40px; --dock-surface-edge: 12px; }}", DockingSheetCSS());
    styles.SetStyleSheet(CSSParser::Parse(css.AsView()));
    styles.ApplyTree(*bed.root.Get());
    CHECK(bed.space->GetEdgeBand() == doctest::Approx(40.0f));
    CHECK(bed.space->GetSurfaceBand() == doctest::Approx(12.0f));
}

TEST_CASE("dock drop: a torn tab closes up its strip, a neighbour shown, and Escape shows the stack as it was")
{
    Bed bed;
    bed.space->SetTornTab(DockTornTab::Close);
    TabView* central = bed.ViewOf(u8"inspector");
    REQUIRE(central != nullptr);
    Tab* inspector = bed.TabOf(u8"inspector");
    central->SetSelectedIndex(central->GetBar()->IndexOf(inspector));
    bed.Lay();
    bed.Tear(u8"inspector");
    CHECK_FALSE(inspector->IsDisplayed());
    CHECK(central->GetSelectedPage() == bed.space->PageOf(SV(u8"scene"))); // the view's, not the layout's
    const DockNode* stack = bed.controller.GetLayout().FindNode(bed.StackOf(u8"inspector"));
    CHECK(stack->Panels[stack->Active] == SV(u8"inspector"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(inspector->IsDisplayed());
    CHECK(central->GetSelectedPage() == bed.space->PageOf(SV(u8"inspector")));

    // Dropped into another stack: it is there, shown, and its old stack shows what the layout has.
    bed.Tear(u8"inspector");
    const core::Float2 middle = Bed::Centre(Bed::Bounds(*bed.space->WidgetOf(bed.StackOf(u8"console"))));
    bed.Over(middle);
    bed.Release(middle);
    REQUIRE(bed.TabOf(u8"inspector") != nullptr);
    CHECK(bed.TabOf(u8"inspector")->IsDisplayed());
    CHECK(central->GetSelectedPage() == bed.space->PageOf(SV(u8"scene")));
}

TEST_CASE("dock drop: a torn tab dims by default; the theme's torn-tab closes it up; a stack's only tab dims its stack")
{
    Bed bed;
    {
        StyleManager styles;
        styles.SetStyleSheet(CSSParser::Parse(DockingSheetCSS()));
        styles.ApplyTree(*bed.root.Get());
        CHECK(bed.space->GetTornTab() == DockTornTab::Dim);
        const core::String css = core::Format(u8"{} :root {{ --dock-torn-tab: close; }}", DockingSheetCSS());
        styles.SetStyleSheet(CSSParser::Parse(css.AsView()));
        styles.ApplyTree(*bed.root.Get());
        CHECK(bed.space->GetTornTab() == DockTornTab::Close);
    }
    bed.space->SetTornTab(DockTornTab::Dim);
    bed.Tear(u8"inspector");
    Tab* inspector = bed.TabOf(u8"inspector");
    CHECK(inspector->IsDisplayed());
    CHECK(inspector->HasClass(SV(u8"dock-torn")));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(inspector->HasClass(SV(u8"dock-torn")));

    bed.space->SetTornTab(DockTornTab::Close);
    bed.Tear(u8"hierarchy"); // alone in its stack: the stack dims, the tab stays
    CHECK(bed.TabOf(u8"hierarchy")->IsDisplayed());
    CHECK(bed.ViewOf(u8"hierarchy")->HasClass(SV(u8"dock-torn")));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(bed.ViewOf(u8"hierarchy")->HasClass(SV(u8"dock-torn")));
}

TEST_CASE("dock drop: a tab moved a few pixels along its strip is a drag at once; dropped further along, the layout reorders it")
{
    Bed bed;
    const DockNodeId central = bed.controller.GetLayout().CentralStack();
    REQUIRE(bed.controller.GetLayout().FindNode(central)->Panels[0] == SV(u8"scene"));
    bed.space->SetTornTab(DockTornTab::Close);
    Tab* scene = bed.TabOf(u8"scene");
    const core::Float2 start = Bed::Centre(Bed::Bounds(*scene));
    bed.D().InjectMouseDown(start, MouseButton::Left);
    bed.Over(core::Float2{start.x + 8.0f, start.y});
    REQUIRE(bed.D().IsDragging());
    CHECK_FALSE(scene->IsDisplayed()); // its strip closed up from the first move
    bed.Lay();
    const Rect inspector = Bed::Bounds(*bed.TabOf(u8"inspector"));
    const core::Float2 end{inspector.x + inspector.width - 5.0f, start.y};
    bed.Over(end);
    bed.Release(end);
    const DockNode* stack = bed.controller.GetLayout().FindNode(central);
    CHECK(stack->Panels[0] == SV(u8"inspector"));
    CHECK(stack->Panels[1] == SV(u8"scene"));
    CHECK(bed.TabOf(u8"scene")->IsDisplayed());
}

namespace
{
    // A drag of `panel`'s stack by its strip's grip, past the threshold.
    void GrabStack(Bed& bed, const char8_t* panel)
    {
        Node* grip = bed.ViewOf(panel)->GetBar()->GetListButton();
        REQUIRE(grip->IsDisplayed());
        const core::Float2 at = Bed::Centre(Bed::Bounds(*grip));
        bed.D().InjectMouseDown(at, MouseButton::Left);
        bed.D().InjectMouseMove(core::Float2{at.x - 20.0f, at.y + 20.0f});
        bed.D().InjectMouseMove(core::Float2{at.x - 30.0f, at.y + 30.0f});
        REQUIRE(bed.D().IsDragging());
    }
}

TEST_CASE("dock drop: a stack's grip, dragged, carries the whole stack: into a stack over its strip, beside one by its edge")
{
    {
        Bed bed;
        TabView* central = bed.ViewOf(u8"scene");
        GrabStack(bed, u8"scene"); // scene and inspector
        CHECK(central->HasClass(SV(u8"dock-torn"))); // the stack dims while it is carried
        CHECK(bed.ViewOf(u8"hierarchy")->GetBar()->GetTabListMenu() == nullptr);
        const core::Float2 strip = Bed::Centre(Bed::Bounds(*bed.TabOf(u8"hierarchy")));
        bed.Over(strip);
        CHECK(bed.D().GetDropTarget() == bed.ViewOf(u8"hierarchy")->GetBar());
        Rect preview;
        REQUIRE(bed.Preview(preview));
        bed.Release(strip);
        const DockNode& into = *bed.controller.GetLayout().FindNode(bed.StackOf(u8"hierarchy"));
        REQUIRE(into.Panels.Size() == 3u);
        CHECK(into.Panels[1] == SV(u8"scene"));
        CHECK(into.Panels[2] == SV(u8"inspector"));
        // The central stack stays, emptied; the drag opened no list.
        CHECK(bed.controller.GetLayout().FindNode(bed.controller.GetLayout().CentralStack())->Panels.IsEmpty());
        CHECK_FALSE(central->HasClass(SV(u8"dock-torn")));
        CHECK(central->GetBar()->GetTabListMenu() == nullptr);
    }
    {
        Bed bed;
        const DockNodeId console = bed.StackOf(u8"console");
        GrabStack(bed, u8"console");
        // Into the hierarchy's bottom edge band: the stack beside it, below.
        const Rect h = Bed::Bounds(*bed.space->WidgetOf(bed.StackOf(u8"hierarchy")));
        const core::Float2 low{h.x + h.width * 0.5f, h.y + h.height - 40.0f}; // past the surface's own band
        bed.Over(low);
        bed.Release(low);
        CHECK(bed.StackOf(u8"console") == console); // the same stack, moved
        const DockLayout& layout = bed.controller.GetLayout();
        const DockNode& split = *layout.FindNode(layout.FindNode(console)->Parent);
        CHECK(split.Axis == DockAxis::Vertical);
        CHECK(split.Children[0] == bed.StackOf(u8"hierarchy"));
        CHECK(split.Children[1] == console);
    }
}

TEST_CASE("dock drop: a stack's grip, clicked, lists its tabs; the cross past it closes every closable panel of the stack")
{
    Bed bed;
    DockPanelDescription fixed;
    fixed.Id = core::String(u8"fixed");
    fixed.Closable = false;
    fixed.Factory = []() { return core::RefPtr<Node>(core::MakeRef<Panel>(core::DefaultAllocator())); };
    REQUIRE(bed.controller.Register(core::Move(fixed)));
    REQUIRE(bed.controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"fixed"), bed.StackOf(u8"scene"), 0); }).Ok());
    bed.Lay();
    TabBar& bar = *bed.ViewOf(u8"scene")->GetBar();
    const core::Float2 grip = Bed::Centre(Bed::Bounds(*bar.GetListButton()));
    bed.D().InjectMouseDown(grip, MouseButton::Left);
    bed.D().InjectMouseUp(grip, MouseButton::Left);
    Menu* list = bar.GetTabListMenu();
    REQUIRE(list != nullptr);
    CHECK(list->ItemCount() == 3);
    list->Close();

    REQUIRE(bar.GetCloseAllPart()->IsDisplayed());
    const core::Float2 cross = Bed::Centre(Bed::Bounds(*bar.GetCloseAllPart()));
    bed.D().InjectMouseDown(cross, MouseButton::Left);
    bed.D().InjectMouseUp(cross, MouseButton::Left);
    CHECK(bed.StackOf(u8"scene") == kNoDock);
    CHECK(bed.StackOf(u8"inspector") == kNoDock);
    CHECK(bed.StackOf(u8"fixed") == bed.controller.GetLayout().CentralStack()); // it cannot be closed
    bed.Lay();
    CHECK_FALSE(bed.ViewOf(u8"fixed")->GetBar()->GetCloseAllPart()->IsDisplayed()); // nothing left to close
}
