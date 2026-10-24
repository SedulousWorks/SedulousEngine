// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the `back` command (K1 of Specs/gui-lab-evolution-3.md): Escape and the pad's East run it
// through the keymap; the topmost auto popup answers it by closing, before anything under it; a
// modal dialog answers it as its close button does; else what handles it on the focus path (a
// game's screen) does; a game rebinds or unbinds it like any key.
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

    // A GUI holding a "screen" that counts the `back`s it hears, with a focused button on it.
    struct BackBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> screen = Make<UIWidget>();
        core::RefPtr<Button> button = Make<Button>();
        int backs = 0;

        BackBed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            screen->SetSize(core::Float2{400.0f, 300.0f});
            root->AddChild(screen.Get());
            button->SetSize(core::Float2{60.0f, 20.0f});
            screen->AddChild(button.Get());
            (void)screen->OnCommand(core::StringView(kBackCommand), [this](CommandEvent&) { ++backs; });
            d().SetFocusNode(button.Get());
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Escape() { (void)d().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape)); }
        core::RefPtr<UIWidget> OpenAuto(Node& owner)
        {
            auto popup = Make<UIWidget>();
            popup->SetSize(core::Float2{50.0f, 50.0f});
            PopupOptions options;
            options.AnchorRect = Rect{100.0f, 100.0f, 0.0f, 0.0f};
            options.HasAnchorRect = true;
            d().OpenPopup(owner, *popup, core::Move(options));
            return popup;
        }
    };
}

TEST_CASE("back: Escape and the pad's East run it, and the screen on the focus path hears it")
{
    BackBed bed;
    bed.Escape();
    CHECK(bed.backs == 1);
    bed.d().InjectPadButton(PadButton::East);
    CHECK(bed.backs == 2);
    CHECK(bed.root->IsCommandAvailable(core::StringView(kBackCommand)));
}

TEST_CASE("back: the topmost auto popup closes first, one at a time, whether or not it holds the focus")
{
    BackBed bed;
    auto outer = bed.OpenAuto(*bed.button);
    auto inner = bed.OpenAuto(*outer); // a submenu
    REQUIRE(bed.d().PopupCount() == 2u);
    bed.Escape();
    CHECK_FALSE(bed.d().IsPopupOpen(*inner));
    CHECK(bed.d().IsPopupOpen(*outer));
    bed.d().InjectPadButton(PadButton::East);
    CHECK_FALSE(bed.d().IsPopupOpen(*outer));
    CHECK(bed.backs == 0); // the screen under them heard neither
    bed.Escape();
    CHECK(bed.backs == 1);
}

TEST_CASE("back: a modal dialog answers it as its close button does, and only while open")
{
    BackBed bed;
    auto window = Make<Window>();
    window->SetSize(core::Float2{200.0f, 120.0f});
    int closed = 0;
    window->SetOnClose([&closed]() { ++closed; });
    window->OpenModal(*bed.root);
    bed.Escape();
    CHECK_FALSE(window->IsOpen());
    CHECK(closed == 1);
    CHECK(bed.backs == 0); // what was under the modal is inert

    // One that may not be closed keeps its back to itself: under it nothing hears it.
    window->SetClosable(false);
    window->OpenModal(*bed.root);
    bed.Escape();
    CHECK(window->IsOpen());
    CHECK(bed.backs == 0);
    window->Close();

    // Not modal, it does not answer: the screen does.
    window->SetClosable(true);
    window->Open(*bed.screen);
    bed.d().SetFocusNode(bed.button.Get());
    bed.Escape();
    CHECK(window->IsOpen());
    CHECK(bed.backs == 1);
}

TEST_CASE("back: a message box picks its cancel result; a popup opened in it closes first")
{
    BackBed bed;
    MessageBox::Result got = MessageBox::Result::Ok;
    auto box = Make<MessageBox>();
    box->Configure(core::StringView(u8"Confirm"), core::StringView(u8"Delete it?"), MessageBox::Buttons::OkCancel);
    box->SetOnResult([&got](MessageBox::Result r) { got = r; });
    box->OpenModal(*bed.root);
    auto list = bed.OpenAuto(*box->ButtonAt(1)); // a combo box's list in the dialog
    bed.d().InjectPadButton(PadButton::East);
    CHECK_FALSE(bed.d().IsPopupOpen(*list));
    CHECK(box->IsOpen());
    bed.Escape();
    CHECK_FALSE(box->IsOpen());
    CHECK(got == MessageBox::Result::Cancel);
    CHECK(bed.backs == 0);
}

TEST_CASE("back: a game unbinds Escape from it, and Escape closes nothing")
{
    BackBed bed;
    (void)bed.root->GetContext().GetKeymap().Bind(core::StringView(u8"escape"), core::StringView{});
    auto popup = bed.OpenAuto(*bed.button);
    bed.Escape();
    CHECK(bed.d().IsPopupOpen(*popup));
    CHECK(bed.backs == 0);
    bed.d().InjectPadButton(PadButton::East); // the pad's binding stands
    CHECK_FALSE(bed.d().IsPopupOpen(*popup));
}

TEST_CASE("back: a focused widget's own Escape still comes first")
{
    BackBed bed;
    (void)bed.button->AddEventListener(EventType::KeyDown, [](const Event& e) { e.Handled = true; });
    bed.Escape();
    CHECK(bed.backs == 0);
    bed.d().InjectPadButton(PadButton::East); // the pad's East is `back` first, by its binding
    CHECK(bed.backs == 1);
}
