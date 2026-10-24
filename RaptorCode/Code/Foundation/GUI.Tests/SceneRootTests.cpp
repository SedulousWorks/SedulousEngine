// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - SceneRoot coordinator tests: root lookup, deferred Close via the
// MutationQueue, and the update loop draining tree edits.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.vg;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<SceneRoot> MakeScene()
    {
        return core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    }
    core::RefPtr<Node> MakeNode() { return core::MakeRef<Node>(core::DefaultAllocator()); }
}

TEST_CASE("scene: nodes find the coordinator by walking to the root")
{
    auto root = MakeScene();
    auto mid = MakeNode();
    auto leaf = MakeNode();
    root->AddChild(mid.Get());
    mid->AddChild(leaf.Get());

    CHECK(leaf->GetRootNode() == root.Get());
    CHECK(leaf->GetActionManager() == root->GetActionManager());
    CHECK(leaf->GetMutationQueue() == root->GetMutationQueue());
}

TEST_CASE("scene: Close defers removal until update drains the queue")
{
    auto root = MakeScene();
    auto child = MakeNode();
    root->AddChild(child.Get());

    child->Close();
    CHECK(root->ChildCount() == 1); // not yet - deferred
    CHECK_FALSE(root->GetMutationQueue()->IsEmpty());

    root->GetContext().Update(core::Duration::FromSeconds(0.016));
    CHECK(root->ChildCount() == 0); // drained
    CHECK(root->GetMutationQueue()->IsEmpty());
}

TEST_CASE("scene: Close without a coordinator removes immediately")
{
    auto parent = MakeNode(); // plain Node, not a SceneRoot
    auto child = MakeNode();
    parent->AddChild(child.Get());

    child->Close();
    CHECK(parent->ChildCount() == 0); // immediate fallback
}

TEST_CASE("scene: update with nothing queued is harmless")
{
    auto root = MakeScene();
    root->GetContext().Update(core::Duration::FromSeconds(0.016));
    CHECK(root->GetActionManager()->IsEmpty());
    CHECK(root->GetMutationQueue()->IsEmpty());
}

TEST_CASE("scene: OnUpdate hook fires each update")
{
    struct CountingScene : SceneRoot
    {
        explicit CountingScene(core::RefPtr<GUIContext> gui) : SceneRoot(core::Move(gui)) {}
        int ticks = 0;
        void OnUpdate(core::Duration) override { ++ticks; }
    };
    auto gui = core::MakeRef<GUIContext>(core::DefaultAllocator());
    auto scene = core::MakeRef<CountingScene>(core::DefaultAllocator(), gui);
    gui->Update(core::Duration::FromSeconds(0.016));
    gui->Update(core::Duration::FromSeconds(0.016));
    CHECK(scene->ticks == 2);
}

TEST_CASE("scene: a node finds its GUI's root; a detached subtree has none but keeps its top")
{
    auto root = MakeScene();
    auto mid = MakeNode();
    auto leaf = MakeNode();
    root->AddChild(mid.Get());
    mid->AddChild(leaf.Get());
    CHECK(leaf->GetSceneRoot() == root.Get());
    CHECK(root->GetSceneRoot() == root.Get());

    mid->RemoveFromParent();
    CHECK(leaf->GetSceneRoot() == nullptr);   // in no GUI now
    CHECK(leaf->GetRootNode() == mid.Get());  // the detached subtree's top
}

TEST_CASE("scene: each root has its own display scale; its tree lays out in logical units")
{
    // Two windows on monitors of different density, the same tree in each.
    auto standard = MakeScene();
    auto dense = MakeScene();
    standard->SetViewportSize(core::Float2{800.0f, 600.0f});
    dense->SetViewportSize(core::Float2{800.0f, 600.0f});
    dense->SetDisplayScale(2.0f);
    CHECK(standard->GetSize().x == doctest::Approx(800.0f));
    CHECK(dense->GetSize().x == doctest::Approx(400.0f)); // 800 device pixels at 2x
    CHECK(dense->GetSize().y == doctest::Approx(300.0f));
    CHECK(dense->GetMediaContext().Width == doctest::Approx(400.0f));
    CHECK(dense->GetMediaContext().Dpi == doctest::Approx(192.0f));

    // A button at logical (10, 10), 40 x 20: at 1x it covers device 10..50, at 2x 20..100.
    const auto button = [](SceneRoot& root)
    {
        auto b = core::MakeRef<Button>(core::DefaultAllocator());
        b->SetPosition(core::Float2{10.0f, 10.0f});
        b->SetSize(core::Float2{40.0f, 20.0f});
        root.AddChild(b.Get());
        return b;
    };
    auto a = button(*standard);
    auto b = button(*dense);
    // Input arrives in device pixels and hit-tests through the root's scale.
    CHECK(standard->OverFind(core::Float2{30.0f, 20.0f}) == a.Get());
    CHECK(standard->OverFind(core::Float2{70.0f, 40.0f}) != a.Get()); // past 50 at 1x
    CHECK(dense->OverFind(core::Float2{70.0f, 40.0f}) == b.Get());    // inside 20..100 at 2x
    CHECK(dense->OverFind(core::Float2{15.0f, 15.0f}) != b.Get());    // before 20 at 2x

    // Drawing goes through the same scale: the dense root's box lands at twice the place.
    NodeBox box;
    box.BackgroundColor = core::Color{1.0f, 0.0f, 0.0f, 1.0f};
    b->SetBox(core::Move(box));
    foundation::vg::VGContext canvas;
    canvas.SetAnalyticBoxes(true);
    DrawContext dc{canvas};
    dense->Draw(dc);
    REQUIRE(canvas.GetBatch().boxVertices.Size() == 6u);
    CHECK(canvas.GetBatch().boxVertices[0].halfSize.x == doctest::Approx(40.0f)); // 40 logical -> 80 device, halved
}

TEST_CASE("scene: media queries see the root's logical size and its density")
{
    StyleSheet sheet = CSSParser::Parse(core::StringView(
        u8"@media (min-resolution: 2dppx) { label { opacity: 0.5; } } "
        u8"@media (max-width: 500) { label { color: red; } }"));
    auto dense = MakeScene();
    dense->SetViewportSize(core::Float2{800.0f, 600.0f});
    dense->SetDisplayScale(2.0f);
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    dense->AddChild(label.Get());
    const ResolvedStyle atDense = sheet.Resolve(*label.Get(), dense->GetMediaContext());
    CHECK(atDense.Has(core::StringView(u8"opacity"))); // 192 dpi >= 2dppx
    CHECK(atDense.Has(core::StringView(u8"color")));   // 400 logical <= 500

    auto standard = MakeScene();
    standard->SetViewportSize(core::Float2{800.0f, 600.0f});
    const ResolvedStyle atStandard = sheet.Resolve(*label.Get(), standard->GetMediaContext());
    CHECK_FALSE(atStandard.Has(core::StringView(u8"opacity")));
    CHECK_FALSE(atStandard.Has(core::StringView(u8"color"))); // 800 logical
}
