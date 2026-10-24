// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - its elements' reflection, what is left of it after the GUI.Gamekit port: the
// script surface's methods (S19). The rest is Code/Foundation/Sedulous.GUI.Gamekit/src: the
// properties as [GuiProperty] in ScreenStack.bf and Prompt.bf, the creators and the `Screens` tag
// as [GuiReflect], and RegisterGamekitElements in GamekitModule.bf.

namespace foundation::gui
{
    namespace
    {
        template <typename T>
        [[nodiscard]] core::Variant GamekitElementOf(core::Variant handle)
        {
            Node* node = Node::FromHandle(handle);
            T* typed = node != nullptr ? core::Cast<T>(node) : nullptr;
            return typed != nullptr ? typed->HandleAs(T::StaticType()) : core::Variant{};
        }
    }

    REFLECT_MEMBERS(Screen, "rtti::gui::gamekit")
    {
        builder.Method<&Screen::IsCovered>("isCovered");
        builder.Method<&Screen::StackElement, ScreenStack>("stack");
        builder.Method<&GamekitElementOf<Screen>, Screen, Node>("of");
    }

    REFLECT_MEMBERS(ScreenStack, "rtti::gui::gamekit")
    {
        builder.Method<&ScreenStack::PushScript, Screen>("push");         // a document's path
        builder.Method<&ScreenStack::PushNodeScript, Screen, Node>("pushNode");
        builder.Method<&ScreenStack::ReplaceScript, Screen>("replace");
        builder.Method<&ScreenStack::ReplaceNodeScript, Screen, Node>("replaceNode");
        builder.Method<&ScreenStack::Pop>("pop");
        builder.Method<&ScreenStack::Clear>("clear");
        builder.Method<&ScreenStack::Back>("back");
        builder.Method<&ScreenStack::TopScript, Screen>("top");
        builder.Method<&ScreenStack::CountScript>("count");
        builder.Method<&ScreenStack::IsPaused>("isPaused");
        builder.Method<&GamekitElementOf<ScreenStack>, ScreenStack, Node>("of");
    }

    REFLECT_MEMBERS(Prompt, "rtti::gui::gamekit")
    {
        builder.Method<&GamekitElementOf<Prompt>, Prompt, Node>("of");
    }
}
