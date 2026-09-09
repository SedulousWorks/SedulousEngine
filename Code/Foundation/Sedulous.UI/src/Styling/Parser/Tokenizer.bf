using System;
using System.Collections;

namespace Sedulous.UI;

/// The lexer for style sheet files.
///
/// Every token's Text is a VIEW into the source, so the source must outlive the tokens.
class Tokenizer
{
	private StringView mSource;
	private int32 mPos = 0;
	private int32 mLine = 1;
	private int32 mCol = 1;

	public this(StringView source)
	{
		mSource = source;
	}

	// Deliberately ASCII rather than Beef's char8 classifiers: those answer for bytes at or
	// above 0x80 too, and in a UTF-8 source those bytes are continuations of a character, not
	// letters. A lexer is the last place to want that difference.
	private static bool IsDigitC(char8 c) => (c >= '0') && (c <= '9');
	private static bool IsLetterC(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'));
	private static bool IsLetterOrDigitC(char8 c) => IsLetterC(c) || IsDigitC(c);
	private static bool IsIdentStartC(char8 c) => IsLetterC(c) || (c == '_');
	private static bool IsIdentCharC(char8 c) => IsLetterOrDigitC(c) || (c == '_');

	private int32 Length => (int32)mSource.Length;
	private char8 At(int32 index) => mSource[index];

	public Token NextToken()
	{
		SkipWhitespaceAndComments();

		if (mPos >= Length)
			return .(.EndOfInput, "", mLine, mCol);

		let startLine = mLine;
		let startCol = mCol;
		let ch = At(mPos);

		switch (ch)
		{
		case '{': Advance(); return .(.LBrace, "{", startLine, startCol);
		case '}': Advance(); return .(.RBrace, "}", startLine, startCol);
		case '(': Advance(); return .(.LParen, "(", startLine, startCol);
		case ')': Advance(); return .(.RParen, ")", startLine, startCol);
		case ';': Advance(); return .(.Semicolon, ";", startLine, startCol);
		case ',': Advance(); return .(.Comma, ",", startLine, startCol);
		case '=': Advance(); return .(.Equals, "=", startLine, startCol);
		case '%': Advance(); return .(.Percent, "%", startLine, startCol);
		case '>': Advance(); return .(.Greater, ">", startLine, startCol);
		case '+': Advance(); return .(.Plus, "+", startLine, startCol);
		default:
		}

		// `#name` is a hex colour in a value and an id in a selector. The PARSER decides by
		// position; the token just carries the name.
		if (ch == '#')
			return ReadHexColor(startLine, startCol);

		// A custom property name, `--name`, which is never a number.
		if ((ch == '-') && (mPos + 1 < Length) && (At(mPos + 1) == '-'))
			return ReadIdent(startLine, startCol);

		if (ch == '$')
			return ReadVariable(startLine, startCol);

		if (ch == '@')
			return ReadDirective(startLine, startCol);

		if (ch == ':')
		{
			// A pseudo state only when a name follows; a bare colon separates a property from
			// its value.
			if ((mPos + 1 < Length) && IsIdentStartC(At(mPos + 1)))
				return ReadPseudoState(startLine, startCol);
			Advance();
			return .(.Colon, ":", startLine, startCol);
		}

		if (ch == '.')
		{
			if ((mPos + 1 < Length) && IsIdentStartC(At(mPos + 1)))
				return ReadClassSelector(startLine, startCol);
			// A leading dot may also start a number, as in `.5`.
			if ((mPos + 1 < Length) && IsDigitC(At(mPos + 1)))
				return ReadNumber(startLine, startCol);
			Advance();
			// Raptor answers a COLON here, carrying the dot as its text. Kept as is: a lone
			// dot is not valid anywhere in the grammar, so nothing reads the kind, and
			// changing it would be a silent divergence rather than a fix.
			return .(.Colon, ".", startLine, startCol);
		}

		if (ch == '"')
			return ReadString(startLine, startCol);

		if (IsDigitC(ch)
			|| ((ch == '-') && (mPos + 1 < Length)
				&& (IsDigitC(At(mPos + 1)) || (At(mPos + 1) == '.'))))
			return ReadNumber(startLine, startCol);

		if (IsIdentStartC(ch))
			return ReadIdent(startLine, startCol);

		// A standalone minus, the calc operator: the number and `--name` cases went above.
		if (ch == '-')
		{
			Advance();
			return .(.Minus, "-", startLine, startCol);
		}

		// Anything else is skipped.
		Advance();
		return .(.EndOfInput, "", startLine, startCol);
	}

	/// Tokenizes the whole source, ending with an EndOfInput token.
	public void TokenizeAll(List<Token> tokens)
	{
		for (;;)
		{
			let token = NextToken();
			tokens.Add(token);
			if (token.Kind == .EndOfInput)
				break;
		}
	}

	// ---- Readers -------------------------------------------------------------------------------

	/// Consumes identifier characters and dashes, from `start`, answering the slice.
	private StringView ReadNameBody(int32 start)
	{
		while ((mPos < Length) && (IsIdentCharC(At(mPos)) || (At(mPos) == '-')))
			Advance();
		return Slice(start, mPos);
	}

	private Token ReadHexColor(int32 line, int32 col)
	{
		let start = mPos;
		Advance();
		return .(.HexColor, ReadNameBody(start), line, col);
	}

	private Token ReadVariable(int32 line, int32 col)
	{
		let start = mPos;
		Advance();
		return .(.Variable, ReadNameBody(start), line, col);
	}

	private Token ReadDirective(int32 line, int32 col)
	{
		let start = mPos;
		Advance();
		// A directive takes no dashes, unlike the others.
		while ((mPos < Length) && IsIdentCharC(At(mPos)))
			Advance();
		return .(.Directive, Slice(start, mPos), line, col);
	}

	private Token ReadPseudoState(int32 line, int32 col)
	{
		let start = mPos;
		Advance();
		return .(.PseudoState, ReadNameBody(start), line, col);
	}

	private Token ReadClassSelector(int32 line, int32 col)
	{
		let start = mPos;
		Advance();
		return .(.ClassSelector, ReadNameBody(start), line, col);
	}

	private Token ReadString(int32 line, int32 col)
	{
		// Skip the opening quote.
		Advance();
		let start = mPos;
		while ((mPos < Length) && (At(mPos) != '"'))
		{
			if (At(mPos) == '\n')
			{
				mLine++;
				mCol = 0;
			}
			Advance();
		}

		let text = Slice(start, mPos);
		// An unterminated string simply ends at the end of input rather than failing.
		if (mPos < Length)
			Advance();
		return .(.StringLit, text, line, col);
	}

	private Token ReadNumber(int32 line, int32 col)
	{
		let start = mPos;
		if ((mPos < Length) && (At(mPos) == '-'))
			Advance();
		while ((mPos < Length) && IsDigitC(At(mPos)))
			Advance();

		if ((mPos < Length) && (At(mPos) == '.'))
		{
			Advance();
			while ((mPos < Length) && IsDigitC(At(mPos)))
				Advance();
		}

		let numberText = Slice(start, mPos);

		// A unit suffix: px, dp or pt.
		let unitStart = mPos;
		while ((mPos < Length) && IsLetterC(At(mPos)))
			Advance();
		let unitText = Slice(unitStart, mPos);

		Token token = .(.Number, Slice(start, mPos), line, col);
		token.NumericValue = ParseNumber(numberText);
		token.UnitSuffix = unitText;
		return token;
	}

	/// The scanner has already checked the shape, so anything that fails to parse is empty or
	/// a lone sign, and nought is the right answer.
	private static float ParseNumber(StringView text)
	{
		if (text.IsEmpty)
			return 0.0f;
		if (float.Parse(text) case .Ok(let value))
			return value;
		return 0.0f;
	}

	private Token ReadIdent(int32 line, int32 col)
	{
		let start = mPos;
		let text = ReadNameBody(start);

		if ((text == "true") || (text == "false"))
			return .(.BoolLit, text, line, col);
		if (text == "extends")
			return .(.Extends, text, line, col);

		return .(.Ident, text, line, col);
	}

	// ---- Helpers -------------------------------------------------------------------------------

	private void SkipWhitespaceAndComments()
	{
		while (mPos < Length)
		{
			let ch = At(mPos);

			if ((ch == ' ') || (ch == '\t') || (ch == '\r'))
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

			if ((ch == '/') && (mPos + 1 < Length) && (At(mPos + 1) == '*'))
			{
				mPos += 2;
				mCol += 2;
				while (mPos + 1 < Length)
				{
					if (At(mPos) == '\n')
					{
						mLine++;
						mCol = 0;
					}
					if ((At(mPos) == '*') && (At(mPos + 1) == '/'))
					{
						mPos += 2;
						mCol += 2;
						break;
					}
					mPos++;
					mCol++;
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

	/// The source between `start` and `end`, the end being exclusive.
	private StringView Slice(int32 start, int32 end) => mSource.Substring(start, end - start);
}
