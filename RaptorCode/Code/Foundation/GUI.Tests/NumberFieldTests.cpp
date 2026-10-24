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
