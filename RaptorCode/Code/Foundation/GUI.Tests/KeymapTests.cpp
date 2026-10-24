// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - bindings (G7 of Specs/vg-and-gui-lab.md): keystrokes and gamepad buttons bound to commands,
// scoped by context predicates over the focus path (the deepest match winning, then the later
// binding), unbinding, chords, and the order keys take (the widget, then bindings, then navigation).
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
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> screen = Make<UIWidget>(); // key context "menu"
        core::RefPtr<Button> item = Make<Button>();
        core::Array<core::String> ran;
        Bed()
        {
            root->AddChild(screen.Get());
            screen->AddChild(item.Get());
            screen->SetKeyContext(SV(u8"menu mode=main"));
            item->SetTabFocusable(true);
            item->SetSize(core::Float2{40.0f, 20.0f});
            root->GetEventDispatcher()->SetFocusNode(item.Get());
        }
        void Handle(const char8_t* id)
        {
            (void)root->OnCommand(SV(id), [this, id](CommandEvent&) { ran.PushBack(core::String(id)); });
        }
        void Key(KeyCode key, core::u32 mods = 0) { root->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(key), mods); }
    };
}

TEST_CASE("keymap: a text field keeps its keys, and leaves a shortcut to the bindings")
{
    Bed bed;
    bed.Handle(u8"save");
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-s"), SV(u8"save")));
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-a"), SV(u8"save"))); // the field's own: it keeps it
    auto field = Make<TextField>();
    bed.screen->AddChild(field.Get());
    bed.root->GetEventDispatcher()->SetFocusNode(field.Get());
    field->SetText(SV(u8"hello"));
    bed.Key(KeyCode::A, KeyModCtrl);
    CHECK(bed.ran.IsEmpty()); // select-all in the field
    bed.root->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(KeyCode::Unknown), KeyModCtrl);
    CHECK(bed.ran.IsEmpty());
}

TEST_CASE("keymap: `>` holds for a context inside another")
{
    KeyContextLayer outer;
    outer.Declare(SV(u8"menu"));
    KeyContextLayer inner = outer;
    inner.Declare(SV(u8"textinput"));
    KeyContextLayer elsewhere;
    elsewhere.Declare(SV(u8"textinput"));
    const KeyContextLayer nested[] = {outer, inner};
    const KeyContextLayer alone[] = {elsewhere};
    ContextPredicate p;
    REQUIRE(p.Parse(SV(u8"menu > textinput")));
    CHECK(p.Eval(core::Span<const KeyContextLayer>(nested, 2), 1));
    CHECK_FALSE(p.Eval(core::Span<const KeyContextLayer>(nested, 2), 0)); // the menu itself
    CHECK_FALSE(p.Eval(core::Span<const KeyContextLayer>(alone, 1), 0)); // a field in no menu
    REQUIRE(p.Parse(SV(u8"menu > textinput && !multiline || game"))); // `>` binds loosest
    CHECK(p.Eval(core::Span<const KeyContextLayer>(nested, 2), 1));
    CHECK_FALSE(p.Parse(SV(u8"menu >")));

    // A binding for fields inside a menu beats the fields' own.
    Bed bed;
    bed.Handle(u8"menu.field-escape");
    auto field = Make<TextField>();
    field->SetSize(core::Float2{100.0f, 20.0f});
    bed.screen->AddChild(field.Get());
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-a"), SV(u8"menu.field-escape"), SV(u8"menu > textinput")));
    field->RequestFocus();
    bed.Key(KeyCode::A, KeyModCtrl);
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == SV(u8"menu.field-escape"));
}

TEST_CASE("keymap: a control bound to a command shows its label and keys, and follows them")
{
    Bed bed;
    Command& save = bed.root->GetContext().DefineCommand(SV(u8"save"));
    save.SetLabel(SV(u8"Save"));
    bed.Handle(u8"save");
    auto button = Make<Button>();
    bed.screen->AddChild(button.Get());
    button->SetCommand(SV(u8"save"));
    auto menu = Make<Menu>();
    MenuItem* item = menu->AddItem(SV(u8""), [] {});
    bed.screen->AddChild(menu.Get()); // in the tree, so its binding runs
    item->SetCommand(SV(u8"save"));
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-s"), SV(u8"save")));
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.016)); // bindings run once a frame
    CHECK(button->GetText() == SV(u8"Save"));
    CHECK(item->GetText() == SV(u8"Save"));
    CHECK(item->GetShortcut() == SV(u8"Ctrl+S"));

    save.SetLabel(SV(u8"Save all"));
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-shift-s"), SV(u8"save")));
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.016));
    CHECK(button->GetText() == SV(u8"Save all"));
    CHECK(item->GetShortcut() == SV(u8"Ctrl+Shift+S"));

    // A control with its own text keeps it.
    auto own = Make<Button>();
    own->SetText(SV(u8"Keep"));
    bed.screen->AddChild(own.Get());
    own->SetCommand(SV(u8"save"));
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.016));
    CHECK(own->GetText() == SV(u8"Keep"));
}

TEST_CASE("keymap: a text field's context menu shows the keys bound to its commands")
{
    Bed bed;
    auto field = Make<TextField>();
    field->SetSize(core::Float2{100.0f, 20.0f});
    bed.screen->AddChild(field.Get());
    field->RequestFocus();
    (void)bed.root->GetEventDispatcher()->InjectContextMenu();
    Menu* menu = field->GetContextMenu();
    REQUIRE(menu != nullptr);
    const MenuItem* cut = core::Cast<MenuItem>(menu->GetChildAt(0));
    REQUIRE(cut != nullptr);
    CHECK(cut->GetShortcut() == SV(u8"Ctrl+X"));
}
