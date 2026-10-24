// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the colour widgets (T4 of Specs/gui-lab-evolution-3.md): HSV over sRGB values and back, a hex
// code written, a swatch clicked or hatched when mixed, and a picker dragged (each step reported,
// then its end), typed into, its hue kept through a grey, its alpha hidden where a colour has none.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;

namespace
{
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ColorPicker> picker = core::MakeRef<ColorPicker>(core::DefaultAllocator());
        int steps = 0, changes = 0;
        core::Color last{};

        Bed()
        {
            root->SetSize(core::Float2{400.0f, 400.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            picker->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(300.0f); });
            root->AddChild(picker.Get());
            picker->SetOnColorChanging([this](core::Color c) { ++steps, last = c; });
            picker->SetOnColorChanged([this](core::Color c) { ++changes, last = c; });
            (void)root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        // A point `x`, `y` of the way across a node.
        static core::Float2 Across(const Node& node, f32 x, f32 y)
        {
            const Rect r = node.GetScreenBounds();
            return core::Float2{r.x + r.width * x, r.y + r.height * y};
        }
    };
}

TEST_CASE("color: HSV over the colour's values and back, and its hex")
{
    const ColorHsv red = ToHsv(core::Color{1.0f, 0.0f, 0.0f, 1.0f});
    CHECK(red.H == doctest::Approx(0.0f));
    CHECK(red.S == doctest::Approx(1.0f));
    CHECK(red.V == doctest::Approx(1.0f));
    const ColorHsv teal = ToHsv(core::Color{0.2f, 0.6f, 0.6f, 0.5f});
    CHECK(teal.H == doctest::Approx(180.0f));
    const core::Color back = FromHsv(teal);
    CHECK(back.r == doctest::Approx(0.2f));
    CHECK(back.g == doctest::Approx(0.6f));
    CHECK(back.a == doctest::Approx(0.5f));
    CHECK(ToHsv(core::Color{0.5f, 0.5f, 0.5f, 1.0f}, 210.0f).H == doctest::Approx(210.0f)); // a grey keeps the hue given

    CHECK(FormatHexColor(core::Color{1.0f, 0.5f, 0.0f, 1.0f}, true) == core::String(u8"#FF8000"));
    CHECK(FormatHexColor(core::Color{1.0f, 0.5f, 0.0f, 0.5f}, true) == core::String(u8"#FF800080"));
    CHECK(FormatHexColor(core::Color{1.0f, 0.5f, 0.0f, 0.5f}, false) == core::String(u8"#FF8000"));
}

TEST_CASE("color: a swatch is clicked, or by Return; mixed it shows no colour")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto swatch = core::MakeRef<ColorSwatch>(core::DefaultAllocator());
    swatch->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Width = LayoutLength::Px(40.0f);
        s.Height = LayoutLength::Px(20.0f);
    });
    root->AddChild(swatch.Get());
    (void)root->UpdateLayout();
    int clicks = 0;
    swatch->SetOnClick([&clicks]() { ++clicks; });
    swatch->SetColor(core::Color{0.1f, 0.2f, 0.3f, 0.5f});
    CHECK(swatch->GetColor().b == doctest::Approx(0.3f));
    EventDispatcher& d = *root->GetEventDispatcher();
    d.InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d.InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1);
    swatch->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(clicks == 2);
    swatch->SetMixed(true);
    CHECK(swatch->IsMixed());
}

TEST_CASE("color: a picker's plane and strips are dragged, each step reported, then the end")
{
    Bed bed;
    bed.picker->SetColor(core::Color{1.0f, 0.0f, 0.0f, 1.0f});
    ColorPickerArea& plane = *bed.picker->GetPlane();
    bed.D().InjectMouseDown(Bed::Across(plane, 0.5f, 0.5f), MouseButton::Left);
    bed.D().InjectMouseMove(Bed::Across(plane, 1.0f, 0.0f));
    bed.D().InjectMouseUp(Bed::Across(plane, 1.0f, 0.0f), MouseButton::Left);
    CHECK(bed.steps == 2);
    CHECK(bed.changes == 1);
    CHECK(bed.last.r == doctest::Approx(1.0f).epsilon(0.02));
    CHECK(bed.last.g == doctest::Approx(0.0f).epsilon(0.02));

    // To the black corner and back out: the hue is kept.
    bed.D().InjectMouseDown(Bed::Across(plane, 0.5f, 1.0f), MouseButton::Left);
    bed.D().InjectMouseUp(Bed::Across(plane, 0.5f, 1.0f), MouseButton::Left);
    CHECK(bed.picker->GetColor().r == doctest::Approx(0.0f).epsilon(0.02));
    bed.D().InjectMouseDown(Bed::Across(plane, 1.0f, 0.0f), MouseButton::Left);
    bed.D().InjectMouseUp(Bed::Across(plane, 1.0f, 0.0f), MouseButton::Left);
    CHECK(bed.picker->GetColor().r == doctest::Approx(1.0f).epsilon(0.02));

    // A third of the hue strip: green.
    ColorPickerArea& hue = *bed.picker->GetHueStrip();
    bed.D().InjectMouseDown(Bed::Across(hue, 1.0f / 3.0f, 0.5f), MouseButton::Left);
    bed.D().InjectMouseUp(Bed::Across(hue, 1.0f / 3.0f, 0.5f), MouseButton::Left);
    CHECK(bed.picker->GetColor().g == doctest::Approx(1.0f).epsilon(0.03));
    CHECK(bed.picker->GetColor().r < 0.1f);
    // Half the alpha strip.
    ColorPickerArea& alpha = *bed.picker->GetAlphaStrip();
    bed.D().InjectMouseDown(Bed::Across(alpha, 0.5f, 0.5f), MouseButton::Left);
    bed.D().InjectMouseUp(Bed::Across(alpha, 0.5f, 0.5f), MouseButton::Left);
    CHECK(bed.picker->GetColor().a == doctest::Approx(0.5f).epsilon(0.03));
}

TEST_CASE("color: a picker typed into: a hex code, a channel; its alpha hidden where a colour has none")
{
    Bed bed;
    TextField& hex = *bed.picker->GetHexField();
    hex.RequestFocus();
    hex.GetModel().SelectAll();
    bed.D().InjectText(core::StringView(u8"#3366CC"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(bed.changes == 1);
    CHECK(bed.picker->GetColor().b == doctest::Approx(0.8f).epsilon(0.01));
    CHECK(bed.picker->GetChannelField(1)->GetValue() == doctest::Approx(102.0));

    hex.GetModel().SelectAll();
    bed.D().InjectText(core::StringView(u8"not a colour"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(bed.changes == 1);
    CHECK(hex.GetText() == core::StringView(u8"#3366CC")); // back to what it was

    NumberField& red = *bed.picker->GetChannelField(0);
    red.RequestFocus();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Up)); // one step: 0x34
    CHECK(bed.picker->GetColor().r == doctest::Approx(52.0f / 255.0f).epsilon(0.01));
    CHECK(hex.GetText() == core::StringView(u8"#3466CC"));

    bed.picker->SetShowsAlpha(false);
    CHECK_FALSE(bed.picker->GetAlphaStrip()->IsDisplayed());
    CHECK(bed.picker->GetColor().a == doctest::Approx(1.0f));
}
