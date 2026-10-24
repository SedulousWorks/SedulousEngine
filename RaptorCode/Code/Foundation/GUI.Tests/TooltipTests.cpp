// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - tooltips, context menus and long presses (E5 of Specs/gui-lab-evolution.md): the GUI shows
// the nearest tooltip text up the parent chain from the hovered node after a delay on its own
// clock, by the pointer, as a hint popup; just after one hid the next shows at once; a press hides
// it until the pointer moves on. A right release, Shift+F10 or a long press asks for a context menu
// (a `contextmenu` event); a long press nobody takes shows the tooltip. A text field's context menu
// offers cut, copy, paste and select all.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T, typename... A>
    core::RefPtr<T> Make(A&&... args)
    {
        return core::MakeRef<T>(core::DefaultAllocator(), static_cast<A&&>(args)...);
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = Make<SceneRoot>(Make<GUIContext>());
        core::RefPtr<UIWidget> panel = Make<UIWidget>();
        core::RefPtr<UIWidget> child = Make<UIWidget>();
        core::RefPtr<UIWidget> other = Make<UIWidget>();
        Bed()
        {
            root->SetSize(core::Float2{300.0f, 300.0f});
            panel->SetSize(core::Float2{100.0f, 100.0f});
            panel->SetTooltip(SV(u8"The panel"));
            root->AddChild(panel.Get());
            child->SetSize(core::Float2{40.0f, 40.0f});
            panel->AddChild(child.Get()); // no text of its own: the panel's shows
            other->SetPosition(core::Float2{150.0f, 0.0f});
            other->SetSize(core::Float2{100.0f, 100.0f});
            other->SetTooltip(SV(u8"Another"));
            root->AddChild(other.Get());
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Frames(int n, core::f64 seconds = 0.1)
        {
            for (int i = 0; i < n; ++i)
                root->GetContext().Update(core::Duration::FromSeconds(seconds));
        }
        [[nodiscard]] core::StringView Shown()
        {
            const Tooltip* tip = core::Cast<Tooltip>(d().GetShownTooltip());
            return tip != nullptr ? tip->GetText() : core::StringView{};
        }
    };
}

TEST_CASE("tooltip: the nearest text up the parent chain shows after the delay, by the pointer")
{
    Bed bed;
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f}); // over the child
    bed.Frames(4); // 0.4 s
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.Frames(2);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    CHECK(bed.Shown() == SV(u8"The panel"));
    const Node* tip = bed.d().GetShownTooltip();
    CHECK(tip->GetPosition().x == doctest::Approx(32.0f)); // 12 right of the pointer
    CHECK(tip->GetPosition().y == doctest::Approx(38.0f)); // 18 below it
}

TEST_CASE("tooltip: moving to another hides it, and the next shows at once while warm")
{
    Bed bed;
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f});
    bed.Frames(6);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    bed.d().InjectMouseMove(core::Float2{160.0f, 20.0f}); // onto the other
    bed.Frames(1);
    CHECK(bed.Shown() == SV(u8"Another")); // no second wait
    bed.d().InjectMouseMove(core::Float2{280.0f, 280.0f}); // nothing with a tooltip
    bed.Frames(1);
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.Frames(10); // cold again
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f});
    bed.Frames(1);
    CHECK(bed.d().GetShownTooltip() == nullptr); // the full delay again
}

TEST_CASE("tooltip: its provider's text changing under the pointer shows the new text at once")
{
    Bed bed;
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f});
    bed.Frames(6);
    REQUIRE(bed.Shown() == SV(u8"The panel"));
    bed.panel->SetTooltip(SV(u8"The panel, elsewhere")); // as a code editor's word under the pointer
    bed.d().InjectMouseMove(core::Float2{30.0f, 22.0f});
    bed.Frames(1);
    CHECK(bed.Shown() == SV(u8"The panel, elsewhere"));
    CHECK(bed.d().GetShownTooltip()->GetPosition().x == doctest::Approx(42.0f)); // by the pointer now
    bed.Frames(3);
    CHECK(bed.Shown() == SV(u8"The panel, elsewhere")); // the same text stays
}

TEST_CASE("tooltip: a press hides it until the pointer moves to another node")
{
    Bed bed;
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f});
    bed.Frames(6);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    bed.d().InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    bed.d().InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == nullptr); // not again under the same pointer
}

TEST_CASE("tooltip: a key hides it until the pointer moves to another node")
{
    Bed bed;
    bed.d().InjectMouseMove(core::Float2{20.0f, 20.0f});
    bed.Frames(6);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::A));
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == nullptr); // not reopened at the next tick
}

TEST_CASE("tooltip: sits by the pointer at a display scale")
{
    Bed bed;
    bed.root->SetDisplayScale(2.0f);
    bed.root->SetSize(core::Float2{300.0f, 300.0f});
    bed.d().InjectMouseMove(core::Float2{40.0f, 40.0f}); // device pixels: (20, 20) in the root's units
    bed.Frames(6);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    CHECK(bed.d().GetShownTooltip()->GetPosition().x == doctest::Approx(32.0f));
    CHECK(bed.d().GetShownTooltip()->GetPosition().y == doctest::Approx(38.0f));
}

TEST_CASE("tooltip: the keys moving the focus show the focused control's, below it (E16)")
{
    Bed bed;
    bed.panel->SetTabFocusable(true);
    bed.other->SetTabFocusable(true);
    bed.panel->RequestFocus(); // focused from code at the start: no tooltip of its own accord
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == nullptr);

    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab)); // to the other
    bed.Frames(4);
    CHECK(bed.d().GetShownTooltip() == nullptr); // the delay
    bed.Frames(2);
    REQUIRE(bed.d().GetShownTooltip() != nullptr);
    CHECK(bed.Shown() == SV(u8"Another"));
    const Node* tip = bed.d().GetShownTooltip();
    CHECK(tip->GetPosition().x == doctest::Approx(150.0f)); // below the control, at its start
    CHECK(tip->GetPosition().y == doctest::Approx(104.0f));

    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab)); // on to the panel: its own, after the delay
    bed.Frames(1);
    CHECK(bed.Shown() == SV(u8"The panel")); // warm: at once

    // The pointer in use: the focus's tooltip waits for the keys again.
    bed.d().InjectMouseDown(core::Float2{280.0f, 280.0f}, MouseButton::Left);
    bed.d().InjectMouseUp(core::Float2{280.0f, 280.0f}, MouseButton::Left);
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.d().SetKeyboardTooltips(false);
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab));
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == nullptr); // turned off
}

TEST_CASE("tooltip: an interactive one holds while the pointer crosses into it, and takes a press (E16)")
{
    Bed bed;
    bed.other->SetTooltipInteractive(true);
    bed.d().InjectMouseMove(core::Float2{160.0f, 20.0f});
    bed.Frames(6);
    Node* tip = bed.d().GetShownTooltip();
    REQUIRE(tip != nullptr);
    (void)bed.root->UpdateLayout();
    const core::Float2 inside = tip->ConvertToWorldSpace(core::Float2{tip->GetSize().x * 0.5f, tip->GetSize().y * 0.5f});

    // Off the control, toward the tooltip: it holds a moment.
    bed.d().InjectMouseMove(core::Float2{160.0f, 120.0f}); // below the control, before the tooltip
    bed.Frames(1);
    CHECK(bed.d().GetShownTooltip() == tip);
    bed.d().InjectMouseMove(inside); // in it: it holds
    bed.Frames(10);
    CHECK(bed.d().GetShownTooltip() == tip);
    bed.d().InjectMouseDown(inside, MouseButton::Left); // a press inside does not close it
    bed.d().InjectMouseUp(inside, MouseButton::Left);
    CHECK(bed.d().GetShownTooltip() == tip);

    // Off both: gone after the grace.
    bed.d().InjectMouseMove(core::Float2{20.0f, 280.0f});
    bed.Frames(2); // 0.2 s
    CHECK(bed.d().GetShownTooltip() == tip);
    bed.Frames(2);
    CHECK(bed.d().GetShownTooltip() == nullptr);
}

TEST_CASE("context menu: a right release asks the node there and up; Shift+F10 asks the focused one")
{
    Bed bed;
    auto button = Make<Button>();
    button->SetSize(core::Float2{30.0f, 20.0f});
    bed.child->AddChild(button.Get());
    int asked = 0;
    core::Float2 at{};
    (void)bed.panel->AddEventListener(EventType::ContextMenu, [&](const Event& e)
                                      {
                                          ++asked;
                                          at = static_cast<const MouseEvent&>(e).Position;
                                          e.Handled = true;
                                      });
    bed.d().InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Right);
    CHECK(asked == 0);
    bed.d().InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Right);
    CHECK(asked == 1);
    CHECK(at.x == doctest::Approx(10.0f));
    button->RequestFocus();
    bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::F10), KeyModShift);
    CHECK(asked == 2);
    CHECK(at.y == doctest::Approx(20.0f)); // the focused node's bottom-left
}

TEST_CASE("context menu: a long press asks for one; untaken, it shows the tooltip; and no click follows")
{
    Bed bed;
    auto button = Make<Button>();
    button->SetSize(core::Float2{30.0f, 20.0f});
    bed.child->AddChild(button.Get());
    int clicks = 0;
    button->SetOnClick([&] { ++clicks; });
    bed.d().InjectTouchDown(1, core::Float2{10.0f, 10.0f});
    bed.Frames(3); // 0.3 s
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.Frames(3);
    REQUIRE(bed.d().GetShownTooltip() != nullptr); // nobody opened a menu: the tooltip
    CHECK(bed.Shown() == SV(u8"The panel"));
    bed.d().InjectTouchUp(1, core::Float2{10.0f, 10.0f});
    CHECK(clicks == 0);

    // A finger that moves is a drag, not a long press.
    bed.d().InjectTouchDown(1, core::Float2{10.0f, 10.0f});
    bed.d().InjectTouchMove(1, core::Float2{60.0f, 60.0f});
    bed.Frames(8);
    CHECK(bed.d().GetShownTooltip() == nullptr);
    bed.d().InjectTouchUp(1, core::Float2{60.0f, 60.0f});
}

TEST_CASE("context menu: a text field offers cut, copy, paste and select all, lit where they do something")
{
    Bed bed;
    auto field = Make<TextField>();
    field->SetPosition(core::Float2{0.0f, 150.0f});
    field->SetSize(core::Float2{200.0f, 24.0f});
    bed.root->AddChild(field.Get());
    field->SetText(SV(u8"hello"));
    bed.d().InjectMouseDown(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    bed.d().InjectMouseUp(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    Menu* menu = field->GetContextMenu();
    REQUIRE(menu != nullptr);
    CHECK(menu->IsOpen());
    CHECK(menu->GetParent() == field.Get());
    REQUIRE(menu->ItemCount() == 4u);
    // Nothing selected, no clipboard: only select all is lit.
    menu->Close();
    field->SelectAll();
    bed.d().InjectMouseDown(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    bed.d().InjectMouseUp(core::Float2{20.0f, 160.0f}, MouseButton::Right);
    REQUIRE(menu->IsOpen());
    // Its Cut runs the field's command, and the menu closes, focus back on the field.
    MenuItem* cut = core::Cast<MenuItem>(menu->GetChildAt(0));
    REQUIRE(cut != nullptr);
    CHECK(cut->GetText() == SV(u8"Cut"));
    CHECK(cut->IsEnabled());
    (void)cut->HandleActivate();
    CHECK(field->GetText().Size() == 0u);
    CHECK_FALSE(menu->IsOpen());
    CHECK(field->IsFocused());
}
