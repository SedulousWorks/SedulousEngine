// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The input filter and the undo stack, copied from foundation.ui with their tests (E4 of
// Specs/gui-lab-evolution.md); the undo stack's offsets are bytes here.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("input-filter: None_AcceptsAll")
{
    InputFilter filter;
    CHECK(filter.Accept(U'a'));
    CHECK(filter.Accept(U'Z'));
    CHECK(filter.Accept(U'5'));
    CHECK(filter.Accept(U' '));
    CHECK(filter.Accept(U'!'));
}

TEST_CASE("input-filter: Digits_AcceptsOnlyDigits")
{
    InputFilter filter = InputFilter::Digits();
    CHECK(filter.Accept(U'0'));
    CHECK(filter.Accept(U'5'));
    CHECK(filter.Accept(U'9'));
    CHECK(!filter.Accept(U'a'));
    CHECK(!filter.Accept(U' '));
    CHECK(!filter.Accept(U'.'));
}

TEST_CASE("input-filter: HexDigits_AcceptsHexChars")
{
    InputFilter filter = InputFilter::HexDigits();
    CHECK(filter.Accept(U'0'));
    CHECK(filter.Accept(U'9'));
    CHECK(filter.Accept(U'a'));
    CHECK(filter.Accept(U'f'));
    CHECK(filter.Accept(U'A'));
    CHECK(filter.Accept(U'F'));
    CHECK(!filter.Accept(U'g'));
    CHECK(!filter.Accept(U'G'));
    CHECK(!filter.Accept(U' '));
}

TEST_CASE("input-filter: Custom_UsesDelegate")
{
    InputFilter filter;
    filter.SetCustomFilter([](char32_t c) { return c == U'x' || c == U'y'; });
    CHECK(filter.Accept(U'x'));
    CHECK(filter.Accept(U'y'));
    CHECK(!filter.Accept(U'z'));
    CHECK(!filter.Accept(U'a'));
}

// === UndoStack ===

TEST_CASE("undo-stack: Push then Undo restores the pushed snapshot")
{
    UndoStack stack;
    CHECK(!stack.CanUndo());
    CHECK(!stack.CanRedo());

    stack.Push(u8"a", 1, 1);
    CHECK(stack.CanUndo());
    CHECK(stack.UndoCount() == 1u);

    UndoEntry out;
    CHECK(stack.Undo(UndoEntry{core::String(u8"ab"), 2, 2}, out));
    CHECK(out.Text == u8"a");
    CHECK(out.Caret == 1u);
    CHECK(out.Anchor == 1u);
    CHECK(!stack.CanUndo());
    CHECK(stack.CanRedo()); // the "ab" state went onto redo
}

TEST_CASE("undo-stack: Redo restores the state undone away")
{
    UndoStack stack;
    stack.Push(u8"a", 1, 1);
    UndoEntry undone;
    stack.Undo(UndoEntry{core::String(u8"ab"), 2, 2}, undone);

    UndoEntry redone;
    CHECK(stack.Redo(undone, redone));
    CHECK(redone.Text == u8"ab");
    CHECK(redone.Caret == 2u);
    CHECK(redone.Anchor == 2u);
    CHECK(stack.CanUndo());
    CHECK(!stack.CanRedo());
}

TEST_CASE("undo-stack: Push clears the redo stack")
{
    UndoStack stack;
    stack.Push(u8"a", 1, 1);
    UndoEntry out;
    stack.Undo(UndoEntry{core::String(u8"ab"), 2, 2}, out);
    CHECK(stack.CanRedo());

    stack.Push(u8"new", 3, 3);
    CHECK(!stack.CanRedo()); // redo cleared by the new push
}

TEST_CASE("undo-stack: capacity drops the oldest entry")
{
    UndoStack stack;
    stack.SetMaxEntries(2);
    CHECK(stack.MaxEntries() == 2u);

    stack.Push(u8"one", 0, 0);
    stack.Push(u8"two", 0, 0);
    stack.Push(u8"three", 0, 0); // drops "one"
    CHECK(stack.UndoCount() == 2u);

    UndoEntry out;
    stack.Undo(UndoEntry{core::String(u8"cur"), 0, 0}, out);
    CHECK(out.Text == u8"three");
    UndoEntry again;
    stack.Undo(out, again);
    CHECK(again.Text == u8"two"); // "one" is gone
    CHECK(!stack.CanUndo());
}

TEST_CASE("undo-stack: Undo and Redo on empty stacks return false")
{
    UndoStack stack;
    UndoEntry out;
    CHECK(!stack.Undo(UndoEntry{core::String(u8"x"), 0, 0}, out));
    CHECK(!stack.Redo(UndoEntry{core::String(u8"x"), 0, 0}, out));

    stack.Push(u8"a", 0, 0);
    stack.Clear();
    CHECK(!stack.CanUndo());
    CHECK(!stack.CanRedo());
}
