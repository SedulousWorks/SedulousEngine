namespace Sedulous.UI.Tests;

using System;
using System.Collections;
using Sedulous.UI;

/// Mock clipboard for testing.
class MockClipboard : IClipboard
{
	public String StoredText = new .() ~ delete _;

	public Result<void> GetText(String outText)
	{
		outText.Set(StoredText);
		return .Ok;
	}

	public Result<void> SetText(StringView text)
	{
		StoredText.Set(text);
		return .Ok;
	}

	public bool HasText => !StoredText.IsEmpty;
}

/// Mock text edit host for testing TextEditingBehavior.
class MockTextEditHost : ITextEditHost
{
	public String TextBuffer = new .() ~ delete _;
	public int32 MaxLengthValue;
	public bool ReadOnly;
	public bool Multiline;
	public MockClipboard ClipboardInstance = new .() ~ delete _;
	public float Time;
	public int ModifiedCount;

	StringView ITextEditHost.Text => TextBuffer;
	int32 ITextEditHost.MaxLength => MaxLengthValue;
	bool ITextEditHost.IsReadOnly => ReadOnly;
	bool ITextEditHost.IsMultiline => Multiline;
	IClipboard ITextEditHost.Clipboard => ClipboardInstance;
	float ITextEditHost.CurrentTime => Time;

	int32 ITextEditHost.TextCharCount
	{
		get
		{
			int32 count = 0;
			for (let c in TextBuffer.DecodedChars)
				count++;
			return count;
		}
	}

	void ITextEditHost.ReplaceText(int32 charStart, int32 charLength, StringView replacement)
	{
		let byteStart = CharToByteOffset(TextBuffer, charStart);
		let byteEnd = CharToByteOffset(TextBuffer, charStart + charLength);
		TextBuffer.Remove(byteStart, byteEnd - byteStart);
		TextBuffer.Insert(byteStart, replacement);
	}

	void ITextEditHost.OnTextModified()
	{
		ModifiedCount++;
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		// Simple: assume 8px per char, 16px per line.
		if (Multiline)
			return HitTestMultiline(localX, localY);
		let charCount = ((ITextEditHost)this).TextCharCount;
		return Math.Clamp((int32)(localX / 8), 0, charCount);
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		// Same as HitTestPosition for mock (no padding/scroll difference).
		if (Multiline)
			return HitTestMultiline(glyphX, glyphY);
		let charCount = ((ITextEditHost)this).TextCharCount;
		return Math.Clamp((int32)(glyphX / 8), 0, charCount);
	}

	private int32 HitTestMultiline(float x, float y)
	{
		// Find which line was clicked (16px per line).
		int32 targetLine = Math.Max(0, (int32)(y / 16.0f));

		// Walk text to find the start of that line.
		int32 lineStart = 0;
		int32 currentLine = 0;
		int32 idx = 0;
		for (let c in TextBuffer.DecodedChars)
		{
			if (currentLine == targetLine)
			{
				lineStart = idx;
				break;
			}
			if (c == '\n') currentLine++;
			idx++;
		}
		if (currentLine < targetLine)
			lineStart = idx; // past last line

		// Find line length.
		int32 lineEnd = lineStart;
		int32 idx2 = 0;
		for (let c in TextBuffer.DecodedChars)
		{
			if (idx2 >= lineStart)
			{
				if (c == '\n') break;
				lineEnd = idx2 + 1;
			}
			idx2++;
		}
		if (idx2 == TextBuffer.Length)
			lineEnd = ((ITextEditHost)this).TextCharCount;

		// X position within the line.
		let lineCharIdx = Math.Clamp((int32)(x / 8), 0, lineEnd - lineStart);
		return lineStart + lineCharIdx;
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		return charIndex * 8.0f;
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex)
	{
		// Simple mock: count newlines before charIndex → line * 16.
		int32 line = 0;
		int32 idx = 0;
		for (let c in TextBuffer.DecodedChars)
		{
			if (idx >= charIndex) break;
			if (c == '\n') line++;
			idx++;
		}
		return line * 16.0f;
	}

	float ITextEditHost.LineHeight => 16.0f;

	private static int32 CharToByteOffset(StringView text, int32 charIndex)
	{
		int32 charCount = 0;
		int32 byteOffset = 0;
		for (let c in text.DecodedChars)
		{
			if (charCount >= charIndex) break;
			charCount++;
			byteOffset = (int32)@c.NextIndex;
		}
		if (charCount < charIndex)
			return (int32)text.Length;
		return byteOffset;
	}
}

class TextEditingTests
{
	// === Basic insertion ===

	[Test]
	public static void InsertCharacters()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('H');
		behavior.HandleTextInput('i');

		Test.Assert(StringView(host.TextBuffer) == "Hi");
		Test.Assert(behavior.CursorPosition == 2);
	}

	// === Backspace ===

	[Test]
	public static void Backspace_DeletesCharBefore()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("abc");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 3;
		behavior.AnchorPosition = 3;

		behavior.HandleKeyDown(.Backspace, .None);
		Test.Assert(StringView(host.TextBuffer) == "ab");
		Test.Assert(behavior.CursorPosition == 2);
	}

	// === Delete ===

	[Test]
	public static void Delete_DeletesCharAfter()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("abc");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 1;
		behavior.AnchorPosition = 1;

		behavior.HandleKeyDown(.Delete, .None);
		Test.Assert(StringView(host.TextBuffer) == "ac");
	}

	// === Selection with Shift+Arrow ===

	[Test]
	public static void ShiftRight_ExtendsSelection()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 0;
		behavior.AnchorPosition = 0;

		behavior.HandleKeyDown(.Right, .Shift);
		Test.Assert(behavior.CursorPosition == 1);
		Test.Assert(behavior.AnchorPosition == 0);
		Test.Assert(behavior.IsSelecting);
	}

	[Test]
	public static void Arrow_CollapsesSelection()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 3;
		behavior.AnchorPosition = 0;

		// Right arrow without Shift → collapse to end.
		behavior.HandleKeyDown(.Right, .None);
		Test.Assert(!behavior.IsSelecting);
		Test.Assert(behavior.CursorPosition == 3);
	}

	// === Select All ===

	[Test]
	public static void CtrlA_SelectsAll()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello world");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleKeyDown(.A, .Ctrl);
		Test.Assert(behavior.AnchorPosition == 0);
		Test.Assert(behavior.CursorPosition == 11);
	}

	// === Delete Selection ===

	[Test]
	public static void Backspace_DeletesSelection()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.AnchorPosition = 1;
		behavior.CursorPosition = 4;

		behavior.HandleKeyDown(.Backspace, .None);
		Test.Assert(StringView(host.TextBuffer) == "ho");
	}

	// === Word navigation ===

	[Test]
	public static void CtrlRight_MovesToNextWord()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello world");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 0;
		behavior.AnchorPosition = 0;

		behavior.HandleKeyDown(.Right, .Ctrl);
		// Should move past "hello" and the space.
		Test.Assert(behavior.CursorPosition > 0);
	}

	// === Home / End ===

	[Test]
	public static void Home_MovesToStart()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 3;
		behavior.AnchorPosition = 3;

		behavior.HandleKeyDown(.Home, .None);
		Test.Assert(behavior.CursorPosition == 0);
	}

	[Test]
	public static void End_MovesToEnd()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleKeyDown(.End, .None);
		Test.Assert(behavior.CursorPosition == 5);
	}

	// === ReadOnly ===

	[Test]
	public static void ReadOnly_BlocksInput()
	{
		let host = scope MockTextEditHost();
		host.ReadOnly = true;
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('a');
		Test.Assert(host.TextBuffer.IsEmpty);
	}

	// === MaxLength ===

	[Test]
	public static void MaxLength_EnforcesLimit()
	{
		let host = scope MockTextEditHost();
		host.MaxLengthValue = 3;
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('a');
		behavior.HandleTextInput('b');
		behavior.HandleTextInput('c');
		behavior.HandleTextInput('d'); // should be rejected

		Test.Assert(StringView(host.TextBuffer) == "abc");
	}

	// === InputFilter ===

	[Test]
	public static void InputFilter_RejectsNonDigits()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);
		behavior.Filter = InputFilter.Digits();

		behavior.HandleTextInput('1');
		behavior.HandleTextInput('a'); // rejected
		behavior.HandleTextInput('2');

		Test.Assert(StringView(host.TextBuffer) == "12");
	}

	[Test]
	public static void InputFilter_HexDigits()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);
		behavior.Filter = InputFilter.HexDigits();

		behavior.HandleTextInput('a');
		behavior.HandleTextInput('F');
		behavior.HandleTextInput('g'); // rejected
		behavior.HandleTextInput('3');

		Test.Assert(StringView(host.TextBuffer) == "aF3");
	}

	// === Clipboard ===

	[Test]
	public static void CtrlC_CopiesSelection()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.AnchorPosition = 0;
		behavior.CursorPosition = 5;

		behavior.HandleKeyDown(.C, .Ctrl);
		Test.Assert(StringView(host.ClipboardInstance.StoredText) == "hello");
	}

	[Test]
	public static void CtrlX_CutsSelection()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.AnchorPosition = 0;
		behavior.CursorPosition = 5;

		behavior.HandleKeyDown(.X, .Ctrl);
		Test.Assert(StringView(host.ClipboardInstance.StoredText) == "hello");
		Test.Assert(host.TextBuffer.IsEmpty);
	}

	[Test]
	public static void CtrlV_PastesText()
	{
		let host = scope MockTextEditHost();
		host.ClipboardInstance.StoredText.Set("world");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleKeyDown(.V, .Ctrl);
		Test.Assert(StringView(host.TextBuffer) == "world");
		Test.Assert(behavior.CursorPosition == 5);
	}

	[Test]
	public static void AllowClipboardCopy_False_BlocksCopy()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("secret");
		let behavior = scope TextEditingBehavior(host);
		behavior.AllowClipboardCopy = false;
		behavior.AnchorPosition = 0;
		behavior.CursorPosition = 6;

		behavior.HandleKeyDown(.C, .Ctrl);
		Test.Assert(host.ClipboardInstance.StoredText.IsEmpty);
	}

	// === Undo / Redo ===

	[Test]
	public static void Undo_RestoresText()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('a');
		// Force new undo entry by changing action type.
		host.Time = 2.0f;
		behavior.HandleTextInput('b');

		behavior.HandleKeyDown(.Z, .Ctrl);
		Test.Assert(StringView(host.TextBuffer) == "a");
	}

	[Test]
	public static void Redo_RestoresAfterUndo()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('a');
		host.Time = 2.0f;
		behavior.HandleTextInput('b');

		behavior.HandleKeyDown(.Z, .Ctrl); // undo → "a"
		behavior.HandleKeyDown(.Y, .Ctrl); // redo → "ab"
		Test.Assert(StringView(host.TextBuffer) == "ab");
	}

	// === Undo coalescing ===

	[Test]
	public static void UndoCoalescing_RapidTypingMerges()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		// Rapid typing (same timestamp) → single undo entry.
		behavior.HandleTextInput('a');
		behavior.HandleTextInput('b');
		behavior.HandleTextInput('c');

		Test.Assert(StringView(host.TextBuffer) == "abc");

		behavior.HandleKeyDown(.Z, .Ctrl); // undo → empty
		Test.Assert(host.TextBuffer.IsEmpty);
	}

	[Test]
	public static void UndoCoalescing_NavigationBreaksChain()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput('a');
		behavior.HandleTextInput('b');
		behavior.HandleKeyDown(.Left, .None); // navigation breaks merge
		behavior.HandleTextInput('c');

		// Two undo entries: "abc" and "ab"
		behavior.HandleKeyDown(.Z, .Ctrl); // undo → "ab" (removes 'c')
		Test.Assert(StringView(host.TextBuffer) == "ab");
	}

	// === Double-click word selection ===

	[Test]
	public static void DoubleClick_SelectsWord()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello world");
		let behavior = scope TextEditingBehavior(host);

		// Double-click on "hello" (hit test returns char 2).
		behavior.HandleMouseDown(16, 5, 2, .None);
		Test.Assert(behavior.IsSelecting);
		Test.Assert(behavior.SelectionStart == 0);
		Test.Assert(behavior.SelectionEnd == 5);
	}

	// === Triple-click select all ===

	[Test]
	public static void TripleClick_SelectsAll()
	{
		let host = scope MockTextEditHost();
		host.TextBuffer.Set("hello world");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleMouseDown(16, 5, 3, .None);
		Test.Assert(behavior.SelectionStart == 0);
		Test.Assert(behavior.SelectionEnd == 11);
	}

	// === Control char filter ===

	[Test]
	public static void ControlChars_Filtered()
	{
		let host = scope MockTextEditHost();
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleTextInput((char32)1); // SOH
		behavior.HandleTextInput((char32)10); // LF
		behavior.HandleTextInput('a');

		Test.Assert(StringView(host.TextBuffer) == "a");
	}

	// === Multiline ===

	[Test]
	public static void Multiline_EnterInsertsNewline()
	{
		let host = scope MockTextEditHost();
		host.Multiline = true;
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 5;
		behavior.AnchorPosition = 5;

		behavior.HandleKeyDown(.Return, .None);
		Test.Assert(StringView(host.TextBuffer) == "hello\n");
		Test.Assert(behavior.CursorPosition == 6);
	}

	[Test]
	public static void Multiline_EnterInMiddle()
	{
		let host = scope MockTextEditHost();
		host.Multiline = true;
		host.TextBuffer.Set("helloworld");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 5;
		behavior.AnchorPosition = 5;

		behavior.HandleKeyDown(.Return, .None);
		Test.Assert(StringView(host.TextBuffer) == "hello\nworld");
	}

	[Test]
	public static void SingleLine_EnterDoesNotInsert()
	{
		let host = scope MockTextEditHost();
		host.Multiline = false;
		host.TextBuffer.Set("hello");
		let behavior = scope TextEditingBehavior(host);
		behavior.CursorPosition = 5;
		behavior.AnchorPosition = 5;

		behavior.HandleKeyDown(.Return, .None);
		// Single-line: Enter is not handled by behavior (handled by EditText as submit).
		Test.Assert(StringView(host.TextBuffer) == "hello");
	}

	[Test]
	public static void Multiline_PastePreservesNewlines()
	{
		let host = scope MockTextEditHost();
		host.Multiline = true;
		host.ClipboardInstance.StoredText.Set("line1\nline2");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleKeyDown(.V, .Ctrl);
		Test.Assert(StringView(host.TextBuffer) == "line1\nline2");
	}

	[Test]
	public static void SingleLine_PasteStripsNewlines()
	{
		let host = scope MockTextEditHost();
		host.Multiline = false;
		host.ClipboardInstance.StoredText.Set("line1\nline2");
		let behavior = scope TextEditingBehavior(host);

		behavior.HandleKeyDown(.V, .Ctrl);
		Test.Assert(StringView(host.TextBuffer) == "line1 line2");
	}

	// === UndoStack ===

	[Test]
	public static void UndoStack_PushAndUndo()
	{
		let stack = scope UndoStack();

		stack.PushState("first", 0, 0);
		stack.PushState("second", 5, 5);

		let result = scope String();
		int32 cursor = 0, anchor = 0;
		Test.Assert(stack.Undo("current", 7, 7, result, out cursor, out anchor));
		Test.Assert(StringView(result) == "second");
	}

	[Test]
	public static void UndoStack_CapacityOverflow()
	{
		let stack = scope UndoStack();
		stack.MaxEntries = 3;

		stack.PushState("a", 0, 0);
		stack.PushState("b", 0, 0);
		stack.PushState("c", 0, 0);
		stack.PushState("d", 0, 0); // drops "a"

		Test.Assert(stack.UndoCount == 3);
	}

	[Test]
	public static void UndoStack_RedoAfterUndo()
	{
		let stack = scope UndoStack();
		stack.PushState("initial", 0, 0);

		let result = scope String();
		int32 cursor = 0, anchor = 0;
		stack.Undo("current", 5, 5, result, out cursor, out anchor);

		let redoResult = scope String();
		Test.Assert(stack.Redo("initial", 0, 0, redoResult, out cursor, out anchor));
		Test.Assert(StringView(redoResult) == "current");
	}

	// === InputFilter standalone ===

	[Test]
	public static void InputFilter_Digits_AcceptsRejects()
	{
		let filter = InputFilter.Digits();
		defer delete filter;
		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(!filter.Accept('a'));
		Test.Assert(!filter.Accept(' '));
	}

	[Test]
	public static void InputFilter_None_AcceptsAll()
	{
		let filter = scope InputFilter();
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('1'));
		Test.Assert(filter.Accept(' '));
	}
}
