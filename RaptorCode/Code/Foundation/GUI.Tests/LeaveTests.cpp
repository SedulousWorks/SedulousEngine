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

