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
