// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - tweens (E14 of Specs/gui-lab-evolution-2.md): a property a sheet names moves over the
// cascade on the GUI's clock, from the value underneath or a given start, through the same typed
// values a transition moves (a number, a length, a colour, box shadows, a transform), and holds
// its end until stopped, a sheet's later change leaving it be; a tween of the same property
// replaces the running one from where it shows; delays, repeats, ping-pong and the callback at
// the end; reflected properties move through their accessors; a paused GUI's tweens stand still,
// and a destroyed node takes its tweens with it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // A widget in a GUI styled by a sheet; a frame runs the clock, then the style pass, as a host does.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> widget = core::MakeRef<UIWidget>(core::DefaultAllocator());
        StyleManager styles;

        explicit Bed(const char8_t* css)
        {
            widget->SetTag(SV(u8"box"));
            {
                Node::StyleWriteScope defaults(*widget);
                widget->SetSize(core::Float2{100.0f, 50.0f});
            }
            root->AddChild(widget.Get());
            styles.SetStyleSheet(CSSParser::Parse(SV(css)));
            styles.ApplyTree(*root);
        }
        void Frame(double seconds)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            styles.ApplyTree(*root);
            (void)root->UpdateLayout();
        }
        [[nodiscard]] float Red() const { return widget->GetBox().BackgroundColor.r; }
    };
}

TEST_CASE("tween: a reflected property moves through its accessors, as code's")
{
    Bed bed(u8"box { }");
    auto slider = core::MakeRef<Slider>(core::DefaultAllocator());
    slider->SetMax(100.0f);
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    bed.root->AddChild(slider.Get());
    bed.root->AddChild(label.Get());
    core::RefPtr<Tween> value = slider->Animate(SV(u8"value"), SV(u8"80"), 1.0f, SV(u8"linear"));
    slider->SetValue(20.0f); // the start is the value it has at its first frame
    label->Animate(SV(u8"textColor"), SV(u8"#ffffff"), 1.0f, SV(u8"linear"))->From(SV(u8"#000000"));
    label->Animate(SV(u8"x"), SV(u8"40"), 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    CHECK_FALSE(value->MovesStyle());
    CHECK(slider->GetValue() == doctest::Approx(50.0f));
    CHECK(label->GetTextColor().r == doctest::Approx(0.5f));
    CHECK(label->GetX() == doctest::Approx(20.0f));
    bed.Frame(0.5);
    CHECK(slider->GetValue() == doctest::Approx(80.0f));
    // A name nothing has: the tween ends at once, touching nothing.
    core::RefPtr<Tween> nothing = label->Animate(SV(u8"no-such-thing"), SV(u8"1"), 1.0f);
    bed.Frame(0.1);
    CHECK(nothing->IsDone());
}

TEST_CASE("tween: a spring moves a reflected property, and runs as a group's step")
{
    Bed bed(u8"box { }");
    auto slider = core::MakeRef<Slider>(core::DefaultAllocator());
    slider->SetMax(100.0f);
    bed.root->AddChild(slider.Get());
    core::RefPtr<Tween> spring = slider->SpringTo(SV(u8"value"), SV(u8"60"));
    for (int i = 0; i < 600 && !spring->IsDone(); ++i)
        bed.Frame(1.0 / 60.0);
    CHECK(slider->GetValue() == doctest::Approx(60.0));

    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    core::RefPtr<Tween> step = bed.widget->CreateTween(SV(u8"opacity"), SV(u8"0"), 0.0f);
    step->Spring(400.0f, 40.0f);
    bool after = false;
    sequence->Add(step).Call([&after]() { after = true; });
    bed.widget->RunAction(sequence);
    for (int i = 0; i < 600 && !sequence->IsDone(); ++i)
        bed.Frame(1.0 / 60.0);
    CHECK(after);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
}

// === A data value tweened (K3 of Specs/gui-lab-evolution-3.md) ===

namespace
{
    // A GUI whose data holds `score`, and a label bound to it.
    struct DataBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Label> label = core::MakeRef<Label>(core::DefaultAllocator());

        DataBed()
        {
            root->AddChild(label.Get());
            Label* shown = label.Get();
            GUIContext* gui = &root->GetContext();
            label->Bind([shown, gui]() { shown->SetText(FormatVariant(gui->GetData().Get(SV(u8"score")))); });
            Data().Set(SV(u8"score"), core::Variant::From<core::i32>(0));
            Frame(0.0);
        }
        DataModel& Data() { return root->GetContext().GetData(); }
        void Frame(double seconds) { root->GetContext().Update(core::Duration::FromSeconds(seconds)); }
        [[nodiscard]] core::Variant Score() { return Data().Peek(SV(u8"score")); }
    };
}

TEST_CASE("tween: a data value counts up with no widget to drive it, in its own type, and a bound label follows")
{
    DataBed bed;
    core::RefPtr<Tween> tween = bed.root->GetContext().AnimateData(SV(u8"score"), 1500.0, 1.0f, SV(u8"linear"));
    CHECK(tween->MovesData());
    bed.Frame(0.25);
    REQUIRE(bed.Score().TryGet<core::i32>() != nullptr); // a whole number stays one
    CHECK(*bed.Score().TryGet<core::i32>() == 375);
    CHECK(bed.label->GetText() == SV(u8"375"));
    bed.Frame(0.75);
    CHECK(*bed.Score().TryGet<core::i32>() == 1500);
    CHECK(bed.label->GetText() == SV(u8"1500"));
    CHECK(tween->IsDone());
}

