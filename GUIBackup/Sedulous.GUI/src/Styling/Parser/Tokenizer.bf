namespace Sedulous.GUI;

using System;
using System.Collections;

/// Lexer for .sss stylesheet files.
public class Tokenizer
{
	private StringView mSource;
	private int mPos;
	private int mLine = 1;
	private int mCol = 1;

	public this(StringView source)
	{
		mSource = source;
	}

	public Token NextToken()
	{
		SkipWhitespaceAndComments();

		if (mPos >= mSource.Length)
			return Token(.EOF, "", mLine, mCol);

		let startLine = mLine;
		let startCol = mCol;
		let ch = mSource[mPos];

		// Single-character tokens
		switch (ch)
		{
		case '{': Advance(); return Token(.LBrace, "{", startLine, startCol);
		case '}': Advance(); return Token(.RBrace, "}", startLine, startCol);
		case '(': Advance(); return Token(.LParen, "(", startLine, startCol);
		case ')': Advance(); return Token(.RParen, ")", startLine, startCol);
		case ';': Advance(); return Token(.Semicolon, ";", startLine, startCol);
		case ',': Advance(); return Token(.Comma, ",", startLine, startCol);
		case '=': Advance(); return Token(.Equals, "=", startLine, startCol);
		case '%': Advance(); return Token(.Percent, "%", startLine, startCol);
		}

		// Hex color: #rrggbb or #rrggbbaa
		if (ch == '#')
			return ReadHexColor(startLine, startCol);

		// Variable: $name
		if (ch == '$')
			return ReadVariable(startLine, startCol);

		// Directive: @palette, @icon, @import, @font
		if (ch == '@')
			return ReadDirective(startLine, startCol);

		// Pseudo-state: :hover, :checked, etc.
		// But not standalone : (which is property separator)
		if (ch == ':')
		{
			if (mPos + 1 < mSource.Length && IsIdentStart(mSource[mPos + 1]))
				return ReadPseudoState(startLine, startCol);
			Advance();
			return Token(.Colon, ":", startLine, startCol);
		}

		// Class selector: .primary
		if (ch == '.')
		{
			if (mPos + 1 < mSource.Length && IsIdentStart(mSource[mPos + 1]))
				return ReadClassSelector(startLine, startCol);
			// Might be start of a number like .5
			if (mPos + 1 < mSource.Length && mSource[mPos + 1].IsDigit)
				return ReadNumber(startLine, startCol);
			Advance();
			return Token(.Error, ".", startLine, startCol);
		}

		// String literal: "..."
		if (ch == '"')
			return ReadString(startLine, startCol);

		// Number: starts with digit or negative sign
		if (ch.IsDigit || (ch == '-' && mPos + 1 < mSource.Length && (mSource[mPos + 1].IsDigit || mSource[mPos + 1] == '.')))
			return ReadNumber(startLine, startCol);

		// Identifier or keyword
		if (IsIdentStart(ch))
			return ReadIdent(startLine, startCol);

		// Unknown
		Advance();
		return Token(.Error, mSource.Substring(mPos - 1, 1), startLine, startCol);
	}

	/// Tokenize the entire source into a list.
	public void TokenizeAll(List<Token> tokens)
	{
		while (true)
		{
			let tok = NextToken();
			tokens.Add(tok);
			if (tok.Kind == .EOF) break;
		}
	}

	// === Readers ===

	private Token ReadHexColor(int line, int col)
	{
		let start = mPos;
		Advance(); // skip #
		while (mPos < mSource.Length && IsHexDigit(mSource[mPos]))
			Advance();
		let text = mSource.Substring(start, mPos - start);
		return Token(.HexColor, text, line, col);
	}

	private Token ReadVariable(int line, int col)
	{
		let start = mPos;
		Advance(); // skip $
		while (mPos < mSource.Length && IsIdentChar(mSource[mPos]))
			Advance();
		let text = mSource.Substring(start, mPos - start);
		return Token(.Variable, text, line, col);
	}

	private Token ReadDirective(int line, int col)
	{
		let start = mPos;
		Advance(); // skip @
		while (mPos < mSource.Length && IsIdentChar(mSource[mPos]))
			Advance();
		let text = mSource.Substring(start, mPos - start);
		return Token(.Directive, text, line, col);
	}

	private Token ReadPseudoState(int line, int col)
	{
		let start = mPos;
		Advance(); // skip :
		while (mPos < mSource.Length && IsIdentChar(mSource[mPos]))
			Advance();
		let text = mSource.Substring(start, mPos - start);
		return Token(.PseudoState, text, line, col);
	}

	private Token ReadClassSelector(int line, int col)
	{
		let start = mPos;
		Advance(); // skip .
		while (mPos < mSource.Length && (IsIdentChar(mSource[mPos]) || mSource[mPos] == '-'))
			Advance();
		let text = mSource.Substring(start, mPos - start);
		return Token(.ClassSelector, text, line, col);
	}

	private Token ReadString(int line, int col)
	{
		Advance(); // skip opening "
		let start = mPos;
		while (mPos < mSource.Length && mSource[mPos] != '"')
		{
			if (mSource[mPos] == '\n') { mLine++; mCol = 0; }
			Advance();
		}
		let text = mSource.Substring(start, mPos - start);
		if (mPos < mSource.Length) Advance(); // skip closing "
		return Token(.StringLit, text, line, col);
	}

	private Token ReadNumber(int line, int col)
	{
		let start = mPos;
		if (mPos < mSource.Length && mSource[mPos] == '-') Advance();
		while (mPos < mSource.Length && mSource[mPos].IsDigit) Advance();
		if (mPos < mSource.Length && mSource[mPos] == '.')
		{
			Advance();
			while (mPos < mSource.Length && mSource[mPos].IsDigit) Advance();
		}

		let numText = mSource.Substring(start, mPos - start);

		// Check for unit suffix (px, dp, pt)
		let unitStart = mPos;
		while (mPos < mSource.Length && mSource[mPos].IsLetter)
			Advance();
		let unitText = mSource.Substring(unitStart, mPos - unitStart);
		let fullText = mSource.Substring(start, mPos - start);

		var tok = Token(.Number, fullText, line, col);
		if (float.Parse(numText) case .Ok(let val))
			tok.NumericValue = val;
		tok.UnitSuffix = unitText;
		return tok;
	}

	private Token ReadIdent(int line, int col)
	{
		let start = mPos;
		while (mPos < mSource.Length && (IsIdentChar(mSource[mPos]) || mSource[mPos] == '-'))
			Advance();
		let text = mSource.Substring(start, mPos - start);

		// Keywords
		if (text == "true") return Token(.BoolLit, text, line, col);
		if (text == "false") return Token(.BoolLit, text, line, col);
		if (text == "extends") return Token(.Extends, text, line, col);

		return Token(.Ident, text, line, col);
	}

	// === Helpers ===

	private void SkipWhitespaceAndComments()
	{
		while (mPos < mSource.Length)
		{
			let ch = mSource[mPos];

			if (ch == ' ' || ch == '\t' || ch == '\r')
			{
				Advance();
				continue;
			}

			if (ch == '\n')
			{
				mPos++;
				mLine++;
				mCol = 1;
				continue;
			}

			// Block comment /* ... */
			if (ch == '/' && mPos + 1 < mSource.Length && mSource[mPos + 1] == '*')
			{
				mPos += 2; mCol += 2;
				while (mPos + 1 < mSource.Length)
				{
					if (mSource[mPos] == '\n') { mLine++; mCol = 0; }
					if (mSource[mPos] == '*' && mSource[mPos + 1] == '/')
					{
						mPos += 2; mCol += 2;
						break;
					}
					mPos++; mCol++;
				}
				continue;
			}

			break;
		}
	}

	private void Advance()
	{
		mPos++;
		mCol++;
	}

	private static bool IsIdentStart(char8 ch) => ch.IsLetter || ch == '_';
	private static bool IsIdentChar(char8 ch) => ch.IsLetterOrDigit || ch == '_';
	private static bool IsHexDigit(char8 ch) => ch.IsDigit || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F');
}
