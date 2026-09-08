using System;
using Sedulous.Core;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// Parsing colour strings.
class SVGColorParserTests
{
	private static bool Near(float a, float b, float epsilon = 0.005f) => Abs(a - b) <= epsilon;

	private static void Expect(StringView text, Color expected)
	{
		Test.Assert(SVGColorParser.Parse(text) case .Ok(let parsed), scope $"'{text}' did not parse");
		Test.Assert(Near(parsed.R, expected.R) && Near(parsed.G, expected.G)
			&& Near(parsed.B, expected.B) && Near(parsed.A, expected.A),
			scope $"'{text}' gave {parsed.R}, {parsed.G}, {parsed.B}, {parsed.A}");
	}

	[Test]
	public static void SixDigitHexParses()
	{
		Expect("#ff0000", .(1, 0, 0, 1));
		Expect("#00FF00", .(0, 1, 0, 1));
		Expect("#000000", .(0, 0, 0, 1));
		Expect("#ffffff", .(1, 1, 1, 1));
	}

	/// The short form DOUBLES each nibble, so f becomes ff rather than f0. Without that,
	/// "#fff" would be a light grey rather than white.
	[Test]
	public static void ThreeDigitHexDoublesItsNibbles()
	{
		Expect("#fff", .(1, 1, 1, 1));
		Expect("#f00", .(1, 0, 0, 1));
		Expect("#abc", .(0xAA / 255.0f, 0xBB / 255.0f, 0xCC / 255.0f, 1));
	}

	[Test]
	public static void EightDigitHexCarriesAlpha()
	{
		Expect("#ff000080", .(1, 0, 0, 128 / 255.0f));
		Expect("#00000000", .(0, 0, 0, 0));
	}

	[Test]
	public static void TheFunctionalFormParses()
	{
		Expect("rgb(255, 0, 0)", .(1, 0, 0, 1));
		Expect("rgb(0,128,255)", .(0, 128 / 255.0f, 1, 1));
		Expect("rgb( 255 , 255 , 255 )", .(1, 1, 1, 1));
	}

	[Test]
	public static void NamedColoursParseWhateverTheirCase()
	{
		Expect("red", .(1, 0, 0, 1));
		Expect("RED", .(1, 0, 0, 1));
		Expect("Red", .(1, 0, 0, 1));
	}

	/// The keyword green is the DARK one; lime is full green. Reading the keyword as the
	/// obvious colour is a classic import bug.
	[Test]
	public static void GreenIsDarkAndLimeIsBright()
	{
		Expect("green", .(0, 128 / 255.0f, 0, 1));
		Expect("lime", .(0, 1, 0, 1));
	}

	/// Both spellings of the aliased names parse to the same colour.
	[Test]
	public static void TheAliasesAgree()
	{
		for (let pair in scope (StringView, StringView)[](
			("cyan", "aqua"), ("magenta", "fuchsia"), ("gray", "grey")))
		{
			Test.Assert(SVGColorParser.Parse(pair.0) case .Ok(let first));
			Test.Assert(SVGColorParser.Parse(pair.1) case .Ok(let second));
			Test.Assert(first == second, scope $"'{pair.0}' and '{pair.1}' differ");
		}
	}

	/// Both parse to a fully transparent colour, so a caller that asked for no fill gets
	/// something that draws nothing rather than a parse failure.
	[Test]
	public static void NoneAndTransparentAreClear()
	{
		Expect("none", .(0, 0, 0, 0));
		Expect("transparent", .(0, 0, 0, 0));
	}

	[Test]
	public static void SurroundingSpaceIsIgnored()
	{
		Expect("  #ff0000  ", .(1, 0, 0, 1));
		Expect("\tred\t", .(1, 0, 0, 1));
	}

	/// Anything unrecognised FAILS rather than defaulting, so an importer can report it
	/// instead of silently drawing black.
	[Test]
	public static void UnrecognisedColoursFail()
	{
		for (let text in scope StringView[](
			"", "   ", "#", "#ff", "#fffff", "#gggggg", "rgb(", "rgb(1,2)", "notacolour",
			"hsl(0, 100%, 50%)"))
		{
			Test.Assert(SVGColorParser.Parse(text) case .Err, scope $"'{text}' should not parse");
		}
	}
}
