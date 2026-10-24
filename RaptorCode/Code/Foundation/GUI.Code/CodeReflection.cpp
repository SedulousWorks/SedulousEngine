// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - its widgets' reflection: the code editor an element markup places, its text and
// settings given in code or markup.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module foundation.gui.code;

import foundation.core;
import foundation.gui;

namespace core = foundation::core;

namespace foundation::gui
{
    REFLECT_MEMBERS(CodeEditor, "rtti::gui::code")
    {
        builder.Attribute("accessRole", core::String(u8"textarea"));
        builder.ComputedProperty<&CodeEditor::GetAccessValue>("accessValue").PropAttribute("access", core::String(u8"value"));
        builder.AccessorProperty<&CodeEditor::IsReadOnly, &CodeEditor::SetReadOnly>("readOnly").PropAttribute("css", core::String(u8"read-only"));
        builder.AccessorProperty<&CodeEditor::GetTabSize, &CodeEditor::SetTabSize>("tabSize").PropAttribute("css", core::String(u8"tab-size"));
        builder.AccessorProperty<&CodeEditor::GetSoftWrap, &CodeEditor::SetSoftWrap>("softWrap").PropAttribute("css", core::String(u8"soft-wrap"));
        builder.Creator();
    }

    RTTI_DEFINE_OBJECT(CodeFindBar, "rtti::gui::code")
    RTTI_DEFINE_OBJECT(CodeCompletionList, "rtti::gui::code")

    void RegisterCodeElements()
    {
        static const bool once = []()
        {
            (void)ElementTypes::Register(CodeEditor::StaticType());
            return true;
        }();
        (void)once;
    }
}
