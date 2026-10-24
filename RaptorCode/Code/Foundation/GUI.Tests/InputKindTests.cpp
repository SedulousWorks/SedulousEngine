// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the input kind (K2b of Specs/gui-lab-evolution-3.md): what drives the GUI now, the
// pointer, the keyboard or a pad, from what the dispatcher is given or what a host's tracker says;
// the focus ring follows it, a pad hides the cursor, the root hears `inputkind`, a binding follows
// it, and a sheet reads it as `@media (input: ...)`.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    struct KindBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Button> button = core::MakeRef<Button>(core::DefaultAllocator());

        KindBed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            button->SetSize(core::Float2{80.0f, 30.0f});
            root->AddChild(button.Get());
            (void)root->UpdateLayout();
            d().SetFocusNode(button.Get());
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Click(core::Float2 at = core::Float2{300.0f, 200.0f})
        {
            d().InjectMouseDown(at, MouseButton::Left);
            d().InjectMouseUp(at, MouseButton::Left);
        }
    };
}

TEST_CASE("input kind: the keys until the pointer is used; a press, a key, a pad button and a pad direction each say theirs")
{
    KindBed bed;
    CHECK(bed.d().GetInputKind() == InputKind::Keyboard);
    CHECK(bed.button->IsFocusVisible());
    bed.Click();
    CHECK(bed.d().GetInputKind() == InputKind::Pointer);
    bed.d().SetFocusNode(bed.button.Get());
    CHECK_FALSE(bed.button->IsFocusVisible()); // the ring hides under the pointer
    (void)bed.d().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab));
    CHECK(bed.d().GetInputKind() == InputKind::Keyboard);
    bed.d().InjectPadButton(PadButton::West);
    CHECK(bed.d().GetInputKind() == InputKind::Pad);
    CHECK(bed.d().IsUsingKeyboard()); // a pad drives as the keys do
    bed.Click();
    bed.d().PressDirection(NavDirection::Down);
    bed.d().ReleaseDirection(NavDirection::Down);
    CHECK(bed.d().GetInputKind() == InputKind::Pad);
    CHECK(bed.button->IsFocusVisible());
}

TEST_CASE("input kind: the pad's East standing in for Escape is still the pad")
{
    KindBed bed;
    (void)bed.root->GetContext().GetKeymap().Bind(core::StringView(u8"pad-east"), core::StringView{}); // nothing takes it as back
    bed.d().InjectPadButton(PadButton::East);
    CHECK(bed.d().GetInputKind() == InputKind::Pad);
}

TEST_CASE("input kind: a host's word sets it; the root hears each change once and a binding follows it")
{
    KindBed bed;
    core::Array<InputKind> heard;
    (void)bed.root->AddEventListener(EventType::InputKindChanged,
                                     [&](const Event&) { heard.PushBack(bed.root->GetEventDispatcher()->GetInputKind()); });
    core::String shown;
    EventDispatcher* dispatcher = &bed.d();
    bed.button->Bind([&shown, dispatcher]() { shown = core::String(InputKindName(dispatcher->ObserveInputKind())); });
    bed.root->GetContext().Update(core::Duration{});
    CHECK(shown == core::StringView(u8"keyboard"));

    bed.d().SetInputKind(InputKind::Pad); // a stick pushed, which reaches no widget
    bed.d().SetInputKind(InputKind::Pad);
    bed.root->GetContext().Update(core::Duration{});
    CHECK(shown == core::StringView(u8"pad"));
    bed.d().SetInputKind(InputKind::Pointer); // a mouse moved
    REQUIRE(heard.Size() == 2);
    CHECK(heard[0] == InputKind::Pad);
    CHECK(heard[1] == InputKind::Pointer);
    CHECK_FALSE(bed.button->IsFocusVisible());
}

TEST_CASE("input kind: a pad hides the cursor; the pointer brings it back; `cursor: none` hides it anywhere")
{
    KindBed bed;
    bed.button->SetCursor(Cursor::Pointer);
    bed.d().InjectMouseMove(core::Float2{10.0f, 10.0f});
    CHECK(bed.d().GetCursor() == Cursor::Pointer);
    bed.d().SetInputKind(InputKind::Pad);
    CHECK(bed.d().GetCursor() == Cursor::None);
    bed.d().SetInputKind(InputKind::Pointer);
    CHECK(bed.d().GetCursor() == Cursor::Pointer);
    CHECK(CursorNamed(core::StringView(u8"none")) == Cursor::None);
    CHECK(CursorName(Cursor::None) == core::StringView(u8"none"));
    bed.button->SetCursorName(core::String(u8"none"));
    CHECK(bed.d().GetCursor() == Cursor::None);
}

TEST_CASE("input kind: a sheet reads it as @media (input: ...), restyling when it changes")
{
    KindBed bed;
    bed.button->AddClass(core::StringView(u8"hint"));
    StyleManager styles(CSSParser::Parse(core::StringView(
        u8".hint { opacity: 1; } @media (input: pad) { .hint { opacity: 0.25; } } @media (input: pointer) { .hint { opacity: 0.5; } }")));
    const auto frame = [&]()
    {
        styles.SetMediaContext(bed.root->GetMediaContext());
        styles.ApplyTree(*bed.root);
    };
    frame();
    CHECK(bed.button->GetAlpha() == doctest::Approx(1.0f)); // the keys: neither
    bed.d().SetInputKind(InputKind::Pad);
    frame();
    CHECK(bed.button->GetAlpha() == doctest::Approx(0.25f));
    bed.d().SetInputKind(InputKind::Pointer);
    frame();
    CHECK(bed.button->GetAlpha() == doctest::Approx(0.5f));
    CHECK(MediaQuery(core::StringView(u8"(input: keyboard)")).Evaluate(MediaContext{100.0f, 100.0f, 96.0f, true, ContrastPreference::NoPreference, false, InputKind::Keyboard}));
    CHECK_FALSE(MediaQuery(core::StringView(u8"(input: mouse)")).Evaluate(MediaContext{})); // a value it does not know matches nothing
}
