// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :gui_script partition, what is left of it after S19's node verbs: the `gui` facade, the
// binding a host installs per script context, and the registrations. GuiEvent, what a handler is
// given, is Code/Foundation/Sedulous.GUI/src/Scene/GuiScript.bf.
//
// The GUI's script surface (G1 of Specs/vg-and-gui-lab.md). There is no separate UI-script layer:
// the widgets and their properties are reflected through our RTTI (GUIReflectionImpl.cpp), so the
// engine's reflection-driven binding reaches the node tree from AngelScript and Luau alike, and
// markup creates the same reflected element types by tag (ElementTypes). What lives here is the way in: the
// `gui` facade (`gui.root()`, the root the host installed for the calling script) and the binding
// a host installs per script context; the element types creatable by name are ElementTypes'.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:gui_script;

import foundation.core;
import foundation.script;
import :node;
import :scene_root;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    inline constexpr core::StringView kGuiScriptService = u8"gui.runtime";

    /// What a host gives a script context: the root its scripts build under, or a way to find it
    /// at each call (a host whose scripts' roots differ by what is running them: an editor's
    /// game per tab), which wins when set.
    struct GuiScriptBinding
    {
        SceneRoot* root = nullptr;
        core::Function<SceneRoot*()> resolve;

        [[nodiscard]] SceneRoot* Root() const { return resolve ? resolve() : root; }
    };

    inline void InstallGuiScriptService(foundation::script::IScriptContext& context, GuiScriptBinding& binding)
    {
        context.SetService(kGuiScriptService, &binding);
    }
    inline void ClearGuiScriptService(foundation::script::IScriptContext& context)
    {
        context.SetService(kGuiScriptService, nullptr);
    }

    /// The `gui` facade: statics only (script name `gui`).
    class Gui : public Object
    {
        RTTI_OBJECT(Gui, Object)
    public:
        /// The calling script's root (a Node handle), or null when its host installed none.
        [[nodiscard]] static Variant Root();
        /// The GUI's data value `name` as a number, text or boolean (converted; 0, empty or false
        /// when unset or unconvertible). A read a binding follows.
        [[nodiscard]] static f64 GetNumber(core::StringView name);
        [[nodiscard]] static core::String GetText(core::StringView name);
        /// The GUI's localized text for `key` (E16): the key itself when no table has it.
        [[nodiscard]] static core::String Translate(core::StringView key);
        /// The key's plural form for `count`, its `{0}` the count.
        [[nodiscard]] static core::String TranslateCount(core::StringView key, i32 count);
        /// The GUI's language ("en", "ar-EG"); empty with no localization.
        [[nodiscard]] static core::String Language();
        [[nodiscard]] static bool GetBool(core::StringView name);
        /// What drives the calling script's GUI now (K2b): "pointer", "keyboard" or "pad" (the
        /// root hears `inputkind` when it changes). A read a binding follows.
        [[nodiscard]] static core::String InputKindNow();
        /// Sets the GUI's data value `name` (whatever is bound to it follows).
        static void Set(core::StringView name, const Variant& value);
        /// Moves the GUI's data value `name` to `to` over `seconds` (K3: GUIContext::AnimateData),
        /// running; and one not yet running, a step for a group. Null when the host installed no root.
        static RefPtr<Tween> TweenData(core::StringView name, f64 to, f32 seconds, core::StringView easing);
        static RefPtr<Tween> CreateDataTween(core::StringView name, f64 to, f32 seconds, core::StringView easing);
        /// Commands (G7): define one (with its label), switch it on or off, set its checked state,
        /// run it along the focus path (true when a handler ran).
        static void DefineCommand(core::StringView id, core::StringView label);
        static void SetCommandEnabled(core::StringView id, bool enabled);
        static void SetCommandChecked(core::StringView id, bool checked);
        /// Why it is disabled, which a control bound to it shows while it is (a tool bar's tooltip).
        static void SetCommandDisabledReason(core::StringView id, core::StringView reason);
        [[nodiscard]] static bool IsCommandChecked(core::StringView id);
        static bool RunCommand(core::StringView id);
        /// Binds `keys` ("ctrl-s", "pad-east", a chord) to `command` where `context` holds (empty:
        /// everywhere); false when they do not parse.
        static bool BindKey(core::StringView keys, core::StringView command, core::StringView context);
        /// The next key or pad button, before anything else sees it (E12: a rebinding screen):
        /// `handler(keys)` with its binding name ("ctrl-s", "pad-north"), or empty when Escape
        /// cancelled. A handler of shape `void KeyHandler(const string &in keys)`.
        static void CaptureKey(RefPtr<foundation::script::IScriptDelegate> handler);
        /// A binding's keys as a menu shows them ("ctrl-s": "Ctrl+S"); empty when they do not parse.
        [[nodiscard]] static core::String KeyText(core::StringView keys);
    };

    /// Registers the GUI's own element types (ElementTypes::Register: Label, Button, the layouts,
    /// ...), once. A host calls it at start-up, as a library adding widgets of its own registers
    /// those.
    void RegisterGuiElements();

    /// Registers the GUI's element types and the `gui` facade for scripts, once (before a script
    /// manager binds the reflection registry).
    void RegisterGuiScriptSurface();
}
