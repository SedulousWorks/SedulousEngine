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

TEST_CASE("tween: a sheet's property moves over the cascade from the value underneath, and holds its end")
{
    Bed bed(u8"box { background-color: #000000; } box.lit { background-color: #00ff00; }");
    core::RefPtr<Tween> tween = bed.widget->Animate(SV(u8"background-color"), SV(u8"#ff0000"), 1.0f, SV(u8"linear"));
    REQUIRE(tween);
    bed.Frame(0.5);
    CHECK(tween->MovesStyle());
    CHECK(bed.Red() == doctest::Approx(0.5f));
    bed.Frame(0.5);
    CHECK(bed.Red() == doctest::Approx(1.0f));
    CHECK(tween->IsDone());
    bed.Frame(0.5);
    CHECK(bed.Red() == doctest::Approx(1.0f)); // held

    // The sheet changes underneath: the tween's end still shows.
    bed.widget->AddClass(SV(u8"lit"));
    bed.Frame(0.1);
    CHECK(bed.Red() == doctest::Approx(1.0f));
    CHECK(bed.widget->GetBox().BackgroundColor.g == doctest::Approx(0.0f));
    // Stopped: the property is the sheet's again.
    CHECK(bed.widget->StopAnimation(SV(u8"background-color")));
    bed.Frame(0.0);
    CHECK(bed.Red() == doctest::Approx(0.0f));
    CHECK(bed.widget->GetBox().BackgroundColor.g == doctest::Approx(1.0f));
    CHECK_FALSE(bed.widget->StopAnimation(SV(u8"background-color"))); // nothing moves it now
}

TEST_CASE("tween: every value kind a transition moves: a number, a length, box shadows, a transform")
{
    Bed bed(u8"box { opacity: 1; width: 100; box-shadow: 0 0 0 transparent; transform: rotate(0deg); }");
    bed.widget->Animate(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"));
    bed.widget->Animate(SV(u8"width"), SV(u8"200"), 1.0f, SV(u8"linear"));
    bed.widget->Animate(SV(u8"box-shadow"), SV(u8"0 4px 8px #000000"), 1.0f, SV(u8"linear"));
    bed.widget->Animate(SV(u8"transform"), SV(u8"rotate(90deg)"), 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.widget->GetSize().x == doctest::Approx(150.0f));
    REQUIRE(bed.widget->GetBox().Shadows.Size() == 1u);
    CHECK(bed.widget->GetBox().Shadows[0].Offset.y == doctest::Approx(2.0f));
    REQUIRE(bed.widget->GetStyleTransforms().Size() == 1u);
    CHECK(bed.widget->GetStyleTransforms()[0].Angle == doctest::Approx(0.7853982f));
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
    CHECK(bed.widget->GetSize().x == doctest::Approx(200.0f));
}

TEST_CASE("tween: a given start, the easing, and nothing to move from")
{
    Bed bed(u8"box { }");
    bed.widget->Animate(SV(u8"opacity"), SV(u8"1"), 1.0f, SV(u8"ease-in-quad"))->From(SV(u8"0"));
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.25f)); // eased in: a quarter at half time
    // A property no sheet sets and with no start moves from its initial value (transparent).
    bed.widget->Animate(SV(u8"background-color"), SV(u8"#ff0000"), 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    CHECK(bed.Red() == doctest::Approx(0.5f));
    CHECK(bed.widget->GetBox().BackgroundColor.a == doctest::Approx(0.5f));
}

TEST_CASE("tween: a tween of the same property replaces the running one from where it shows")
{
    Bed bed(u8"box { opacity: 1; }");
    core::RefPtr<Tween> first = bed.widget->Animate(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"));
    bool firstFinished = false;
    first->OnFinished([&firstFinished]() { firstFinished = true; });
    bed.Frame(0.5);
    REQUIRE(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    core::RefPtr<Tween> second = bed.widget->Animate(SV(u8"opacity"), SV(u8"1"), 1.0f, SV(u8"linear"));
    CHECK(first->IsDone());
    bed.Frame(0.0);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f)); // no jump
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.75f));
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
    CHECK_FALSE(firstFinished); // replaced, not finished
}

TEST_CASE("tween: a delay waits, repeats run again, ping-pong comes back, and the end calls back once")
{
    Bed bed(u8"box { opacity: 1; }");
    int finished = 0;
    bed.widget->Animate(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"))
        ->Delay(0.5f)
        .Repeat(2)
        .PingPong()
        .OnFinished([&finished]() { ++finished; });
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f)); // waiting
    bed.Frame(0.75); // 0.5 into the first run
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    bed.Frame(0.75); // 0.25 into the second, coming back
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.25f));
    CHECK(finished == 0);
    bed.Frame(1.0);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f)); // back at the start
    CHECK(finished == 1);
    bed.Frame(1.0);
    CHECK(finished == 1);

    // Forever: still running long after, and Cancel gives the property back.
    core::RefPtr<Tween> forever = bed.widget->Animate(SV(u8"opacity"), SV(u8"0"), 0.1f, SV(u8"linear"));
    forever->Repeat(-1);
    for (int i = 0; i < 40; ++i)
        bed.Frame(0.25);
    CHECK_FALSE(forever->IsDone());
    forever->Cancel();
    bed.Frame(0.0);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f)); // the sheet's
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

TEST_CASE("tween: a paused GUI's tweens stand still; a destroyed node takes its tweens with it")
{
    Bed bed(u8"box { opacity: 1; }");
    bed.widget->Animate(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"));
    bed.Frame(0.25);
    REQUIRE(bed.widget->GetAlpha() == doctest::Approx(0.75f));
    bed.root->SetPaused(true);
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.75f));
    bed.root->SetPaused(false);
    bed.root->SetTimeScale(2.0f); // a GUI's own time, apart from the game's
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.25f));

    bed.styles.Forget(bed.widget.Get());
    bed.root->RemoveChild(bed.widget.Get());
    bed.widget = core::RefPtr<UIWidget>{};
    bed.Frame(0.1);
    CHECK(bed.root->GetActionManager()->IsEmpty());
}

TEST_CASE("tween: over a running transition, and a sheet transition after it ends")
{
    Bed bed(u8"box { opacity: 1; transition: opacity 1s linear; } box.dim { opacity: 0; }");
    bed.widget->ToggleClass(SV(u8"dim"));
    bed.styles.ApplyTree(*bed.root);
    bed.Frame(0.25);
    REQUIRE(bed.widget->GetAlpha() == doctest::Approx(0.75f));
    bed.widget->Animate(SV(u8"opacity"), SV(u8"1"), 0.5f, SV(u8"linear"))->From(SV(u8"0.5"));
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.75f)); // the tween's, over the transition's 0.5
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
    bed.Frame(1.0); // the transition ended; the tween still holds
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
}

TEST_CASE("tween: a sequence runs its steps in order, each from where the last left the time")
{
    Bed bed(u8"box { opacity: 1; background-color: #000000; }");
    core::Array<int> order;
    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    sequence->Add(bed.widget->CreateTween(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear")))
        .Call([&order]() { order.PushBack(1); })
        .Wait(0.5f)
        .Add(bed.widget->CreateTween(SV(u8"background-color"), SV(u8"#ff0000"), 1.0f, SV(u8"linear")))
        .Call([&order]() { order.PushBack(2); });
    int finished = 0;
    sequence->OnFinished([&finished]() { ++finished; });
    bed.widget->RunAction(sequence);
    bed.Frame(0.5);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.Red() == doctest::Approx(0.0f)); // not yet
    bed.Frame(1.25); // the fade ends at 1.0, the call, the wait to 1.5, then 0.25 of the colour
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
    REQUIRE(order.Size() == 1u);
    CHECK(bed.Red() == doctest::Approx(0.25f));
    bed.Frame(1.0);
    CHECK(bed.Red() == doctest::Approx(1.0f));
    REQUIRE(order.Size() == 2u);
    CHECK(order[1] == 2);
    CHECK(finished == 1);
    CHECK(sequence->IsDone());
}

TEST_CASE("tween: a parallel group runs its steps together and ends with the last; a group repeats")
{
    Bed bed(u8"box { opacity: 1; background-color: #000000; }");
    auto together = core::MakeRef<TweenParallel>(core::DefaultAllocator());
    together->Add(bed.widget->CreateTween(SV(u8"opacity"), SV(u8"0"), 0.5f, SV(u8"linear")))
        .Add(bed.widget->CreateTween(SV(u8"background-color"), SV(u8"#ff0000"), 1.0f, SV(u8"linear")))
        .Repeat(2);
    int finished = 0;
    together->OnFinished([&finished]() { ++finished; });
    bed.widget->RunAction(together);
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.Red() == doctest::Approx(0.25f));
    bed.Frame(0.5); // the fade ended at 0.5; the colour runs on
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
    CHECK(bed.Red() == doctest::Approx(0.75f));
    bed.Frame(0.5); // the first run ended at 1.0; 0.25 into the second, each from where it showed
    CHECK(finished == 0);
    CHECK(bed.Red() == doctest::Approx(1.0f));
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.0f));
    bed.Frame(1.0);
    CHECK(finished == 1);
    CHECK(together->IsDone());
}

TEST_CASE("tween: a tween started on its own takes its property from a group's step")
{
    Bed bed(u8"box { opacity: 1; }");
    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    core::RefPtr<Tween> inGroup = bed.widget->CreateTween(SV(u8"opacity"), SV(u8"0"), 1.0f, SV(u8"linear"));
    sequence->Add(inGroup);
    bed.widget->RunAction(sequence);
    bed.Frame(0.5);
    REQUIRE(bed.widget->GetAlpha() == doctest::Approx(0.5f));
    bed.widget->Animate(SV(u8"opacity"), SV(u8"1"), 0.5f, SV(u8"linear"));
    CHECK(inGroup->IsDone());
    bed.Frame(0.25);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(0.75f));
    CHECK(bed.widget->StopAnimation(SV(u8"opacity")));
    bed.Frame(0.0);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));
}

TEST_CASE("tween: a spring settles on its end; little damping overshoots and rings back")
{
    Bed bed(u8"box { opacity: 0; }");
    int finished = 0;
    core::RefPtr<Tween> spring = bed.widget->SpringTo(SV(u8"opacity"), SV(u8"1"));
    spring->OnFinished([&finished]() { ++finished; });
    CHECK(spring->IsSpring());
    float last = 0.0f;
    bool rising = true;
    for (int i = 0; i < 30 && !spring->IsDone(); ++i)
    {
        bed.Frame(1.0 / 60.0);
        rising = rising && bed.widget->GetAlpha() >= last; // a damped spring comes straight in
        last = bed.widget->GetAlpha();
    }
    CHECK(rising);
    for (int i = 0; i < 600 && !spring->IsDone(); ++i)
        bed.Frame(1.0 / 60.0);
    CHECK(spring->IsDone());
    CHECK(finished == 1);
    CHECK(bed.widget->GetAlpha() == doctest::Approx(1.0f));

    // Loose: past the end, then back under it.
    Bed loose(u8"box { width: 100; }");
    loose.widget->SpringTo(SV(u8"width"), SV(u8"200"), 300.0f, 4.0f);
    float most = 0.0f, leastAfter = 1000.0f;
    for (int i = 0; i < 240; ++i)
    {
        loose.Frame(1.0 / 60.0);
        const float w = loose.widget->GetSize().x;
        most = w > most ? w : most;
        if (most > 200.0f)
            leastAfter = w < leastAfter ? w : leastAfter;
    }
    CHECK(most > 210.0f);
    CHECK(leastAfter < 200.0f);
}

TEST_CASE("tween: a spring retargeted mid-flight turns from where it is, with its speed")
{
    Bed bed(u8"box { width: 100; }");
    core::RefPtr<Tween> spring = bed.widget->SpringTo(SV(u8"width"), SV(u8"300"));
    for (int i = 0; i < 6; ++i)
        bed.Frame(1.0 / 60.0);
    const float before = bed.widget->GetSize().x;
    bed.Frame(1.0 / 60.0);
    const float speed = bed.widget->GetSize().x - before; // per frame
    REQUIRE(speed > 0.0f);
    core::RefPtr<Tween> again = bed.widget->SpringTo(SV(u8"width"), SV(u8"400"));
    CHECK(again.Get() == spring.Get()); // the same spring, turned
    const float at = bed.widget->GetSize().x;
    bed.Frame(1.0 / 60.0);
    const float step = bed.widget->GetSize().x - at;
    CHECK(step > 0.0f);
    CHECK(step == doctest::Approx(speed).epsilon(0.5)); // no jolt: about the speed it had
    for (int i = 0; i < 600 && !spring->IsDone(); ++i)
        bed.Frame(1.0 / 60.0);
    CHECK(bed.widget->GetSize().x == doctest::Approx(400.0f).epsilon(0.01));

    // Toward a value of a different kind of distance (a colour): still continuous.
    Bed colour(u8"box { background-color: #000000; }");
    colour.widget->SpringTo(SV(u8"background-color"), SV(u8"#ff0000"));
    for (int i = 0; i < 6; ++i)
        colour.Frame(1.0 / 60.0);
    const float red = colour.Red();
    colour.widget->SpringTo(SV(u8"background-color"), SV(u8"#0000ff"));
    colour.Frame(0.0);
    CHECK(colour.Red() == doctest::Approx(red));
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

TEST_CASE("tween: a data value's new tween replaces the running one from the value showing")
{
    DataBed bed;
    core::RefPtr<Tween> first = bed.root->GetContext().AnimateData(SV(u8"score"), 100.0, 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    CHECK(*bed.Score().TryGet<core::i32>() == 50);
    core::RefPtr<Tween> second = bed.root->GetContext().AnimateData(SV(u8"score"), 0.0, 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    CHECK(first->IsDone());
    CHECK(*bed.Score().TryGet<core::i32>() == 25); // from 50 toward 0
    bed.Frame(0.5);
    CHECK(*bed.Score().TryGet<core::i32>() == 0);
}

TEST_CASE("tween: a data value never set moves as a number; retargeted it turns from where it is; cancelled it stays")
{
    DataBed bed;
    GUIContext& gui = bed.root->GetContext();
    core::RefPtr<Tween> fill = gui.AnimateData(SV(u8"health"), 1.0, 1.0f, SV(u8"linear"));
    bed.Frame(0.5);
    REQUIRE(gui.GetData().Peek(SV(u8"health")).TryGet<core::f64>() != nullptr);
    CHECK(*gui.GetData().Peek(SV(u8"health")).TryGet<core::f64>() == doctest::Approx(0.5));
    fill->Retarget(SV(u8"0"));
    bed.Frame(0.5);
    CHECK(*gui.GetData().Peek(SV(u8"health")).TryGet<core::f64>() == doctest::Approx(0.25));
    fill->Cancel();
    bed.Frame(1.0);
    CHECK(fill->IsDone());
    CHECK(*gui.GetData().Peek(SV(u8"health")).TryGet<core::f64>() == doctest::Approx(0.25));
}

TEST_CASE("tween: a data value's tween runs as a group's step, after a wait")
{
    DataBed bed;
    auto sequence = core::MakeRef<TweenSequence>(core::DefaultAllocator());
    sequence->Wait(0.5f).Add(bed.root->GetContext().CreateDataTween(SV(u8"score"), 10.0, 0.5f, SV(u8"linear")));
    bed.label->Play(sequence);
    bed.Frame(0.5);
    CHECK(*bed.Score().TryGet<core::i32>() == 0);
    bed.Frame(0.25);
    CHECK(*bed.Score().TryGet<core::i32>() == 5);
    bed.Frame(0.25);
    CHECK(*bed.Score().TryGet<core::i32>() == 10);
    CHECK(sequence->IsDone());
}

TEST_CASE("tween: a data value a script set (a fraction's type) counts in whole numbers when asked")
{
    DataBed bed;
    GUIContext& gui = bed.root->GetContext();
    gui.GetData().Set(SV(u8"points"), core::Variant::From<core::f64>(0.0)); // as a script's numbers arrive
    core::RefPtr<Tween> counting = gui.AnimateData(SV(u8"points"), 100.0, 1.0f, SV(u8"linear"));
    counting->Whole();
    for (int i = 0; i < 7; ++i)
    {
        bed.Frame(1.0 / 7.0);
        const core::Variant value = gui.GetData().Peek(SV(u8"points"));
        const core::f64* now = value.TryGet<core::f64>();
        REQUIRE(now != nullptr);
        CHECK(*now == static_cast<core::f64>(static_cast<core::i64>(*now))); // never a fraction
    }
    CHECK(*gui.GetData().Peek(SV(u8"points")).TryGet<core::f64>() == doctest::Approx(100.0));
}
