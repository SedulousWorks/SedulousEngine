// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - `foundation.gui.code`: the code editor (C0 to C8 of Specs/gui-lab-evolution-3.md).
// foundation.ui's counterpart: UI.Toolkit's CodeEditView. A satellite of the GUI (round three): it
// knows no language; a language's definition and its service are its owners'.

module;
#include "Core/Prelude.h"

export module foundation.gui.code;

export import :code_document; // C0: lines, positions, anchors, edits, undo with selections
export import :code_language; // C2: a language's definition (its owners'), its tokenizer
export import :code_sheet;    // C2: its default sheet, over the theme's tokens
export import :code_find_bar; // C4: the find, replace and go-to-line bar
export import :code_completion; // C6: the language service (the host's), the completion list
export import :code_editor;   // C1: the view: shaped lines in view, several carets, the keymap's text commands

export namespace foundation::gui
{
    /// Registers the code editor's element types (ElementTypes::Register), once: a host calls it at
    /// start-up beside RegisterGuiElements, so markup and scripts can make them.
    void RegisterCodeElements();
}
