using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The style sheet tokenizer: what each piece of syntax lexes to.
class TokenizerTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static Token First(StringView source)
	{
		let tokenizer = scope Tokenizer(source);
		return tokenizer.NextToken();
	}

	// ---- Identifiers and the sigil prefixed forms --------------------------------------------

	/// A hyphen is part of an identifier, not an operator, which is what lets `text-color` be
	/// one token rather than three.
	[Test]
	public static void AnIdentifierMayBeHyphenated()
	{
		let plain = First("Button");
		Test.Assert(plain.Kind == .Ident);
		Test.Assert(plain.Text == "Button");

		let hyphenated = First("text-color");
		Test.Assert(hyphenated.Kind == .Ident);
		Test.Assert(hyphenated.Text == "text-color");
	}

	/// The prefix decides the kind, and the TEXT keeps the prefix, so the parser reads the name
	/// off the same token rather than tracking what it just saw.
	[Test]
	public static void ThePrefixSigilsProduceTheirOwnKinds()
	{
		let variable = First("$surface-bright");
		Test.Assert(variable.Kind == .Variable);
		Test.Assert(variable.Text == "$surface-bright");

		let directive = First("@palette");
		Test.Assert(directive.Kind == .Directive);
		Test.Assert(directive.Text == "@palette");

		let pseudo = First(":hover");
		Test.Assert(pseudo.Kind == .PseudoState);
		Test.Assert(pseudo.Text == ":hover");

		let hyphenatedPseudo = First(":focus-within");
		Test.Assert(hyphenatedPseudo.Kind == .PseudoState);
		Test.Assert(hyphenatedPseudo.Text == ":focus-within");

		let styleClass = First(".primary");
		Test.Assert(styleClass.Kind == .ClassSelector);
		Test.Assert(styleClass.Text == ".primary");

		let hyphenatedClass = First(".label-dim");
		Test.Assert(hyphenatedClass.Kind == .ClassSelector);
		Test.Assert(hyphenatedClass.Text == ".label-dim");
	}

	[Test]
	public static void EveryDirectiveNameLexesAsADirective()
	{
		let tokenizer = scope Tokenizer("@palette @icon @image @import");

		Test.Assert(tokenizer.NextToken().Text == "@palette");
		Test.Assert(tokenizer.NextToken().Text == "@icon");
		Test.Assert(tokenizer.NextToken().Text == "@image");
		Test.Assert(tokenizer.NextToken().Text == "@import");
	}

	// ---- Literals ---------------------------------------------------------------------------

	/// Both CSS hex forms, with and without the alpha byte.
	[Test]
	public static void AHexColourLexesAtSixOrEightDigits()
	{
		let six = First("#4a8eff");
		Test.Assert(six.Kind == .HexColor);
		Test.Assert(six.Text == "#4a8eff");

		let eight = First("#4a8effcc");
		Test.Assert(eight.Kind == .HexColor);
		Test.Assert(eight.Text == "#4a8effcc");
	}

	[Test]
	public static void NumbersLexWithTheirValueAndOptionalUnit()
	{
		let integer = First("42");
		Test.Assert(integer.Kind == .Number);
		Test.Assert(integer.NumericValue == 42);

		let fraction = First("3.14");
		Test.Assert(fraction.Kind == .Number);
		Test.Assert(Near(fraction.NumericValue, 3.14f));

		let withUnit = First("16px");
		Test.Assert(withUnit.Kind == .Number);
		Test.Assert(withUnit.NumericValue == 16);
		Test.Assert(withUnit.UnitSuffix == "px");
	}

	/// A minus that STARTS a number belongs to the number, not to calc: otherwise every
	/// negative literal would arrive as an operator and a positive value.
	[Test]
	public static void ALeadingMinusBelongsToTheNumber()
	{
		let negative = First("-5");

		Test.Assert(negative.Kind == .Number);
		Test.Assert(negative.NumericValue == -5);
	}

	/// The quotes are stripped: the text is the CONTENT, so a path is usable as read.
	[Test]
	public static void AStringLiteralDropsItsQuotes()
	{
		let literal = First("\"icons/check.svg\"");

		Test.Assert(literal.Kind == .StringLit);
		Test.Assert(literal.Text == "icons/check.svg");
	}

	/// The keywords lex as their own kinds rather than as identifiers, so the parser cannot
	/// mistake a property named `true` for the literal.
	[Test]
	public static void TheKeywordsLexAsTheirOwnKinds()
	{
		let tokenizer = scope Tokenizer("true false");
		let yes = tokenizer.NextToken();
		Test.Assert((yes.Kind == .BoolLit) && (yes.Text == "true"));
		let no = tokenizer.NextToken();
		Test.Assert((no.Kind == .BoolLit) && (no.Text == "false"));

		Test.Assert(First("extends").Kind == .Extends);
	}

	// ---- Punctuation, comments and position --------------------------------------------------

	[Test]
	public static void EveryPunctuationMarkHasItsOwnKind()
	{
		let tokenizer = scope Tokenizer("{ } ( ) : ; , = %");

		Test.Assert(tokenizer.NextToken().Kind == .LBrace);
		Test.Assert(tokenizer.NextToken().Kind == .RBrace);
		Test.Assert(tokenizer.NextToken().Kind == .LParen);
		Test.Assert(tokenizer.NextToken().Kind == .RParen);
		Test.Assert(tokenizer.NextToken().Kind == .Colon);
		Test.Assert(tokenizer.NextToken().Kind == .Semicolon);
		Test.Assert(tokenizer.NextToken().Kind == .Comma);
		Test.Assert(tokenizer.NextToken().Kind == .Equals);
		Test.Assert(tokenizer.NextToken().Kind == .Percent);
	}

	[Test]
	public static void CommentsAreSkippedOverOnOneLineOrSeveral()
	{
		let single = First("/* comment */ Button");
		Test.Assert((single.Kind == .Ident) && (single.Text == "Button"));

		let multiple = First("/* line1\nline2 */ View");
		Test.Assert((multiple.Kind == .Ident) && (multiple.Text == "View"));
	}

	[Test]
	public static void EmptyInputIsEndOfInput()
	{
		Test.Assert(First("").Kind == .EndOfInput);
	}

	/// The line number is tracked for diagnostics, and a newline advances it.
	[Test]
	public static void TheLineNumberFollowsTheNewlines()
	{
		let tokenizer = scope Tokenizer("a\nb");

		Test.Assert(tokenizer.NextToken().Line == 1);
		Test.Assert(tokenizer.NextToken().Line == 2);
	}

	// ---- Whole selectors ---------------------------------------------------------------------

	/// A compound selector has NO separators: the sigils alone say where each part begins.
	[Test]
	public static void ACompoundSelectorSplitsOnItsSigils()
	{
		let tokenizer = scope Tokenizer("Button.primary:hover");
		let tokens = scope List<Token>();
		tokenizer.TokenizeAll(tokens);

		Test.Assert(tokens.Count >= 4, "ident, class, pseudo state and the end");
		Test.Assert((tokens[0].Kind == .Ident) && (tokens[0].Text == "Button"));
		Test.Assert((tokens[1].Kind == .ClassSelector) && (tokens[1].Text == ".primary"));
		Test.Assert((tokens[2].Kind == .PseudoState) && (tokens[2].Text == ":hover"));
	}

	[Test]
	public static void TwoPseudoStatesInARowStayTwoTokens()
	{
		let tokenizer = scope Tokenizer("CheckBox:checked:hover");
		let tokens = scope List<Token>();
		tokenizer.TokenizeAll(tokens);

		Test.Assert((tokens[0].Kind == .Ident) && (tokens[0].Text == "CheckBox"));
		Test.Assert((tokens[1].Kind == .PseudoState) && (tokens[1].Text == ":checked"));
		Test.Assert((tokens[2].Kind == .PseudoState) && (tokens[2].Text == ":hover"));
	}
}
