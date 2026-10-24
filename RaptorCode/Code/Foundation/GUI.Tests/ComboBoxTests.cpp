// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ComboBox tests: item management, opening/closing the dropdown popup, picking
// an item through the dropdown, and dismissal (outside click / Escape) via the dispatcher's
// popup support.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
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

    core::RefPtr<ComboBox> MakeCombo(SceneRoot* root)
    {
        auto cb = core::MakeRef<ComboBox>(core::DefaultAllocator());
        cb->SetSize(core::Float2{120.0f, 26.0f});
        cb->SetItemHeight(24.0f);
        cb->AddItem(core::StringView(u8"Red"));
        cb->AddItem(core::StringView(u8"Green"));
        cb->AddItem(core::StringView(u8"Blue"));
        root->AddChild(cb.Get());
        return cb;
    }
}

TEST_CASE("combobox: item management and selection")
{
    auto cb = Make<ComboBox>();
    cb->AddItem(core::StringView(u8"One"));
    cb->AddItem(core::StringView(u8"Two"));
    CHECK(cb->ItemCount() == 2);
    CHECK(cb->GetSelectedIndex() == -1);

    int changes = 0;
    cb->SetOnSelectionChanged([&](int) { ++changes; });
    cb->SetSelectedIndex(1);
    CHECK(cb->GetSelectedIndex() == 1);
    CHECK(cb->GetSelectedText() == core::StringView(u8"Two"));
    CHECK(changes == 1);
    cb->SetSelectedIndex(1); // no change
    CHECK(changes == 1);
}

TEST_CASE("combobox: -1 selects none, and its placeholder shows")
{
    auto cb = Make<ComboBox>();
    cb->AddItem(core::StringView(u8"One"));
    cb->AddItem(core::StringView(u8"Two"));
    cb->SetPlaceholder(core::String(u8"Mixed"));
    cb->SetSelectedIndex(1);
    int changes = 0, last = 0;
    cb->SetOnSelectionChanged([&](int i) { ++changes; last = i; });
    cb->SetSelectedIndex(-1);
    CHECK(cb->GetSelectedIndex() == -1);
    CHECK(cb->GetSelectedText().Size() == 0u);
    CHECK(changes == 1);
    CHECK(last == -1);
    cb->SetSelectedIndex(-2); // not an index: nothing
    CHECK(changes == 1);
}

TEST_CASE("combobox: click opens the dropdown; it registers as the dispatcher popup")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto cb = MakeCombo(root.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    CHECK_FALSE(cb->IsOpen());
    CHECK(d->PopupCount() == 0u);

    // Click the combo (a press+release on it).
    d->InjectMouseDown(core::Float2{20.0f, 13.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 13.0f}, MouseButton::Left);
    CHECK(cb->IsOpen());
    CHECK(d->TopPopup() == cb->GetDropdown()); // the dropdown is the open popup
    CHECK(cb->GetDropdown()->GetParent() == cb.Get()); // the combo box's child while open
}

TEST_CASE("combobox: clicking a dropdown row selects it and closes")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto cb = MakeCombo(root.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{20.0f, 13.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 13.0f}, MouseButton::Left); // open
    REQUIRE(cb->IsOpen());

    // The dropdown sits just below the combo (combo is 26 tall at y=0). Row 1 (Green) spans
    // y in [26 + 24, 26 + 48) = [50, 74).
    d->InjectMouseDown(core::Float2{20.0f, 60.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 60.0f}, MouseButton::Left);
    CHECK(cb->GetSelectedIndex() == 1);
    CHECK(cb->GetSelectedText() == core::StringView(u8"Green"));
    CHECK_FALSE(cb->IsOpen());
    CHECK(root->GetEventDispatcher()->PopupCount() == 0u);
}

TEST_CASE("combobox: clicking outside dismisses the dropdown")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto cb = MakeCombo(root.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{20.0f, 13.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 13.0f}, MouseButton::Left); // open
    REQUIRE(cb->IsOpen());

    // Press far away from the combo and its dropdown -> dismissed.
    d->InjectMouseDown(core::Float2{350.0f, 350.0f}, MouseButton::Left);
    CHECK_FALSE(cb->IsOpen());
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("combobox: Escape dismisses the dropdown")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto cb = MakeCombo(root.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{20.0f, 13.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 13.0f}, MouseButton::Left); // open
    REQUIRE(cb->IsOpen());

    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(cb->IsOpen());
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("combobox: the dropdown opens below the box at a display scale")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetDisplayScale(2.0f); // device pixels are twice the root's units
    root->SetSize(core::Float2{300.0f, 300.0f});
    auto cb = MakeCombo(root.Get());
    cb->SetPosition(core::Float2{10.0f, 20.0f});
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{60.0f, 60.0f}, MouseButton::Left); // device pixels, inside the box
    d->InjectMouseUp(core::Float2{60.0f, 60.0f}, MouseButton::Left);
    REQUIRE(cb->IsOpen());
    REQUIRE(d->TopPopup() != nullptr);
    CHECK(d->TopPopup()->GetPosition().x == doctest::Approx(10.0f));
    CHECK(d->TopPopup()->GetPosition().y == doctest::Approx(46.0f)); // the box's bottom, in root units
}

TEST_CASE("combobox: new items drop the old selection's text; the selection binds and a pick reports a change")
{
    auto cb = Make<ComboBox>();
    cb->SetItemsText(core::String(u8"Low|High"));
    cb->SetSelectedIndex(1);
    CHECK(cb->GetSelectedText() == core::StringView(u8"High"));
    cb->SetItemsText(core::String(u8"A|B|C"));
    CHECK(cb->GetSelectedIndex() == -1);
    CHECK(cb->GetSelectedText().Size() == 0u);

    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto combo = MakeCombo(root.Get());
    DataModel& data = root->GetContext().GetData();
    data.Set(core::StringView(u8"pick"), core::Variant::From<core::i32>(1));
    REQUIRE(combo->BindData(core::StringView(u8"selected"), root->GetContext().GetDataRef(), core::StringView(u8"pick")));
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(combo->GetSelectedIndex() == 1); // the data's
    int changes = 0;
    (void)combo->AddEventListener(EventType::Changed, [&changes](const Event&) { ++changes; });
    combo->SelectByUser(2);
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(changes == 1);
    const core::Variant back = data.Get(core::StringView(u8"pick"));
    REQUIRE(back.TryGet<core::i32>() != nullptr);
    CHECK(*back.TryGet<core::i32>() == 2); // written back
    combo->SetSelectedIndex(0);
    CHECK(changes == 1); // code's change is no user's
}
