// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :node partition, what is left of it after slice S17 and S19's handles: the members whose
// bodies or types belong to the rest of S19, the script surface. The rest is
// Code/Foundation/Sedulous.GUI/src/Core/Node.bf (ElementTable, Node, the script handles,
// AddElement, FindElement and FocusElement; layout in
// Layout/LayoutImpl.bf; the GUI a node is in in Scene/GUIClusterImpl.bf; Element<T> and
// ElementSet in Scene/ElementTypes.bf; the tweens in Styling/TweenImpl.bf; BindProperty,
// BindPropertyBack, BindData and BindTranslation in Scene/Bindings.bf).

export namespace foundation::gui
{
    class Node
    {

        // --- S19: the script surface (Scene/GUIReflectionImpl.cpp) ---
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
        /// Handles command `id` with a script function, in the bubble phase; the function returning
        /// true lets the command go on up the focus path.
        i32 OnCommandScript(core::StringView id, RefPtr<foundation::script::IScriptDelegate> handler);
    };
}
