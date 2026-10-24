// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - its elements' reflection: a screen's covering, blocking, pausing and back, which
// markup and a sheet set, the stack's script surface (push, pop, replace, clear, back, top), and a
// prompt's action, set and the binding it shows.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module foundation.gui.gamekit;

import foundation.core;
import foundation.gui;

namespace core = foundation::core;

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
        builder.AccessorProperty<&Screen::GetCovers, &Screen::SetCovers>("covers").PropAttribute("css", core::String(u8"covers"));
        builder.AccessorProperty<&Screen::GetBlocks, &Screen::SetBlocks>("blocks").PropAttribute("css", core::String(u8"blocks"));
        builder.AccessorProperty<&Screen::GetPauses, &Screen::SetPauses>("pauses").PropAttribute("css", core::String(u8"pauses"));
        builder.AccessorProperty<&Screen::GetBack, &Screen::SetBack>("back").PropAttribute("css", core::String(u8"back"));
        builder.Method<&Screen::IsCovered>("isCovered");
        builder.Method<&Screen::StackElement, ScreenStack>("stack");
        builder.Method<&GamekitElementOf<Screen>, Screen, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ScreenStack, "rtti::gui::gamekit")
    {
        builder.Attribute("element", core::String(u8"Screens"));
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
        builder.Creator();
    }

    REFLECT_MEMBERS(Prompt, "rtti::gui::gamekit")
    {
        builder.AccessorProperty<&Prompt::GetAction, &Prompt::SetAction>("action").PropAttribute("css", core::String(u8"action"));
        builder.AccessorProperty<&Prompt::GetSet, &Prompt::SetSet>("set").PropAttribute("css", core::String(u8"set"));
        // What a sheet's [binding=...] and [kind=...] read (glyphs are the sheet's).
        builder.ComputedProperty<&Prompt::GetBinding>("binding").PropAttribute("css", core::String(u8"binding"));
        builder.ComputedProperty<&Prompt::GetBindingKind>("kind").PropAttribute("css", core::String(u8"kind"));
        builder.Method<&GamekitElementOf<Prompt>, Prompt, Node>("of");
        builder.Creator();
    }

    void RegisterGamekitElements()
    {
        static const bool once = []()
        {
            (void)ElementTypes::Register(ScreenStack::StaticType());
            (void)ElementTypes::Register(Screen::StaticType());
            (void)ElementTypes::Register(Prompt::StaticType());
            return true;
        }();
        (void)once;
    }
}
