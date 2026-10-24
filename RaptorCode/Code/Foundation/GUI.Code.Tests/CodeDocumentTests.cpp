// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - the document (C0 of Specs/gui-lab-evolution-3.md): lines from a text and back, positions
// on characters' boundaries, edits across lines told as the lines they replaced, anchors carried
// through edits by their bias, and undo as transactions that put the selections back, typing within
// 300 ms merged into one step.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui.code;

using namespace foundation::gui;
namespace core = foundation::core;
using core::u32;
using core::u64;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    CodePosition At(u32 line, u32 column) { return CodePosition{line, column}; }
}

TEST_CASE("code document: lines from a text and back; an empty text one empty line")
{
    CodeDocument doc(core::DefaultAllocator());
    CHECK(doc.LineCount() == 1u);
    CHECK(doc.LineText(0).Size() == 0u);
    doc.SetText(SV(u8"int a;\r\nint b;\n\nend"));
    REQUIRE(doc.LineCount() == 4u);
    CHECK(doc.LineText(0) == SV(u8"int a;")); // the carriage return dropped
    CHECK(doc.LineText(2).Size() == 0u);
    CHECK(doc.GetText() == core::String(u8"int a;\nint b;\n\nend"));
    CHECK(doc.End() == At(3, 3));
    CHECK(doc.TextIn(CodeRange{At(0, 4), At(1, 3)}) == core::String(u8"a;\nint"));
    CHECK(doc.LineHash(0) != doc.LineHash(1)); // a hash per line
    doc.SetText(SV(u8"x\n"));
    CHECK(doc.LineCount() == 2u); // a text ending in a line feed ends in an empty line
}

TEST_CASE("code document: positions stay on characters; a step is a grapheme, across lines at their ends")
{
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"aé b\ncd")); // é is two bytes
    CHECK(doc.Clamp(At(0, 2)) == At(0, 1));  // inside é: back to its start
    CHECK(doc.Clamp(At(0, 99)) == At(0, 5)); // past the line's end
    CHECK(doc.Clamp(At(7, 0)) == doc.End());  // past the last line
    CHECK(doc.NextCharacter(At(0, 1)) == At(0, 3)); // over é
    CHECK(doc.PreviousCharacter(At(0, 3)) == At(0, 1));
    CHECK(doc.NextCharacter(At(0, 5)) == At(1, 0)); // a line's end to the next's start
    CHECK(doc.PreviousCharacter(At(1, 0)) == At(0, 5));
    CHECK(doc.NextCharacter(doc.End()) == doc.End());
    CHECK(doc.PreviousCharacter(At(0, 0)) == At(0, 0));
}

TEST_CASE("code document: an edit across lines replaces them, told as the lines it replaced")
{
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"one\ntwo\nthree"));
    core::Array<CodeChange> changes{core::DefaultAllocator()};
    const core::u32 token = doc.AddChangeListener([&changes](const CodeChange& change) { changes.PushBack(change); });
    core::Array<CodeChange> others{core::DefaultAllocator()};
    const core::u32 second = doc.AddChangeListener([&others](const CodeChange& change) { others.PushBack(change); });
    const u64 version = doc.GetVersion();
    const u64 hash = doc.LineHash(1);
    const CodeRange put = doc.Replace(CodeRange{At(0, 2), At(2, 2)}, SV(u8"X\r\nYY"));
    CHECK(doc.GetText() == core::String(u8"onX\nYYree"));
    CHECK(put == CodeRange{At(0, 2), At(1, 2)});
    REQUIRE(changes.Size() == 1);
    CHECK(changes[0].FirstLine == 0u);
    CHECK(changes[0].RemovedLines == 3u);
    CHECK(changes[0].InsertedLines == 2u);
    CHECK(doc.GetVersion() > version);
    CHECK(doc.LineHash(1) != hash);
    CHECK(others.Size() == 1); // every listener told
    doc.RemoveChangeListener(second);
    doc.RemoveChangeListener(token);

    // Given backwards, the same; removed listeners hear no more.
    doc.Erase(CodeRange{At(1, 2), At(0, 2)});
    CHECK(changes.Size() == 1);
    CHECK(others.Size() == 1);
    CHECK(doc.GetText() == core::String(u8"onree"));
    doc.Insert(At(0, 5), SV(u8"\n"));
    CHECK(doc.LineCount() == 2u);
    CHECK(doc.LineText(1).Size() == 0u);
}

TEST_CASE("code document: anchors go with the text, by their bias where text is put at them")
{
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"alpha beta\ngamma"));
    const CodeAnchorId before = doc.AddAnchor(At(0, 2));
    const CodeAnchorId left = doc.AddAnchor(At(0, 6), CodeBias::Left);
    const CodeAnchorId right = doc.AddAnchor(At(0, 6), CodeBias::Right);
    const CodeAnchorId later = doc.AddAnchor(At(0, 8));
    const CodeAnchorId below = doc.AddAnchor(At(1, 3));
    doc.Insert(At(0, 6), SV(u8"new\nline "));
    CHECK(doc.GetAnchor(before) == At(0, 2));
    CHECK(doc.GetAnchor(left) == At(0, 6));   // stays before what was put
    CHECK(doc.GetAnchor(right) == At(1, 5));  // goes after it
    CHECK(doc.GetAnchor(later) == At(1, 7));  // carried with "beta"
    CHECK(doc.GetAnchor(below) == At(2, 3));  // a line down
    // Inside what is erased: to its start.
    doc.Erase(CodeRange{At(0, 1), At(1, 7)});
    CHECK(doc.GetAnchor(right) == At(0, 1));
    CHECK(doc.GetAnchor(later) == At(0, 1));
    CHECK(doc.GetText() == core::String(u8"ata\ngamma"));
    CHECK(doc.GetAnchor(below) == At(1, 3));
    doc.RemoveAnchor(before);
    CHECK(doc.AddAnchor(At(1, 0)) == before); // its slot reused
}

TEST_CASE("code document: undo and redo step by transactions, the selections put back")
{
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"int x;"));
    const CodeSelection beforeTwo[] = {CodeSelection{At(0, 0), At(0, 0)}, CodeSelection{At(0, 4), At(0, 5)}};
    const CodeSelection afterTwo[] = {CodeSelection{At(0, 2), At(0, 2)}, CodeSelection{At(0, 7), At(0, 7)}};
    doc.Begin(beforeTwo);
    doc.Insert(At(0, 4), SV(u8"yy"));
    doc.Insert(At(0, 0), SV(u8"//"));
    doc.End(afterTwo);
    CHECK(doc.GetText() == core::String(u8"//int yyx;"));
    CHECK(doc.UndoCount() == 1u);

    core::Array<CodeSelection> selections{core::DefaultAllocator()};
    REQUIRE(doc.Undo(selections));
    CHECK(doc.GetText() == core::String(u8"int x;"));
    REQUIRE(selections.Size() == 2);
    CHECK(selections[1] == beforeTwo[1]);
    CHECK(doc.CanRedo());
    REQUIRE(doc.Redo(selections));
    CHECK(doc.GetText() == core::String(u8"//int yyx;"));
    REQUIRE(selections.Size() == 2);
    CHECK(selections[0] == afterTwo[0]);

    // An edit after an undo drops what redo had.
    REQUIRE(doc.Undo(selections));
    doc.Insert(At(0, 0), SV(u8"z"));
    CHECK_FALSE(doc.CanRedo());

    // Nested transactions are one; one with no edits is no step.
    const usize steps = doc.UndoCount();
    doc.Begin({});
    doc.Begin({});
    doc.Insert(At(0, 0), SV(u8"a"));
    doc.End({});
    doc.Insert(At(0, 0), SV(u8"b"));
    doc.End({});
    CHECK(doc.UndoCount() == steps + 1);
    doc.Begin({});
    doc.End({});
    CHECK(doc.UndoCount() == steps + 1);
}

TEST_CASE("code document: typing within 300 ms merges into one step; a pause, a caret moved or another kind breaks it")
{
    CodeDocument doc(core::DefaultAllocator());
    const auto type = [&doc](const char8_t* text)
    {
        doc.Insert(doc.End(), core::StringView(text), CodeEditKind::Typing);
        doc.AdvanceClock(0.1f);
    };
    type(u8"a");
    type(u8"b");
    type(u8"c");
    CHECK(doc.UndoCount() == 1u);
    doc.AdvanceClock(0.5f); // a pause
    type(u8"d");
    CHECK(doc.UndoCount() == 2u);
    doc.BreakMerge(); // the caret moved
    type(u8"e");
    CHECK(doc.UndoCount() == 3u);
    doc.Erase(CodeRange{At(0, 4), At(0, 5)}); // deleting: a step of its own
    CHECK(doc.UndoCount() == 4u);
    core::Array<CodeSelection> selections{core::DefaultAllocator()};
    (void)doc.Undo(selections);
    (void)doc.Undo(selections);
    (void)doc.Undo(selections);
    CHECK(doc.GetText() == core::String(u8"abc"));
    (void)doc.Undo(selections);
    CHECK(doc.GetText().IsEmpty());

    doc.SetUndoLimit(2);
    for (int i = 0; i < 5; ++i)
    {
        doc.BreakMerge();
        type(u8"x");
    }
    CHECK(doc.UndoCount() == 2u);
}
