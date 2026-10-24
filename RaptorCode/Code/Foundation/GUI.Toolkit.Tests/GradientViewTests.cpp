// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the gradient view (T5 of Specs/gui-lab-evolution-3.md): one of Core's gradients edited
// as a value, each gesture reported as it goes and once at its end, or given up: a click adds a stop
// of what is there (alpha above, colour below), a drag moves one (sorted again as it passes) or
// pulls it off (never a kind's last); the picker edits a colour stop, the fields an alpha and a
// place, the drop-down the blend.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;

namespace
{
    // A 300 px wide view at the root's corner: its strip's alpha stops on y 0 to 12, the bar on 12
    // to 36, its colour stops on 36 to 48; time t at x = 300 t.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<GradientView> view = core::MakeRef<GradientView>(core::DefaultAllocator());
        int changing = 0;
        core::Array<ColorGradient> changed{core::DefaultAllocator()};
        int cancelled = 0;

        Bed()
        {
            root->SetSize(core::Float2{500.0f, 400.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            view->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(300.0f); });
            root->AddChild(view.Get());
            ColorGradient value;
            value.Colors.PushBack(core::GradientColorStop{0.0f, core::Color{1.0f, 0.0f, 0.0f, 1.0f}});
            value.Colors.PushBack(core::GradientColorStop{1.0f, core::Color{0.0f, 0.0f, 1.0f, 1.0f}});
            value.Alphas.PushBack(core::GradientAlphaStop{0.0f, 1.0f});
            value.Alphas.PushBack(core::GradientAlphaStop{1.0f, 0.0f});
            view->SetValue(value);
            view->SetOnGradientChanging([this](const ColorGradient&) { ++changing; });
            view->SetOnGradientChanged([this](const ColorGradient& v) { changed.PushBack(v); });
            view->SetOnGradientCancelled([this]() { ++cancelled; });
            (void)root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        const ColorGradient& V() const { return view->GetValue(); }
        static core::Float2 Colour(f32 t) { return core::Float2{300.0f * t, 44.0f}; }
        static core::Float2 Alpha(f32 t) { return core::Float2{300.0f * t, 4.0f}; }
        void Frame() { (void)root->UpdateLayout(); }
        void Press(core::Float2 at)
        {
            D().InjectMouseMove(at);
            D().InjectMouseDown(at, MouseButton::Left);
        }
        void Drag(core::Float2 from, core::Float2 to)
        {
            Press(from);
            D().InjectMouseMove(core::Float2{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f});
            D().InjectMouseMove(to);
            D().InjectMouseUp(to, MouseButton::Left);
        }
        void Click(core::Float2 at)
        {
            Press(at);
            D().InjectMouseUp(at, MouseButton::Left);
        }
        void Pause()
        {
            D().InjectMouseMove(core::Float2{490.0f, 390.0f});
            D().InjectMouseDown(core::Float2{490.0f, 390.0f}, MouseButton::Left);
            D().InjectMouseUp(core::Float2{490.0f, 390.0f}, MouseButton::Left);
        }
        static core::Float2 Centre(const Node& node)
        {
            const Rect r = node.GetScreenBounds();
            return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
        }
    };
}

TEST_CASE("GradientView: a click on the strip adds a stop of what the gradient has there, one change")
{
    Bed bed;
    bed.Click(Bed::Colour(0.5f));
    REQUIRE(bed.V().Colors.Size() == 3);
    CHECK(bed.V().Colors[1].time == doctest::Approx(0.5f));
    CHECK(bed.V().Colors[1].color.r == doctest::Approx(0.5f)); // halfway from red to blue, sRGB blended
    CHECK(bed.V().Colors[1].color.b == doctest::Approx(0.5f));
    CHECK(bed.V().Colors[1].color.a == 1.0f);
    CHECK(bed.view->GetSelected() == GradientStopRef{false, 1});
    CHECK(bed.changed.Size() == 1);

    bed.Pause();
    bed.Click(Bed::Alpha(0.25f));
    REQUIRE(bed.V().Alphas.Size() == 3);
    CHECK(bed.V().Alphas[1].alpha == doctest::Approx(0.75f));
    CHECK(bed.view->GetSelected() == GradientStopRef{true, 1});
    CHECK(bed.changed.Size() == 2);

    // Full: nothing added.
    bed.view->SetMaxStops(3);
    bed.Pause();
    bed.Click(Bed::Alpha(0.75f));
    CHECK(bed.V().Alphas.Size() == 3);
    CHECK(bed.changed.Size() == 2);
}

TEST_CASE("GradientView: a drag moves a stop, sorted again as it passes; a press that does not move changes nothing")
{
    Bed bed;
    bed.Click(Bed::Colour(0.0f)); // selects the first, changes nothing
    CHECK(bed.view->GetSelected() == GradientStopRef{false, 0});
    CHECK(bed.changed.IsEmpty());
    bed.Pause();
    bed.Drag(Bed::Colour(0.0f), Bed::Colour(1.0f) + core::Float2{40.0f, 0.0f}); // past the other, past the end
    REQUIRE(bed.V().Colors.Size() == 2);
    CHECK(bed.V().Colors[1].time == doctest::Approx(1.0f));
    CHECK(bed.V().Colors[1].color.r == doctest::Approx(1.0f)); // red, now second
    CHECK(bed.view->GetSelected() == GradientStopRef{false, 1});
    CHECK(bed.changing >= 1);
    CHECK(bed.changed.Size() == 1);
}

TEST_CASE("GradientView: a stop pulled off the strip goes, back on it returns; a kind's last stays; Escape gives a drag up")
{
    Bed bed;
    bed.Press(Bed::Alpha(1.0f) + core::Float2{-2.0f, 0.0f});
    bed.D().InjectMouseMove(core::Float2{280.0f, 120.0f}); // well below
    CHECK(bed.V().Alphas.Size() == 1);
    bed.D().InjectMouseMove(core::Float2{280.0f, 20.0f}); // back
    CHECK(bed.V().Alphas.Size() == 2);
    bed.D().InjectMouseMove(core::Float2{280.0f, -60.0f});
    bed.D().InjectMouseUp(core::Float2{280.0f, -60.0f}, MouseButton::Left);
    REQUIRE(bed.V().Alphas.Size() == 1);
    CHECK(bed.changed.Size() == 1);

    bed.Pause();
    bed.Press(Bed::Alpha(0.0f) + core::Float2{2.0f, 0.0f}); // the last alpha stop
    bed.D().InjectMouseMove(core::Float2{10.0f, 150.0f});
    bed.D().InjectMouseUp(core::Float2{10.0f, 150.0f}, MouseButton::Left);
    CHECK(bed.V().Alphas.Size() == 1);

    bed.Pause();
    bed.Press(Bed::Colour(1.0f) + core::Float2{-2.0f, 0.0f});
    bed.D().InjectMouseMove(Bed::Colour(0.5f));
    CHECK(bed.V().Colors[0].time == doctest::Approx(0.0f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.cancelled == 1);
    CHECK(bed.V().Colors[1].time == doctest::Approx(1.0f));
    bed.D().InjectMouseUp(Bed::Colour(0.5f), MouseButton::Left);
    CHECK(bed.V().Colors[1].time == doctest::Approx(1.0f));
    const core::usize before = bed.changed.Size();
    CHECK(before == 2); // the last-stop attempt moved it, so it changed once
}

TEST_CASE("GradientView: the selected stop's place and an alpha stop's alpha are fields; the blend a drop-down")
{
    Bed bed;
    bed.Click(Bed::Alpha(1.0f) + core::Float2{-2.0f, 0.0f});
    REQUIRE(bed.view->GetSelected() == GradientStopRef{true, 1});
    CHECK(bed.view->GetAlphaField()->IsDisplayed());
    CHECK_FALSE(bed.view->GetSwatch()->IsDisplayed());
    bed.Frame();

    const auto type = [&bed](NumberField& field, const char8_t* text)
    {
        const Rect r = field.GetScreenBounds();
        const core::Float2 at{r.x + 12.0f, r.y + r.height * 0.5f};
        bed.Pause();
        bed.Click(at);
        bed.D().InjectText(core::StringView(text));
        bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    };
    type(*bed.view->GetAlphaField(), u8"0.5");
    CHECK(bed.V().Alphas[1].alpha == doctest::Approx(0.5f));
    CHECK(bed.changed.Size() == 1);
    type(*bed.view->GetTimeField(), u8"0.4");
    CHECK(bed.V().Alphas[1].time == doctest::Approx(0.4f));
    CHECK(bed.changed.Size() == 2);

    bed.view->GetInterpolationBox()->SetSelectedIndex(2);
    CHECK(bed.V().Interpolation == core::GradientInterpolation::OkLab);
    CHECK(bed.changed.Size() == 3);

    // A colour stop shows its swatch instead.
    bed.view->Select(GradientStopRef{false, 0});
    CHECK_FALSE(bed.view->GetAlphaField()->IsDisplayed());
    CHECK(bed.view->GetSwatch()->IsDisplayed());
    CHECK(bed.changed.Size() == 3); // showing a selection is no change
}

TEST_CASE("GradientView: a double click on a colour stop opens the picker; its drags preview, closing changes once, Escape gives up")
{
    Bed bed;
    bed.Click(Bed::Colour(0.0f) + core::Float2{2.0f, 0.0f});
    bed.Click(Bed::Colour(0.0f) + core::Float2{2.0f, 0.0f});
    ColorPicker* picker = bed.view->GetPicker();
    REQUIRE(picker != nullptr);
    CHECK(picker->GetColor().r == doctest::Approx(1.0f));
    CHECK_FALSE(picker->ShowsAlpha());
    CHECK(bed.changed.IsEmpty());

    const Rect r = picker->GetPlane()->GetScreenBounds();
    bed.D().InjectMouseDown(core::Float2{r.x + 5.0f, r.y + r.height * 0.5f}, MouseButton::Left);
    bed.D().InjectMouseUp(core::Float2{r.x + 5.0f, r.y + r.height * 0.5f}, MouseButton::Left);
    CHECK(bed.changing >= 1);
    CHECK(bed.changed.IsEmpty());
    CHECK(bed.V().Colors[0].color.r < 0.9f); // previewed
    bed.D().ClosePopup(*bed.view->GetPicker()->GetParent());
    REQUIRE(bed.changed.Size() == 1);
    CHECK(bed.V().Colors[0].color.a == 1.0f);

    const core::Color picked = bed.V().Colors[0].color;
    bed.Frame();
    bed.Pause();
    bed.Click(Bed::Centre(*bed.view->GetSwatch()));
    REQUIRE(bed.view->GetPicker() != nullptr);
    const Rect again = bed.view->GetPicker()->GetPlane()->GetScreenBounds();
    bed.D().InjectMouseDown(core::Float2{again.Right() - 5.0f, again.y + 5.0f}, MouseButton::Left);
    bed.D().InjectMouseUp(core::Float2{again.Right() - 5.0f, again.y + 5.0f}, MouseButton::Left);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.view->GetPicker() == nullptr);
    CHECK(bed.cancelled == 1);
    CHECK(bed.V().Colors[0].color == picked);
    CHECK(bed.changed.Size() == 1);
}

TEST_CASE("GradientView: Delete takes the selected stop away, never a kind's last")
{
    Bed bed;
    bed.Click(Bed::Colour(1.0f) + core::Float2{-2.0f, 0.0f});
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    REQUIRE(bed.V().Colors.Size() == 1);
    CHECK_FALSE(bed.view->GetSelected().IsValid());
    bed.view->Select(GradientStopRef{false, 0});
    CHECK_FALSE(bed.view->RemoveSelected());
    CHECK(bed.changed.Size() == 1);
}
