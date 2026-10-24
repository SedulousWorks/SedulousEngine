// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the style system's core (G2 of Specs/vg-and-gui-lab.md): declarations parsed once into
// typed values, shorthands cascading as their longhands, var() substituted anywhere in a value and
// custom properties inherited, and a widget's reflected property styled by its CSS name.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = core::MakeRef<UIWidget>(core::DefaultAllocator());
        w->SetTag(SV(tag));
        return w;
    }

    // A library's widget with a property of its own, styled by the name it declares.
    class Gauge : public UIWidget
    {
        RTTI_OBJECT(Gauge, UIWidget)
    public:
        [[nodiscard]] core::Color GetNeedleColor() const noexcept { return m_needle; }
        void SetNeedleColor(core::Color c) { m_needle = c; }
        [[nodiscard]] core::f32 GetNeedleWidth() const noexcept { return m_needleWidth; }
        void SetNeedleWidth(core::f32 w) { m_needleWidth = w; }

    private:
        core::Color m_needle{};
        core::f32 m_needleWidth = 1.0f;
    };
}

REFLECT_MEMBERS(Gauge, "rtti::gui::tests")
{
    builder.AccessorProperty<&Gauge::GetNeedleColor, &Gauge::SetNeedleColor>("needleColor")
        .PropAttribute("css", core::String(u8"needle-color"));
    builder.AccessorProperty<&Gauge::GetNeedleWidth, &Gauge::SetNeedleWidth>("needleWidth")
        .PropAttribute("css", core::String(u8"needle-width"));
}

TEST_CASE("style-core: var() resolves anywhere in a value, nested and with fallbacks")
{
    StyleSheet sheet = CSSParser::Parse(SV(
        u8"box { --x: 3px; --shade: rgba(0, 0, 0, 0.5); --outer: var(--x); "
        u8"box-shadow: var(--outer) 4px 6px var(--shade), inset 0 0 2px var(--missing, red); "
        u8"border: var(--w, 2px) solid var(--c, blue); }"));
    auto w = Widget(u8"box");
    ResolvedStyle rs = sheet.Resolve(*w.Get());

    const StyleValue* shadows = rs.Value(SV(u8"box-shadow"));
    REQUIRE(shadows != nullptr);
    REQUIRE(shadows->Shadows.Size() == 2u);
    CHECK(shadows->Shadows[0].OffsetX.Value == doctest::Approx(3.0f)); // var() -> var() -> 3px
    CHECK(shadows->Shadows[0].ShadowColor.a == doctest::Approx(0.5f));  // a var() inside rgba's place
    CHECK(shadows->Shadows[1].Inset);
    CHECK(shadows->Shadows[1].ShadowColor.r == doctest::Approx(1.0f)); // the fallback
    // A shorthand built of var()s expands after they resolve.
    CHECK(rs.Get(SV(u8"border-left-width")) == SV(u8"2px"));
    CHECK(rs.Value(SV(u8"border-top-color"))->ColorValue.b == doctest::Approx(1.0f));

    // A reference with no value and no fallback leaves its declaration out.
    StyleSheet broken = CSSParser::Parse(SV(u8"box { opacity: var(--nothing); }"));
    CHECK_FALSE(broken.Resolve(*w.Get()).Has(SV(u8"opacity")));
}

TEST_CASE("style-core: custom properties inherit from the parent's style")
{
    StyleSheet sheet = CSSParser::Parse(SV(u8"panel { --accent: #00ff00; } button { color: var(--accent); }"));
    auto panel = Widget(u8"panel");
    auto button = Widget(u8"button");
    const ResolvedStyle parent = sheet.Resolve(*panel.Get());
    CHECK_FALSE(sheet.Resolve(*button.Get()).Has(SV(u8"color"))); // alone, --accent is unset
    const ResolvedStyle child = sheet.Resolve(*button.Get(), MediaContext{}, true, {}, &parent);
    REQUIRE(child.Value(SV(u8"color")) != nullptr);
    CHECK(child.Value(SV(u8"color"))->ColorValue.g == doctest::Approx(1.0f));
}

TEST_CASE("style-core: a shorthand cascades as its longhands")
{
    // A later, more specific longhand overrides one side of an earlier shorthand; the others stay.
    StyleSheet sheet = CSSParser::Parse(SV(
        u8"box { border: 1px solid red; padding: 2 4; } .warn { border-left-color: yellow; padding-top: 9; }"));
    auto w = Widget(u8"box");
    w->AddClass(SV(u8"warn"));
    ResolvedStyle rs = sheet.Resolve(*w.Get());
    CHECK(rs.Value(SV(u8"border-left-color"))->ColorValue.g == doctest::Approx(1.0f)); // yellow
    CHECK(rs.Value(SV(u8"border-right-color"))->ColorValue.g == doctest::Approx(0.0f)); // still red
    CHECK(rs.Get(SV(u8"padding-top")) == SV(u8"9"));
    CHECK(rs.Get(SV(u8"padding-right")) == SV(u8"4"));
    CHECK(rs.Get(SV(u8"padding-bottom")) == SV(u8"2"));
    CHECK_FALSE(rs.Has(SV(u8"border"))); // only longhands are resolved
}

TEST_CASE("style-core: a declaration without var() is parsed once, and once more after it changes")
{
    StyleSheet sheet = CSSParser::Parse(SV(u8"box { transform: rotate(90deg) scale(2); }"));
    auto w = Widget(u8"box");
    (void)sheet.Resolve(*w.Get());
    const StyleProperty& declared = sheet.Rules()[0].Properties()[0];
    CHECK(declared.Cached);
    REQUIRE(declared.CacheValid);
    REQUIRE(declared.Longhands.Size() == 1u);
    CHECK(declared.Longhands[0].Value.Kind == StyleValueKind::Transforms);
    CHECK(declared.Longhands[0].Value.Transforms.Size() == 2u);
    // A second cascade reads the cached value (the same parse, the same result).
    const ResolvedStyle second = sheet.Resolve(*w.Get());
    const StyleValue* again = second.Value(SV(u8"transform"));
    REQUIRE(again != nullptr);
    CHECK(again->Transforms[0].Angle == doctest::Approx(1.5707963f));

    // A declaration with a var() is substituted on every cascade instead.
    StyleSheet withVar = CSSParser::Parse(SV(u8"box { --a: 0.25; opacity: var(--a); }"));
    (void)withVar.Resolve(*w.Get());
    CHECK_FALSE(withVar.Rules()[0].Properties()[1].CacheValid);
}

TEST_CASE("style-core: a widget's reflected property takes the CSS name it declares")
{
    StyleSheet sheet = CSSParser::Parse(SV(u8"gauge { needle-color: #ff8000; needle-width: 0.5rem; }"));
    auto gauge = core::MakeRef<Gauge>(core::DefaultAllocator());
    gauge->SetTag(SV(u8"gauge"));
    LengthContext lengths;
    lengths.RootFontSize = 16.0f;
    ApplyStyle(*gauge.Get(), sheet.Resolve(*gauge.Get()), nullptr, nullptr, lengths);
    CHECK(gauge->GetNeedleColor().r == doctest::Approx(1.0f));
    CHECK(gauge->GetNeedleColor().g == doctest::Approx(128.0f / 255.0f));
    CHECK(gauge->GetNeedleWidth() == doctest::Approx(8.0f)); // a length, resolved
}

TEST_CASE("style-core: the box belongs to the sheet: a restyle without box properties clears it")
{
    StyleSheet sheet = CSSParser::Parse(SV(u8".card { background-color: red; box-shadow: 0 2px 4px black; }"));
    auto w = Widget(u8"box");
    w->AddClass(SV(u8"card"));
    ApplyStyle(*w.Get(), sheet.Resolve(*w.Get()));
    CHECK(w->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
    CHECK(w->GetBox().Shadows.Size() == 1u);
    w->RemoveClass(SV(u8"card"));
    ApplyStyle(*w.Get(), sheet.Resolve(*w.Get()));
    CHECK(w->GetBox().IsEmpty());

    // A box set natively is the node's own: a sheet with no box properties leaves it.
    auto native = Widget(u8"box");
    NodeBox box;
    box.BackgroundColor = core::Color{0.0f, 0.0f, 1.0f, 1.0f};
    native->SetBox(core::Move(box));
    ApplyStyle(*native.Get(), sheet.Resolve(*native.Get()));
    CHECK(native->GetBox().BackgroundColor.b == doctest::Approx(1.0f));
}

TEST_CASE("style-core: the style manager gives each widget its ancestors' custom properties")
{
    // A var() set on a row reaches its children through ApplyTree (it was dropped when the
    // manager resolved each widget alone).
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto row = Widget(u8"row");
    auto card = Widget(u8"card");
    root->AddChild(row.Get());
    row->AddChild(card.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"row { --glow: #00ff00; } card { box-shadow: 0 0 4px var(--glow); }")));
    styles.ApplyTree(*root.Get());
    REQUIRE(card->GetBox().Shadows.Size() == 1u);
    CHECK(card->GetBox().Shadows[0].ShadowColor.g == doctest::Approx(1.0f));
}
