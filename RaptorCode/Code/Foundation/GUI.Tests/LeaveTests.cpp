// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - leaving (K0 of Specs/gui-lab-evolution-3.md): Node::Leave puts a node in `:leaving`, where
// the sheet's exit transition or animation plays, keeps input off it, and removes it once that
// ends; `transitionend` and `animationend` tell a node a sheet's motion on it ended.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::Duration Secs(double s) { return core::Duration::FromSeconds(s); }

    // A GUI with a sheet and one widget of class "card" under its root.
    struct LeaveBed
    {
        core::RefPtr<SceneRoot> root =
            core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Button> card = core::MakeRef<Button>(core::DefaultAllocator());
        StyleManager styles;

        explicit LeaveBed(const char8_t* css)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            card->AddClass(core::StringView(u8"card"));
            card->SetSize(core::Float2{100.0f, 40.0f});
            root->AddChild(card.Get());
            styles.SetStyleSheet(CSSParser::Parse(core::StringView(css)));
            Frame(0.0);
        }
        // One frame as a host runs it: the GUI's update, then the style pass.
        void Frame(double seconds)
        {
            root->GetContext().Update(Secs(seconds));
            styles.ApplyTree(*root);
        }
        [[nodiscard]] bool Attached() const { return card->GetParent() == root.Get(); }
    };

    struct Heard
    {
        core::String Name;
        float Elapsed = -1.0f;
        int Count = 0;
    };
    void Listen(Node& node, EventType type, Heard& heard)
    {
        (void)node.AddEventListener(type,
                                    [&heard](const Event& e)
                                    {
                                        const MotionEndEvent& end = static_cast<const MotionEndEvent&>(e);
                                        heard.Name = core::String(end.Name);
                                        heard.Elapsed = end.Elapsed;
                                        ++heard.Count;
                                    });
    }
}

TEST_CASE("leave: the sheet's exit transition plays, then the node goes")
{
    LeaveBed bed(u8".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }");
    Heard ended;
    Listen(*bed.card, EventType::TransitionEnd, ended);

    bed.card->Leave();
    CHECK(bed.card->IsLeaving());
    bed.Frame(0.0); // the style pass: `:leaving` matches, the transition starts
    CHECK(bed.Attached());
    CHECK(bed.card->GetAlpha() == doctest::Approx(1.0f));

    bed.Frame(0.25);
    CHECK(bed.Attached());
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.5f));
    CHECK(ended.Count == 0);

    bed.Frame(0.25); // it ends: told, and taken off at the update's drain
    CHECK(ended.Count == 1);
    CHECK(ended.Name == core::StringView(u8"opacity"));
    CHECK(ended.Elapsed == doctest::Approx(0.5f));
    CHECK_FALSE(bed.Attached());
    CHECK_FALSE(bed.card->IsLeaving()); // out of its parent, it has left
}

TEST_CASE("leave: with no exit in the sheet, it goes at the next update")
{
    LeaveBed bed(u8".card { opacity: 1; }");
    bed.card->Leave();
    bed.styles.ApplyTree(*bed.root);
    CHECK(bed.Attached()); // never inside the style pass's walk
    bed.root->GetContext().Update(Secs(0.0));
    CHECK_FALSE(bed.Attached());
}

TEST_CASE("leave: in a GUI no style pass runs over it goes at the next update, never inside the event that sent it; detached, at once")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto widget = core::MakeRef<UIWidget>(core::DefaultAllocator());
    root->AddChild(widget.Get());
    widget->Leave();
    CHECK(widget->GetParent() == root.Get()); // a click handler that closed it still finds it there
    CHECK(widget->IsLeaving());
    root->GetContext().Update(core::Duration{});
    CHECK(widget->GetParent() == nullptr);
    CHECK_FALSE(widget->IsLeaving());

    auto parent = core::MakeRef<UIWidget>(core::DefaultAllocator());
    auto child = core::MakeRef<UIWidget>(core::DefaultAllocator());
    parent->AddChild(child.Get());
    child->Leave();
    CHECK(child->GetParent() == nullptr);
}

TEST_CASE("leave: a keyframe exit is told once as animationend, and a forwards fill still lets it go")
{
    LeaveBed bed(u8"@keyframes out { from { opacity: 1; } to { opacity: 0; } }"
                 u8".card:leaving { animation: out 0.3s linear forwards; }");
    Heard ended;
    Listen(*bed.card, EventType::AnimationEnd, ended);
    bed.card->Leave();
    bed.Frame(0.0);
    bed.Frame(0.15);
    CHECK(bed.Attached());
    CHECK(bed.card->GetAlpha() == doctest::Approx(0.5f));
    bed.Frame(0.15);
    CHECK(ended.Count == 1);
    CHECK(ended.Name == core::StringView(u8"out"));
    CHECK(ended.Elapsed == doctest::Approx(0.3f));
    CHECK_FALSE(bed.Attached());
}

TEST_CASE("leave: an infinite animation running is not waited for")
{
    LeaveBed bed(u8"@keyframes pulse { from { opacity: 1; } to { opacity: 0.5; } }"
                 u8".card { animation: pulse 1s infinite; }");
    bed.Frame(0.25);
    bed.card->Leave();
    bed.Frame(0.0);
    bed.root->GetContext().Update(Secs(0.0));
    CHECK_FALSE(bed.Attached());
}

TEST_CASE("leave: a leaving node takes no pointer, focus or navigation")
{
    LeaveBed bed(u8".card { opacity: 1; transition: opacity 1s linear; } .card:leaving { opacity: 0; }");
    (void)bed.root->UpdateLayout();
    EventDispatcher& dispatcher = *bed.root->GetEventDispatcher();
    bed.card->RequestFocus();
    REQUIRE(dispatcher.GetFocusNode() == bed.card.Get());
    const core::Float2 over{10.0f, 10.0f};
    REQUIRE(bed.root->OverFind(over) == bed.card.Get());

    bed.card->Leave();
    CHECK(dispatcher.GetFocusNode() == nullptr); // dropped, as from a removed subtree
    CHECK(bed.root->OverFind(over) != bed.card.Get());
    bed.card->RequestFocus();
    CHECK(dispatcher.GetFocusNode() == nullptr); // refused while it leaves
    int clicks = 0;
    bed.card->SetOnClick([&clicks]() { ++clicks; });
    dispatcher.InjectMouseDown(over, MouseButton::Left);
    dispatcher.InjectMouseUp(over, MouseButton::Left);
    CHECK(clicks == 0);
    (void)dispatcher.MoveFocus(NavDirection::Down); // nothing else to reach, and not it
    CHECK(dispatcher.GetFocusNode() == nullptr);
}

TEST_CASE("leave: a node taken back before its exit ends stays, whole")
{
    LeaveBed bed(u8".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }");
    auto shelf = core::MakeRef<UIWidget>(core::DefaultAllocator());
    bed.root->AddChild(shelf.Get());
    bed.Frame(0.0);
    bed.card->Leave();
    bed.Frame(0.0);
    shelf->AddChild(bed.card.Get()); // moved elsewhere mid-exit
    CHECK_FALSE(bed.card->IsLeaving());
    for (int i = 0; i < 4; ++i)
        bed.Frame(0.25);
    CHECK(bed.card->GetParent() == shelf.Get());
    CHECK(bed.card->GetAlpha() == doctest::Approx(1.0f));
}

TEST_CASE("leave: transitionend tells each property once, and a replaced transition is not told")
{
    LeaveBed bed(u8".card { opacity: 1; transition: opacity 0.4s linear; } .card.dim { opacity: 0.2; }");
    Heard ended;
    Listen(*bed.card, EventType::TransitionEnd, ended);
    bed.card->AddClass(core::StringView(u8"dim"));
    bed.Frame(0.0);
    bed.Frame(0.2);
    bed.card->RemoveClass(core::StringView(u8"dim")); // replaced halfway: back toward 1
    bed.Frame(0.0);
    CHECK(ended.Count == 0);
    bed.Frame(0.4);
    CHECK(ended.Count == 1); // the one that ran to its end
    CHECK(ended.Name == core::StringView(u8"opacity"));
    bed.Frame(1.0);
    CHECK(ended.Count == 1);
    CHECK(bed.Attached()); // a node not leaving stays
}

TEST_CASE("leave: :leaving reads through an ancestor")
{
    LeaveBed bed(u8".card:leaving .label { opacity: 0.25; }");
    auto label = core::MakeRef<UIWidget>(core::DefaultAllocator());
    label->AddClass(core::StringView(u8"label"));
    bed.card->AddChild(label.Get());
    bed.Frame(0.0);
    CHECK(label->GetAlpha() == doctest::Approx(1.0f));
    bed.card->Leave();
    bed.styles.ApplyTree(*bed.root);
    CHECK(label->GetAlpha() == doctest::Approx(0.25f));
}
