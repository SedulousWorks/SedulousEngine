// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - entering (K5 of Specs/gui-lab-evolution-3.md): Node::Enter puts a node in `:entering`
// while the sheet's entrance plays (a keyframe animation, or values it starts from), then moves it
// to its own style and tells `entered` once that has settled; a Leave cuts it short from where it
// is; and the GUI's clock may be capped so a hitch slows motion rather than skipping it.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    struct EnterBed
    {
        core::RefPtr<SceneRoot> root =
            core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> card = core::MakeRef<UIWidget>(core::DefaultAllocator());
        StyleManager styles;
        int entered = 0;

        explicit EnterBed(const char8_t* css)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            styles.SetStyleSheet(CSSParser::Parse(core::StringView(css)));
            styles.ApplyTree(*root); // a style pass runs over this GUI
            card->AddClass(core::StringView(u8"card"));
            card->SetSize(core::Float2{100.0f, 40.0f});
            (void)card->AddEventListener(EventType::Entered, [this](const Event&) { ++entered; });
        }
        // One frame as a host runs it: the GUI's update, then the style pass.
        void Frame(double seconds)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            styles.ApplyTree(*root);
        }
        // The card arrives: added and entering before its first style.
        void Arrive()
        {
            root->AddChild(card.Get());
            card->Enter();
        }
    };
}

TEST_CASE("enter: a keyframe entrance plays under :entering, then the node hears entered")
{
    EnterBed bed(u8"@keyframes rise { from { opacity: 0; } to { opacity: 1; } }"
                 u8".card:entering { animation: rise 0.4s linear; }");
    bed.Arrive();
    CHECK(bed.card->IsEntering());
    bed.Frame(0.0);
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.0f));
    bed.Frame(0.2);
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.card->IsEntering());
    bed.Frame(0.2); // it ends: :entering goes
    CHECK_FALSE(bed.card->IsEntering());
    CHECK(bed.card->IsArriving());
    CHECK(bed.entered == 0);
    bed.Frame(0.0); // its own style moved nothing: settled
    CHECK(bed.entered == 1);
    CHECK_FALSE(bed.card->IsArriving());
    CHECK(bed.card->GetAlpha() == doctest::Approx(1.0f));
}

TEST_CASE("enter: values :entering starts from move to the node's own through its transition, as @starting-style")
{
    EnterBed bed(u8".card { opacity: 1; transition: opacity 0.4s linear; } .card:entering { opacity: 0; }");
    bed.Arrive();
    bed.Frame(0.0); // its first style: where it starts, with nothing to move from
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.0f));
    bed.Frame(0.0); // :entering goes: toward its own
    CHECK_FALSE(bed.card->IsEntering());
    bed.Frame(0.2);
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.entered == 0);
    bed.Frame(0.2);
    CHECK(bed.card->GetAlpha() == doctest::Approx(1.0f));
    CHECK(bed.entered == 1);
}

TEST_CASE("enter: with no entrance in the sheet it settles in a couple of updates; with no style pass, at once")
{
    EnterBed bed(u8".card { opacity: 1; }");
    bed.Arrive();
    for (int i = 0; i < 3; ++i)
        bed.Frame(0.0);
    CHECK(bed.entered == 1);

    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto widget = core::MakeRef<UIWidget>(core::DefaultAllocator());
    int heard = 0;
    (void)widget->AddEventListener(EventType::Entered, [&heard](const Event&) { ++heard; });
    root->AddChild(widget.Get());
    widget->Enter();
    CHECK(heard == 1);
    CHECK_FALSE(widget->IsArriving());
}

TEST_CASE("enter: a Leave cuts the entrance short and leaves from where it is")
{
    EnterBed bed(u8".card { opacity: 1; transition: opacity 0.4s linear; } .card:entering { opacity: 0; }"
                 u8".card:leaving { opacity: 0; }");
    bed.Arrive();
    bed.Frame(0.0);
    bed.Frame(0.0);
    bed.Frame(0.2); // half in
    REQUIRE(bed.card->GetAlpha() == doctest::Approx(0.5f));
    bed.card->Leave();
    CHECK_FALSE(bed.card->IsArriving());
    bed.Frame(0.0);
    bed.Frame(0.2); // from 0.5 toward 0, halfway
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.25f));
    bed.Frame(0.2);
    CHECK(bed.card->GetParent() == nullptr);
    CHECK(bed.entered == 0);
}

TEST_CASE("enter: a capped clock slows a hitch's motion rather than skipping it")
{
    EnterBed bed(u8".card { opacity: 1; transition: opacity 0.5s linear; } .card.dim { opacity: 0; }");
    bed.root->AddChild(bed.card.Get());
    bed.Frame(0.0);
    bed.root->GetContext().SetMaxClockStep(0.1f);
    bed.card->AddClass(core::StringView(u8"dim"));
    bed.Frame(0.0);
    bed.Frame(1.0); // a one-second hitch moves it a tenth of a second
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.8f));
    CHECK(bed.root->GetContext().GetMaxClockStep() == doctest::Approx(0.1f));
}
