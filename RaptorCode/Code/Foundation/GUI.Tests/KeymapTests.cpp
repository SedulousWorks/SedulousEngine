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

TEST_CASE("keymap: keystrokes, chords and predicates parse")
{
    const auto s = ParseKeystroke(SV(u8"ctrl-shift-a"));
    REQUIRE(s.HasValue());
    CHECK(s.Value().Code == static_cast<core::u32>(KeyCode::A));
    CHECK(s.Value().Modifiers == (KeyModCtrl | KeyModShift));
    CHECK(ParseKeystroke(SV(u8"pad-east")).Value().Pad);
    CHECK_FALSE(ParseKeystroke(SV(u8"hyper-a")).HasValue());
    CHECK_FALSE(ParseKeystroke(SV(u8"pad-turbo")).HasValue());

    ContextPredicate p;
    REQUIRE(p.Parse(SV(u8"menu && (mode == main || !modal)")));
    KeyContextLayer layer;
    layer.Declare(SV(u8"menu mode=main"));
    CHECK(p.Eval(layer));
    layer.Declare(SV(u8"mode=settings modal"));
    CHECK_FALSE(p.Eval(layer));
    CHECK_FALSE(p.Parse(SV(u8"menu &&")));
    CHECK_FALSE(p.Eval(layer)); // malformed matches nothing
    Keymap keymap;
    CHECK_FALSE(keymap.Bind(SV(u8"ctrl-nonesuch"), SV(u8"x")));
    CHECK_FALSE(keymap.Bind(SV(u8"escape"), SV(u8"x"), SV(u8"(menu")));
}

TEST_CASE("keymap: the deepest matching context wins, then the later binding")
{
    Bed bed;
    bed.Handle(u8"quit");
    bed.Handle(u8"back");
    bed.Handle(u8"close");
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"quit")));                   // everywhere
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"back"), SV(u8"menu")));     // in the menu: deeper
    bed.Key(KeyCode::Escape);
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == core::String(u8"back"));

    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"close"), SV(u8"mode == main"))); // as deep, later: wins
    bed.Key(KeyCode::Escape);
    CHECK(bed.ran[1] == core::String(u8"close"));

    // Focus outside the menu: only the context-free binding holds.
    auto outside = Make<Button>();
    outside->SetTabFocusable(true);
    bed.root->AddChild(outside.Get());
    bed.root->GetEventDispatcher()->SetFocusNode(outside.Get());
    bed.Key(KeyCode::Escape);
    CHECK(bed.ran[2] == core::String(u8"quit"));
}

TEST_CASE("keymap: an outer node's context does not outrank the focused one's")
{
    // The game screen declares "game"; the menu inside it declares "menu". Escape pauses in the
    // game and closes in the menu, whichever was bound later.
    Bed bed;
    bed.Handle(u8"pause");
    bed.Handle(u8"close");
    auto game = Make<UIWidget>();
    bed.root->RemoveChild(bed.screen.Get());
    bed.root->AddChild(game.Get());
    game->AddChild(bed.screen.Get());
    game->SetKeyContext(SV(u8"game"));
    bed.root->GetEventDispatcher()->SetFocusNode(bed.item.Get());
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"close"), SV(u8"menu")));
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"pause"), SV(u8"game"))); // later, but outer
    bed.Key(KeyCode::Escape);
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == core::String(u8"close"));

    // "not in a menu" holds only outside it.
    REQUIRE(keys.Bind(SV(u8"f1"), SV(u8"pause"), SV(u8"game && !menu")));
    bed.Key(KeyCode::F1);
    CHECK(bed.ran.Size() == 1u);
    auto hud = Make<Button>();
    hud->SetTabFocusable(true);
    game->AddChild(hud.Get());
    bed.root->GetEventDispatcher()->SetFocusNode(hud.Get());
    bed.Key(KeyCode::F1);
    REQUIRE(bed.ran.Size() == 2u);
    CHECK(bed.ran[1] == core::String(u8"pause"));
    bed.Key(KeyCode::Escape); // outside the menu: the game's binding
    REQUIRE(bed.ran.Size() == 3u);
    CHECK(bed.ran[2] == core::String(u8"pause"));
}

TEST_CASE("keymap: a binding to nothing unbinds a key there")
{
    Bed bed;
    bed.Handle(u8"quit");
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8"quit")));
    REQUIRE(keys.Bind(SV(u8"escape"), SV(u8""), SV(u8"menu"))); // not in the menu
    bed.Key(KeyCode::Escape);
    CHECK(bed.ran.IsEmpty());
}

TEST_CASE("keymap: a chord waits for its next keystroke, and lapses")
{
    Bed bed;
    bed.Handle(u8"comment");
    bed.Handle(u8"select-all");
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"ctrl-x ctrl-c"), SV(u8"comment")));
    REQUIRE(keys.Bind(SV(u8"ctrl-a"), SV(u8"select-all")));
    bed.Key(KeyCode::X, KeyModCtrl); // waits
    CHECK(bed.ran.IsEmpty());
    bed.Key(KeyCode::C, KeyModCtrl);
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == core::String(u8"comment"));

    bed.Key(KeyCode::X, KeyModCtrl);
    bed.root->GetContext().Update(core::Duration::FromSeconds(1.5)); // too slow: dropped
    bed.Key(KeyCode::C, KeyModCtrl);
    CHECK(bed.ran.Size() == 1u);

    bed.Key(KeyCode::X, KeyModCtrl);
    bed.Key(KeyCode::A, KeyModCtrl); // broken off: the keystroke alone
    REQUIRE(bed.ran.Size() == 2u);
    CHECK(bed.ran[1] == core::String(u8"select-all"));
}

TEST_CASE("keymap: a gamepad's buttons bind too; South activates when unbound")
{
    Bed bed;
    bed.Handle(u8"back");
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"pad-east"), SV(u8"back")));
    int clicks = 0;
    (void)bed.item->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    EventDispatcher& d = *bed.root->GetEventDispatcher();
    d.InjectPadButton(PadButton::East);
    REQUIRE(bed.ran.Size() == 1u);
    d.InjectPadButton(PadButton::South);
    CHECK(clicks == 1);
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

TEST_CASE("keymap: a command's keys as text, the latest binding's, following a rebinding")
{
    Keymap keymap;
    CHECK(keymap.ShortcutText(SV(u8"save")).Size() == 0u);
    REQUIRE(keymap.Bind(SV(u8"ctrl-s"), SV(u8"save")));
    CHECK(keymap.ShortcutText(SV(u8"save")) == SV(u8"Ctrl+S"));
    REQUIRE(keymap.Bind(SV(u8"ctrl-k ctrl-shift-s"), SV(u8"save")));
    CHECK(keymap.ShortcutText(SV(u8"save")) == SV(u8"Ctrl+K Ctrl+Shift+S"));
    REQUIRE(keymap.Bind(SV(u8"f12"), SV(u8"shot")));
    CHECK(keymap.ShortcutText(SV(u8"shot")) == SV(u8"F12"));
    REQUIRE(keymap.Bind(SV(u8"pad-east"), SV(u8"back")));
    CHECK(keymap.ShortcutText(SV(u8"back")) == SV(u8"Pad East"));
    CHECK(KeystrokeText(ParseKeystroke(SV(u8"alt-enter")).Value()) == SV(u8"Alt+Enter"));
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

TEST_CASE("keymap: a chord cut short runs what its first key binds alone: timed out, or broken off")
{
    Bed bed;
    bed.Handle(u8"kill");
    bed.Handle(u8"kill-all");
    bed.Handle(u8"select-all");
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"ctrl-k"), SV(u8"kill")));
    REQUIRE(keys.Bind(SV(u8"ctrl-k ctrl-a"), SV(u8"kill-all")));
    REQUIRE(keys.Bind(SV(u8"ctrl-a"), SV(u8"select-all")));
    bed.Key(KeyCode::K, KeyModCtrl); // waits: a chord may follow
    CHECK(bed.ran.IsEmpty());
    bed.root->GetContext().Update(core::Duration::FromSeconds(1.5)); // none did
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == core::String(u8"kill"));

    bed.Key(KeyCode::K, KeyModCtrl);
    bed.Key(KeyCode::Z, KeyModCtrl); // continues no binding: ctrl-k alone, then ctrl-z (unbound)
    REQUIRE(bed.ran.Size() == 2u);
    CHECK(bed.ran[1] == core::String(u8"kill"));
}

TEST_CASE("keymap: a command's keys as text are those bound where the control is")
{
    Bed bed;
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"ctrl-s"), SV(u8"save"), SV(u8"menu")));
    REQUIRE(keys.Bind(SV(u8"ctrl-shift-s"), SV(u8"save"), SV(u8"editor"))); // later, but elsewhere
    const core::Array<KeyContextLayer> here = bed.root->KeyContextsAt(bed.item.Get());
    CHECK(keys.ShortcutText(SV(u8"save"), here.AsSpan()) == core::String(u8"Ctrl+S"));
}

TEST_CASE("keymap: the whole keyboard has names, the keypad apart from the digits, each shown as a menu writes it")
{
    CHECK(ParseKeystroke(SV(u8"numpad5")).Value().Code == static_cast<core::u32>(KeyCode::Keypad5));
    CHECK(ParseKeystroke(SV(u8"5")).Value().Code == static_cast<core::u32>(KeyCode::Num5));
    CHECK(ParseKeystroke(SV(u8"f24")).Value().Code == static_cast<core::u32>(KeyCode::F24));
    CHECK(ParseKeystroke(SV(u8"f13")).Value().Code == static_cast<core::u32>(KeyCode::F13));
    CHECK_FALSE(ParseKeystroke(SV(u8"f25")).HasValue());
    CHECK(ParseKeystroke(SV(u8"ctrl-slash")).Value().Code == static_cast<core::u32>(KeyCode::Slash));
    CHECK(KeystrokeText(ParseKeystroke(SV(u8"ctrl-minus")).Value()) == SV(u8"Ctrl+-"));
    CHECK(KeystrokeText(ParseKeystroke(SV(u8"numpadenter")).Value()) == SV(u8"Numpad Enter"));
    CHECK(KeystrokeText(ParseKeystroke(SV(u8"f17")).Value()) == SV(u8"F17"));
    CHECK(KeystrokeText(ParseKeystroke(SV(u8"backslash")).Value()) == SV(u8"\\"));
    // Every named key reads back from its own name.
    for (const detail::NamedKey& key : detail::kKeyNames)
    {
        const auto stroke = ParseKeystroke(SV(key.Name));
        REQUIRE(stroke.HasValue());
        CHECK(stroke.Value().Code == static_cast<core::u32>(key.Code));
    }
}

TEST_CASE("keymap: a modifier key binds alone, though pressing it sets its own modifier")
{
    Bed bed;
    bed.Handle(u8"sprint");
    bed.Handle(u8"zoom");
    Keymap& keys = bed.root->GetContext().GetKeymap();
    REQUIRE(keys.Bind(SV(u8"leftshift"), SV(u8"sprint")));
    REQUIRE(keys.Bind(SV(u8"ctrl-rightshift"), SV(u8"zoom")));
    bed.Key(KeyCode::LeftShift, KeyModShift); // the platform reports Shift held as the key goes down
    REQUIRE(bed.ran.Size() == 1u);
    CHECK(bed.ran[0] == SV(u8"sprint"));
    bed.Key(KeyCode::RightShift, KeyModShift | KeyModCtrl);
    REQUIRE(bed.ran.Size() == 2u);
    CHECK(bed.ran[1] == SV(u8"zoom"));
    bed.Key(KeyCode::Keypad5);
    CHECK(bed.ran.Size() == 2u); // unbound: Numpad 5 is not 5
}

TEST_CASE("keymap: a keystroke's name reads back as the same keystroke")
{
    const char8_t* const names[] = {u8"ctrl-shift-s", u8"numpad5", u8"pad-north", u8"f24", u8"alt-f4", u8"leftshift",
                                    u8"ctrl-minus", u8"enter", u8"super-space", u8"7", u8"grave"};
    for (const char8_t* name : names)
    {
        const auto stroke = ParseKeystroke(SV(name));
        REQUIRE(stroke.HasValue());
        CHECK(KeystrokeName(stroke.Value()) == SV(name));
        CHECK(ParseKeystroke(KeystrokeName(stroke.Value()).AsView()).Value() == stroke.Value());
    }
    CHECK(KeystrokeName(Keystroke{static_cast<core::u32>(KeyCode::Unknown), 0, false}).IsEmpty());
}
