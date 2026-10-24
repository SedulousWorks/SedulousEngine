// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - incremental frames (G4 of Specs/vg-and-gui-lab.md): a frame restyles only the widgets
// that changed and their subtrees, lays out only the containers that asked, once per frame, and
// an idle GUI needs no frame at all.
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
    // A node whose drawing marks another node (one drawn before it) dirty, once.
    class Toucher : public Node
    {
    public:
        Node* Touches = nullptr;
        bool Done = false;

    protected:
        void OnDraw(DrawContext&, const Rect&) override
        {
            if (Touches != nullptr && !Done)
            {
                Done = true;
                Touches->Invalidate();
            }
        }
    };

    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Sec(double s) { return core::Duration::FromSeconds(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        w->SetSize(core::Float2{40.0f, 20.0f});
        return w;
    }

    // One host frame: styles, ticks, lays out and draws, as a sample does.
    void Frame(SceneRoot& root, StyleManager& styles)
    {
        styles.ApplyTree(root);
        root.GetContext().Update(Sec(0.016));
        vg::VGContext canvas;
        DrawContext dc{canvas};
        root.Draw(dc);
    }
}

TEST_CASE("incremental: many adds to a layout in a scene lay it out once, at the frame")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto column = Make<Panel>();
    column->SetSize(core::Float2{100.0f, 400.0f});
    root->AddChild(column.Get());
    root->UpdateLayout();

    core::Array<core::RefPtr<UIWidget>> rows{core::DefaultAllocator()};
    for (int i = 0; i < 10; ++i)
    {
        auto row = Widget(u8"row");
        column->AddChild(row.Get());
        rows.PushBack(row);
    }
    CHECK(rows[9]->GetPosition().y == doctest::Approx(0.0f)); // deferred: not yet placed
    CHECK(root->NeedsFrame());

    root->UpdateLayout();
    CHECK(root->LastLayoutCount() == 1u);
    CHECK(rows[9]->GetPosition().y == doctest::Approx(180.0f)); // nine 20-high rows above
    root->UpdateLayout();
    CHECK(root->LastLayoutCount() == 0u);
}

TEST_CASE("incremental: a layout outside a scene lays out when asked")
{
    auto column = Make<Panel>();
    column->SetSize(core::Float2{100.0f, 400.0f});
    auto a = Widget(u8"row");
    auto b = Widget(u8"row");
    column->AddChild(a.Get());
    column->AddChild(b.Get());
    CHECK(column->UpdateLayout() == 1u);
    CHECK(b->GetPosition().y == doctest::Approx(20.0f));
}

TEST_CASE("incremental: a child resized after a layout lays its container out again, once")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto column = Make<Panel>();
    column->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    column->SetSize(core::Float2{200.0f, 400.0f});
    root->AddChild(column.Get());
    auto a = Make<UIWidget>(); // unsized when the layout first meets them
    auto b = Make<UIWidget>();
    a->SetTag(SV(u8"item"));
    b->SetTag(SV(u8"item"));
    column->AddChild(a.Get());
    column->AddChild(b.Get());
    root->UpdateLayout();
    CHECK(b->GetPosition().y == doctest::Approx(0.0f)); // both empty, stacked at the top

    // The sheet sizes them afterwards (a frame's restyle): the flex takes the new basis.
    StyleManager styles(CSSParser::Parse(SV(u8"item { width: 100px; height: 40px; }")));
    styles.ApplyTree(*root.Get());
    root->UpdateLayout();
    CHECK(b->GetPosition().y == doctest::Approx(40.0f));
    CHECK(b->GetSize().y == doctest::Approx(40.0f));

    root->UpdateLayout(); // its own writes asked for nothing more
    CHECK(root->LastLayoutCount() == 0u);
}

TEST_CASE("incremental: a child displayed or not lays its container out again")
{
    // The showcase's panels: one shown in place of another after the first layout lands in the
    // slot the other had, not wherever it was left.
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto column = Make<Panel>();
    column->SetSize(core::Float2{200.0f, 400.0f});
    root->AddChild(column.Get());
    auto title = Widget(u8"title");
    auto menu = Widget(u8"menu");
    auto settings = Widget(u8"settings");
    column->AddChild(title.Get());
    column->AddChild(menu.Get());
    column->AddChild(settings.Get());
    settings->SetDisplayed(false);
    root->UpdateLayout();
    CHECK(menu->GetPosition().y == doctest::Approx(20.0f));

    menu->SetDisplayed(false);
    settings->SetDisplayed(true);
    root->UpdateLayout();
    CHECK(root->LastLayoutCount() >= 1u);
    CHECK(settings->GetPosition().y == doctest::Approx(20.0f)); // under the title, where the menu was
    root->UpdateLayout();
    CHECK(root->LastLayoutCount() == 0u);
}

TEST_CASE("incremental: a change under a node that was hidden through a frame still asks for a frame")
{
    // A hidden node is not drawn, so it keeps its invalidation: a change under it later must still
    // reach the root (pooled item rows are hidden and shown again; their changes went unseen).
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto row = Widget(u8"panel");
    auto label = Make<Label>();
    root->AddChild(row.Get());
    row->AddChild(label.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"panel { opacity: 1; }")));
    row->SetDisplayed(false);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());
    row->SetDisplayed(true);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());
    row->SetDisplayed(false);
    Frame(*root.Get(), styles);
    label->SetText(SV(u8"changed while hidden"));
    Frame(*root.Get(), styles);
    row->SetDisplayed(true);
    label->SetText(SV(u8"changed again, shown"));
    styles.ApplyTree(*root.Get());
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame());
}

TEST_CASE("incremental: a list's insert above and a click's selection each ask for a frame")
{
    StringListModel model; // outlives the scene, whose list is its client
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    for (int i = 0; i < 50; ++i)
        model.AddItem(core::Format(u8"row {}", i).AsView());
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    StyleManager styles(CSSParser::Parse(SV(u8"listview { opacity: 1; }")));
    Frame(*root.Get(), styles);
    list->ScrollTo(core::Float2{0.0f, 400.0f}, ScrollBehavior::Instant);
    Frame(*root.Get(), styles);
    list->ScrollTo(core::Float2{0.0f, 0.0f}, ScrollBehavior::Instant); // rows released and taken again
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());

    model.InsertItem(0, SV(u8"inserted"));
    root->GetContext().Update(Sec(0.016));
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame());
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());

    root->GetEventDispatcher()->InjectMouseDown(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    root->GetEventDispatcher()->InjectMouseUp(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    styles.ApplyTree(*root.Get());
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame());
}

TEST_CASE("incremental: a node marked during the frame's drawing does not stop later changes under it asking for a frame")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto a = Widget(u8"panel");
    auto label = Make<Label>();
    a->AddChild(label.Get());
    root->AddChild(a.Get());
    auto toucher = core::MakeRef<Toucher>(core::DefaultAllocator());
    toucher->SetSize(core::Float2{10.0f, 10.0f});
    toucher->Touches = a.Get(); // drawn after `a`, it marks `a` again
    root->AddChild(toucher.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"panel { opacity: 1; }")));
    Frame(*root.Get(), styles); // `a` is marked again after it was drawn
    // A host skips a frame the root does not need, so `a` stays marked; a change under it must
    // still reach the root.
    label->SetText(SV(u8"a change under it"));
    styles.ApplyTree(*root.Get());
    (void)root->UpdateLayout(); // as a host does before it asks
    CHECK(root->NeedsFrame());
}

TEST_CASE("incremental: an animation on a page out of view asks for no frames; one in view does; hiding asks for one")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto page = Widget(u8"panel");
    root->AddChild(page.Get());
    auto bar = Make<ProgressBar>();
    bar->SetSize(core::Float2{100.0f, 10.0f});
    page->AddChild(bar.Get());
    bar->SetIndeterminate(true); // sweeps on the GUI's clock
    StyleManager styles(CSSParser::Parse(SV(u8"panel { opacity: 1; }")));
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame()); // shown: its sweep moves

    page->SetDisplayed(false);
    (void)root->UpdateLayout();
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    (void)root->UpdateLayout();
    CHECK_FALSE(root->NeedsFrame()); // out of view: nothing on screen moves

    page->SetDisplayed(true);
    (void)root->UpdateLayout();
    Frame(*root.Get(), styles);
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame()); // back in view, sweeping again

    auto still = Widget(u8"panel");
    root->AddChild(still.Get());
    bar->SetIndeterminate(false);
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    (void)root->UpdateLayout();
    REQUIRE_FALSE(root->NeedsFrame());
    still->SetVisible(false); // what drew it must draw again
    CHECK(root->NeedsFrame());
}
