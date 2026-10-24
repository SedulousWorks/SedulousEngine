// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The keyboard and the pad in composite widgets (E5 of Specs/gui-lab-evolution.md): a walk through
// a menu bar and a submenu, a combo box closed and open, and a message box, by keys and by the pad.
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
    core::u32 K(KeyCode k) { return static_cast<core::u32>(k); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = Make<SceneRoot>(Make<GUIContext>());
        Bed() { root->SetSize(core::Float2{600.0f, 400.0f}); }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Key(KeyCode k, core::u32 mods = 0) { (void)d().InjectKeyDown(K(k), mods); }
        // A key that types: its key, then its text (what type-ahead reads, E12).
        void Type(KeyCode k, const char8_t* text)
        {
            Key(k);
            (void)d().InjectText(core::StringView(text));
        }
    };

    // The text of the focused menu item, or empty.
    core::StringView FocusedItem(EventDispatcher& d)
    {
        const MenuItem* item = core::Cast<MenuItem>(d.GetFocusNode());
        return item != nullptr ? item->GetText() : core::StringView{};
    }
}

TEST_CASE("keyboard: a walk through a menu bar, its menus and a submenu")
{
    Bed bed;
    auto bar = Make<MenuBar>();
    bed.root->AddChild(bar.Get());
    int opened = 0, saved = 0, deep = 0;
    Menu* file = bar->AddMenu(SV(u8"File"));
    file->AddItem(SV(u8"Open"), [&] { ++opened; });
    file->AddItem(SV(u8"Save"), [&] { ++saved; })->SetEnabled(false); // skipped
    Menu* recent = file->AddSubMenu(SV(u8"Recent"));
    recent->AddItem(SV(u8"First"), [&] { ++deep; });
    recent->AddItem(SV(u8"Second"), [] {});
    Menu* edit = bar->AddMenu(SV(u8"Edit"));
    edit->AddItem(SV(u8"Undo"), [] {});
    bed.root->UpdateLayout();

    bed.Key(KeyCode::F10); // into the bar
    REQUIRE(bed.d().GetFocusNode() == bar->ButtonAt(0));
    bed.Key(KeyCode::Down); // opens File, its first item lit
    CHECK(file->IsOpen());
    CHECK(FocusedItem(bed.d()) == SV(u8"Open"));
    bed.Key(KeyCode::Down); // Save is disabled: skipped
    CHECK(FocusedItem(bed.d()) == SV(u8"Recent"));
    bed.Key(KeyCode::Right); // into the submenu
    CHECK(recent->IsOpen());
    CHECK(FocusedItem(bed.d()) == SV(u8"First"));
    bed.Key(KeyCode::Left); // out again, back on its item
    CHECK_FALSE(recent->IsOpen());
    CHECK(FocusedItem(bed.d()) == SV(u8"Recent"));
    bed.Key(KeyCode::Right); // the next menu on the bar: Right on a submenu item goes in, so first move off it
    bed.Key(KeyCode::Left);
    bed.Key(KeyCode::Up); // Open
    CHECK(FocusedItem(bed.d()) == SV(u8"Open"));
    bed.Key(KeyCode::Right); // File's Open has no submenu: the next menu
    CHECK(edit->IsOpen());
    CHECK_FALSE(file->IsOpen());
    CHECK(FocusedItem(bed.d()) == SV(u8"Undo"));
    bed.Key(KeyCode::Left);
    CHECK(file->IsOpen());
    CHECK(FocusedItem(bed.d()) == SV(u8"Open"));
    bed.Key(KeyCode::Return); // runs it and closes the menu
    CHECK(opened == 1);
    CHECK_FALSE(file->IsOpen());

    // Escape closes, focus going back to the bar's button.
    bar->ButtonAt(0)->RequestFocus();
    bed.Key(KeyCode::Down);
    REQUIRE(file->IsOpen());
    bed.Key(KeyCode::Escape);
    CHECK_FALSE(file->IsOpen());
    CHECK(bed.d().GetFocusNode() == bar->ButtonAt(0));
    CHECK(saved == 0);
    CHECK(deep == 0);
}

TEST_CASE("keyboard: a combo box steps its selection closed, types ahead, and opens on its current item")
{
    Bed bed;
    auto combo = Make<ComboBox>();
    combo->SetSize(core::Float2{140.0f, 26.0f});
    combo->SetItemsText(core::String(SV(u8"Apple|Banana|Blueberry|Cherry")));
    combo->SetSelectedIndex(0);
    bed.root->AddChild(combo.Get());
    combo->RequestFocus();

    bed.Key(KeyCode::Down);
    CHECK(combo->GetSelectedIndex() == 1);
    bed.Type(KeyCode::B, u8"b"); // the next starting with b
    CHECK(combo->GetSelectedText() == SV(u8"Blueberry"));
    bed.Type(KeyCode::B, u8"b"); // round to the first b
    CHECK(combo->GetSelectedText() == SV(u8"Banana"));
    bed.Type(KeyCode::C, u8"c");
    CHECK(combo->GetSelectedIndex() == 3);
    bed.Key(KeyCode::Down); // at the end: given back, the selection stays
    CHECK(combo->GetSelectedIndex() == 3);
    combo->RequestFocus();

    bed.Key(KeyCode::Return); // opens, the list focused on the current item
    REQUIRE(combo->IsOpen());
    ListBox* list = combo->GetDropdown();
    CHECK(bed.d().GetFocusNode() == list);
    CHECK(list->GetSelectedIndex() == 3);
    bed.Key(KeyCode::Up);
    CHECK(combo->GetSelectedIndex() == 3); // moving in the list picks nothing yet
    bed.Key(KeyCode::Return);
    CHECK_FALSE(combo->IsOpen());
    CHECK(combo->GetSelectedText() == SV(u8"Blueberry"));
    CHECK(combo->IsFocused()); // focus back

    bed.Key(KeyCode::Down, KeyModAlt);
    CHECK(combo->IsOpen());
    bed.Key(KeyCode::Escape);
    CHECK_FALSE(combo->IsOpen());
    CHECK(combo->GetSelectedText() == SV(u8"Blueberry"));
    CHECK(combo->IsFocused());
}

TEST_CASE("keyboard: the pad opens a combo box with South and backs out with East")
{
    Bed bed;
    auto combo = Make<ComboBox>();
    combo->SetSize(core::Float2{140.0f, 26.0f});
    combo->SetItemsText(core::String(SV(u8"One|Two")));
    combo->SetSelectedIndex(0);
    bed.root->AddChild(combo.Get());
    combo->RequestFocus();
    bed.d().InjectPadButton(PadButton::South);
    REQUIRE(combo->IsOpen());
    bed.d().PressDirection(NavDirection::Down);
    bed.d().ReleaseDirection(NavDirection::Down);
    bed.d().InjectPadButton(PadButton::South);
    CHECK(combo->GetSelectedText() == SV(u8"Two"));
    CHECK_FALSE(combo->IsOpen());
    bed.d().InjectPadButton(PadButton::South);
    REQUIRE(combo->IsOpen());
    bed.d().InjectPadButton(PadButton::East);
    CHECK_FALSE(combo->IsOpen());
    CHECK(combo->IsFocused());
}

TEST_CASE("keyboard: a message box opens on its default button; Escape and the pad's East cancel")
{
    Bed bed;
    auto behind = Make<Button>();
    behind->SetSize(core::Float2{40.0f, 20.0f});
    bed.root->AddChild(behind.Get());
    behind->RequestFocus();
    MessageBox::Result got = MessageBox::Result::Ok;
    int results = 0;
    const auto show = [&](MessageBox::Buttons buttons)
    {
        auto box = Make<MessageBox>();
        box->Configure(SV(u8"Leave"), SV(u8"Leave the ball?"), buttons);
        box->SetOnResult([&](MessageBox::Result r) { got = r; ++results; });
        box->OpenModal(*bed.root);
        return box;
    };
    auto box = show(MessageBox::Buttons::YesNo);
    CHECK(bed.d().GetFocusNode() == box->ButtonAt(1)); // Yes, the default
    bed.Key(KeyCode::Return);
    CHECK(results == 1);
    CHECK(got == MessageBox::Result::Yes);
    CHECK(behind->IsFocused()); // focus back

    box = show(MessageBox::Buttons::OkCancel);
    bed.Key(KeyCode::Escape);
    CHECK(results == 2);
    CHECK(got == MessageBox::Result::Cancel);

    box = show(MessageBox::Buttons::YesNo);
    bed.d().InjectPadButton(PadButton::East);
    CHECK(results == 3);
    CHECK(got == MessageBox::Result::No);
    CHECK_FALSE(box->IsOpen());
}
