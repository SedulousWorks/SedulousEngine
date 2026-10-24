// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - NumberField (E6): expressions read on commit, snapped and kept in range, written with the
// step's decimals between a prefix and a suffix; arrows, keys and the wheel step it; a press and
// a drag scrubs it, a press let go starts editing.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<NumberField> field = core::MakeRef<NumberField>(core::DefaultAllocator());
        core::RefPtr<Panel> other = core::MakeRef<Panel>(core::DefaultAllocator());
        int inputs = 0, changes = 0, changeEvents = 0;
        Bed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            field->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(120.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
            root->AddChild(field.Get());
            other->SetTabFocusable(true);
            other->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(20.0f); s.Width = LayoutLength::Px(20.0f); });
            root->AddChild(other.Get());
            (void)root->UpdateLayout();
            field->SetOnValueChanging([this](core::f64) { ++inputs; });
            field->SetOnValueChanged([this](core::f64) { ++changes; });
            (void)field->AddEventListener(EventType::Changed, [this](const Event&) { ++changeEvents; });
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        static core::u32 K(KeyCode k) { return static_cast<core::u32>(k); }
        // A press let go on the field: editing, all of it selected.
        void ClickToEdit()
        {
            D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
            D().InjectMouseUp(core::Float2{30.0f, 12.0f}, MouseButton::Left);
        }
    };
}

TEST_CASE("number: expressions are read as arithmetic, or not at all")
{
    CHECK(EvaluateExpression(core::StringView(u8"2*3")).Value() == doctest::Approx(6.0));
    CHECK(EvaluateExpression(core::StringView(u8" 1 + 2 * (3 - 1) / 4 ")).Value() == doctest::Approx(2.0));
    CHECK(EvaluateExpression(core::StringView(u8"-1.5")).Value() == doctest::Approx(-1.5));
    CHECK(EvaluateExpression(core::StringView(u8"10/4")).Value() == doctest::Approx(2.5));
    CHECK_FALSE(EvaluateExpression(core::StringView(u8"abc")).HasValue());
    CHECK_FALSE(EvaluateExpression(core::StringView(u8"1/0")).HasValue());
    CHECK_FALSE(EvaluateExpression(core::StringView(u8"(1+2")).HasValue());
    CHECK_FALSE(EvaluateExpression(core::StringView(u8"")).HasValue());
}

TEST_CASE("number: written with the step's decimals between its prefix and suffix")
{
    Bed b;
    b.field->SetStep(0.25);
    b.field->SetValue(1.5);
    CHECK(b.field->GetText() == core::StringView(u8"1.5"));
    b.field->SetPrefix(core::String(u8"$"));
    b.field->SetSuffix(core::String(u8" ea"));
    CHECK(b.field->GetText() == core::StringView(u8"$1.5 ea"));
    b.field->SetInteger(true);
    CHECK(b.field->GetValue() == doctest::Approx(2.0)); // whole numbers
    CHECK(b.field->GetText() == core::StringView(u8"$2 ea"));
    CHECK(b.changes == 0); // code reports nothing
}

TEST_CASE("number: typed text commits on Return as its expression, snapped and kept in range")
{
    Bed b;
    b.field->SetStep(0.5);
    b.ClickToEdit();
    CHECK(b.field->IsEditing());
    b.D().InjectText(core::StringView(u8"2*3.6"));
    b.D().InjectKeyDown(Bed::K(KeyCode::Return));
    CHECK(b.field->GetValue() == doctest::Approx(7.0)); // 7.2 to the step
    CHECK(b.field->GetText() == core::StringView(u8"7"));
    CHECK(b.changes == 1);
    CHECK(b.changeEvents == 1);

    b.ClickToEdit();
    b.D().InjectText(core::StringView(u8"500"));
    b.other->RequestFocus(); // leaving commits too
    CHECK(b.field->GetValue() == doctest::Approx(100.0)); // the maximum
    CHECK(b.changes == 2);

    b.field->RequestFocus();
    b.ClickToEdit();
    b.D().InjectText(core::StringView(u8"nonsense"));
    b.D().InjectKeyDown(Bed::K(KeyCode::Return));
    CHECK(b.field->GetValue() == doctest::Approx(100.0)); // back as it was
    CHECK(b.field->GetText() == core::StringView(u8"100"));
    CHECK(b.changes == 2);

    // Its prefix and suffix may be typed or left out.
    b.field->SetSuffix(core::String(u8" px"));
    b.ClickToEdit();
    b.D().InjectText(core::StringView(u8"12 px"));
    b.D().InjectKeyDown(Bed::K(KeyCode::Return));
    CHECK(b.field->GetValue() == doctest::Approx(12.0));
}

TEST_CASE("number: the arrows, the keys and the wheel step it, each a committed change")
{
    Bed b;
    b.field->SetStep(2.0);
    b.field->SetPage(10.0);
    b.field->RequestFocus();
    b.D().InjectKeyDown(Bed::K(KeyCode::Up));
    CHECK(b.field->GetValue() == doctest::Approx(2.0));
    b.D().InjectKeyDown(Bed::K(KeyCode::PageUp));
    CHECK(b.field->GetValue() == doctest::Approx(12.0));
    b.D().InjectKeyDown(Bed::K(KeyCode::Down));
    CHECK(b.field->GetValue() == doctest::Approx(10.0));
    CHECK(b.changes == 3);

    b.D().InjectMouseWheel(core::Float2{30.0f, 12.0f}, core::Float2{0.0f, 1.0f});
    CHECK(b.field->GetValue() == doctest::Approx(12.0));

    // The up arrow, held: once on the press, then repeating.
    const Rect up = b.field->GetUpButton()->GetScreenBounds();
    const core::Float2 at{up.x + up.width * 0.5f, up.y + up.height * 0.5f};
    b.D().InjectMouseMove(at);
    b.D().InjectMouseDown(at, MouseButton::Left);
    CHECK(b.field->GetValue() == doctest::Approx(14.0));
    b.root->GetContext().Update(core::Duration::FromSeconds(0.5)); // past the delay
    b.root->GetContext().Update(core::Duration::FromSeconds(0.13)); // two intervals
    b.D().InjectMouseUp(at, MouseButton::Left);
    CHECK(b.field->GetValue() > 14.0);
    CHECK(b.field->IsFocused()); // the field keeps the focus
}

TEST_CASE("number: a press and a drag scrubs it; Shift fine, Ctrl coarse")
{
    Bed b;
    b.D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseMove(core::Float2{32.0f, 12.0f}); // within the threshold
    CHECK(b.field->GetValue() == doctest::Approx(0.0));
    b.D().InjectMouseMove(core::Float2{50.0f, 12.0f}); // 20 px: five steps
    CHECK(b.field->GetValue() == doctest::Approx(5.0));
    CHECK(b.inputs == 1);
    CHECK(b.changes == 0);
    b.D().InjectMouseUp(core::Float2{50.0f, 12.0f}, MouseButton::Left);
    CHECK(b.changes == 1);
    CHECK_FALSE(b.field->IsEditing()); // a scrub, not a click

    b.field->SetStep(0.0); // continuous: a two-hundredth of the range per four pixels
    b.D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseMove(core::Float2{70.0f, 12.0f}, KeyModShift); // a tenth: 40 px is 0.5
    CHECK(b.field->GetValue() == doctest::Approx(5.5));
    b.D().InjectMouseUp(core::Float2{70.0f, 12.0f}, MouseButton::Left);
}

TEST_CASE("number: Escape mid-scrub puts the value back and reports the cancel")
{
    Bed b;
    b.field->SetValue(3.0);
    int cancels = 0;
    b.field->SetOnValueCancelled([&cancels]() { ++cancels; });
    b.D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseMove(core::Float2{50.0f, 12.0f});
    CHECK(b.field->GetValue() == doctest::Approx(8.0));
    b.D().InjectKeyDown(Bed::K(KeyCode::Escape));
    CHECK(b.field->GetValue() == doctest::Approx(3.0));
    CHECK(b.field->GetText() == core::StringView(u8"3"));
    CHECK(cancels == 1);
    b.D().InjectMouseMove(core::Float2{90.0f, 12.0f}); // the press no longer scrubs
    b.D().InjectMouseUp(core::Float2{90.0f, 12.0f}, MouseButton::Left);
    CHECK(b.field->GetValue() == doctest::Approx(3.0));
    CHECK(b.changes == 0);
    CHECK_FALSE(b.field->IsEditing());

    // Escape on a press not yet a scrub cancels nothing that changed.
    b.D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    b.D().InjectKeyDown(Bed::K(KeyCode::Escape));
    b.D().InjectMouseUp(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    CHECK(cancels == 1);
}

TEST_CASE("number: mixed, no number shows, and the user's next change commits even the value it held")
{
    Bed b;
    b.field->SetPlaceholder(core::StringView(u8"Mixed"));
    b.field->SetValue(4.0);
    b.field->SetMixed(true);
    CHECK(b.field->IsMixed());
    CHECK(b.field->GetText().Size() == 0u);

    // A press let go and Return with nothing typed: still mixed, nothing committed.
    b.ClickToEdit();
    b.D().InjectKeyDown(Bed::K(KeyCode::Return));
    CHECK(b.field->IsMixed());
    CHECK(b.changes == 0);

    // Typed: the value it already held is committed all the same.
    b.D().InjectText(core::StringView(u8"4"));
    b.D().InjectKeyDown(Bed::K(KeyCode::Return));
    CHECK_FALSE(b.field->IsMixed());
    CHECK(b.field->GetValue() == doctest::Approx(4.0));
    CHECK(b.changes == 1);

    // A scrub from mixed, given up: mixed again.
    b.field->SetValue(4.0);
    b.field->SetMixed(true);
    b.other->RequestFocus();
    b.D().InjectMouseDown(core::Float2{30.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseMove(core::Float2{50.0f, 12.0f});
    CHECK_FALSE(b.field->IsMixed());
    b.D().InjectKeyDown(Bed::K(KeyCode::Escape));
    CHECK(b.field->IsMixed());
    CHECK(b.field->GetText().Size() == 0u);
    b.D().InjectMouseUp(core::Float2{50.0f, 12.0f}, MouseButton::Left);

    // SetValue clears it.
    b.field->SetValue(2.0);
    CHECK_FALSE(b.field->IsMixed());
    CHECK(b.field->GetText() == core::StringView(u8"2"));
}

TEST_CASE("number: with wheel steps off, the wheel goes on to what scrolls")
{
    Bed b;
    b.field->SetStepsOnWheel(false);
    b.field->RequestFocus();
    b.D().InjectMouseWheel(core::Float2{30.0f, 12.0f}, core::Float2{0.0f, 1.0f});
    CHECK(b.field->GetValue() == doctest::Approx(0.0));
    CHECK(b.changes == 0);
}

TEST_CASE("number: markup sets its range, its form and its value")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<NumberField min="-10" max="10" step="0.1" value="2.25" suffix=" m"/>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* f = core::Cast<NumberField>(tree.Get());
    REQUIRE(f != nullptr);
    CHECK(f->GetMin() == doctest::Approx(-10.0));
    CHECK(f->GetValue() == doctest::Approx(2.3)); // to the step
    CHECK(f->GetText() == core::StringView(u8"2.3 m"));
}
