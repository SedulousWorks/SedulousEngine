// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - :prompt partition
//
// Button prompts (K6 of Specs/gui-lab-evolution-3.md). A `prompt` element names an action (and,
// if it likes, its set) of the game's InputMap and shows the control that does it for the input
// kind in use: a pad's button while a pad plays, a key or a mouse button under the keyboard or the
// pointer, else any binding the action has, else nothing. It reads the map the game runs, after
// the player's rebinding, through the host's InputPrompts (an ActionRuntime: its map and its
// enabled sets, the highest priority first), labels the binding with foundation.input's
// BindingNames, and follows the input kind and the bindings as they change. Every reference names
// an action's first binding whatever the device; this one asks the device.
//
// No glyph table in code (ruling 2): a prompt shows its binding to the sheet as attributes,
// `binding` (the label's words, lower case, joined by dashes: `pad-south`, `space`, `mouse-left`)
// and `kind` (`pad`, `keyboard`, `pointer`), so a game's sheet draws its own glyphs
// (`prompt[binding="pad-south"] { background-image: url(...) }`), the text label its fallback.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.gamekit:prompt;

import foundation.core;
import foundation.input;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;
namespace input = foundation::input;

export namespace foundation::gui
{
    /// The key a GUI's InputPrompts is found under (GUIContext::GetService).
    inline constexpr core::StringView kInputPromptsService = u8"gamekit.input-prompts";

    /// The kind of input a binding is for: a pad's sources the pad, touch the pointer, the rest
    /// (keys, the mouse) the keyboard and the pointer alike.
    [[nodiscard]] inline InputKind BindingInputKind(const input::Binding& binding) noexcept
    {
        switch (binding.source)
        {
        case input::BindingSource::GamepadButton:
        case input::BindingSource::GamepadAxis:
        case input::BindingSource::GamepadStick: return InputKind::Pad;
        case input::BindingSource::TouchButton:
        case input::BindingSource::TouchStick: return InputKind::Pointer;
        default: return InputKind::Keyboard;
        }
    }
    /// A binding as a sheet names it: its label's words, lower case, joined by dashes ("Pad South":
    /// `pad-south`).
    [[nodiscard]] inline core::String BindingToken(const input::Binding& binding)
    {
        const core::String label = input::DescribeBinding(binding);
        core::String token;
        for (const char8_t c : label.AsView())
            token.Append(c == u8' ' ? u8'-' : (c >= u8'A' && c <= u8'Z' ? static_cast<char8_t>(c - u8'A' + u8'a') : c));
        return token;
    }

    /// What a GUI's prompts read the game's bindings through: the host's ActionRuntime (its map
    /// after the player's rebinding, its enabled sets). The host installs it on the GUI and tells
    /// it when the bindings change (a rebinding saved).
    class InputPrompts
    {
    public:
        InputPrompts() = default;
        InputPrompts(const InputPrompts&) = delete;
        InputPrompts& operator=(const InputPrompts&) = delete;

        void SetRuntime(const input::ActionRuntime* runtime)
        {
            m_runtime = runtime;
            m_changed.Notify();
        }
        /// The runtime's map or enabled sets changed: every prompt reads them again.
        void NotifyBindingsChanged() { m_changed.Notify(); }
        /// Makes it the one `gui`'s prompts read (null: none). It must outlive that.
        void Install(GUIContext& gui) { gui.SetService(kInputPromptsService, this); }
        static void Uninstall(GUIContext& gui) { gui.SetService(kInputPromptsService, nullptr); }

        /// The binding to show for `action`, in `set` (empty: the highest-priority enabled set that
        /// has it), for input of `kind`: its first of that kind, else its first, else none. A read a
        /// binding follows.
        [[nodiscard]] Optional<input::Binding> Find(core::StringView action, core::StringView set, InputKind kind) const
        {
            m_changed.Track();
            if (m_runtime == nullptr || action.IsEmpty())
                return {};
            const input::Action* found = nullptr;
            i32 priority = 0;
            for (const input::ActionSet& candidate : m_runtime->Map().sets)
            {
                if (set.Size() != 0 ? candidate.name.AsView() != set : !m_runtime->IsSetEnabled(candidate.name.AsView()))
                    continue;
                if (found != nullptr && candidate.priority <= priority)
                    continue;
                for (const input::Action& a : candidate.actions)
                    if (a.name.AsView() == action)
                    {
                        found = &a;
                        priority = candidate.priority;
                        break;
                    }
            }
            if (found == nullptr || found->bindings.IsEmpty())
                return {};
            const InputKind wanted = kind == InputKind::Pad ? InputKind::Pad : InputKind::Keyboard;
            for (const input::Binding& binding : found->bindings)
                if (BindingInputKind(binding) == wanted)
                    return binding;
            return found->bindings[0];
        }

    private:
        const input::ActionRuntime* m_runtime = nullptr;
        Observable m_changed;
    };

    /// Shows the control that does an action, for the input kind in use.
    class Prompt : public Label
    {
        RTTI_OBJECT(Prompt, Label)
    public:
        Prompt()
        {
            SetTag(core::StringView(u8"prompt"));
            Bind([this]() { Refresh(); }); // the GUI it is in, its action, the input kind, the bindings
        }

        [[nodiscard]] core::String GetAction() const { return m_action; }
        void SetAction(const core::String& action)
        {
            m_action = action;
            m_inputs.Notify();
        }
        /// The set it reads the action in (empty: the highest-priority enabled set that has it).
        [[nodiscard]] core::String GetSet() const { return m_set; }
        void SetSet(const core::String& set)
        {
            m_set = set;
            m_inputs.Notify();
        }
        /// The binding shown, as a sheet names it (`pad-south`), and its kind (`pad`, `keyboard`,
        /// `pointer`): empty when none is shown.
        [[nodiscard]] core::String GetBinding() const { return m_binding; }
        [[nodiscard]] core::String GetBindingKind() const { return m_kind; }

    private:
        void Refresh()
        {
            m_inputs.Track();
            SceneRoot* root = ObserveSceneRoot();
            Optional<input::Binding> binding;
            if (root != nullptr)
            {
                const InputKind kind = root->GetEventDispatcher()->ObserveInputKind();
                if (const auto* prompts = static_cast<const InputPrompts*>(root->GetContext().GetService(kInputPromptsService)))
                    binding = prompts->Find(m_action.AsView(), m_set.AsView(), kind);
            }
            Untracked([&]
                      {
                          const core::String token = binding.HasValue() ? BindingToken(binding.Value()) : core::String{};
                          const core::String kind = binding.HasValue() ? core::String(InputKindName(BindingInputKind(binding.Value())))
                                                                       : core::String{};
                          SetText(binding.HasValue() ? input::DescribeBinding(binding.Value()).AsView() : core::StringView{});
                          if (token.AsView() != m_binding.AsView() || kind.AsView() != m_kind.AsView())
                          {
                              m_binding = token;
                              m_kind = kind;
                              MarkStyleDirty(false); // a sheet's [binding=...] and [kind=...] read it
                          }
                      });
        }

        core::String m_action;
        core::String m_set;
        core::String m_binding;
        core::String m_kind;
        Observable m_inputs; // its action or set changed
    };
}
