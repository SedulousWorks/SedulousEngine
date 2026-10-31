using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The text a code editor edits: lines, positions, undo, search, markers and diagnostics.
///
/// A MODEL with no view in it at all, which is what makes it testable without a font, a context
/// or a frame. The editor view reads it and mutates it through one method.
///
/// Lines are stored SPLIT rather than as one buffer with newlines, because every operation here
/// is addressed by line and column: a gutter, a marker, a diagnostic, a cursor. The single
/// mutation stitches the affected lines and splices the result.
///
/// The line list is NEVER empty. One empty line is an empty document, so nothing has to special
/// case a buffer with no lines in it.
class CodeDocument
{
	/// Edits of the same kind merge while they arrive within this of one another.
	public const double UndoCoalesceSeconds = 1.0;
	/// Older entries fall off the bottom, so a long session cannot grow without bound.
	public const int MaxUndoEntries = 256;

	private enum CharClass : uint8
	{
		Space,
		Word,
		Punct
	}

	/// OWNED.
	private List<String> mLines = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mVersion = 0;

	/// Fires after any line mutation: the first line touched, how many were removed, how many
	/// were added. A wholesale reload reports minus one removed.
	public delegate void(int32, int32, int32) OnLinesChanged ~ delete _;

	public this()
	{
		mLines.Add(new String());
	}

	// ---- Content --------------------------------------------------------------------------------

	public int32 LineCount => (int32)mLines.Count;

	public StringView Line(int32 line) => mLines[line];

	/// In CODEPOINTS, not bytes.
	public int32 LineLength(int32 line) => Utf8Text.CharCount(Line(line));

	/// Monotonic, bumped on every mutation. Caches key off it rather than trying to work out
	/// what changed.
	public uint64 Version => mVersion;

	public void GetText(String outText)
	{
		for (int i = 0; i < mLines.Count; i++)
		{
			if (i > 0)
				outText.Append('\n');

			outText.Append(mLines[i]);
		}
	}

	/// Replaces the whole buffer.
	///
	/// A full reload is a NEW DOCUMENT as far as line anchors go, so undo, markers, diagnostics
	/// and the execution line all go with it. Keeping a breakpoint on line forty of a file that
	/// was just replaced would point at something unrelated.
	///
	/// Carriage returns are DROPPED rather than kept, so a file saved on another platform does
	/// not leave an invisible character at the end of every line.
	public void SetText(StringView text)
	{
		ClearAndDeleteItems!(mLines);

		var current = new String();
		for (int i = 0; i < text.Length; i++)
		{
			if (text[i] == '\n')
			{
				mLines.Add(current);
				current = new String();
			}
			else if (text[i] != '\r')
			{
				current.Append(text[i]);
			}
		}
		mLines.Add(current);

		ClearUndoHistory();
		ClearAnchors();
		BumpVersion();

		if (OnLinesChanged != null)
			OnLinesChanged(0, -1, LineCount);
	}

	public void GetTextInSpan(CodeSpan span, String outText)
	{
		let s = ClampSpan(span.Normalized);

		if (s.Begin.Line == s.End.Line)
		{
			AppendColumns(outText, s.Begin.Line, s.Begin.Column, s.End.Column);
			return;
		}

		AppendColumns(outText, s.Begin.Line, s.Begin.Column, LineLength(s.Begin.Line));
		for (int32 line = s.Begin.Line + 1; line < s.End.Line; line++)
		{
			outText.Append('\n');
			outText.Append(Line(line));
		}
		outText.Append('\n');
		AppendColumns(outText, s.End.Line, 0, s.End.Column);
	}

	// ---- Positions ------------------------------------------------------------------------------

	/// Pulls a position inside the document, which is what makes every caller's arithmetic safe
	/// without each of them checking.
	public CodePosition ClampPosition(CodePosition pos)
	{
		if (pos.Line < 0)
			return .(0, 0);

		if (pos.Line >= LineCount)
			return EndPosition;

		var clamped = pos;
		if (clamped.Column < 0)
			clamped.Column = 0;

		let length = LineLength(clamped.Line);
		if (clamped.Column > length)
			clamped.Column = length;

		return clamped;
	}

	public CodePosition EndPosition
	{
		get
		{
			let last = LineCount - 1;
			return .(last, LineLength(last));
		}
	}

	/// The byte a codepoint column starts at.
	public int ColumnToByte(int32 line, int32 column) =>
		Utf8Text.CharToByteOffset(Line(line), column);

	/// The codepoint column a byte offset falls in, rounding DOWN into the character that
	/// contains it rather than past it.
	public int32 ByteToColumn(int32 line, int byteOffset)
	{
		let text = Line(line);
		let limit = Math.Min(byteOffset, text.Length);
		var index = 0;
		var column = 0;

		while (index < limit)
		{
			let before = index;
			Utf8Text.DecodeAt(text, ref index);

			// A byte offset that lands INSIDE a character belongs to the character before it.
			if ((index > limit) && (before < limit))
				break;

			column++;
		}

		return (int32)column;
	}

	// ---- Word boundaries ------------------------------------------------------------------------

	/// Where a leftward word jump lands: over any spaces first, then over one run of the same
	/// class. Two classes, word and punctuation, so a jump stops between `foo` and `(`.
	public CodePosition PrevWordBoundary(CodePosition pos)
	{
		let start = ClampPosition(pos);

		if (start.Column == 0)
			return (start.Line == 0) ? start : .(start.Line - 1, LineLength(start.Line - 1));

		let text = Line(start.Line);
		var column = start.Column;

		while ((column > 0) && (CharClassAt(text, column - 1) == .Space))
			column--;

		if (column > 0)
		{
			let cls = CharClassAt(text, column - 1);
			while ((column > 0) && (CharClassAt(text, column - 1) == cls))
				column--;
		}

		return .(start.Line, column);
	}

	/// Where a rightward jump lands: over the current run, then over any spaces after it, so the
	/// cursor arrives at the start of the next word rather than the end of this one.
	public CodePosition NextWordBoundary(CodePosition pos)
	{
		let start = ClampPosition(pos);
		let length = LineLength(start.Line);

		if (start.Column >= length)
			return (start.Line >= LineCount - 1) ? start : .(start.Line + 1, 0);

		let text = Line(start.Line);
		var column = start.Column;
		let cls = CharClassAt(text, column);

		while ((column < length) && (CharClassAt(text, column) == cls))
			column++;

		while ((column < length) && (CharClassAt(text, column) == .Space))
			column++;

		return .(start.Line, column);
	}

	/// The identifier under a position, or immediately to its LEFT.
	///
	/// Looking left matters because a double click at the end of a word, or a completion asking
	/// what has been typed so far, both sit just past the last character.
	public CodeSpan WordAt(CodePosition pos)
	{
		let at = ClampPosition(pos);
		let text = Line(at.Line);
		let length = LineLength(at.Line);
		var probe = at.Column;

		if ((probe >= length) || (CharClassAt(text, probe) != .Word))
		{
			if ((probe == 0) || (CharClassAt(text, probe - 1) != .Word))
				return .(at, at);

			probe--;
		}

		var begin = probe;
		while ((begin > 0) && (CharClassAt(text, begin - 1) == .Word))
			begin--;

		var end = probe;
		while ((end < length) && (CharClassAt(text, end) == .Word))
			end++;

		return .(.(at.Line, begin), .(at.Line, end));
	}

	// ---- Internals ------------------------------------------------------------------------------

	/// Anything above the ASCII range counts as a WORD character, so a jump over an identifier
	/// with accented letters or CJK in it behaves the way it does over a plain one.
	private static CharClass Classify(uint32 codepoint)
	{
		// CAST at every comparison: a codepoint is a number here, and Beef will not compare one
		// against a character literal.
		if ((codepoint == (uint32)' ') || (codepoint == (uint32)'\t'))
			return .Space;

		let isWord = ((codepoint >= (uint32)'a') && (codepoint <= (uint32)'z'))
			|| ((codepoint >= (uint32)'A') && (codepoint <= (uint32)'Z'))
			|| ((codepoint >= (uint32)'0') && (codepoint <= (uint32)'9'))
			|| (codepoint == (uint32)'_') || (codepoint > 127);

		return isWord ? .Word : .Punct;
	}

	/// Past the end of a line reads as SPACE, which is what makes the boundary walks above stop
	/// there without a separate length check at every step.
	private CharClass CharClassAt(StringView text, int32 column)
	{
		var index = Utf8Text.CharToByteOffset(text, column);
		if (index >= text.Length)
			return .Space;

		return Classify(Utf8Text.DecodeAt(text, ref index));
	}

	private CodeSpan ClampSpan(CodeSpan span) => .(ClampPosition(span.Begin),
		ClampPosition(span.End));

	private void AppendColumns(String outText, int32 line, int32 fromColumn, int32 toColumn)
	{
		let text = Line(line);
		let fromByte = ColumnToByte(line, fromColumn);
		let toByte = ColumnToByte(line, toColumn);
		outText.Append(text.Substring(fromByte, toByte - fromByte));
	}

	/// One codepoint forward across a line boundary, clamping at the end of the document.
	private CodePosition NextOnDocument(CodePosition pos)
	{
		if (pos.Column < LineLength(pos.Line))
			return .(pos.Line, pos.Column + 1);

		return (pos.Line + 1 < LineCount) ? CodePosition(pos.Line + 1, 0) : pos;
	}

	private CodePosition PreviousOnDocument(CodePosition pos)
	{
		if (pos.Column > 0)
			return .(pos.Line, pos.Column - 1);

		return (pos.Line > 0) ? CodePosition(pos.Line - 1, LineLength(pos.Line - 1)) : pos;
	}

	private void BumpVersion()
	{
		mVersion++;
	}
}
