// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - bindings (G5 of Specs/vg-and-gui-lab.md): a node's bindings follow what they read, on the
// GUI's frame; any reflected property binds by name, converted to its type; a widget's user-set
// state writes back; the GUI's data model holds named values; nothing subscribes by hand.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::f64;
using core::i32;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Frame() { return core::Duration::FromSeconds(0.016); }
}

TEST_CASE("binding: values convert to the property's type, and compare across numbers")
{
    CHECK(FormatVariant(core::Variant::From<f64>(3.0)) == core::String(u8"3"));
    CHECK(FormatVariant(core::Variant::From<f32>(0.25f)) == core::String(u8"0.25"));
    CHECK(FormatVariant(core::Variant::From<f32>(0.4f)) == core::String(u8"0.4")); // not 0.4000000059604645
    CHECK(FormatVariant(core::Variant::From<f32>(2.0f)) == core::String(u8"2"));
    CHECK(FormatVariant(core::Variant::From<bool>(true)) == core::String(u8"true"));
    const core::Variant f = ConvertVariant(core::Variant::From<f64>(0.5), core::TypeOf<f32>());
    REQUIRE(f.TryGet<f32>() != nullptr);
    CHECK(*f.TryGet<f32>() == doctest::Approx(0.5f));
    const core::Variant i = ConvertVariant(core::Variant::From<core::String>(core::String(u8" 42 ")), core::TypeOf<i32>());
    REQUIRE(i.TryGet<i32>() != nullptr);
    CHECK(*i.TryGet<i32>() == 42);
    CHECK(ConvertVariant(core::Variant::From<core::String>(core::String(u8"abc")), core::TypeOf<f32>()).IsEmpty());
    CHECK(VariantsEqual(core::Variant::From<i32>(2), core::Variant::From<f64>(2.0)));
    CHECK_FALSE(VariantsEqual(core::Variant::From<i32>(2), core::Variant::From<core::String>(core::String(u8"2"))));
}

TEST_CASE("binding: a bound label follows its source on the GUI's frame")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto label = Make<Label>();
    root->AddChild(label.Get());
    DataModel& data = root->GetContext().GetData();
    data.Set(SV(u8"score"), core::Variant::From<i32>(3));

    REQUIRE(label->BindProperty(SV(u8"text"), [&data] { return data.Get(SV(u8"score")); }));
    CHECK(label->GetText() == SV(u8"3")); // bound at once

    data.Set(SV(u8"score"), core::Variant::From<i32>(4));
    data.Set(SV(u8"score"), core::Variant::From<i32>(5));
    CHECK(label->GetText() == SV(u8"3")); // waits for the frame
    CHECK(root->NeedsFrame());
    root->GetContext().Update(Frame());
    CHECK(label->GetText() == SV(u8"5"));
    CHECK(root->GetContext().LastBindingCount() == 1u); // two changes, one run

    root->GetContext().Update(Frame());
    CHECK(root->GetContext().LastBindingCount() == 0u);
    data.Set(SV(u8"score"), core::Variant::From<f64>(5.0)); // the same number: no change
    root->GetContext().Update(Frame());
    CHECK(root->GetContext().LastBindingCount() == 0u);
}

TEST_CASE("binding: one widget's state drives another's, with no subscription")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto slider = Make<Slider>();
    auto label = Make<Label>();
    auto bar = Make<ProgressBar>();
    root->AddChild(slider.Get());
    root->AddChild(label.Get());
    root->AddChild(bar.Get());
    Slider* s = slider.Get();
    REQUIRE(label->BindProperty(SV(u8"text"), [s] { return core::Variant::From<f32>(s->GetValue()); }));
    REQUIRE(bar->BindProperty(SV(u8"value"), [s] { return core::Variant::From<core::f64>(s->GetValue()); }));

    slider->SetValue(0.25f);
    root->GetContext().Update(Frame());
    CHECK(label->GetText() == SV(u8"0.25"));
    CHECK(bar->GetValue() == doctest::Approx(0.25f));
}

TEST_CASE("binding: a widget the user changes writes back, both ways without a loop")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto slider = Make<Slider>();
    root->AddChild(slider.Get());
    DataModel& data = root->GetContext().GetData();
    data.Set(SV(u8"volume"), core::Variant::From<f64>(0.5));
    REQUIRE(slider->BindProperty(SV(u8"value"), [&data] { return data.Get(SV(u8"volume")); }));
    REQUIRE(slider->BindPropertyBack(SV(u8"value"), [&data](const core::Variant& v) { data.Set(SV(u8"volume"), v); }));
    CHECK(slider->GetValue() == doctest::Approx(0.5f));

    slider->SetValue(0.75f); // the user drags it
    root->GetContext().Update(Frame());
    REQUIRE(data.Get(SV(u8"volume")).TryGet<core::f64>() != nullptr); // a range's value is an f64
    CHECK(*data.Get(SV(u8"volume")).TryGet<core::f64>() == doctest::Approx(0.75));
    root->GetContext().Update(Frame());
    CHECK(root->GetContext().LastBindingCount() == 0u); // settled

    data.Set(SV(u8"volume"), core::Variant::From<f64>(0.1)); // the game sets it
    root->GetContext().Update(Frame());
    CHECK(slider->GetValue() == doctest::Approx(0.1f));
}

TEST_CASE("binding: a text field written back keeps its caret")
{
    auto field = Make<TextField>();
    field->SetText(SV(u8"hello"));
    field->SetCaret(2);
    field->SetText(SV(u8"hello")); // a binding writing back what was typed
    CHECK(field->GetCaret() == 2u);
}

TEST_CASE("binding: outside a scene a binding runs at once; it ends with its node")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    DataModel& data = root->GetContext().GetData();
    auto label = Make<Label>(); // not in the scene
    REQUIRE(label->BindProperty(SV(u8"text"), [&data] { return data.Get(SV(u8"name")); }));
    data.Set(SV(u8"name"), core::Variant::From<core::String>(core::String(u8"Ada")));
    CHECK(label->GetText() == SV(u8"Ada"));

    label->ClearBindings();
    data.Set(SV(u8"name"), core::Variant::From<core::String>(core::String(u8"Bo")));
    CHECK(label->GetText() == SV(u8"Ada"));

    {
        auto gone = Make<Label>();
        root->AddChild(gone.Get());
        REQUIRE(gone->BindProperty(SV(u8"text"), [&data] { return data.Get(SV(u8"name")); }));
        data.Set(SV(u8"name"), core::Variant::From<core::String>(core::String(u8"Cy"))); // queued
        root->RemoveChild(gone.Get());
    }
    root->GetContext().Update(Frame()); // the queued binding went with its node
    CHECK(root->GetContext().LastBindingCount() == 0u);
}

TEST_CASE("binding: an unknown or read-only property does not bind")
{
    auto label = Make<Label>();
    CHECK_FALSE(label->BindProperty(SV(u8"nonesuch"), [] { return core::Variant{}; }));
    CHECK_FALSE(label->BindPropertyBack(SV(u8"nonesuch"), [](const core::Variant&) {}));
    CHECK(label->BindingCount() == 0u);
}

TEST_CASE("binding: a name read before it is set is followed, and takes its first value")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto label = Make<Label>();
    root->AddChild(label.Get());
    DataModel& data = root->GetContext().GetData();
    REQUIRE(label->BindProperty(SV(u8"text"), [&data] { return data.Get(SV(u8"later")); }));
    CHECK_FALSE(data.Has(SV(u8"later")));
    data.Set(SV(u8"later"), core::Variant::From<i32>(9));
    root->GetContext().Update(Frame());
    CHECK(label->GetText() == SV(u8"9"));
}
