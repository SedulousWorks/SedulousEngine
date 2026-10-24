// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_editing_keys partition
//
// The editing keys, as bindings (E4 of Specs/gui-lab-evolution.md): every GUI starts with them, in
// the "textinput" key context a text field declares ("textinput multiline" for a text area), so a
// later binding of the same keys, there or deeper, overrides one, and an empty command unbinds it.
// The keys are the common desktop ones (Ctrl with the arrows by word, Home and End by line, Ctrl+Z
// and Ctrl+Y, Shift+Delete and Shift+Insert as well as Ctrl+X, C and V).

module;
#include "Core/Prelude.h"

export module foundation.gui:text_editing_keys;

import foundation.core; // StringView
import :keymap;
import :text_edit_model;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What a single-line field does with Return: it submits.
    inline constexpr const char8_t* kTextSubmitCommand = u8"text.submit";

    /// Binds the editing keys to the editing commands: in the text contexts (`context` empty), or,
    /// every key a multiline editor takes, in `context` alone (a widget that edits text but is not
    /// a text input to the keymap, so a field inside it is one alone: a code editor's find bar).
    inline void BindTextEditingKeys(Keymap& keymap, core::StringView context = {})
    {
        using C = TextEditCommand;
        struct Binding
        {
            const char8_t* Keys;
            TextEditCommand Command;
        };
        static constexpr Binding kEverywhere[] = {
            {u8"left", C::MoveLeft},
            {u8"right", C::MoveRight},
            {u8"ctrl-left", C::MoveWordLeft},
            {u8"ctrl-right", C::MoveWordRight},
            {u8"home", C::MoveLineStart},
            {u8"end", C::MoveLineEnd},
            {u8"ctrl-home", C::MoveDocumentStart},
            {u8"ctrl-end", C::MoveDocumentEnd},
            {u8"shift-left", C::SelectLeft},
            {u8"shift-right", C::SelectRight},
            {u8"ctrl-shift-left", C::SelectWordLeft},
            {u8"ctrl-shift-right", C::SelectWordRight},
            {u8"shift-home", C::SelectLineStart},
            {u8"shift-end", C::SelectLineEnd},
            {u8"ctrl-shift-home", C::SelectDocumentStart},
            {u8"ctrl-shift-end", C::SelectDocumentEnd},
            {u8"ctrl-a", C::SelectAll},
            {u8"shift-backspace", C::DeleteBackward},
            {u8"backspace", C::DeleteBackward},
            {u8"delete", C::DeleteForward},
            {u8"ctrl-backspace", C::DeleteWordBackward},
            {u8"ctrl-delete", C::DeleteWordForward},
            {u8"ctrl-z", C::Undo},
            {u8"ctrl-shift-z", C::Redo},
            {u8"ctrl-y", C::Redo},
            // The alternates first: the last binding to a command is the one a menu shows.
            {u8"shift-delete", C::Cut},
            {u8"ctrl-x", C::Cut},
            {u8"ctrl-insert", C::Copy},
            {u8"ctrl-c", C::Copy},
            {u8"shift-insert", C::Paste},
            {u8"ctrl-v", C::Paste},
        };
        static constexpr Binding kMultiline[] = {
            {u8"up", C::MoveUp},
            {u8"down", C::MoveDown},
            {u8"pageup", C::MovePageUp},
            {u8"pagedown", C::MovePageDown},
            {u8"shift-up", C::SelectUp},
            {u8"shift-down", C::SelectDown},
            {u8"shift-pageup", C::SelectPageUp},
            {u8"shift-pagedown", C::SelectPageDown},
            {u8"enter", C::InsertNewline},
            {u8"shift-enter", C::InsertNewline},
        };
        if (context.Size() != 0)
        {
            for (const Binding& b : kEverywhere)
                (void)keymap.Bind(core::StringView(b.Keys), TextEditCommandName(b.Command), context);
            for (const Binding& b : kMultiline)
                (void)keymap.Bind(core::StringView(b.Keys), TextEditCommandName(b.Command), context);
            return;
        }
        for (const Binding& b : kEverywhere)
            (void)keymap.Bind(core::StringView(b.Keys), TextEditCommandName(b.Command), core::StringView(u8"textinput"));
        for (const Binding& b : kMultiline)
            (void)keymap.Bind(core::StringView(b.Keys), TextEditCommandName(b.Command),
                              core::StringView(u8"textinput && multiline"));
        (void)keymap.Bind(core::StringView(u8"enter"), core::StringView(kTextSubmitCommand),
                          core::StringView(u8"textinput && !multiline"));
        // Where Return breaks a line, Ctrl+Return submits (a comment's or a message's way).
        (void)keymap.Bind(core::StringView(u8"ctrl-enter"), core::StringView(kTextSubmitCommand),
                          core::StringView(u8"textinput && multiline"));
    }
}
