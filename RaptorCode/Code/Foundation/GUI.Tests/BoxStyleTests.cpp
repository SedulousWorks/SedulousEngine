// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the box properties from sheets (G2 of Specs/vg-and-gui-lab.md), per property: several box
// shadows, transform functions about an origin, gradients with angles and stops, and a border per
// side; each parsed, applied to the node, and drawn.
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
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // A 100 x 50 box styled by `css` (its rules on `box`).
    core::RefPtr<UIWidget> Styled(const char8_t* css)
    {
        auto w = core::MakeRef<UIWidget>(core::DefaultAllocator());
        w->SetTag(SV(u8"box"));
        w->SetSize(core::Float2{100.0f, 50.0f});
        StyleSheet sheet = CSSParser::Parse(SV(css));
        ApplyStyle(*w.Get(), sheet.Resolve(*w.Get()));
        return w;
    }

    core::Float2 Mapped(const Node& node, core::Float2 p) { return node.GetTransform().TransformPoint(p); }
}

TEST_CASE("box-style: several box shadows, outer and inset, with spread")
{
    auto w = Styled(u8"box { box-shadow: 2px 4px 6px 1px rgba(0,0,0,0.5), inset 0 0 3px #ff0000; }");
    const NodeBox& box = w->GetBox();
    REQUIRE(box.Shadows.Size() == 2u);
    CHECK(box.Shadows[0].Offset.x == doctest::Approx(2.0f));
    CHECK(box.Shadows[0].Offset.y == doctest::Approx(4.0f));
    CHECK(box.Shadows[0].Blur == doctest::Approx(6.0f));
    CHECK(box.Shadows[0].Spread == doctest::Approx(1.0f));
    CHECK(box.Shadows[0].ShadowColor.a == doctest::Approx(0.5f));
    CHECK_FALSE(box.Shadows[0].Inset);
    CHECK(box.Shadows[1].Inset);
    CHECK(box.Shadows[1].ShadowColor.r == doctest::Approx(1.0f));

    // Drawn: one box-shadow draw per shadow (the outer under the box, the inset over its fill).
    vg::VGContext canvas;
    DrawContext dc{canvas};
    w->Draw(dc);
    core::usize shadowDraws = 0;
    for (const vg::VGCommand& cmd : canvas.GetBatch().commands)
        shadowDraws += cmd.drawMode == vg::VGDrawMode::BoxShadow ? 1u : 0u;
    CHECK(shadowDraws >= 1u);

    // none clears them; a malformed list is not applied.
    CHECK(Styled(u8"box { box-shadow: none; }")->GetBox().Shadows.IsEmpty());
    CHECK(Styled(u8"box { box-shadow: 1px; }")->GetBox().Shadows.IsEmpty());
}

TEST_CASE("box-style: transform functions apply left to right about the origin")
{
    // rotate(90deg) about the centre (50, 25): the top-left corner goes to (75, -25).
    {
        auto w = Styled(u8"box { transform: rotate(90deg); }");
        const core::Float2 p = Mapped(*w, core::Float2{0.0f, 0.0f});
        CHECK(p.x == doctest::Approx(75.0f));
        CHECK(p.y == doctest::Approx(-25.0f));
    }
    // A translation in percentages of the box's own size, and in pixels.
    {
        auto w = Styled(u8"box { transform: translate(50%, 10px); }");
        const core::Float2 p = Mapped(*w, core::Float2{0.0f, 0.0f});
        CHECK(p.x == doctest::Approx(50.0f));
        CHECK(p.y == doctest::Approx(10.0f));
        // The percentage follows the size.
        w->SetSize(core::Float2{200.0f, 50.0f});
        CHECK(Mapped(*w, core::Float2{0.0f, 0.0f}).x == doctest::Approx(100.0f));
    }
    // scale about the top-left corner, then skew about it.
    {
        auto w = Styled(u8"box { transform: scale(2, 3); transform-origin: left top; }");
        const core::Float2 p = Mapped(*w, core::Float2{10.0f, 10.0f});
        CHECK(p.x == doctest::Approx(20.0f));
        CHECK(p.y == doctest::Approx(30.0f));
    }
    {
        auto w = Styled(u8"box { transform: skewX(45deg); transform-origin: 0 0; }");
        const core::Float2 p = Mapped(*w, core::Float2{0.0f, 10.0f});
        CHECK(p.x == doctest::Approx(10.0f)); // x moves by tan(45deg) * y
        CHECK(p.y == doctest::Approx(10.0f));
    }
    // Order: translate then scale differs from scale then translate.
    {
        auto a = Styled(u8"box { transform: translate(10px, 0) scale(2); transform-origin: 0 0; }");
        auto b = Styled(u8"box { transform: scale(2) translate(10px, 0); transform-origin: 0 0; }");
        CHECK(Mapped(*a, core::Float2{0.0f, 0.0f}).x == doctest::Approx(10.0f));
        CHECK(Mapped(*b, core::Float2{0.0f, 0.0f}).x == doctest::Approx(20.0f));
    }
    // matrix(), and none.
    {
        auto w = Styled(u8"box { transform: matrix(1, 0, 0, 1, 5, 6); }");
        const core::Float2 p = Mapped(*w, core::Float2{0.0f, 0.0f});
        CHECK(p.x == doctest::Approx(5.0f));
        CHECK(p.y == doctest::Approx(6.0f));
        CHECK(Styled(u8"box { transform: none; }")->GetTransform().IsIdentity());
    }
    // A transform moves hit testing with the drawing.
    {
        auto w = Styled(u8"box { transform: translate(200px, 0); }");
        CHECK(w->PointInside(core::Float2{250.0f, 25.0f}));
        CHECK_FALSE(w->PointInside(core::Float2{50.0f, 25.0f}));
    }
}

TEST_CASE("box-style: gradients from sheets take angles, sides and stops")
{
    {
        auto w = Styled(u8"box { background: linear-gradient(90deg, red, blue 75%), #00ff00; }");
        const NodeBox& box = w->GetBox();
        CHECK(box.BackgroundColor.g == doctest::Approx(1.0f)); // the bottom layer's colour
        REQUIRE(box.Layers.Size() == 1u);
        const BoxGradient& g = box.Layers[0].Gradient;
        CHECK(g.Kind == BoxGradientKind::Linear);
        CHECK(g.Angle == doctest::Approx(1.5707963f));
        REQUIRE(g.Stops.Size() == 2u);
        CHECK(g.Stops[0].offset == doctest::Approx(0.0f));
        CHECK(g.Stops[1].offset == doctest::Approx(0.75f));
        CHECK(g.Stops[1].color.b == doctest::Approx(1.0f));
    }
    {
        // `to bottom right` points down and right (135deg); unplaced stops space evenly.
        auto w = Styled(u8"box { background-image: linear-gradient(to bottom right, red, #00ff00, blue); }");
        const BoxGradient& g = w->GetBox().Layers[0].Gradient;
        CHECK(g.Angle == doctest::Approx(2.3561945f));
        REQUIRE(g.Stops.Size() == 3u);
        CHECK(g.Stops[1].offset == doctest::Approx(0.5f));
    }
    {
        auto w = Styled(u8"box { background-image: radial-gradient(circle, white, black), "
                        u8"repeating-conic-gradient(from 90deg, red 0%, blue 25%); }");
        const NodeBox& box = w->GetBox();
        REQUIRE(box.Layers.Size() == 2u);
        CHECK(box.Layers[0].Gradient.Kind == BoxGradientKind::Radial);
        CHECK(box.Layers[1].Gradient.Kind == BoxGradientKind::Conic);
        CHECK(box.Layers[1].Gradient.Repeating);
        CHECK(box.Layers[1].Gradient.Angle == doctest::Approx(1.5707963f));
    }
    // A gradient with a single stop, or an unknown direction, is not applied.
    CHECK(Styled(u8"box { background-image: linear-gradient(red); }")->GetBox().Layers.IsEmpty());
    CHECK(Styled(u8"box { background-image: linear-gradient(to nowhere, red, blue); }")->GetBox().Layers.IsEmpty());

    // Drawn through a gradient fill.
    auto w = Styled(u8"box { background-image: linear-gradient(red, blue); }");
    vg::VGContext canvas;
    DrawContext dc{canvas};
    w->Draw(dc);
    CHECK(canvas.GetBatch().vertices.Size() > 0u);
}

TEST_CASE("box-style: a border per side, each its own width, style and colour")
{
    auto w = Styled(u8"box { border: 1px solid #808080; border-top: 3px solid red; "
                    u8"border-left: 4px dashed blue; border-bottom-style: none; border-radius: 2 4 6 8; }");
    const NodeBox& box = w->GetBox();
    CHECK(box.BorderWidths.top == doctest::Approx(3.0f));
    CHECK(box.BorderWidths.right == doctest::Approx(1.0f));
    CHECK(box.BorderWidths.bottom == doctest::Approx(0.0f)); // style none: no border
    CHECK(box.BorderWidths.left == doctest::Approx(4.0f));
    CHECK(box.BorderColors.top.r == doctest::Approx(1.0f));
    CHECK(box.BorderColors.left.b == doctest::Approx(1.0f));
    CHECK(box.BorderColors.right.r == doctest::Approx(128.0f / 255.0f));
    CHECK(box.Radii.topLeft == doctest::Approx(2.0f));
    CHECK(box.Radii.topRight == doctest::Approx(4.0f));
    CHECK(box.Radii.bottomRight == doctest::Approx(6.0f));
    CHECK(box.Radii.bottomLeft == doctest::Approx(8.0f));

    // border-width and border-color take one to four values, in CSS's side order.
    auto sides = Styled(u8"box { border-style: solid; border-width: 1 2 3; border-color: red blue; }");
    CHECK(sides->GetBox().BorderWidths.left == doctest::Approx(2.0f)); // three values: left = right
    CHECK(sides->GetBox().BorderWidths.bottom == doctest::Approx(3.0f));
    CHECK(sides->GetBox().BorderColors.bottom.r == doctest::Approx(1.0f)); // two values: bottom = top
    CHECK(sides->GetBox().BorderColors.left.b == doctest::Approx(1.0f));

    // A radius in percent is of the box's smaller side.
    CHECK(Styled(u8"box { border-radius: 50%; background-color: red; }")->GetBox().Radii.topLeft == doctest::Approx(25.0f));
}

TEST_CASE("box-style: a repeating gradient repeats the span of its stops")
{
    // Stops over the first quarter: the line is cut to that quarter, so across the box the
    // gradient parameter runs to 4 (four repeats), on VG's repeat spread.
    auto w = Styled(u8"box { background: repeating-linear-gradient(90deg, red 0%, blue 25%); }");
    vg::VGContext canvas;
    DrawContext dc{canvas};
    w->Draw(dc);
    bool repeat = false;
    for (const vg::VGCommand& cmd : canvas.GetBatch().commands)
        repeat = repeat || cmd.gradientSpread == vg::VGGradientSpread::Repeat;
    CHECK(repeat);
    core::f32 maxU = 0.0f;
    for (const vg::VGVertex& v : canvas.GetBatch().vertices)
        maxU = core::Max(maxU, v.texCoord.x);
    CHECK(maxU == doctest::Approx(4.0f).epsilon(0.05));
}
