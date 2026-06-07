namespace Sedulous.GUI.Tests;

using System;
using System.Collections;
using Sedulous.GUI;

class TokenizerTests
{
	[Test]
	public static void Ident()
	{
		let tok = scope Tokenizer("Button");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Ident);
		Test.Assert(t.Text == "Button");
	}

	[Test]
	public static void HexColor_6Digit()
	{
		let tok = scope Tokenizer("#4a8eff");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .HexColor);
		Test.Assert(t.Text == "#4a8eff");
	}

	[Test]
	public static void HexColor_8Digit()
	{
		let tok = scope Tokenizer("#4a8effcc");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .HexColor);
		Test.Assert(t.Text == "#4a8effcc");
	}

	[Test]
	public static void Variable()
	{
		let tok = scope Tokenizer("$surface");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Variable);
		Test.Assert(t.Text == "$surface");
	}

	[Test]
	public static void Directive()
	{
		let tok = scope Tokenizer("@palette");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Directive);
		Test.Assert(t.Text == "@palette");
	}

	[Test]
	public static void PseudoState()
	{
		let tok = scope Tokenizer(":hover");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .PseudoState);
		Test.Assert(t.Text == ":hover");
	}

	[Test]
	public static void ClassSelector()
	{
		let tok = scope Tokenizer(".primary");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .ClassSelector);
		Test.Assert(t.Text == ".primary");
	}

	[Test]
	public static void Number_Integer()
	{
		let tok = scope Tokenizer("42");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Number);
		Test.Assert(t.NumericValue == 42);
	}

	[Test]
	public static void Number_Float()
	{
		let tok = scope Tokenizer("3.14");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Number);
		Test.Assert(Math.Abs(t.NumericValue - 3.14f) < 0.01f);
	}

	[Test]
	public static void Number_WithUnit()
	{
		let tok = scope Tokenizer("16px");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Number);
		Test.Assert(t.NumericValue == 16);
		Test.Assert(t.UnitSuffix == "px");
	}

	[Test]
	public static void StringLiteral()
	{
		let tok = scope Tokenizer("\"icons/check.svg\"");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .StringLit);
		Test.Assert(t.Text == "icons/check.svg");
	}

	[Test]
	public static void BoolLiterals()
	{
		let tok = scope Tokenizer("true false");
		let t1 = tok.NextToken();
		Test.Assert(t1.Kind == .BoolLit);
		Test.Assert(t1.Text == "true");
		let t2 = tok.NextToken();
		Test.Assert(t2.Kind == .BoolLit);
		Test.Assert(t2.Text == "false");
	}

	[Test]
	public static void Extends()
	{
		let tok = scope Tokenizer("extends");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Extends);
	}

	[Test]
	public static void Punctuation()
	{
		let tok = scope Tokenizer("{ } ( ) : ; , = %");
		Test.Assert(tok.NextToken().Kind == .LBrace);
		Test.Assert(tok.NextToken().Kind == .RBrace);
		Test.Assert(tok.NextToken().Kind == .LParen);
		Test.Assert(tok.NextToken().Kind == .RParen);
		Test.Assert(tok.NextToken().Kind == .Colon);
		Test.Assert(tok.NextToken().Kind == .Semicolon);
		Test.Assert(tok.NextToken().Kind == .Comma);
		Test.Assert(tok.NextToken().Kind == .Equals);
		Test.Assert(tok.NextToken().Kind == .Percent);
	}

	[Test]
	public static void Comment_Skipped()
	{
		let tok = scope Tokenizer("/* comment */ Button");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Ident);
		Test.Assert(t.Text == "Button");
	}

	[Test]
	public static void EOF()
	{
		let tok = scope Tokenizer("");
		Test.Assert(tok.NextToken().Kind == .EOF);
	}

	[Test]
	public static void FullSelector_Tokenizes()
	{
		let tok = scope Tokenizer("Button.primary:hover");
		let tokens = scope List<Token>();
		tok.TokenizeAll(tokens);

		Test.Assert(tokens.Count >= 4); // Ident, ClassSelector, PseudoState, EOF
		Test.Assert(tokens[0].Kind == .Ident);
		Test.Assert(tokens[0].Text == "Button");
		Test.Assert(tokens[1].Kind == .ClassSelector);
		Test.Assert(tokens[1].Text == ".primary");
		Test.Assert(tokens[2].Kind == .PseudoState);
		Test.Assert(tokens[2].Text == ":hover");
	}

	[Test]
	public static void LineTracking()
	{
		let tok = scope Tokenizer("a\nb");
		let t1 = tok.NextToken();
		Test.Assert(t1.Line == 1);
		let t2 = tok.NextToken();
		Test.Assert(t2.Line == 2);
	}

	[Test]
	public static void NegativeNumber()
	{
		let tok = scope Tokenizer("-5");
		let t = tok.NextToken();
		Test.Assert(t.Kind == .Number);
		Test.Assert(t.NumericValue == -5);
	}
}
