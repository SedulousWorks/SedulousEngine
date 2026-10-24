// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_edit_model partition
//
// The editing model (E4 of Specs/gui-lab-evolution.md): a text with a caret and an anchor, edited by
// named commands. Offsets are bytes kept on grapheme boundaries, so a caret never splits "é" written
// as e + U+0301 or an emoji's parts; words come from :text_segmentation. Keys reach the model through
// the keymap: a field declares the "textinput" key context, the GUI binds the editing keys to the
// commands' names there (BindTextEditingKeys), and the field handles each name by running it here,
// so the keys are rebindable and a menu can show and run them like any other command (eepp's text
// input over a document and a command map). What each command does follows foundation.ui's editor.
//
// Vertical movement and a visual line's ends ask a view's lines (ITextLines: a wrapped text area
// knows them); with none, lines are the text's own, between line breaks. Undo keeps whole
// snapshots and folds a run of typing, or of deleting one way, into one step while it goes on
// within a second (the host advances the model's clock); moving the caret, or any other edit, ends
// the run.

module;
#include "Core/Prelude.h"

export module foundation.gui:text_edit_model;

import foundation.core; // String, StringView, Function, Min, Max, DecodeUtf8, AppendUtf8
import :clipboard;
import :text_segmentation;
import :undo_stack;
import :input_filter;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class TextEditCommand : u8
    {
        MoveLeft,
        MoveRight,
        MoveWordLeft,
        MoveWordRight,
        MoveLineStart,
        MoveLineEnd,
        MoveUp,
        MoveDown,
        MovePageUp,
        MovePageDown,
        MoveDocumentStart,
        MoveDocumentEnd,
        SelectLeft,
        SelectRight,
        SelectWordLeft,
        SelectWordRight,
        SelectLineStart,
        SelectLineEnd,
        SelectUp,
        SelectDown,
        SelectPageUp,
        SelectPageDown,
        SelectDocumentStart,
        SelectDocumentEnd,
        SelectAll,
        DeleteBackward,
        DeleteForward,
        DeleteWordBackward,
        DeleteWordForward,
        DeleteToLineStart,
        DeleteToLineEnd,
        InsertNewline,
        Undo,
        Redo,
        Cut,
        Copy,
        Paste,
        Count,
    };

    namespace detail
    {
        inline constexpr const char8_t* kTextEditCommandNames[] = {
            u8"text.move-left", u8"text.move-right", u8"text.move-word-left", u8"text.move-word-right",
            u8"text.move-line-start", u8"text.move-line-end", u8"text.move-up", u8"text.move-down",
            u8"text.move-page-up", u8"text.move-page-down", u8"text.move-document-start", u8"text.move-document-end",
            u8"text.select-left", u8"text.select-right", u8"text.select-word-left", u8"text.select-word-right",
            u8"text.select-line-start", u8"text.select-line-end", u8"text.select-up", u8"text.select-down",
            u8"text.select-page-up", u8"text.select-page-down", u8"text.select-document-start",
            u8"text.select-document-end", u8"text.select-all", u8"text.delete-backward", u8"text.delete-forward",
            u8"text.delete-word-backward", u8"text.delete-word-forward", u8"text.delete-to-line-start",
            u8"text.delete-to-line-end", u8"text.newline", u8"text.undo", u8"text.redo", u8"text.cut", u8"text.copy",
            u8"text.paste",
        };
        static_assert(sizeof(kTextEditCommandNames) / sizeof(kTextEditCommandNames[0]) ==
                      static_cast<usize>(TextEditCommand::Count));
    }

    /// The command's name, as the keymap binds it ("text.move-word-left").
    [[nodiscard]] inline core::StringView TextEditCommandName(TextEditCommand command) noexcept
    {
        return core::StringView(detail::kTextEditCommandNames[static_cast<usize>(command)]);
    }

    /// What a view knows of the lines it shows the text in (wrapped, they are not the text's own).
    class ITextLines
    {
    public:
        virtual ~ITextLines() = default;
        /// The line holding the caret at `offset` (its ends are where Home and End go).
        [[nodiscard]] virtual TextRange LineAt(usize offset) const = 0;
        /// The offset `lines` lines above (negative) or below `offset`, nearest `goalX` across; the
        /// text's start or end past the first or last line. `goalX` below 0: from `offset`'s own x,
        /// which it sets.
        [[nodiscard]] virtual usize OffsetByLines(usize offset, i32 lines, f32& goalX) const = 0;
        /// How many lines a page moves.
        [[nodiscard]] virtual i32 LinesPerPage() const = 0;
    };

    /// What a view knows of where carets stand (E9c): Left and Right move across what it shows,
    /// which in mixed-direction text is not the order of the bytes.
    class ITextCaretPlaces
    {
    public:
        virtual ~ITextCaretPlaces() = default;
        /// The caret one place left (`step` below 0) or right of (`offset`, `upstream`); false when
        /// there is none that way (it stays).
        [[nodiscard]] virtual bool OffsetVisually(usize offset, bool upstream, i32 step, usize& outOffset, bool& outUpstream) const = 0;
        /// Whether the paragraph holding `offset` runs right to left: there a word to the left is
        /// the next one, and a selection's left end its logical end (E11).
        [[nodiscard]] virtual bool IsRightToLeftAt(usize offset) const = 0;
    };

    class TextEditModel
    {
    public:
        /// How long a run of typing (or deleting) folds into one undo step.
        static constexpr f64 kCoalesceSeconds = 1.0;

        // === Text ===
        [[nodiscard]] core::StringView GetText() const noexcept { return m_text.AsView(); }
        /// Replaces the text from outside an edit: the caret goes to its end, and the history goes.
        void SetText(core::StringView text)
        {
            m_text = core::String(text);
            m_caret = m_anchor = m_text.Size();
            m_upstream = false;
            m_undo.Clear();
            EndRun();
            m_goalX = -1.0f;
            Changed();
        }
        /// How many times the text has changed (a view redraws and notifies on a new count).
        [[nodiscard]] u64 GetVersion() const noexcept { return m_version; }

        // === Caret and selection ===
        [[nodiscard]] usize GetCaret() const noexcept { return m_caret; }
        /// Whether the caret stands after the text before it rather than before the text after it
        /// (where the two differ, at a direction's boundary, E9c).
        [[nodiscard]] bool IsCaretUpstream() const noexcept { return m_upstream; }
        [[nodiscard]] usize GetAnchor() const noexcept { return m_anchor; }
        [[nodiscard]] bool HasSelection() const noexcept { return m_caret != m_anchor; }
        [[nodiscard]] TextRange GetSelection() const noexcept
        {
            return TextRange{core::Min(m_caret, m_anchor), core::Max(m_caret, m_anchor)};
        }
        [[nodiscard]] core::StringView SelectedText() const
        {
            const TextRange s = GetSelection();
            return m_text.AsView().SubStr(s.Start, s.End - s.Start);
        }
        /// Puts the caret at `offset` (snapped back to a grapheme boundary); `extend` keeps the
        /// anchor, so the selection grows to it.
        void SetCaret(usize offset, bool extend = false, bool upstream = false)
        {
            m_caret = Snap(offset);
            m_upstream = upstream && m_caret == offset;
            if (!extend)
                m_anchor = m_caret;
            EndRun();
            m_goalX = -1.0f;
        }
        void Select(TextRange range)
        {
            m_anchor = Snap(range.Start);
            m_caret = Snap(range.End);
            m_upstream = false;
            EndRun();
            m_goalX = -1.0f;
        }
        void SelectAll() { Select(TextRange{0, m_text.Size()}); }
        /// Selects the word, spaces or punctuation at `offset` (a double click).
        void SelectWordAt(usize offset) { Select(WordRangeAt(m_text.AsView(), Snap(offset))); }

        // === Rules ===
        void SetMultiline(bool multiline) noexcept { m_multiline = multiline; }
        [[nodiscard]] bool IsMultiline() const noexcept { return m_multiline; }
        void SetReadOnly(bool readOnly) noexcept { m_readOnly = readOnly; }
        [[nodiscard]] bool IsReadOnly() const noexcept { return m_readOnly; }
        /// The most graphemes the text may hold (0: no limit); what does not fit is cut.
        void SetMaxLength(usize graphemes) noexcept { m_maxLength = graphemes; }
        [[nodiscard]] usize GetMaxLength() const noexcept { return m_maxLength; }
        void SetFilter(InputFilter filter) { m_filter = core::Move(filter); }
        [[nodiscard]] const InputFilter& GetFilter() const noexcept { return m_filter; }
        /// Whether the text may leave through copy and cut (a password's may not).
        void SetCopyAllowed(bool allowed) noexcept { m_copyAllowed = allowed; }
        [[nodiscard]] bool IsCopyAllowed() const noexcept { return m_copyAllowed; }
        /// The lines vertical movement and Home and End follow (null: the text's own).
        void SetLines(const ITextLines* lines) noexcept { m_lines = lines; }
        /// Where carets stand in the view (null: Left and Right move by graphemes, as the bytes go).
        void SetCaretPlaces(const ITextCaretPlaces* places) noexcept { m_places = places; }
        [[nodiscard]] UndoStack& GetUndoStack() noexcept { return m_undo; }

        /// The model's clock, in seconds, which undo folding reads.
        void SetTime(f64 seconds) noexcept { m_now = seconds; }
        [[nodiscard]] f64 GetTime() const noexcept { return m_now; }

        // === Editing ===
        /// Types `text` at the caret, over the selection: what the filter lets in, line breaks only
        /// in a multiline text, as much as the length limit leaves room for. True when it changed.
        bool Insert(core::StringView text) { return InsertText(text, RunKind::Typing); }

        /// Runs `command`; `clipboard` serves cut, copy and paste (null: they do nothing). True when
        /// it applies to this text (a read-only text takes moves and copies, not edits).
        bool Run(TextEditCommand command, IClipboard* clipboard = nullptr)
        {
            using C = TextEditCommand;
            const core::StringView text = m_text.AsView();
            switch (command)
            {
            // Across what the view shows (E9c); a selection collapses to its end on that side (in a
            // right-to-left paragraph, Left goes to its logical end).
            case C::MoveLeft:
                return HasSelection() ? MoveCaret(RightToLeftHere() ? GetSelection().End : GetSelection().Start, false)
                                      : MoveAcross(-1, false);
            case C::MoveRight:
                return HasSelection() ? MoveCaret(RightToLeftHere() ? GetSelection().Start : GetSelection().End, false)
                                      : MoveAcross(1, false);
            case C::SelectLeft: return MoveAcross(-1, true);
            case C::SelectRight: return MoveAcross(1, true);
            // A word on that side, by the text's order in the caret's paragraph (E11): to the left
            // of a right-to-left one is the next word.
            case C::MoveWordLeft:
            case C::SelectWordLeft:
                return MoveCaret(RightToLeftHere() ? NextWordBoundary(text, m_caret) : PrevWordBoundary(text, m_caret),
                                 command == C::SelectWordLeft);
            case C::MoveWordRight:
            case C::SelectWordRight:
                return MoveCaret(RightToLeftHere() ? PrevWordBoundary(text, m_caret) : NextWordBoundary(text, m_caret),
                                 command == C::SelectWordRight);
            case C::MoveLineStart:
            case C::SelectLineStart: return MoveCaret(LineAt(m_caret).Start, command == C::SelectLineStart);
            case C::MoveLineEnd:
            case C::SelectLineEnd: return MoveCaret(LineAt(m_caret).End, command == C::SelectLineEnd);
            case C::MoveDocumentStart:
            case C::SelectDocumentStart: return MoveCaret(0, command == C::SelectDocumentStart);
            case C::MoveDocumentEnd:
            case C::SelectDocumentEnd: return MoveCaret(text.Size(), command == C::SelectDocumentEnd);
            case C::MoveUp:
            case C::SelectUp: return MoveLines(-1, command == C::SelectUp);
            case C::MoveDown:
            case C::SelectDown: return MoveLines(1, command == C::SelectDown);
            case C::MovePageUp:
            case C::SelectPageUp: return MoveLines(-PageLines(), command == C::SelectPageUp);
            case C::MovePageDown:
            case C::SelectPageDown: return MoveLines(PageLines(), command == C::SelectPageDown);
            case C::SelectAll:
                SelectAll();
                return true;
            case C::DeleteBackward:
                return DeleteTo(HasSelection() ? m_caret : PrevGrapheme(text, m_caret), RunKind::DeletingBack);
            case C::DeleteForward:
                return DeleteTo(HasSelection() ? m_caret : NextGrapheme(text, m_caret), RunKind::DeletingForward);
            case C::DeleteWordBackward: return DeleteTo(HasSelection() ? m_caret : PrevWordBoundary(text, m_caret), RunKind::Other);
            case C::DeleteWordForward: return DeleteTo(HasSelection() ? m_caret : NextWordBoundary(text, m_caret), RunKind::Other);
            case C::DeleteToLineStart: return DeleteTo(HasSelection() ? m_caret : LineAt(m_caret).Start, RunKind::Other);
            case C::DeleteToLineEnd: return DeleteTo(HasSelection() ? m_caret : LineAt(m_caret).End, RunKind::Other);
            case C::InsertNewline:
                if (!m_multiline)
                    return false;
                return InsertText(core::StringView(u8"\n"), RunKind::Other);
            case C::Undo: return StepHistory(true);
            case C::Redo: return StepHistory(false);
            case C::Copy:
                if (clipboard != nullptr && HasSelection() && m_copyAllowed)
                    clipboard->SetText(SelectedText());
                return true;
            case C::Cut:
                if (!m_copyAllowed)
                    return true; // nothing leaves a password, and nothing goes
                if (clipboard != nullptr && HasSelection())
                    clipboard->SetText(SelectedText());
                if (m_readOnly)
                    return true; // a read-only cut is a copy
                return DeleteTo(m_caret, RunKind::Other);
            case C::Paste:
                if (m_readOnly)
                    return false;
                if (clipboard != nullptr && clipboard->HasText())
                    (void)InsertText(clipboard->GetText().AsView(), RunKind::Other);
                return true;
            case C::Count: break;
            }
            return false;
        }

        /// The command a name names (as the keymap binds it); false for a name not the model's.
        [[nodiscard]] static bool FindCommand(core::StringView name, TextEditCommand& out)
        {
            for (usize i = 0; i < static_cast<usize>(TextEditCommand::Count); ++i)
                if (name == core::StringView(detail::kTextEditCommandNames[i]))
                {
                    out = static_cast<TextEditCommand>(i);
                    return true;
                }
            return false;
        }

    private:
        enum class RunKind : u8
        {
            None,
            Typing,
            DeletingBack,
            DeletingForward,
            Other,
        };

        [[nodiscard]] usize Snap(usize offset) const
        {
            const core::StringView text = m_text.AsView();
            offset = core::Min(offset, text.Size());
            // Back off a UTF-8 continuation byte, then off a mark that belongs to the grapheme before.
            while (offset > 0 && offset < text.Size() &&
                   ((static_cast<u8>(text[offset]) & 0xC0) == 0x80 || !IsGraphemeBoundary(text, offset)))
                --offset;
            return offset;
        }

        // Whether the caret's paragraph runs right to left (the view says; none: left to right).
        [[nodiscard]] bool RightToLeftHere() const { return m_places != nullptr && m_places->IsRightToLeftAt(m_caret); }

        // One place left or right: across the view where it says where carets stand, else by a
        // grapheme as the bytes go.
        bool MoveAcross(i32 step, bool extend)
        {
            const core::StringView text = m_text.AsView();
            if (m_places == nullptr)
                return MoveCaret(step < 0 ? PrevGrapheme(text, m_caret) : NextGrapheme(text, m_caret), extend);
            usize to = m_caret;
            bool upstream = m_upstream;
            if (!m_places->OffsetVisually(m_caret, m_upstream, step, to, upstream))
                return MoveCaret(m_caret, extend, m_upstream);
            const usize snapped = Snap(core::Min(to, text.Size()));
            return MoveCaret(snapped, extend, upstream && snapped == to);
        }
        bool MoveCaret(usize to, bool extend, bool upstream = false)
        {
            m_upstream = upstream;
            m_caret = to;
            if (!extend)
                m_anchor = to;
            EndRun();
            m_goalX = -1.0f;
            return true;
        }

        [[nodiscard]] TextRange LineAt(usize offset) const
        {
            return m_lines != nullptr ? m_lines->LineAt(offset) : LineRangeAt(m_text.AsView(), offset);
        }
        [[nodiscard]] i32 PageLines() const { return m_lines != nullptr ? core::Max(1, m_lines->LinesPerPage()) : 1; }

        bool MoveLines(i32 lines, bool extend)
        {
            if (!m_multiline)
                return false;
            usize to;
            if (m_lines != nullptr)
            {
                f32 x = m_goalX;
                to = m_lines->OffsetByLines(m_caret, lines, x);
                m_goalX = x;
            }
            else
            {
                to = OffsetByTextLines(lines);
            }
            m_caret = to; // the goal stays for the next vertical move
            m_upstream = false;
            if (!extend)
                m_anchor = to;
            EndRun();
            return true;
        }
        // The text's own lines, the column counted in graphemes (the goal kept in m_goalX).
        [[nodiscard]] usize OffsetByTextLines(i32 lines)
        {
            const core::StringView text = m_text.AsView();
            TextRange line = LineRangeAt(text, m_caret);
            if (m_goalX < 0.0f)
                m_goalX = static_cast<f32>(GraphemeCount(text.SubStr(line.Start, m_caret - line.Start)));
            for (; lines < 0; ++lines)
            {
                if (line.Start == 0)
                    return 0;
                line = LineRangeAt(text, line.Start - 1);
            }
            for (; lines > 0; --lines)
            {
                usize next = line.End;
                while (next < text.Size() && text[next] != u8'\n')
                    ++next;
                if (next >= text.Size())
                    return text.Size();
                line = LineRangeAt(text, next + 1);
            }
            usize at = line.Start;
            for (i32 column = 0; column < static_cast<i32>(m_goalX) && at < line.End; ++column)
                at = NextGrapheme(text, at);
            return core::Min(at, line.End);
        }

        // Deletes from the caret to `to` (or the selection, when there is one).
        bool DeleteTo(usize to, RunKind kind)
        {
            if (m_readOnly)
                return false;
            const TextRange range = HasSelection() ? GetSelection() : TextRange{core::Min(m_caret, to), core::Max(m_caret, to)};
            if (range.IsEmpty())
            {
                EndRun();
                return true;
            }
            Remember(HasSelection() ? RunKind::Other : kind);
            m_text.Remove(range.Start, range.End - range.Start);
            m_caret = m_anchor = range.Start;
            m_upstream = false;
            m_goalX = -1.0f;
            Changed();
            return true;
        }

        bool InsertText(core::StringView text, RunKind kind)
        {
            if (m_readOnly)
                return false;
            // What the filter lets in; a single-line text takes a line break as a space.
            core::String accepted;
            for (usize i = 0; i < text.Size();)
            {
                u32 c = core::DecodeUtf8(text, i);
                if (c == u8'\r')
                {
                    if (i < text.Size() && text[i] == u8'\n')
                        continue; // CR LF: the LF follows
                    c = u8'\n';
                }
                if (c == u8'\n' && !m_multiline)
                    c = u8' ';
                if (c != u8'\n' && c != u8'\t' && c < 0x20)
                    continue; // other controls are not text
                if (c != u8'\n' && !m_filter.Accept(static_cast<char32_t>(c)))
                    continue;
                core::AppendUtf8(accepted, c);
            }
            // As many graphemes as the limit leaves room for.
            const TextRange selection = GetSelection();
            if (m_maxLength > 0)
            {
                const core::StringView whole = m_text.AsView();
                const usize kept = GraphemeCount(whole) - GraphemeCount(whole.SubStr(selection.Start, selection.End - selection.Start));
                const usize room = kept >= m_maxLength ? 0 : m_maxLength - kept;
                usize end = 0;
                for (usize n = 0; n < room && end < accepted.Size(); ++n)
                    end = NextGrapheme(accepted.AsView(), end);
                accepted = core::String(accepted.AsView().SubStr(0, end));
            }
            // Nothing of what was typed is let in: nothing changes (the selection it would have
            // replaced stays, rather than being deleted for nothing).
            if (accepted.Size() == 0 && (selection.IsEmpty() || text.Size() != 0))
                return false;
            Remember(selection.IsEmpty() ? kind : RunKind::Other);
            m_text.Remove(selection.Start, selection.End - selection.Start);
            m_text.Insert(selection.Start, accepted.AsView());
            m_caret = m_anchor = selection.Start + accepted.Size();
            m_upstream = false;
            m_goalX = -1.0f;
            Changed();
            return true;
        }

        // Before an edit: a new undo step, unless it goes on the run before it.
        void Remember(RunKind kind)
        {
            const bool folds = kind != RunKind::Other && kind == m_run && m_now - m_runTime <= kCoalesceSeconds;
            if (!folds)
                m_undo.Push(m_text.AsView(), m_caret, m_anchor);
            m_run = kind;
            m_runTime = m_now;
        }
        void EndRun() noexcept { m_run = RunKind::None; }

        bool StepHistory(bool back)
        {
            if (m_readOnly)
                return false;
            const UndoEntry current{m_text, m_caret, m_anchor};
            UndoEntry restored;
            if (!(back ? m_undo.Undo(current, restored) : m_undo.Redo(current, restored)))
                return true;
            m_text = core::Move(restored.Text);
            m_caret = core::Min(restored.Caret, m_text.Size());
            m_upstream = false;
            m_anchor = core::Min(restored.Anchor, m_text.Size());
            EndRun();
            m_goalX = -1.0f;
            Changed();
            return true;
        }

        void Changed() noexcept { ++m_version; }

        core::String m_text;
        usize m_caret = 0;
        usize m_anchor = 0;
        u64 m_version = 0;
        UndoStack m_undo;
        InputFilter m_filter;
        const ITextLines* m_lines = nullptr;
        const ITextCaretPlaces* m_places = nullptr;
        bool m_upstream = false; // the caret's affinity (E9c)
        usize m_maxLength = 0;
        f32 m_goalX = -1.0f; // where vertical movement aims across (-1: from the caret)
        f64 m_now = 0.0;
        f64 m_runTime = 0.0;
        RunKind m_run = RunKind::None;
        bool m_multiline = false;
        bool m_readOnly = false;
        bool m_copyAllowed = true;
    };
}
