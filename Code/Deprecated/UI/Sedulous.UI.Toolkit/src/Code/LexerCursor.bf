using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// A cursor over one line that tracks the codepoint COLUMN alongside the byte index, so a token
/// knows both without either being recomputed.
struct LexerCursor
{
	public StringView Text = default;
	public int Index = 0;
	public int32 Column = 0;

	public this(StringView text)
	{
		Text = text;
	}

	public bool AtEnd => Index >= Text.Length;

	public char8 Peek(int ahead = 0) =>
		((Index + ahead) < Text.Length) ? Text[Index + ahead] : (char8)0;

	public bool Match(StringView s)
	{
		if ((Index + s.Length) > Text.Length)
			return false;

		for (int k = 0; k < s.Length; k++)
		{
			if (Text[Index + k] != s[k])
				return false;
		}

		return true;
	}

	/// One CODEPOINT: past the lead byte, then over any continuation bytes, so the column counts
	/// characters while the index counts bytes.
	public void Advance() mut
	{
		if (AtEnd)
			return;

		Index++;
		while ((Index < Text.Length) && ((((uint8)Text[Index]) & 0xC0) == 0x80))
			Index++;

		Column++;
	}
}

/// The character tests and token scanners the concrete lexers share.
///
/// Anything above the ASCII range counts as an identifier character, so a name with accented
/// letters or CJK in it lexes as one word rather than fragmenting.
static class LexerScan
{
	public static bool IsDigit(char8 c) => (c >= '0') && (c <= '9');

	public static bool IsIdentStart(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || (c == '_') || ((uint8)c >= 0x80);

	public static bool IsIdentChar(char8 c) => IsIdentStart(c) || IsDigit(c);

	public static bool IsSpace(char8 c) => (c == ' ') || (c == '\t');

	public static bool IsPunctuationChar(char8 c) =>
		(c == '(') || (c == ')') || (c == '[') || (c == ']') || (c == '{') || (c == '}')
			|| (c == ',') || (c == ';') || (c == '.');

	/// An EMPTY run emits nothing, so a scanner that consumed no characters leaves no zero
	/// width token for the renderer to trip over.
	public static void Emit(List<CodeToken> outTokens, int byteBegin, int byteEnd, int32 column,
		CodeTokenKind kind)
	{
		if (byteEnd > byteBegin)
			outTokens.Add(.((uint32)byteBegin, (uint32)byteEnd, column, kind));
	}

	/// A quoted literal with backslash escapes. An UNTERMINATED one takes the rest of the line
	/// rather than carrying into the next, because a stray quote should not recolour the file.
	public static void ScanQuoted(ref LexerCursor cursor, List<CodeToken> outTokens, char8 quote)
	{
		let begin = cursor.Index;
		let column = cursor.Column;
		cursor.Advance();

		while (!cursor.AtEnd)
		{
			let c = cursor.Peek();
			if (c == '\\')
			{
				// The escape AND what it escapes, so an escaped quote does not end the string.
				cursor.Advance();
				cursor.Advance();
				continue;
			}

			cursor.Advance();
			if (c == quote)
				break;
		}

		Emit(outTokens, begin, cursor.Index, column, .String);
	}

	/// A loose number: integers, floats, hex, exponents and suffixes all at once.
	///
	/// Built for COLOURING, not validation. An editor that refused to colour a half typed number
	/// would flicker on every keystroke.
	public static void ScanNumber(ref LexerCursor cursor, List<CodeToken> outTokens)
	{
		let begin = cursor.Index;
		let column = cursor.Column;
		char8 previous = 0;

		while (!cursor.AtEnd)
		{
			let c = cursor.Peek();
			// A sign is part of the number only right after an exponent marker.
			let exponentSign = ((c == '+') || (c == '-')) && ((previous == 'e') || (previous == 'E'));

			if (!(IsIdentChar(c) || (c == '.') || exponentSign))
				break;

			previous = c;
			cursor.Advance();
		}

		Emit(outTokens, begin, cursor.Index, column, .Number);
	}

	/// An identifier run, classified against the owner's tables.
	public static void ScanWord(ref LexerCursor cursor, List<CodeToken> outTokens,
		Dictionary<String, bool> keywords, Dictionary<String, bool> types)
	{
		let begin = cursor.Index;
		let column = cursor.Column;

		while (!cursor.AtEnd && IsIdentChar(cursor.Peek()))
			cursor.Advance();

		let word = cursor.Text.Substring(begin, cursor.Index - begin);
		var kind = CodeTokenKind.Default;

		if (keywords.ContainsKeyAlt<StringView>(word))
			kind = .Keyword;
		else if (types.ContainsKeyAlt<StringView>(word))
			kind = .Type;

		Emit(outTokens, begin, cursor.Index, column, kind);
	}

	/// Owns copies of the words, because the caller's views may not outlive the lexer.
	public static void AdoptWords(Span<StringView> words, Dictionary<String, bool> into)
	{
		for (let word in words)
		{
			if (!into.ContainsKeyAlt<StringView>(word))
				into[new String(word)] = true;
		}
	}
}
