// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the Splitter (D0 of Specs/gui-lab-evolution-3.md): panes laid out by their weights with a
// handle between each two; minimums held (a sheet's, never the content's), the rest shared again;
// when even the minimums do not fit, each has its own and the end is clipped; a handle moves the two
// panes beside it alone, by the pointer and the keys; a pane that goes gives its share to its
// neighbours; vertical, right to left, markup, and a handle read as a separator.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::RefPtr<Panel> Pane(f32 minWidth = -1.0f)
    {
        core::RefPtr<Panel> pane = core::MakeRef<Panel>(core::DefaultAllocator());
        if (minWidth >= 0.0f)
            pane->EditLayoutStyle([minWidth](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(minWidth); });
        return pane;
    }

    // A root with a splitter 300 by 100 in it, its panes added.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Splitter> splitter = core::MakeRef<Splitter>(core::DefaultAllocator());
        core::Array<core::RefPtr<Panel>> panes;

        explicit Bed(usize count, f32 width = 300.0f)
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            splitter->EditLayoutStyle([width](LayoutStyle& s) {
                s.Width = LayoutLength::Px(width);
                s.Height = LayoutLength::Px(100.0f);
            });
            for (usize i = 0; i < count; ++i)
            {
                panes.PushBack(Pane());
                splitter->AddChild(panes.Back().Get());
            }
            root->AddChild(splitter.Get());
            Lay();
        }
        void Lay() { root->UpdateLayout(); }
        [[nodiscard]] f32 X(usize pane) const { return panes[pane]->GetPosition().x; }
        [[nodiscard]] f32 W(usize pane) const { return panes[pane]->GetSize().x; }
    };
}

TEST_CASE("splitter: panes by their weights, a handle between each two, in that order")
{
    Bed bed(3);
    REQUIRE(bed.splitter->GetPaneCount() == 3u);
    REQUIRE(bed.splitter->ChildCount() == 5u); // pane, handle, pane, handle, pane
    CHECK(bed.splitter->GetChildAt(0) == bed.panes[0].Get());
    CHECK(Cast<SplitterHandle>(bed.splitter->GetChildAt(1)) != nullptr);
    CHECK(bed.splitter->GetChildAt(2) == bed.panes[1].Get());
    // 300 less two handles of 6: 96 each.
    CHECK(bed.W(0) == doctest::Approx(96.0f));
    CHECK(bed.W(1) == doctest::Approx(96.0f));
    CHECK(bed.X(1) == doctest::Approx(102.0f));
    CHECK(bed.X(2) == doctest::Approx(204.0f));
    CHECK(bed.panes[0]->GetSize().y == doctest::Approx(100.0f));

    const f32 shares[3] = {1.0f, 2.0f, 1.0f};
    bed.splitter->SetWeights(core::Span<const f32>(shares, 3));
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(72.0f));
    CHECK(bed.W(1) == doctest::Approx(144.0f));
    CHECK(bed.splitter->GetWeights()[1] == doctest::Approx(0.5f));
}

TEST_CASE("splitter: a pane below its minimum holds it and the others share the rest; past the room, each its own, clipped")
{
    Bed bed(3);
    bed.panes[0]->EditLayoutStyle([](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(150.0f); });
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(150.0f));
    CHECK(bed.W(1) == doctest::Approx(69.0f)); // (288 - 150) / 2
    CHECK(bed.W(2) == doctest::Approx(69.0f));
    // Content wider than its share is no minimum: the user alone moves a handle (the pane wraps or
    // clips it where it stands).
    core::RefPtr<Panel> wide = core::MakeRef<Panel>(core::DefaultAllocator());
    wide->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(120.0f); });
    bed.panes[2]->AddChild(wide.Get());
    bed.Lay();
    CHECK(bed.W(2) == doctest::Approx(69.0f));
    CHECK(bed.W(1) == doctest::Approx(69.0f));
    bed.panes[2]->EditLayoutStyle([](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(120.0f); });
    bed.Lay();
    CHECK(bed.W(2) == doctest::Approx(120.0f));
    CHECK(bed.W(1) == doctest::Approx(18.0f)); // what is left
    // Minimums past the room: each has its own; what passes the end is clipped, never squeezed.
    bed.panes[1]->EditLayoutStyle([](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(100.0f); });
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(150.0f));
    CHECK(bed.W(1) == doctest::Approx(100.0f));
    CHECK(bed.W(2) == doctest::Approx(120.0f));
    CHECK(bed.splitter->GetLayoutStyle().OverflowX == Overflow::Hidden);
}

TEST_CASE("splitter: a handle moves the two panes beside it alone, as far as their minimums let it")
{
    Bed bed(3);
    bed.panes[1]->EditLayoutStyle([](LayoutStyle& s) { s.MinWidth = LayoutLength::Px(40.0f); });
    bed.Lay();
    int resized = 0;
    bed.splitter->SetOnResized([&resized]() { ++resized; });
    bed.splitter->MoveHandleTo(0, 120.0f); // the first pane to 120
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(120.0f));
    CHECK(bed.W(1) == doctest::Approx(72.0f));
    CHECK(bed.W(2) == doctest::Approx(96.0f)); // untouched
    CHECK(resized == 1);
    bed.splitter->MoveHandleTo(0, 400.0f); // as far as the middle pane's minimum
    bed.Lay();
    CHECK(bed.W(1) == doctest::Approx(40.0f));
    CHECK(bed.W(0) == doctest::Approx(152.0f));
    CHECK(bed.W(2) == doctest::Approx(96.0f));
}

TEST_CASE("splitter: a pane that goes gives its share to its neighbours; one that comes takes the others' average")
{
    Bed bed(3);
    const f32 shares[3] = {1.0f, 2.0f, 3.0f};
    bed.splitter->SetWeights(core::Span<const f32>(shares, 3));
    bed.Lay();
    bed.panes[1]->RemoveFromParent(); // its 2 goes to the 1 and the 3, a quarter and three quarters
    bed.Lay();
    REQUIRE(bed.splitter->GetPaneCount() == 2u);
    CHECK(bed.splitter->ChildCount() == 3u);
    CHECK(bed.splitter->GetWeights()[0] == doctest::Approx(1.5f / 6.0f));
    CHECK(bed.splitter->GetWeights()[1] == doctest::Approx(4.5f / 6.0f));
    core::RefPtr<Panel> more = Pane();
    bed.splitter->AddChild(more.Get());
    bed.Lay();
    REQUIRE(bed.splitter->GetPaneCount() == 3u);
    CHECK(bed.splitter->ChildCount() == 5u);
    CHECK(Cast<SplitterHandle>(bed.splitter->GetChildAt(3)) != nullptr); // before the new pane
    CHECK(bed.splitter->GetChildAt(4) == more.Get());
    // The newcomer's share is its given one (the third, 3) when it has one.
    CHECK(bed.splitter->GetWeights()[2] == doctest::Approx(3.0f / 9.0f));
}

TEST_CASE("splitter: vertical, and right to left from the right")
{
    Bed bed(2);
    bed.splitter->SetAxis(SplitterAxis::Vertical);
    bed.Lay();
    CHECK(bed.panes[0]->GetSize().y == doctest::Approx(47.0f)); // (100 - 6) / 2
    CHECK(bed.panes[1]->GetPosition().y == doctest::Approx(53.0f));
    CHECK(bed.panes[0]->GetSize().x == doctest::Approx(300.0f));
    CHECK(bed.splitter->GetHandle(0)->HasClass(core::StringView(u8"vertical")));

    Bed rtl(2);
    rtl.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    rtl.Lay();
    CHECK(rtl.X(0) == doctest::Approx(153.0f)); // the first pane at the right
    CHECK(rtl.X(1) == doctest::Approx(0.0f));
    rtl.splitter->MoveHandleTo(0, 100.0f); // the handle dragged left: the first (right) pane grows
    rtl.Lay();
    CHECK(rtl.W(0) == doctest::Approx(194.0f));
    CHECK(rtl.W(1) == doctest::Approx(100.0f));
}

TEST_CASE("splitter: a handle moves by the keys and the pointer, and a double click gives the shares back")
{
    Bed bed(2);
    SplitterHandle* handle = bed.splitter->GetHandle(0);
    REQUIRE(handle != nullptr);
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    handle->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(155.0f)); // 147 + 8
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Left), KeyModShift);
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(107.0f)); // less 48
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Home)); // as far toward the start as it goes
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(0.0f));

    // A drag: pressed in its middle, moved 50 to the right of where it now is.
    const Rect at = handle->GetScreenBounds();
    const core::Float2 middle{at.x + at.width * 0.5f, at.y + at.height * 0.5f};
    d.InjectMouseMove(middle);
    d.InjectMouseDown(middle, MouseButton::Left);
    d.InjectMouseMove(core::Float2{middle.x + 50.0f, middle.y});
    d.InjectMouseUp(core::Float2{middle.x + 50.0f, middle.y}, MouseButton::Left);
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(50.0f));
    // It keeps under the pointer through many moves, wherever the splitter stands on the screen.
    bed.root->SetPadding(Thickness{40.0f, 30.0f, 0.0f, 0.0f});
    bed.Lay();
    const Rect from = handle->GetScreenBounds();
    core::Float2 pointer{from.x + 2.0f, from.y + 10.0f};
    d.InjectMouseMove(pointer);
    d.InjectMouseDown(pointer, MouseButton::Left);
    for (int step = 0; step < 10; ++step)
    {
        pointer.x += 7.0f;
        d.InjectMouseMove(pointer);
        bed.Lay();
        CHECK(handle->GetScreenBounds().x == doctest::Approx(pointer.x - 2.0f));
    }
    d.InjectMouseUp(pointer, MouseButton::Left);
    CHECK(bed.W(0) == doctest::Approx(120.0f)); // 50 + 70

    bed.splitter->ResetWeights(); // what a double click does
    bed.Lay();
    CHECK(bed.W(0) == doctest::Approx(147.0f));
}

TEST_CASE("splitter: from markup, and each handle read as a separator with where it stands")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> loaded =
        loader.LoadFromString(core::StringView(u8R"(<Splitter axis="vertical" weights="1 3"><Panel/><Panel/></Splitter>)"));
    REQUIRE(loaded.Get() != nullptr);
    auto* splitter = Cast<Splitter>(loaded.Get());
    REQUIRE(splitter != nullptr);
    CHECK(splitter->GetAxis() == SplitterAxis::Vertical);
    REQUIRE(splitter->GetPaneCount() == 2u);
    CHECK(splitter->GetWeights()[1] == doctest::Approx(0.75f));

    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 406.0f});
    splitter->EditLayoutStyle([](LayoutStyle& s) {
        s.Width = LayoutLength::Px(400.0f);
        s.Height = LayoutLength::Px(406.0f); // 400 for the panes, a quarter above the handle
    });
    root->AddChild(loaded.Get());
    root->UpdateLayout();
    const AccessTreeUpdate tree = root->GetContext().BuildAccessTree(*root.Get());
    const AccessNode* separator = nullptr;
    for (const AccessNode& n : tree.Nodes)
        if (n.Role == AccessRole::Separator)
            separator = &n;
    REQUIRE(separator != nullptr);
    CHECK(separator->Max == doctest::Approx(100.0));
    CHECK(separator->Value == core::StringView(u8"25"));
    CHECK((separator->States & AccessFocusable) != 0);
}
