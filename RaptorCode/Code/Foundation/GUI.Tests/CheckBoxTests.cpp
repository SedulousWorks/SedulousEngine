// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CheckBox and ToggleSwitch tests: the button core as a toggle with an indicator part; a
// click toggles and reports, code does not report; the mixed state settles on a click.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{100.0f, 100.0f});
        root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; }); // each at its own size
        return root;
    }

    void Click(EventDispatcher& d)
    {
        d.InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
        d.InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    }

    core::usize Vertices(SceneRoot& root)
    {
        (void)root.UpdateLayout();
        foundation::vg::VGContext vg;
        DrawContext dc{vg};
        root.Draw(dc);
        return vg.GetBatch().vertices.Size();
    }
}

TEST_CASE("checkbox: defaults")
{
    auto cb = Make<CheckBox>();
    CHECK_FALSE(cb->IsChecked());
    CHECK(cb->IsToggle());
    CHECK(cb->IsTabFocusable());
    CHECK(cb->GetTag() == core::StringView(u8"checkbox"));
    CHECK(cb->GetIndicatorPart() != nullptr);
}

TEST_CASE("checkbox: a click toggles it and reports; code's changes do not report")
{
    auto root = MakeRoot();
    auto cb = Make<CheckBox>();
    root->AddChild(cb.Get());
    (void)root->UpdateLayout();
    core::i32 changes = 0;
    bool last = false;
    cb->SetOnToggled([&](bool checked)
    {
        ++changes;
        last = checked;
    });
    EventDispatcher* d = root->GetEventDispatcher();

    Click(*d);
    CHECK(cb->IsChecked());
    CHECK(changes == 1);
    CHECK(last);
    Click(*d);
    CHECK_FALSE(cb->IsChecked());
    CHECK(changes == 2);

    cb->Toggle();
    cb->SetChecked(false);
    CHECK(changes == 2);
}

TEST_CASE("checkbox: the mixed state shows until set, and a click on it checks it")
{
    auto root = MakeRoot();
    auto cb = Make<CheckBox>();
    root->AddChild(cb.Get());
    (void)root->UpdateLayout();
    cb->SetIndeterminate(true);
    CHECK(cb->IsIndeterminate());
    CHECK((cb->GetWidgetStates() & WidgetStateIndeterminate) != 0);

    Click(*root->GetEventDispatcher());
    CHECK(cb->IsChecked());
    CHECK_FALSE(cb->IsIndeterminate());

    cb->SetIndeterminate(true);
    cb->SetChecked(true); // a choice settles it, though the state was already checked
    CHECK_FALSE(cb->IsIndeterminate());
}

TEST_CASE("checkbox: its indicator draws the box, a tick when checked, a bar when mixed")
{
    auto root = MakeRoot();
    auto cb = Make<CheckBox>();
    root->AddChild(cb.Get());
    const core::usize unchecked = Vertices(*root);
    CHECK(unchecked > 0); // the outline
    cb->SetIndeterminate(true);
    const core::usize mixed = Vertices(*root);
    CHECK(mixed > unchecked); // the outline and the bar
    cb->SetChecked(true);
    const core::usize checked = Vertices(*root);
    CHECK(checked > unchecked); // the outline and the tick
    CHECK(checked != mixed);    // a stroked tick, not the bar's rectangle
}

TEST_CASE("switch: toggles like a check box, its knob moving along the track")
{
    auto root = MakeRoot();
    auto sw = Make<ToggleSwitch>();
    root->AddChild(sw.Get());
    (void)root->UpdateLayout();
    CHECK(sw->GetTag() == core::StringView(u8"switch"));
    CHECK(sw->GetSize().x == doctest::Approx(36.0f));
    const core::usize off = Vertices(*root);
    CHECK(off > 0);
    Click(*root->GetEventDispatcher());
    CHECK(sw->IsChecked());
    CHECK(Vertices(*root) == off); // the same track and knob, the knob at the other end
}
