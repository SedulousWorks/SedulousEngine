namespace Sedulous.UI;

/// What the style sheet tokenizer produced.
enum TokenKind
{
	EndOfInput,
	/// An identifier: Button, background, lighten.
	Ident,
	/// A string literal.
	StringLit,
	/// A numeric literal, with or without a unit: 13, 0.5, 8px, 12dp.
	Number,
	/// A hex colour, either #rrggbb or #rrggbbaa.
	HexColor,
	/// A palette variable reference, $name.
	Variable,
	/// A directive: @palette, @icon, @import, @image.
	Directive,
	/// A pseudo state: :hover, :checked.
	PseudoState,
	/// A class selector, .primary.
	ClassSelector,
	LBrace,
	RBrace,
	LParen,
	RParen,
	Colon,
	Semicolon,
	Comma,
	Equals,
	Percent,
	/// The child combinator.
	Greater,
	/// A calc operator.
	Plus,
	/// A calc operator. A minus that STARTS a number belongs to the number instead.
	Minus,
	/// The keyword true or false.
	BoolLit,
	/// The keyword extends.
	Extends
}
