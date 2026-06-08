namespace Sedulous.UI;

using System;

public enum TokenKind
{
	/// End of input
	EOF,
	/// Identifier (e.g., Button, background, lighten)
	Ident,
	/// String literal ("path/to/file")
	StringLit,
	/// Numeric literal (13, 0.5, 8px, 12dp)
	Number,
	/// Hex color (#rrggbb, #rrggbbaa)
	HexColor,
	/// Variable reference ($name)
	Variable,
	/// Directive (@palette, @icon, @import, @image)
	Directive,
	/// Pseudo-state (:hover, :checked)
	PseudoState,
	/// Class selector (.primary)
	ClassSelector,
	/// {
	LBrace,
	/// }
	RBrace,
	/// (
	LParen,
	/// )
	RParen,
	/// :
	Colon,
	/// ;
	Semicolon,
	/// ,
	Comma,
	/// =
	Equals,
	/// %
	Percent,
	/// Keyword: true/false
	BoolLit,
	/// Keyword: extends
	Extends,
}

public struct Token
{
	public TokenKind Kind;
	public StringView Text;
	public int Line;
	public int Column;

	/// For Number tokens: the parsed numeric value.
	public float NumericValue;

	/// For Number tokens: the unit suffix (px, dp, pt, or empty).
	public StringView UnitSuffix;

	public this(TokenKind kind, StringView text, int line, int col)
	{
		Kind = kind;
		Text = text;
		Line = line;
		Column = col;
		NumericValue = 0;
		UnitSuffix = default;
	}
}
