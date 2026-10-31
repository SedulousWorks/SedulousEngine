using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// The lexer for the C-shaped languages, configured rather than subclassed.
///
/// Its STATE packs a mode in the low byte and a depth in the rest, which is what lets a nested
/// block comment carry how deep it is across a line boundary in one number.
class CLikeLexer : ICodeLexer
{
	private const uint32 ModeBlockComment = 1;
	private const uint32 ModeTripleString = 2;

	private bool mNestedBlockComments;
	private bool mTripleQuotedStrings;
	private bool mHashPreprocessorLines;
	private bool mCharLiterals;

	/// OWNED copies: the caller's views may not outlive the lexer.
	private Dictionary<String, bool> mKeywords = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, bool> mTypes = new .() ~ DeleteDictionaryAndKeys!(_);

	public this(CLikeLexerSpec spec)
	{
		mNestedBlockComments = spec.NestedBlockComments;
		mTripleQuotedStrings = spec.TripleQuotedStrings;
		mHashPreprocessorLines = spec.HashPreprocessorLines;
		mCharLiterals = spec.CharLiterals;

		LexerScan.AdoptWords(spec.Keywords, mKeywords);
		LexerScan.AdoptWords(spec.Types, mTypes);
	}

	public uint32 LexLine(StringView line, uint32 entryState, List<CodeToken> outTokens)
	{
		var cursor = LexerCursor(line);

		if (ResumeMultiLine(ref cursor, entryState, outTokens, let carried))
			return carried;

		if (mHashPreprocessorLines && TryLexPreprocessorLine(cursor, line, outTokens))
			return 0;

		return LexBody(ref cursor, line, outTokens);
	}

	/// Picks up whatever the previous line left open. True when the construct is STILL open at
	/// the end of this line, in which case its state is carried on.
	private bool ResumeMultiLine(ref LexerCursor cursor, uint32 entryState,
		List<CodeToken> outTokens, out uint32 carried)
	{
		carried = 0;
		let mode = entryState & 0xFF;

		if (mode == ModeBlockComment)
		{
			carried = ScanBlockComment(ref cursor, outTokens, entryState >> 8,
				mNestedBlockComments, 0, 0);
			return carried != 0;
		}

		if (mode == ModeTripleString)
		{
			carried = ScanTripleString(ref cursor, outTokens, 0, 0);
			return carried != 0;
		}

		return false;
	}

	/// A hash as the first VISIBLE character makes the whole line one token, which is what a
	/// preprocessor directive is: not something to lex piece by piece.
	private bool TryLexPreprocessorLine(LexerCursor cursor, StringView line,
		List<CodeToken> outTokens)
	{
		var probe = cursor;
		while (!probe.AtEnd && LexerScan.IsSpace(probe.Peek()))
			probe.Advance();

		if (probe.AtEnd || (probe.Peek() != '#'))
			return false;

		LexerScan.Emit(outTokens, probe.Index, line.Length, probe.Column, .Preprocessor);
		return true;
	}

	private uint32 LexBody(ref LexerCursor cursor, StringView line, List<CodeToken> outTokens)
	{
		while (!cursor.AtEnd)
		{
			let c = cursor.Peek();

			if (LexerScan.IsSpace(c))
			{
				cursor.Advance();
				continue;
			}

			if ((c == '/') && (cursor.Peek(1) == '/'))
			{
				// A line comment runs to the end and nothing after it matters.
				LexerScan.Emit(outTokens, cursor.Index, line.Length, cursor.Column, .Comment);
				return 0;
			}

			if ((c == '/') && (cursor.Peek(1) == '*'))
			{
				let begin = cursor.Index;
				let column = cursor.Column;
				cursor.Advance();
				cursor.Advance();

				let carried = ScanBlockComment(ref cursor, outTokens, 1, mNestedBlockComments,
					begin, column);
				if (carried != 0)
					return carried;

				continue;
			}

			if (c == '"')
			{
				if (mTripleQuotedStrings && cursor.Match("\"\"\""))
				{
					let begin = cursor.Index;
					let column = cursor.Column;
					cursor.Advance();
					cursor.Advance();
					cursor.Advance();

					let carried = ScanTripleString(ref cursor, outTokens, begin, column);
					if (carried != 0)
						return carried;

					continue;
				}

				LexerScan.ScanQuoted(ref cursor, outTokens, '"');
				continue;
			}

			if (mCharLiterals && (c == '\''))
			{
				LexerScan.ScanQuoted(ref cursor, outTokens, '\'');
				continue;
			}

			// A leading point followed by a digit is a number, not punctuation.
			if (LexerScan.IsDigit(c) || ((c == '.') && LexerScan.IsDigit(cursor.Peek(1))))
			{
				LexerScan.ScanNumber(ref cursor, outTokens);
				continue;
			}

			if (LexerScan.IsIdentStart(c))
			{
				LexerScan.ScanWord(ref cursor, outTokens, mKeywords, mTypes);
				continue;
			}

			EmitSingleGlyph(ref cursor, outTokens, c);
		}

		return 0;
	}

	private static void EmitSingleGlyph(ref LexerCursor cursor, List<CodeToken> outTokens, char8 c)
	{
		let begin = cursor.Index;
		let column = cursor.Column;
		cursor.Advance();
		LexerScan.Emit(outTokens, begin, cursor.Index, column,
			LexerScan.IsPunctuationChar(c) ? CodeTokenKind.Punctuation : CodeTokenKind.Operator);
	}

	/// Scans from INSIDE a block comment. Nought when it closed on this line, else the state to
	/// carry, with the remaining depth packed above the mode.
	private static uint32 ScanBlockComment(ref LexerCursor cursor, List<CodeToken> outTokens,
		uint32 depth, bool nested, int tokenBegin, int32 tokenColumn)
	{
		var remaining = depth;

		while (!cursor.AtEnd)
		{
			if (cursor.Match("*/"))
			{
				cursor.Advance();
				cursor.Advance();
				remaining--;

				if (remaining == 0)
				{
					LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, .Comment);
					return 0;
				}

				continue;
			}

			if (nested && cursor.Match("/*"))
			{
				cursor.Advance();
				cursor.Advance();
				remaining++;
				continue;
			}

			cursor.Advance();
		}

		LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, .Comment);
		return ModeBlockComment | (remaining << 8);
	}

	private static uint32 ScanTripleString(ref LexerCursor cursor, List<CodeToken> outTokens,
		int tokenBegin, int32 tokenColumn)
	{
		while (!cursor.AtEnd)
		{
			if (cursor.Match("\"\"\""))
			{
				cursor.Advance();
				cursor.Advance();
				cursor.Advance();
				LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, .String);
				return 0;
			}

			cursor.Advance();
		}

		LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, .String);
		return ModeTripleString;
	}
}
