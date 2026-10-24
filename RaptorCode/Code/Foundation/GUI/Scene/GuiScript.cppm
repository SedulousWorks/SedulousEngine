// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :gui_script partition
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

    /// What a script handler (`node.on(name, fn)`) is given: the event's data, positions in the
    /// GUI's own units (`x`, `y` from the root, `localX`, `localY` from the node the handler is
    /// on). A handler returning true takes the event: it goes no further on its route.
    struct GuiEvent
    {
        core::String type;  ///< the name it was listened for: "click", "mousedown", "keydown", ...
        core::String phase; ///< "capture", "target" or "bubble"
        core::String id;    ///< the id of the node it is for (empty: none)
        core::String pointer; ///< "mouse" or "touch", for pointer events
        f32 x = 0.0f;
        f32 y = 0.0f;
        f32 localX = 0.0f;
        f32 localY = 0.0f;
        i32 button = 0; ///< 0 left, 1 right, 2 middle, 3 and 4 the extra buttons
        i32 clickCount = 0;
        i32 key = 0; ///< a KeyCode value for keys
        i32 modifiers = 0; ///< shift 1, ctrl 2, alt 4, super 8
        core::String text; ///< typed text; a link's id; the property or @keyframes a transitionend or animationend is of
        f32 deltaX = 0.0f; ///< the wheel; a gesture's translation since the last event
        f32 deltaY = 0.0f;
        // A gesture (E17c), x and y its fingers' middle: totals since it began, and this event's change.
        f32 scale = 1.0f;
        f32 rotation = 0.0f; ///< radians, clockwise
        f32 translationX = 0.0f;
        f32 translationY = 0.0f;
        f32 scaleDelta = 1.0f;
        f32 rotationDelta = 0.0f;
        core::String dragType; ///< a drag's payload type (its value as `text`, its place as `index`)
        core::String effect;   ///< a drag's effect: "none", "copy", "move" or "link"
        i32 index = -1; ///< the tab for `tabclose`; the row for `activate`, and for a pointer event over a row
        f32 elapsed = 0.0f; ///< the seconds a transitionend's or animationend's motion ran
    };

    /// Registers the GUI's own element types (ElementTypes::Register: Label, Button, the layouts,
    /// ...), once. A host calls it at start-up, as a library adding widgets of its own registers
    /// those.
    void RegisterGuiElements();

    /// Registers the GUI's element types and the `gui` facade for scripts, once (before a script
    /// manager binds the reflection registry).
    void RegisterGuiScriptSurface();
}
