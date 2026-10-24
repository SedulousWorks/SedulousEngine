// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - effects through VG (G4 of Specs/vg-and-gui-lab.md): filter and backdrop-filter blurs,
// mix-blend-mode, group opacity through layers, and overflow clipping to rounded corners; each
// parsed, applied, animated where it moves, and drawn.
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

    core::RefPtr<UIWidget> Box(const char8_t* tag)
    {
        auto w = core::MakeRef<UIWidget>(core::DefaultAllocator());
        w->SetTag(SV(tag));
        w->SetSize(core::Float2{100.0f, 50.0f});
        return w;
    }

    void Apply(UIWidget& w, const char8_t* css)
    {
        StyleSheet sheet = CSSParser::Parse(SV(css));
        ApplyStyle(w, sheet.Resolve(w));
    }

    // `w` drawn into a canvas with layers (and, when asked, stencil fills) on.
    void DrawWith(Node& node, vg::VGContext& canvas, bool stencil = false)
    {
        canvas.SetLayers(true);
        canvas.SetStencilFills(stencil);
        DrawContext dc{canvas};
        node.Draw(dc);
    }
}

TEST_CASE("effects: filter lists parse blur and refuse what VG cannot draw")
{
    const auto parsed = ParseFilters(SV(u8"blur(4px) blur(3px)"));
    REQUIRE(parsed.HasValue());
    REQUIRE(parsed.Value().Size() == 2u);
    CHECK(parsed.Value()[0].Amount.Value == doctest::Approx(4.0f));
    CHECK(ParseFilters(SV(u8"none")).Value().IsEmpty());
    CHECK(ParseFilters(SV(u8"blur()")).Value()[0].Amount.Value == doctest::Approx(0.0f));
    CHECK_FALSE(ParseFilters(SV(u8"blur(-1px)")).HasValue());
    CHECK_FALSE(ParseFilters(SV(u8"blur(10%)")).HasValue());
    CHECK_FALSE(ParseFilters(SV(u8"brightness(2)")).HasValue());
    CHECK_FALSE(ParseFilters(SV(u8"blur(2px) sepia(1)")).HasValue());
}

TEST_CASE("effects: filters interpolate, from none through blur(0)")
{
    StyleValue none, blur;
    REQUIRE(ParseStyleValue(StyleGrammar::Filters, SV(u8"none"), none));
    REQUIRE(ParseStyleValue(StyleGrammar::Filters, SV(u8"blur(8px)"), blur));
    const StyleValue half = InterpolateStyleValue(none, blur, 0.5f);
    REQUIRE(half.Filters.Size() == 1u);
    CHECK(half.Filters[0].Amount.Value == doctest::Approx(4.0f));
    // An overshooting easing does not take a blur below zero.
    CHECK(InterpolateStyleValue(none, blur, -0.25f).Filters[0].Amount.Value == doctest::Approx(0.0f));
    CHECK(IsTransitionable(SV(u8"filter")));
    CHECK(IsTransitionable(SV(u8"backdrop-filter")));
}

TEST_CASE("effects: the sheet's filter, backdrop filter and blend become the box's")
{
    auto w = Box(u8"card");
    Apply(*w.Get(), u8"card { filter: blur(3px) blur(4px); backdrop-filter: blur(6px); mix-blend-mode: screen; }");
    const NodeBox& box = w->GetBox();
    CHECK(box.FilterBlur == doctest::Approx(5.0f)); // two blurs: the root of the squares' sum
    CHECK(box.BackdropBlur == doctest::Approx(6.0f));
    CHECK(box.BlendMode == vg::VGBlendMode::Screen);
    CHECK(box.NeedsLayer());

    Apply(*w.Get(), u8"card { mix-blend-mode: plus-lighter; }");
    CHECK(w->GetBox().BlendMode == vg::VGBlendMode::Additive);
    CHECK(w->GetBox().FilterBlur == doctest::Approx(0.0f)); // the sheet owns the box: dropped
    Apply(*w.Get(), u8"card { mix-blend-mode: difference; }"); // not one VG composites
    CHECK(w->GetBox().BlendMode == vg::VGBlendMode::Normal);
}

TEST_CASE("effects: a faded node with children draws through one layer, a faded leaf does not")
{
    auto parent = Box(u8"panel");
    auto child = Box(u8"button");
    parent->AddChild(child.Get());
    Apply(*child.Get(), u8"button { background-color: red; }");
    parent->SetAlpha(0.5f);
    {
        vg::VGContext canvas;
        DrawWith(*parent.Get(), canvas);
        REQUIRE(canvas.GetBatch().layers.Size() == 1u);
        CHECK(canvas.GetBatch().layers[0].opacity == doctest::Approx(0.5f));
    }
    child->SetAlpha(0.5f);
    parent->SetAlpha(1.0f);
    {
        vg::VGContext canvas;
        DrawWith(*parent.Get(), canvas);
        CHECK(canvas.GetBatch().layers.IsEmpty()); // the leaf's opacity multiplies into its draws
    }
}

TEST_CASE("effects: a filter blurs the node's layer in device pixels, and a blend composites it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetDisplayScale(2.0f);
    auto card = Box(u8"card");
    root->AddChild(card.Get());
    Apply(*card.Get(), u8"card { background-color: white; filter: blur(3px); mix-blend-mode: multiply; }");
    vg::VGContext canvas;
    DrawWith(*root.Get(), canvas);
    REQUIRE(canvas.GetBatch().layers.Size() == 1u);
    const vg::VGLayer& layer = canvas.GetBatch().layers[0];
    CHECK(layer.blur == doctest::Approx(6.0f)); // 3 logical units at 2x
    CHECK(layer.blendMode == vg::VGBlendMode::Multiply);
}

TEST_CASE("effects: a backdrop filter blurs what is behind the box")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto behind = Box(u8"wall");
    auto glass = Box(u8"glass");
    root->AddChild(behind.Get());
    root->AddChild(glass.Get());
    Apply(*behind.Get(), u8"wall { background-color: blue; }");
    Apply(*glass.Get(), u8"glass { background-color: rgba(255,255,255,0.3); backdrop-filter: blur(5px); }");
    vg::VGContext canvas;
    DrawWith(*root.Get(), canvas);
    bool backdrop = false;
    for (const vg::VGLayer& layer : canvas.GetBatch().layers)
        backdrop = backdrop || layer.backdropBlur == doctest::Approx(5.0f);
    CHECK(backdrop);
}

TEST_CASE("effects: overflow clips the children, to the rounded corners through a clip path")
{
    auto card = Box(u8"card");
    auto inner = Box(u8"inner");
    card->AddChild(inner.Get());
    Apply(*inner.Get(), u8"inner { background-color: red; }");
    Apply(*card.Get(), u8"card { overflow: hidden; border-radius: 12px; }");
    CHECK(card->ClipsChildren());

    vg::VGContext canvas;
    DrawWith(*card.Get(), canvas, true);
    bool stencilClipped = false;
    for (const vg::VGCommand& cmd : canvas.GetBatch().commands)
        stencilClipped = stencilClipped || cmd.clipMode == vg::VGClipMode::Stencil;
    CHECK(stencilClipped);

    // Square corners: a scissor, no stencil.
    Apply(*card.Get(), u8"card { overflow: hidden; }");
    vg::VGContext square;
    DrawWith(*card.Get(), square, true);
    for (const vg::VGCommand& cmd : square.GetBatch().commands)
        CHECK(cmd.clipMode != vg::VGClipMode::Stencil);

    Apply(*card.Get(), u8"card { overflow: visible; }");
    CHECK_FALSE(card->ClipsChildren());
}

TEST_CASE("effects: a transition moves a filter's blur")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto card = Box(u8"card");
    root->AddChild(card.Get());
    StyleManager styles(CSSParser::Parse(
        SV(u8"card { filter: blur(0px); transition: filter 1s linear; } card.soft { filter: blur(10px); }")));
    styles.ApplyTree(*root.Get());
    card->AddClass(SV(u8"soft"));
    styles.ApplyTree(*root.Get());
    root->GetContext().Update(core::Duration::FromSeconds(0.5));
    styles.ApplyTree(*root.Get());
    CHECK(card->GetBox().FilterBlur == doctest::Approx(5.0f).epsilon(0.05));
}

namespace
{
    // A widget that records the text effects its draw sees.
    struct EffectProbe : UIWidget
    {
        vg::TextEffects seen{};
        void OnDraw(DrawContext& ctx, const Rect&) override { seen = ctx.VG().GetTextEffects(); }
    };
}

TEST_CASE("effects: text-shadow, text-outline and text-glow reach the text, inherited and overridden")
{
    auto parent = Box(u8"menu");
    auto child = core::MakeRef<EffectProbe>(core::DefaultAllocator());
    child->SetTag(SV(u8"item"));
    child->SetSize(core::Float2{40.0f, 20.0f});
    parent->AddChild(child.Get());
    Apply(*parent.Get(), u8"menu { text-shadow: 1px 2px 3px rgba(0,0,0,0.5); text-glow: 6px #ffcc66; }");
    Apply(*child.Get(), u8"item { text-outline: 2px #101010; text-glow: none; }");
    {
        vg::VGContext canvas;
        DrawWith(*parent.Get(), canvas);
        const vg::TextEffects& e = child->seen;
        CHECK(e.shadowOffset.y == doctest::Approx(2.0f)); // the parent's, inherited
        CHECK(e.shadowBlur == doctest::Approx(3.0f));
        CHECK(e.outlineWidth == doctest::Approx(2.0f));   // its own
        CHECK(e.outlineColor.r == doctest::Approx(16.0f / 255.0f).epsilon(0.01));
        CHECK_FALSE(e.HasGlow());                          // none: the parent's turned off
    }
    // A text-glow interpolates (an animated title).
    StyleValue from, to;
    REQUIRE(ParseStyleValue(StyleGrammar::TextGlow, SV(u8"2px #ffffff"), from));
    REQUIRE(ParseStyleValue(StyleGrammar::TextGlow, SV(u8"10px #ffffff"), to));
    CHECK(InterpolateStyleValue(from, to, 0.5f).Shadows[0].Blur.Value == doctest::Approx(6.0f));
    CHECK(IsTransitionable(SV(u8"text-glow")));
    StyleValue bad;
    CHECK_FALSE(ParseStyleValue(StyleGrammar::TextOutline, SV(u8"#ffffff"), bad)); // no width
}

TEST_CASE("effects: a fading panel's backdrop blur is of what lies behind it, at its opacity")
{
    // Frosted settings rising in (opacity 0 -> 1, with children): the blur must see the orbs behind
    // it while it fades, not the panel's own empty layer.
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto orb = Box(u8"orb");
    auto panel = Box(u8"panel");
    auto row = Box(u8"row");
    root->AddChild(orb.Get());
    root->AddChild(panel.Get());
    panel->AddChild(row.Get());
    Apply(*orb.Get(), u8"orb { background-color: blue; }");
    Apply(*panel.Get(), u8"panel { background-color: rgba(255,255,255,0.1); backdrop-filter: blur(8px); }");
    Apply(*row.Get(), u8"row { background-color: red; }");
    panel->SetAlpha(0.5f); // mid-fade: a layer of its own
    vg::VGContext canvas;
    DrawWith(*root.Get(), canvas);
    const vg::VGBatch& batch = canvas.GetBatch();
    core::i32 backdrop = -1, group = -1;
    for (core::usize i = 0; i < batch.layers.Size(); ++i)
    {
        if (batch.layers[i].backdropBlur > 0.0f)
            backdrop = static_cast<core::i32>(i);
        else if (batch.layers[i].opacity == doctest::Approx(0.5f))
            group = static_cast<core::i32>(i);
    }
    REQUIRE(backdrop >= 0);
    REQUIRE(group >= 0);
    CHECK(batch.layers[static_cast<core::usize>(backdrop)].parent == -1); // the canvas behind, not the panel's layer
    CHECK(batch.layers[static_cast<core::usize>(backdrop)].bounds.width > 0.0f); // the orb is in it
    // The blurred shape is drawn at the panel's opacity.
    bool halfShape = false;
    for (const vg::VGVertex& v : batch.vertices)
        halfShape = halfShape || (v.color.a == doctest::Approx(0.5f) && v.color.r == doctest::Approx(1.0f) && v.color.g == doctest::Approx(1.0f));
    CHECK(halfShape);
}
