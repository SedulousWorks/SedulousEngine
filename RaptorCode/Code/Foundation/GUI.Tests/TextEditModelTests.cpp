// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The editing model (E4 of Specs/gui-lab-evolution.md): graphemes and words over UTF-8, each
// command on multi-byte and combining text, undo folding, the filter and the length limit, read-only
// and password rules, and the editing keys bound in the text contexts.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    using SV = core::StringView;

    class TestClipboard : public IClipboard
    {
    public:
        bool HasText() const override { return m_text.Size() != 0; }
        core::String GetText() const override { return m_text; }
        void SetText(core::StringView text) override { m_text = core::String(text); }
        core::String m_text;
    };

    TextEditModel Model(SV text)
    {
        TextEditModel model;
        model.SetText(text);
        return model;
    }
}

TEST_CASE("segmentation: a combining mark, an emoji's joined parts and a flag are one grapheme each")
{
    const SV accent(u8"e\u0301x"); // e + combining acute, then x
    CHECK(NextGrapheme(accent, 0) == 3u);
    CHECK(PrevGrapheme(accent, 3) == 0u);
    CHECK_FALSE(IsGraphemeBoundary(accent, 1));
    CHECK(GraphemeCount(accent) == 2u);

    const SV family(u8"\U0001F469\u200D\U0001F467!"); // woman ZWJ girl, then !
    CHECK(NextGrapheme(family, 0) == family.Size() - 1);
    const SV flags(u8"\U0001F1EF\U0001F1F5\U0001F1EB\U0001F1F7"); // two flags
    CHECK(NextGrapheme(flags, 0) == 8u);
    CHECK(GraphemeCount(flags) == 2u);
    const SV crlf(u8"a\r\nb");
    CHECK(NextGrapheme(crlf, 1) == 3u);
    const SV thumbs(u8"\U0001F44D\U0001F3FD."); // thumbs up, medium skin tone
    CHECK(NextGrapheme(thumbs, 0) == 8u);
}

TEST_CASE("segmentation: words move over a word and the gap after it, never across a line break")
{
    const SV text(u8"one two,  three\nfour");
    CHECK(NextWordBoundary(text, 0) == 4u);  // "one " -> before "two"
    CHECK(NextWordBoundary(text, 4) == 10u); // "two,  " -> before "three"
    CHECK(NextWordBoundary(text, 10) == 15u); // stops at the break
    CHECK(NextWordBoundary(text, 15) == 16u); // over the break
    CHECK(PrevWordBoundary(text, 20) == 16u);
    CHECK(PrevWordBoundary(text, 16) == 15u);
    CHECK(PrevWordBoundary(text, 15) == 10u);
    CHECK(PrevWordBoundary(text, 10) == 4u);
    CHECK(WordRangeAt(text, 5) == TextRange{4, 7});
    CHECK(WordRangeAt(text, 8) == TextRange{8, 10}); // the spaces
    const SV accented(u8"café crème");
    CHECK(WordRangeAt(accented, 1) == TextRange{0, 5}); // é counts as a letter
    CHECK(LineRangeAt(text, 17) == TextRange{16, 20});
}

TEST_CASE("text edit model: caret moves step by grapheme, collapse a selection, and extend one")
{
    TextEditModel m = Model(u8"ae\u0301z");
    CHECK(m.GetCaret() == 5u);
    m.Run(TextEditCommand::MoveLeft);
    CHECK(m.GetCaret() == 4u); // before z
    m.Run(TextEditCommand::MoveLeft);
    CHECK(m.GetCaret() == 1u); // over e + acute at once
    m.Run(TextEditCommand::SelectRight);
    CHECK(m.SelectedText() == SV(u8"e\u0301"));
    m.Run(TextEditCommand::MoveLeft);
    CHECK(m.GetCaret() == 1u); // collapsed to the selection's start
    CHECK_FALSE(m.HasSelection());
    m.Run(TextEditCommand::SelectDocumentEnd);
    CHECK(m.SelectedText() == SV(u8"e\u0301z"));
    m.Run(TextEditCommand::MoveRight);
    CHECK(m.GetCaret() == 5u);
    m.SetCaret(2); // inside the grapheme: snapped back to its start
    CHECK(m.GetCaret() == 1u);
}

TEST_CASE("text edit model: delete by grapheme and by word, and to the line's ends")
{
    TextEditModel m = Model(u8"hello wo\u0308rld");
    m.Run(TextEditCommand::DeleteWordBackward);
    CHECK(m.GetText() == SV(u8"hello "));
    m.SetText(u8"x\U0001F469\u200D\U0001F467");
    m.Run(TextEditCommand::DeleteBackward);
    CHECK(m.GetText() == SV(u8"x")); // the whole family at once
    m.SetText(u8"one two three");
    m.SetCaret(4);
    m.Run(TextEditCommand::DeleteWordForward);
    CHECK(m.GetText() == SV(u8"one three"));
    m.Run(TextEditCommand::DeleteToLineEnd);
    CHECK(m.GetText() == SV(u8"one "));
    m.Run(TextEditCommand::DeleteToLineStart);
    CHECK(m.GetText() == SV(u8""));
    m.SetText(u8"ab");
    m.SetCaret(0);
    m.Run(TextEditCommand::DeleteForward);
    CHECK(m.GetText() == SV(u8"b"));
}

TEST_CASE("text edit model: typing replaces the selection; the filter and the limit cut what comes in")
{
    TextEditModel m = Model(u8"hello");
    m.Select(TextRange{1, 4});
    CHECK(m.Insert(u8"ipp"));
    CHECK(m.GetText() == SV(u8"hippo"));
    CHECK(m.GetCaret() == 4u);

    TextEditModel digits;
    digits.SetFilter(InputFilter::Digits());
    digits.Insert(u8"a1b2c3");
    CHECK(digits.GetText() == SV(u8"123"));

    TextEditModel limited;
    limited.SetMaxLength(3);
    limited.Insert(u8"e\u0301e\u0301e\u0301e\u0301"); // four graphemes, eight codepoints
    CHECK(GraphemeCount(limited.GetText()) == 3u);
    CHECK_FALSE(limited.Insert(u8"x")); // full
    limited.SelectAll();
    CHECK(limited.Insert(u8"ok")); // a selection's room counts
    CHECK(limited.GetText() == SV(u8"ok"));
}

TEST_CASE("text edit model: a single line takes a pasted line break as a space; multiline keeps it")
{
    TestClipboard clipboard;
    clipboard.SetText(u8"a\r\nb\nc");
    TextEditModel line;
    line.Run(TextEditCommand::Paste, &clipboard);
    CHECK(line.GetText() == SV(u8"a b c"));
    CHECK_FALSE(line.Run(TextEditCommand::InsertNewline));

    TextEditModel area;
    area.SetMultiline(true);
    area.Run(TextEditCommand::Paste, &clipboard);
    CHECK(area.GetText() == SV(u8"a\nb\nc"));
    area.Run(TextEditCommand::InsertNewline);
    CHECK(area.GetText() == SV(u8"a\nb\nc\n"));
}

TEST_CASE("text edit model: cut, copy and paste through a clipboard")
{
    TestClipboard clipboard;
    TextEditModel m = Model(u8"copy me");
    m.Select(TextRange{5, 7});
    m.Run(TextEditCommand::Copy, &clipboard);
    CHECK(clipboard.GetText() == SV(u8"me"));
    m.Run(TextEditCommand::Cut, &clipboard);
    CHECK(m.GetText() == SV(u8"copy "));
    m.SetCaret(0);
    m.Run(TextEditCommand::Paste, &clipboard);
    CHECK(m.GetText() == SV(u8"mecopy "));
}

TEST_CASE("text edit model: read-only takes moves and copies, not edits; a password lets nothing out")
{
    TestClipboard clipboard;
    TextEditModel m = Model(u8"fixed");
    m.SetReadOnly(true);
    m.SelectAll();
    CHECK_FALSE(m.Insert(u8"x"));
    CHECK_FALSE(m.Run(TextEditCommand::DeleteBackward));
    CHECK(m.Run(TextEditCommand::Cut, &clipboard)); // a copy
    CHECK(clipboard.GetText() == SV(u8"fixed"));
    CHECK(m.GetText() == SV(u8"fixed"));
    CHECK(m.Run(TextEditCommand::MoveLeft));

    TestClipboard other;
    TextEditModel secret = Model(u8"hunter2");
    secret.SetCopyAllowed(false);
    secret.SelectAll();
    secret.Run(TextEditCommand::Copy, &other);
    secret.Run(TextEditCommand::Cut, &other);
    CHECK_FALSE(other.HasText());
    CHECK(secret.GetText() == SV(u8"hunter2"));
}

TEST_CASE("text edit model: a run of typing undoes as one step; a pause, a move or another edit ends it")
{
    TextEditModel m;
    m.SetTime(0.0);
    m.Insert(u8"a");
    m.SetTime(0.2);
    m.Insert(u8"b");
    m.SetTime(0.4);
    m.Insert(u8"c");
    m.SetTime(3.0); // a pause
    m.Insert(u8"d");
    CHECK(m.GetText() == SV(u8"abcd"));
    m.Run(TextEditCommand::Undo);
    CHECK(m.GetText() == SV(u8"abc"));
    m.Run(TextEditCommand::Undo);
    CHECK(m.GetText() == SV(u8""));
    m.Run(TextEditCommand::Redo);
    CHECK(m.GetText() == SV(u8"abc"));
    CHECK(m.GetCaret() == 3u);

    m.Run(TextEditCommand::MoveLeft); // a move ends the run
    m.Insert(u8"x");
    m.Insert(u8"y");
    m.Run(TextEditCommand::DeleteBackward); // another kind of edit
    m.Run(TextEditCommand::DeleteBackward); // deleting folds with itself
    CHECK(m.GetText() == SV(u8"abc"));
    m.Run(TextEditCommand::Undo);
    CHECK(m.GetText() == SV(u8"abxyc"));
    m.Run(TextEditCommand::Undo);
    CHECK(m.GetText() == SV(u8"abc"));
}

TEST_CASE("text edit model: up and down keep their column across the text's lines")
{
    TextEditModel m = Model(u8"long line\nab\nanother");
    m.SetMultiline(true);
    m.SetCaret(7); // "long li|ne"
    m.Run(TextEditCommand::MoveDown);
    CHECK(m.GetCaret() == 12u); // the end of "ab"
    m.Run(TextEditCommand::MoveDown);
    CHECK(m.GetCaret() == 20u); // column 7 of "another"
    m.Run(TextEditCommand::MoveUp);
    m.Run(TextEditCommand::MoveUp);
    CHECK(m.GetCaret() == 7u);
    m.Run(TextEditCommand::MoveUp);
    CHECK(m.GetCaret() == 0u); // past the first line
    m.Run(TextEditCommand::SelectDown); // the column kept from before
    CHECK(m.SelectedText() == SV(u8"long line\nab"));
    m.SetCaret(14);
    m.Run(TextEditCommand::MoveLineStart);
    CHECK(m.GetCaret() == 13u);
    m.Run(TextEditCommand::MoveLineEnd);
    CHECK(m.GetCaret() == 20u);
}

TEST_CASE("text edit model: every command has a name the keymap binds, found again from it")
{
    for (core::usize i = 0; i < static_cast<core::usize>(TextEditCommand::Count); ++i)
    {
        TextEditCommand found{};
        REQUIRE(TextEditModel::FindCommand(TextEditCommandName(static_cast<TextEditCommand>(i)), found));
        CHECK(static_cast<core::usize>(found) == i);
    }
    TextEditCommand none{};
    CHECK_FALSE(TextEditModel::FindCommand(SV(u8"text.nonesuch"), none));
}

TEST_CASE("text editing keys: bound in the text contexts, multiline keys only in a text area")
{
    Keymap keymap;
    BindTextEditingKeys(keymap);
    KeyContextLayer field;
    field.Declare(SV(u8"textinput"));
    KeyContextLayer area;
    area.Declare(SV(u8"textinput multiline"));
    const auto match = [&](SV keys, const KeyContextLayer& layer, core::String& command)
    {
        const Keystroke stroke = ParseKeystroke(keys).Value();
        return keymap.Match(core::Span<const Keystroke>(&stroke, 1), core::Span<const KeyContextLayer>(&layer, 1), command);
    };
    core::String command;
    CHECK(match(SV(u8"ctrl-shift-left"), field, command) == KeymapMatch::Matched);
    CHECK(command == TextEditCommandName(TextEditCommand::SelectWordLeft));
    CHECK(match(SV(u8"enter"), field, command) == KeymapMatch::Matched);
    CHECK(command == SV(kTextSubmitCommand));
    CHECK(match(SV(u8"enter"), area, command) == KeymapMatch::Matched);
    CHECK(command == TextEditCommandName(TextEditCommand::InsertNewline));
    CHECK(match(SV(u8"up"), field, command) == KeymapMatch::None); // a field's up is navigation's
    CHECK(match(SV(u8"up"), area, command) == KeymapMatch::Matched);
    KeyContextLayer elsewhere;
    elsewhere.Declare(SV(u8"menu"));
    CHECK(match(SV(u8"left"), elsewhere, command) == KeymapMatch::None);
}

TEST_CASE("edit model: typing the filter refuses whole leaves the selection as it was")
{
    TextEditModel digits;
    digits.SetFilter(InputFilter::Digits());
    digits.SetText(core::StringView(u8"12345"));
    digits.Select(TextRange{1, 3});
    CHECK_FALSE(digits.Insert(core::StringView(u8"ab"))); // letters: none let in
    CHECK(digits.GetText() == core::StringView(u8"12345"));
    CHECK(digits.GetSelection().Start == 1u);
    CHECK(digits.GetSelection().End == 3u);
    CHECK(digits.Insert(core::StringView(u8"a9"))); // some let in: they replace it
    CHECK(digits.GetText() == core::StringView(u8"1945"));
}
