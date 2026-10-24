// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :undo_stack partition
//
// A bounded undo and redo stack for text editing: each entry is the whole text with its caret and
// anchor (byte offsets), a snapshot rather than a delta, which keeps undo exact for any edit.
//
// Copied from foundation.ui's :undo_stack (E4 of Specs/gui-lab-evolution.md), and the GUI's own
// from then on: offsets are bytes, as the GUI's text keeps them.

module;
#include "Core/Prelude.h"

export module foundation.gui:undo_stack;

import foundation.core; // String, StringView, Array, Max

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// The text, caret and anchor at one point of an edit's history.
    struct UndoEntry
    {
        core::String Text;
        usize Caret = 0;
        usize Anchor = 0;
    };

    class UndoStack
    {
    public:
        [[nodiscard]] bool CanUndo() const noexcept { return m_undo.Size() != 0; }
        [[nodiscard]] bool CanRedo() const noexcept { return m_redo.Size() != 0; }
        [[nodiscard]] usize UndoCount() const noexcept { return m_undo.Size(); }
        [[nodiscard]] usize RedoCount() const noexcept { return m_redo.Size(); }

        [[nodiscard]] usize MaxEntries() const noexcept { return m_maxEntries; }
        void SetMaxEntries(usize value) noexcept { m_maxEntries = core::Max(usize{1}, value); }

        /// Remembers the state before an edit; what was undone can no longer be redone.
        void Push(core::StringView text, usize caret, usize anchor)
        {
            m_redo.Clear();
            PushBounded(m_undo, UndoEntry{core::String(text), caret, anchor});
        }

        /// Steps back: `current` goes onto the redo stack and the state before it comes out in `out`.
        bool Undo(const UndoEntry& current, UndoEntry& out) { return Step(m_undo, m_redo, current, out); }
        /// Steps forward again: `current` goes back onto the undo stack.
        bool Redo(const UndoEntry& current, UndoEntry& out) { return Step(m_redo, m_undo, current, out); }

        void Clear()
        {
            m_undo.Clear();
            m_redo.Clear();
        }

    private:
        void PushBounded(Array<UndoEntry>& stack, UndoEntry entry)
        {
            if (stack.Size() >= m_maxEntries)
                stack.RemoveAt(0); // the oldest goes
            stack.PushBack(Move(entry));
        }
        bool Step(Array<UndoEntry>& from, Array<UndoEntry>& to, const UndoEntry& current, UndoEntry& out)
        {
            if (from.Size() == 0)
                return false;
            PushBounded(to, current);
            out = Move(from.Back());
            from.PopBack();
            return true;
        }

        Array<UndoEntry> m_undo;
        Array<UndoEntry> m_redo;
        usize m_maxEntries = 100;
    };
}
