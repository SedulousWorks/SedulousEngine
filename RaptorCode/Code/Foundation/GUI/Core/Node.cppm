// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :node partition, what is left of it after slice S8: the members whose bodies or types
// belong to later slices (S11 the GUI a node is in, S12 tweens, S19 the script surface). The rest
// is Code/Foundation/Sedulous.GUI/src/Core/Node.bf (ElementTable, Node; layout in
// Layout/LayoutImpl.bf; Element<T> and ElementSet in Scene/ElementTypes.bf).

export namespace foundation::gui
{
    class EventDispatcher; // owned by the SceneRoot; reached via GetEventDispatcher()
    class Tween;           // a property moving on the GUI's clock (:tween, E14)
    class TweenGroup;      // tweens run as one (:tween)
    class SceneRoot;       // the root of a GUI (:scene_root)
    class GUIContext;      // the GUI a root is part of (:scene_root)

    class Node
    {

        // --- S11: the GUI a node is in (Scene/GUIClusterImpl.cpp; SceneRoot, GUIContext, EventDispatcher) ---
        /// The root of the GUI this node is in, or null when it is in none (a detached subtree:
        /// GetRootNode gives its topmost node).
        [[nodiscard]] SceneRoot* GetSceneRoot();
        /// Whether access keys are underlined now (while Alt is held, or always as its GUI says).
        [[nodiscard]] bool AreMnemonicsShown();
        /// The GUI this node is in, read as a binding's dependency: the binding reruns when the node
        /// joins or leaves one (a control bound to a command, made by markup before it is attached).
        [[nodiscard]] SceneRoot* ObserveSceneRoot()
        {
            m_sceneRootChanged.Track();
            return GetSceneRoot();
        }
        /// The GUI this node is in (its root's context), or null outside one.
        [[nodiscard]] virtual GUIContext* GetGUIContext() { return m_parent ? m_parent->GetGUIContext() : nullptr; }
        [[nodiscard]] virtual EventDispatcher* GetEventDispatcher()
        {
            return m_parent ? m_parent->GetEventDispatcher() : nullptr;
        }
        [[nodiscard]] const EventDispatcher* GetEventDispatcher() const
        {
            return const_cast<Node*>(this)->GetEventDispatcher(); // a read: which dispatcher, not a change
        }
        // Programmatic focus (routes through the dispatcher; defined in the impl unit).
        void RequestFocus();
        void ReleaseFocus();
        // === Input routing === (the EventDispatcher starts a route; RouteEvent walks it)
        /// Sends an input event (pointer, wheel, key, text) along its route to this node: down
        /// from the root through the capture listeners, at this node, and back up through each
        /// node's own handler (OnMouseDown and the rest) and its bubble listeners; a handler
        /// marking it Handled ends the route once that node is done. The path is held for the
        /// walk, so a handler may remove nodes on it (one that left the tree is skipped). True
        /// when it was handled.
        bool RouteEvent(Event& event);
        // === Leaving (K0 of Specs/gui-lab-evolution-3.md) ===
        // A node that goes plays its way out first: Leave puts it in `:leaving`, where the sheet's
        // exit transition or animation runs, takes it out of the pointer, focus and navigation at
        // once, and the style pass removes it from its parent when what the sheet started on it
        // has ended (the next frame when nothing moves it; an infinite or paused animation is not
        // waited for). Leaving ends when it leaves its parent, by this or any other removal, so a
        // node taken back is whole again. Defined in Scene/GUIClusterImpl.cpp.

        /// Leaves its parent after its exit plays: at the GUI's next update when nothing plays one (no
        /// style pass, or a node no sheet styles), at once in no GUI.
        void Leave();
        // === Inert (K4 of Specs/gui-lab-evolution-3.md, HTML's `inert`) ===
        /// An inert node and what it holds take no pointer, focus, navigation, keys or commands,
        /// and still draw (a game's screen under a blocking one). Made inert, what the dispatcher
        /// held in it lets go, as of a removed subtree: a press held, the hover, the focus, its
        /// popups. Defined in Scene/GUIClusterImpl.cpp.
        void SetInert(bool inert);
        /// The style pass's: what moves it has ended, so it goes (at the next safe point, once).
        void FinishLeaving();
        // === Entering (K5 of Specs/gui-lab-evolution-3.md) ===
        // A node that arrives plays its way in: Enter puts it in `:entering`, where the sheet's
        // entrance runs (a keyframe animation, or values it starts from, as CSS's @starting-style),
        // until what that started has ended; then `:entering` goes, the node moves to its own style
        // (through its transitions), and once that has settled it hears `entered`. Leave cuts an
        // entrance short, leaving from where it is. In no GUI, in one no style pass runs over, or
        // not styled, it has no entrance and hears `entered` at once. Defined in Scene/GUIClusterImpl.cpp.

        void Enter();
        /// The style pass's: nothing the sheet started on it waits now. A leaving node goes; an
        /// arriving one takes its entrance's next step (at the GUI's next drain).
        void MotionSettled();
        /// Binds this control to command `id` (empty: none): it is enabled while the command is
        /// available and shows its checked state (OnBoundCommandState), and runs it when used
        /// (RunBoundCommand, from the widget's click). Reflected as `command`, so markup and sheets
        /// set it too.
        void SetCommand(core::StringView id);
        [[nodiscard]] core::StringView GetCommand() const noexcept { return m_command.Peek().AsView(); }
        [[nodiscard]] bool HasCommand() const noexcept { return m_command.Peek().Size() != 0; }
        /// Runs the bound command along the focus path; false with none, or none ran.
        bool RunBoundCommand();
        // A click at the centre, as activation delivers it (listeners see a click, as with a mouse).
        bool ActivateAsClick()
        {
            MouseEvent click(EventType::MouseClick, this, ConvertToWorldSpace(core::Float2{m_size.x * 0.5f, m_size.y * 0.5f}));
            (void)RouteEvent(click);
            return true;
        }

        // --- S11: declared in Node.bf with empty bodies (their callers are ported); S11 fills them with these ---
        // Tells this GUI's dispatcher a child's subtree is leaving (GUIClusterImpl.cpp, which
        // sees :event_dispatcher).
        void NotifyRemovingChild(Node& child);
        // Tells this GUI's commands that what decides availability changed (GUIClusterImpl.cpp).
        void NotifyCommandsChanged();

        // --- S11: the bound command's state (fields) ---
        Property<core::String> m_command; // the bound command's id (SetCommand)
        bool m_commandBound = false;      // its binding made (once)

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
        /// The preview a drag shows when its source gives none (GUIClusterImpl.cpp: a label of
        /// the payload's label), and the hint beside the pointer with a target's reason.
        [[nodiscard]] virtual core::RefPtr<Node> CreateDragPreview(const DragPayload& payload);
        [[nodiscard]] virtual core::RefPtr<Node> CreateDropHint(core::StringView reason, bool refused);
        /// What its tooltip shows for `text` (E5): a Tooltip label by default (defined where the
        /// widgets are); any node, for a richer one. Null: no tooltip.
        [[nodiscard]] virtual core::RefPtr<Node> CreateTooltipContent(core::StringView text);
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
