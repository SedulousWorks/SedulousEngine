// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - colour functions (E13 of Specs/gui-lab-evolution-2.md): hsl() and hsla(), color-mix() in
// sRGB (premultiplied, percentages normalized), and currentColor, the nearest declared colour.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    void CheckColor(const core::Optional<core::Color>& c, core::f32 r, core::f32 g, core::f32 b, core::f32 a)
    {
        REQUIRE(c.HasValue());
        CHECK(c.Value().r == doctest::Approx(r).epsilon(0.002));
        CHECK(c.Value().g == doctest::Approx(g).epsilon(0.002));
        CHECK(c.Value().b == doctest::Approx(b).epsilon(0.002));
        CHECK(c.Value().a == doctest::Approx(a).epsilon(0.002));
    }
}

TEST_CASE("colours: hsl() and hsla(), commas or spaces, an alpha as a number or a percentage")
{
    CheckColor(ParseColor(SV(u8"hsl(120, 100%, 50%)")), 0.0f, 1.0f, 0.0f, 1.0f);
    CheckColor(ParseColor(SV(u8"hsl(0 100% 50% / 0.5)")), 1.0f, 0.0f, 0.0f, 0.5f);
    CheckColor(ParseColor(SV(u8"hsla(240deg, 100%, 25%, 25%)")), 0.0f, 0.0f, 0.5f, 0.25f);
    CheckColor(ParseColor(SV(u8"hsl(-120, 100%, 50%)")), 0.0f, 0.0f, 1.0f, 1.0f); // a hue round the circle
    CheckColor(ParseColor(SV(u8"hsl(30, 0%, 40%)")), 0.4f, 0.4f, 0.4f, 1.0f);    // no saturation: grey
    CHECK_FALSE(ParseColor(SV(u8"hsl(10, 20%)")).HasValue());
}

TEST_CASE("colours: color-mix() in srgb, premultiplied, its percentages normalized")
{
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, red 25%, blue)")), 0.25f, 0.0f, 0.75f, 1.0f);
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, red, blue 75%)")), 0.25f, 0.0f, 0.75f, 1.0f);
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, red 60%, blue 60%)")), 0.5f, 0.0f, 0.5f, 1.0f); // over 100: scaled down
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, red 20%, blue 20%)")), 0.5f, 0.0f, 0.5f, 0.4f); // under: the alpha
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, red, transparent)")), 1.0f, 0.0f, 0.0f, 0.5f);  // premultiplied
    CheckColor(ParseColor(SV(u8"color-mix(in srgb, hsl(120, 100%, 50%), #000)")), 0.0f, 0.5f, 0.0f, 1.0f);
    CHECK_FALSE(ParseColor(SV(u8"color-mix(red, blue)")).HasValue());
}

TEST_CASE("colours: currentColor is the nearest declared colour, a descendant's too; on color, the parent's")
{
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    core::RefPtr<Panel> outer = core::MakeRef<Panel>(core::DefaultAllocator());
    core::RefPtr<Panel> inner = core::MakeRef<Panel>(core::DefaultAllocator());
    core::RefPtr<Label> text = core::MakeRef<Label>(core::DefaultAllocator());
    root->AddChild(outer.Get());
    outer->AddChild(inner.Get());
    inner->AddChild(text.Get());
    outer->AddClass(SV(u8"outer"));
    inner->AddClass(SV(u8"inner"));
    text->AddClass(SV(u8"text"));
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".outer { border-color: currentColor; border-width: 1px; color: #ff0000; }"
                                             u8".inner { background-color: color-mix(in srgb, currentColor 50%, transparent); }"
                                             u8".text { color: currentColor; background-color: currentColor; }")));
    styles.ApplyTree(*root.Get());
    // Declared after it in the rule, the colour still applies to the border (the cascade's winner).
    CHECK(outer->GetBox().BorderColors.top.r == doctest::Approx(1.0f));
    CHECK(outer->GetBox().BorderColors.top.g == doctest::Approx(0.0f));
    // A descendant that declares none reads its ancestor's.
    CHECK(inner->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
    CHECK(inner->GetBox().BackgroundColor.a == doctest::Approx(0.5f));
    CHECK(text->GetTextColor().r == doctest::Approx(1.0f)); // color: currentColor is the inherited one
    CHECK(text->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
    // A theme's retint reaches every currentColor.
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".outer { color: hsl(240, 100%, 50%); } .inner { background-color: currentColor; }")));
    styles.ApplyTree(*root.Get());
    CHECK(inner->GetBox().BackgroundColor.b == doctest::Approx(1.0f));
}
