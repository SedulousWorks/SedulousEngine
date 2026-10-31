using System;

namespace Sedulous.UI;

/// One token from a style sheet.
///
/// Text and UnitSuffix are VIEWS into the source being tokenized, which must outlive the
/// tokens: nothing here copies, because a sheet produces thousands of these.
struct Token
{
	public TokenKind Kind = .EndOfInput;
	public StringView Text = default;
	public int32 Line = 0;
	public int32 Column = 0;

	/// For a Number, the parsed value.
	public float NumericValue = 0.0f;
	/// For a Number, the unit written after it: px, dp, pt, or nothing.
	public StringView UnitSuffix = default;

	public this() {}

	public this(TokenKind kind, StringView text, int32 line, int32 column)
	{
		Kind = kind;
		Text = text;
		Line = line;
		Column = column;
	}
}
