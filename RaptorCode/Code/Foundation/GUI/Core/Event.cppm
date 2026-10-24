// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :event partition, what is left of it after slice S4: the members that name Node, ported
// with Node (S8). The rest is Code/Foundation/Sedulous.GUI/src/Core/Event.bf.

export namespace foundation::gui
{
    struct Event
    {
        /// The node the event is for (the hovered or pressed node, the focus).
        Node* Target = nullptr;
        /// The node whose handlers are running now, on the event's route.
        Node* CurrentTarget = nullptr;

        explicit Event(EventType type, Node* target = nullptr) noexcept
            : Type(type), Target(target), CurrentTarget(target)
        {
        }
    };

    // Each event's constructor takes the target and passes it on to Event's (the Beef ones have no
    // target parameter yet):
        MouseEvent(EventType type, Node* target, core::Float2 position,
            : Event(type, target), Position(position), Button(button), Modifiers(modifiers)
        WheelEvent(Node* target, core::Float2 position, core::Float2 delta, u32 modifiers = 0) noexcept
            : Event(EventType::MouseWheel, target), Position(position), Delta(delta), Modifiers(modifiers)
        GestureEvent(EventType type, Node* target) noexcept : Event(type, target) {}
        KeyEvent(EventType type, Node* target, u32 keyCode, u32 modifiers = 0) noexcept
            : Event(type, target), KeyCode(keyCode), Modifiers(modifiers)
        TextInputEvent(Node* target, core::StringView text) noexcept
            : Event(EventType::TextInput, target), Text(text)
        ToggleEvent(Node* target, bool open, PopupCloseReason reason) noexcept
            : Event(EventType::Toggle, target), Open(open), Reason(reason)
        TabEvent(EventType type, Node* target, i32 index) noexcept : Event(type, target), Index(index) {}
        ItemEvent(EventType type, Node* target, i32 item, ModelIndex index) noexcept : Event(type, target), Item(item), Index(index) {}
        CompositionEvent(Node* target, core::StringView text, i32 cursor) noexcept
            : Event(EventType::Composition, target), Text(text), Cursor(cursor)
        LinkEvent(Node* target, core::StringView link) noexcept : Event(EventType::Link, target), Link(link) {}
        MotionEndEvent(EventType type, Node* target, core::StringView name, f32 elapsed) noexcept
            : Event(type, target), Name(name), Elapsed(elapsed)
        NamedEvent(Node* target, core::StringView name, core::StringView detail = {}) noexcept
            : Event(EventType::Named, target), Name(name), Detail(detail)
        DragEvent(EventType type, Node* target, const DragPayload& payload) noexcept
            : Event(type, target), Payload(payload)

    struct DragRequest
    {
        core::RefPtr<Node> Preview;
    };

    struct DragResult
    {
        Node* Target = nullptr;
    };
}
