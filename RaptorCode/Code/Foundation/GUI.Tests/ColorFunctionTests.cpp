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
