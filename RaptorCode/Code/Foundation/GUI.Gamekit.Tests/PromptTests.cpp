// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - button prompts (K6 of Specs/gui-lab-evolution-3.md): a prompt shows the binding of
// its action for the input kind in use, from the game's runtime after its rebinding and in its
// enabled sets by priority, labelled by foundation.input's names, with `binding` and `kind` for a
// sheet's glyphs, and follows the input kind and the bindings as they change.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.shell;
import foundation.input;
import foundation.gui;
import foundation.gui.gamekit;

using namespace foundation::gui;
namespace core = foundation::core;
namespace input = foundation::input;
namespace shell = foundation::shell;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    input::Binding Key(shell::KeyCode key)
    {
        input::Binding b;
        b.source = input::BindingSource::Key;
        b.code = static_cast<core::u32>(key);
        return b;
    }
    input::Binding Pad(shell::GamepadButton button)
    {
        input::Binding b;
        b.source = input::BindingSource::GamepadButton;
        b.code = static_cast<core::u32>(button);
        return b;
    }
    template <typename... Bindings>
    input::ActionSet Set(const char8_t* name, core::i32 priority, const char8_t* action, Bindings... bindings)
    {
        input::ActionSet set;
        set.name = core::String(name);
        set.priority = priority;
        input::Action a;
        a.name = core::String(action);
        (a.bindings.PushBack(bindings), ...);
        set.actions.PushBack(core::Move(a));
        return set;
    }

    // A GUI with a "jump" prompt, reading a runtime whose Gameplay set binds jump to Space and South.
    struct PromptBed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Prompt> prompt = core::MakeRef<Prompt>(core::DefaultAllocator());
        input::ActionRuntime runtime;
        InputPrompts prompts;

        PromptBed()
        {
            input::InputMap map;
            map.sets.PushBack(Set(u8"Gameplay", 0, u8"jump", Key(shell::KeyCode::Space), Pad(shell::GamepadButton::South)));
            runtime.SetMap(map);
            prompts.SetRuntime(&runtime);
            prompts.Install(root->GetContext());
            prompt->SetAction(core::String(u8"jump"));
            root->AddChild(prompt.Get());
            Frame();
        }
        void Frame() { root->GetContext().Update(core::Duration{}); }
        void Kind(InputKind kind)
        {
            root->GetEventDispatcher()->SetInputKind(kind);
            Frame();
        }
    };
}

TEST_CASE("prompts: the binding for the input kind in use, labelled, with its binding and kind for the sheet")
{
    PromptBed bed;
    CHECK(bed.prompt->GetText() == SV(u8"Space")); // the GUI starts on the keys
    CHECK(bed.prompt->GetBinding() == SV(u8"space"));
    CHECK(bed.prompt->GetBindingKind() == SV(u8"keyboard"));
    bed.Kind(InputKind::Pad);
    CHECK(bed.prompt->GetText() == SV(u8"Pad South"));
    CHECK(bed.prompt->GetBinding() == SV(u8"pad-south"));
    CHECK(bed.prompt->GetBindingKind() == SV(u8"pad"));
    bed.Kind(InputKind::Pointer); // a mouse user reads the keys and buttons
    CHECK(bed.prompt->GetBinding() == SV(u8"space"));
}

TEST_CASE("prompts: a sheet draws the glyph by the binding it shows")
{
    PromptBed bed;
    StyleManager styles(CSSParser::Parse(SV(u8"prompt { opacity: 1; } prompt[binding=\"pad-south\"] { opacity: 0.5; } prompt[kind=\"keyboard\"] { opacity: 0.75; }")));
    styles.ApplyTree(*bed.root);
    CHECK(bed.prompt->GetAlpha() == doctest::Approx(0.75f));
    bed.Kind(InputKind::Pad);
    styles.ApplyTree(*bed.root);
    CHECK(bed.prompt->GetAlpha() == doctest::Approx(0.5f));
}

TEST_CASE("prompts: a rebinding the host announces shows; without a binding of the kind, any; without one, nothing")
{
    PromptBed bed;
    bed.Kind(InputKind::Pad);
    input::InputMap rebound;
    rebound.sets.PushBack(Set(u8"Gameplay", 0, u8"jump", Key(shell::KeyCode::Space), Pad(shell::GamepadButton::North)));
    bed.runtime.SetMap(rebound);
    bed.prompts.NotifyBindingsChanged();
    bed.Frame();
    CHECK(bed.prompt->GetBinding() == SV(u8"pad-north"));

    input::InputMap keysOnly;
    keysOnly.sets.PushBack(Set(u8"Gameplay", 0, u8"jump", Key(shell::KeyCode::E)));
    bed.runtime.SetMap(keysOnly);
    bed.prompts.NotifyBindingsChanged();
    bed.Frame();
    CHECK(bed.prompt->GetBinding() == SV(u8"e")); // a pad in hand, but the action has only a key

    bed.prompt->SetAction(core::String(u8"fly"));
    bed.Frame();
    CHECK(bed.prompt->GetText().IsEmpty());
    CHECK(bed.prompt->GetBinding().IsEmpty());
}

TEST_CASE("prompts: the highest-priority enabled set that has the action, or the set named")
{
    PromptBed bed;
    input::InputMap map;
    map.sets.PushBack(Set(u8"Gameplay", 0, u8"confirm", Key(shell::KeyCode::E)));
    map.sets.PushBack(Set(u8"Menu", 10, u8"confirm", Key(shell::KeyCode::Return)));
    bed.runtime.SetMap(map);
    bed.prompts.NotifyBindingsChanged();
    bed.prompt->SetAction(core::String(u8"confirm"));
    bed.Frame();
    CHECK(bed.prompt->GetBinding() == SV(u8"return"));
    bed.runtime.DisableSet(SV(u8"Menu"));
    bed.prompts.NotifyBindingsChanged();
    bed.Frame();
    CHECK(bed.prompt->GetBinding() == SV(u8"e"));
    bed.prompt->SetSet(core::String(u8"Menu")); // named: read there, enabled or not
    bed.Frame();
    CHECK(bed.prompt->GetBinding() == SV(u8"return"));
}

TEST_CASE("prompts: none until the host installs its prompts; from markup by action")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    RegisterGuiElements();
    RegisterGamekitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8"<Prompt action=\"jump\"/>"));
    Prompt* prompt = core::Cast<Prompt>(made.Get());
    REQUIRE(prompt != nullptr);
    CHECK(prompt->GetAction() == SV(u8"jump"));
    root->AddChild(prompt);
    root->GetContext().Update(core::Duration{});
    CHECK(prompt->GetBinding().IsEmpty());

    input::ActionRuntime runtime;
    input::InputMap map;
    map.sets.PushBack(Set(u8"Gameplay", 0, u8"jump", Key(shell::KeyCode::Space)));
    runtime.SetMap(map);
    InputPrompts prompts;
    prompts.SetRuntime(&runtime);
    prompts.Install(root->GetContext()); // installed later: the prompt follows
    root->GetContext().Update(core::Duration{});
    CHECK(prompt->GetBinding() == SV(u8"space"));
    InputPrompts::Uninstall(root->GetContext());
    root->GetContext().Update(core::Duration{});
    CHECK(prompt->GetBinding().IsEmpty());
}
