using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// The lexer for the Lua shaped languages.
///
/// What the C shaped scanner cannot express is the LONG BRACKET: an opener of a bracket, any
/// number of equals signs, and a bracket again, closed only by the same count. That count is
/// carried across lines in the state's upper bits, exactly as a comment depth is.
class LuaLikeLexer : ICodeLexer
{
	private const uint32 ModeLongString = 1;
	private const uint32 ModeLongComment = 2;

	/// OWNED copies.
	private Dictionary<String, bool> mKeywords = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, bool> mTypes = new .() ~ DeleteDictionaryAndKeys!(_);

	public this(LuaLikeLexerSpec spec)
	{
		LexerScan.AdoptWords(spec.Keywords, mKeywords);
		LexerScan.AdoptWords(spec.Types, mTypes);
	}

	public StringView LineCommentPrefix => "--";

	public uint32 LexLine(StringView line, uint32 entryState, List<CodeToken> outTokens)
	{
		var cursor = LexerCursor(line);

		let mode = entryState & 0xFF;
		if ((mode == ModeLongString) || (mode == ModeLongComment))
		{
			let kind = (mode == ModeLongString) ? CodeTokenKind.String : CodeTokenKind.Comment;
			let carried = ScanLongBracket(ref cursor, outTokens, entryState >> 8, kind, mode, 0, 0);
			if (carried != 0)
				return carried;
		}

		return LexBody(ref cursor, line, outTokens);
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

			if ((c == '-') && (cursor.Peek(1) == '-'))
			{
				if (LexComment(ref cursor, line, outTokens, let carried))
					return carried;

				continue;
			}

			// An opening long bracket starts a long string; anything else beginning with one is
			// ordinary punctuation, so this falls through rather than consuming it.
			if (c == '[')
			{
				if (TryLexLongString(ref cursor, outTokens, let carried))
				{
					if (carried != 0)
						return carried;

					continue;
				}
			}

			// Three quoting characters, the backtick being the interpolated form, all coloured
			// whole and all single line.
			if ((c == '"') || (c == '\'') || (c == '`'))
			{
				LexerScan.ScanQuoted(ref cursor, outTokens, c);
				continue;
			}

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

			let begin = cursor.Index;
			let column = cursor.Column;
			cursor.Advance();
			LexerScan.Emit(outTokens, begin, cursor.Index, column,
				LexerScan.IsPunctuationChar(c) ? CodeTokenKind.Punctuation : CodeTokenKind.Operator);
		}

		return 0;
	}

	/// Two dashes begin either a line comment or, when a long bracket follows, a long one. True
	/// when the line is FINISHED, which a line comment always is.
	private bool LexComment(ref LexerCursor cursor, StringView line, List<CodeToken> outTokens,
		out uint32 carried)
	{
		carried = 0;
		let begin = cursor.Index;
		let column = cursor.Column;
		cursor.Advance();
		cursor.Advance();

		let level = LongBracketLevel(cursor, '[');
		if (level >= 0)
		{
			ConsumeLongBracket(ref cursor, (uint32)level);
			carried = ScanLongBracket(ref cursor, outTokens, (uint32)level, .Comment,
				ModeLongComment, begin, column);
			return carried != 0;
		}

		LexerScan.Emit(outTokens, begin, line.Length, column, .Comment);
		carried = 0;
		return true;
	}

	private bool TryLexLongString(ref LexerCursor cursor, List<CodeToken> outTokens,
		out uint32 carried)
	{
		carried = 0;
		let level = LongBracketLevel(cursor, '[');
		if (level < 0)
			return false;

		let begin = cursor.Index;
		let column = cursor.Column;
		ConsumeLongBracket(ref cursor, (uint32)level);
		carried = ScanLongBracket(ref cursor, outTokens, (uint32)level, .String, ModeLongString,
			begin, column);
		return true;
	}

	/// The LEVEL of a long bracket at the cursor, which is how many equals signs sit between
	/// its two brackets, or minus one when this is not one. Does NOT advance.
	private static int32 LongBracketLevel(LexerCursor cursor, char8 bracket)
	{
		if (cursor.Peek() != bracket)
			return -1;

		var level = 0;
		while (cursor.Peek(1 + level) == '=')
			level++;

		return (cursor.Peek(1 + level) == bracket) ? (int32)level : -1;
	}

	/// The bracket, its equals signs, and the closing bracket.
	private static void ConsumeLongBracket(ref LexerCursor cursor, uint32 level)
	{
		for (uint32 n = 0; n < level + 2; n++)
			cursor.Advance();
	}

	/// Scans to the matching close of a long bracket at this LEVEL. A close at a different level
	/// does not end it, which is the whole point of the notation.
	private static uint32 ScanLongBracket(ref LexerCursor cursor, List<CodeToken> outTokens,
		uint32 level, CodeTokenKind kind, uint32 mode, int tokenBegin, int32 tokenColumn)
	{
		while (!cursor.AtEnd)
		{
			if ((cursor.Peek() == ']') && (LongBracketLevel(cursor, ']') == (int32)level))
			{
				ConsumeLongBracket(ref cursor, level);
				LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, kind);
				return 0;
			}

			cursor.Advance();
		}

		LexerScan.Emit(outTokens, tokenBegin, cursor.Index, tokenColumn, kind);
		return mode | (level << 8);
	}
}
