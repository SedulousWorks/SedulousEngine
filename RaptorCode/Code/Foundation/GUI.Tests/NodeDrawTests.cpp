// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Node draw tests: the tree renders through the DrawContext/VG seam.
// GPU-free (VGContext tessellates into a CPU vertex batch), so we assert geometry is
// produced and that visibility/alpha gate drawing.
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
    core::RefPtr<Node> MakeNode() { return core::MakeRef<Node>(core::DefaultAllocator()); }

    core::RefPtr<Node> MakePanel(core::Float2 size, core::Color color)
    {
        auto node = MakeNode();
        node->SetSize(size);
        node->SetBox(FilledBox(color));
        return node;
    }
}

TEST_CASE("node-draw: background renders through VG")
{
    auto panel = MakePanel(core::Float2{100.0f, 50.0f}, core::Color::Blue);
    vg::VGContext ctx;
    DrawContext dc{ctx};
    panel->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() + ctx.GetBatch().boxVertices.Size() > 0);
}

TEST_CASE("node-draw: empty node with no background draws nothing")
{
    auto node = MakeNode();
    node->SetSize(core::Float2{100.0f, 50.0f});
    vg::VGContext ctx;
    DrawContext dc{ctx};
    node->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}

TEST_CASE("node-draw: invisible node draws nothing")
{
    auto panel = MakePanel(core::Float2{100.0f, 50.0f}, core::Color::Blue);
    panel->SetVisible(false);
    vg::VGContext ctx;
    DrawContext dc{ctx};
    panel->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}

TEST_CASE("node-draw: fully transparent node draws nothing")
{
    auto panel = MakePanel(core::Float2{100.0f, 50.0f}, core::Color::Blue);
    panel->SetAlpha(0.0f);
    vg::VGContext ctx;
    DrawContext dc{ctx};
    panel->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() == 0);
}

TEST_CASE("node-draw: nested tree renders parent and children")
{
    auto root = MakePanel(core::Float2{200.0f, 200.0f}, core::Color::White);
    auto child = MakePanel(core::Float2{50.0f, 50.0f}, core::Color::Red);
    child->SetPosition(core::Float2{20.0f, 20.0f});
    root->AddChild(child.Get());

    vg::VGContext ctx;
    DrawContext dc{ctx};
    root->Draw(dc);
    // Both the root background and the child background contribute geometry.
    CHECK(ctx.GetBatch().vertices.Size() + ctx.GetBatch().boxVertices.Size() > 0);
}

TEST_CASE("node-draw: hidden child is skipped while parent still draws")
{
    auto root = MakePanel(core::Float2{100.0f, 100.0f}, core::Color::White);
    auto child = MakePanel(core::Float2{40.0f, 40.0f}, core::Color::Red);
    root->AddChild(child.Get());

    vg::VGContext ctxBoth;
    DrawContext dcBoth{ctxBoth};
    root->Draw(dcBoth);
    const core::usize withChild = ctxBoth.GetBatch().vertices.Size();

    child->SetVisible(false);
    vg::VGContext ctxRootOnly;
    DrawContext dcRootOnly{ctxRootOnly};
    root->Draw(dcRootOnly);
    const core::usize withoutChild = ctxRootOnly.GetBatch().vertices.Size();

    CHECK(withoutChild > 0);
    CHECK(withoutChild < withChild); // the hidden child contributed no geometry
}

TEST_CASE("node-draw: clip children does not crash and still draws")
{
    auto root = MakePanel(core::Float2{100.0f, 100.0f}, core::Color::White);
    root->SetClipChildren(true);
    auto child = MakePanel(core::Float2{200.0f, 200.0f}, core::Color::Red); // overflows
    root->AddChild(child.Get());

    vg::VGContext ctx;
    DrawContext dc{ctx};
    root->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() + ctx.GetBatch().boxVertices.Size() > 0);
}

