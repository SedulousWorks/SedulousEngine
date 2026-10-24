// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :node partition, what is left of it after slice S11: the members whose bodies or types
// belong to later slices (S12 tweens, S19 the script surface). The rest is
// Code/Foundation/Sedulous.GUI/src/Core/Node.bf (ElementTable, Node; layout in
// Layout/LayoutImpl.bf; the GUI a node is in in Scene/GUIClusterImpl.bf; Element<T> and
// ElementSet in Scene/ElementTypes.bf).

export namespace foundation::gui
{
    class Tween;           // a property moving on the GUI's clock (:tween, E14)
    class TweenGroup;      // tweens run as one (:tween)

    class Node
    {

        // --- S12: tweens (Styling/TweenImpl.cpp) ---
        /// Moves `property` to `to` over `seconds` on the GUI's clock (E14), eased as `easing` names
        /// (a CSS easing or a named curve). The property is named as a sheet names it, and composes
        /// over the cascade, holding its end until stopped; a name no sheet knows is a reflected
        /// property (`value`, `x`, `textColor`). A tween of the same property replaces the running
        /// one, from the value showing. The tween, to shape further (a start value, a delay,
        /// repeats); inert on a node in no GUI. Defined in Styling/TweenImpl.cpp.
        RefPtr<Tween> Animate(core::StringView property, core::StringView to, f32 seconds,
                              core::StringView easing = core::StringView(u8"ease"));
        /// Moves `property` toward `to` as a damped spring (E14, Tween::Spring): a spring already
        /// moving it turns toward the new end from where it is, at the speed it has, rather than
        /// starting again. The spring, running.
        RefPtr<Tween> SpringTo(core::StringView property, core::StringView to, f32 stiffness = 170.0f, f32 damping = 26.0f,
                               f32 mass = 1.0f);
        /// Runs `group` on this node's GUI clock (a script's RunAction for a group, E14).
        void Play(RefPtr<TweenGroup> group);
        /// A tween of this node as Animate makes one, not yet running: a step for a group (E14).
        RefPtr<Tween> CreateTween(core::StringView property, core::StringView to, f32 seconds,
                                  core::StringView easing = core::StringView(u8"ease"));
        /// Stops what moves `property` and gives it back to the sheet (a tween that ended holds
        /// its end until this); false when nothing moved it.
        bool StopAnimation(core::StringView property);

        // --- declared in Node.bf returning null (the dispatcher calls them); the slice with Tooltip and
        // DragPreview fills them in place with these (their bodies are in Scene/GUIReflectionImpl.cpp) ---
        /// The preview a drag shows when its source gives none (GUIClusterImpl.cpp: a label of
        /// the payload's label), and the hint beside the pointer with a target's reason.
        [[nodiscard]] virtual core::RefPtr<Node> CreateDragPreview(const DragPayload& payload);
        [[nodiscard]] virtual core::RefPtr<Node> CreateDropHint(core::StringView reason, bool refused);
        /// What its tooltip shows for `text` (E5): a Tooltip label by default (defined where the
        /// widgets are); any node, for a richer one. Null: no tooltip.
        [[nodiscard]] virtual core::RefPtr<Node> CreateTooltipContent(core::StringView text);

        // --- S19: the script surface (Scene/GUIReflectionImpl.cpp) ---
        /// A handle to this node typed as `type` (this node's type or a base of it); empty when the
        /// node is in no GUI (a detached element has no owner a handle could resolve through).
        [[nodiscard]] Variant HandleAs(const TypeInfo& type);
        /// The node a handle resolves to now, or null (gone, or not a node's handle).
        [[nodiscard]] static Node* FromHandle(const Variant& handle);
        /// Creates the element `tag` names in this GUI's element set as this node's last child,
        /// from this node's allocator; its handle, or empty when the set does not allow `tag`.
        Variant AddElement(core::StringView tag);
        /// The first widget in this subtree (depth first, this node first) whose id is `id`.
        [[nodiscard]] Variant FindElement(core::StringView id);
        [[nodiscard]] Variant ParentElement();
        [[nodiscard]] Variant ChildElement(i32 index);
        /// Calls `handler` on each event named `eventName` (click, mousedown, mouseup,
        /// mouseenter, mouseleave, mousemove, wheel, keydown, keyup, textinput, focus, blur, and the
        /// rest of the core's), or of a name a library sends (SendNamedEvent: a screen's
        /// `screenenter`). A token for Off (0 for an empty name).
        i32 On(core::StringView eventName, RefPtr<foundation::script::IScriptDelegate> handler);
        /// Opens `content` (a node's handle) as a popup below this node (E16): closed by a press
        /// outside it or Escape, focus going into it and back; whether it opened.
        [[nodiscard]] core::Variant OpenPopupScript(core::Variant content);
        /// Closes this node where it is open as a popup (a script's popup, menu or window); false
        /// when it is not one.
        bool ClosePopupScript();
        /// Binds `property` to what `expression` returns, run again whenever what it read changed
        /// (gui.getNumber and the rest, widget properties). False when no such property.
        bool BindScript(core::StringView property, RefPtr<foundation::script::IScriptDelegate> expression);
        /// Binds `property` to this GUI's data value `key` (BindData with its scene's model); false
        /// outside a scene or with no such property.
        bool BindSceneData(core::StringView property, core::StringView key);
        /// Focuses this widget, or, for a container (a page, a dialog), its entry: what was last
        /// focused in it, else its default focus (nav-default), else its first focusable widget.
        /// False when there is nothing to focus.
        bool FocusElement();
        /// Handles command `id` with a script function, in the bubble phase; the function returning
        /// true lets the command go on up the focus path.
        i32 OnCommandScript(core::StringView id, RefPtr<foundation::script::IScriptDelegate> handler);
        /// Binds reflected property `property` (one marked `translatable`) to the text of `key` in
        /// the GUI's Localization: resolved now and again when the language changes, the node joins
        /// a GUI, or a named argument changes. With a count, the key's plural form for it, `{0}`
        /// the count and `args` from `{1}`; else `args` from `{0}`. A key shows as written while no
        /// Localization is set or auto-translation is off. False when the property is none such.
        /// `fallback` shows where no table has the key, or the GUI has no Localization (a widget's own
        /// label, "OK", over "gui.ok"); empty: the key shows, as for markup's @key.
        bool BindTranslation(core::StringView property, core::StringView key, RefPtr<DataModel> data = {},
                             Optional<TranslationArgument> count = {}, Array<TranslationArgument> args = {},
                             core::StringView fallback = {}); // GUIReflectionImpl.cpp
        /// Binds the reflected property named `name` (this node's type's or a base's) to
        /// `expression`'s value, converted to the property's type: native code, markup and scripts
        /// bind any widget's properties this way, a library's included. False when the node has no
        /// such writable property.
        bool BindProperty(core::StringView name, core::Function<Variant()> expression);
        /// The reverse: `write` takes the property's value now and whenever it changes (the user
        /// moved a slider, typed). Only for the properties a widget's user changes (the `twoWay`
        /// property attribute); false for any other.
        bool BindPropertyBack(core::StringView name, core::Function<void(const Variant&)> write);
        /// Binds `property` to `model`'s value `key`, as markup's `{{key}}` does: it follows the
        /// value, and writes it back when the property is one the user changes. False when the node
        /// has no such writable property.
        bool BindData(core::StringView property, RefPtr<DataModel> model, core::StringView key)
        {
            const core::String name(key);
            if (!BindProperty(property, [model, name] { return model->Get(name.AsView()); }))
                return false;
            (void)BindPropertyBack(property, [model, name](const Variant& v) { model->Set(name.AsView(), v); });
            return true;
        }
    };
}
