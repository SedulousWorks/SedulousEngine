using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

class FontLoadOptionsTests
{
	[Test]
	static void TestFontLoadOptionsDefault()
	{
		let options = FontLoadOptions.Default;

		Test.Assert(options.PixelHeight > 0);
		Test.Assert(options.FirstCodepoint >= 32); // At least space
		Test.Assert(options.LastCodepoint >= options.FirstCodepoint);
		Test.Assert(options.AtlasWidth > 0 && IsPowerOfTwo(options.AtlasWidth));
		Test.Assert(options.AtlasHeight > 0 && IsPowerOfTwo(options.AtlasHeight));
		Test.Assert(options.OversampleX >= 1);
		Test.Assert(options.OversampleY >= 1);
	}

	[Test]
	static void TestFontLoadOptionsExtendedLatin()
	{
		let options = FontLoadOptions.ExtendedLatin;

		Test.Assert(options.LastCodepoint >= 255); // Extended Latin
		Test.Assert(options.AtlasWidth >= 512); // Larger for more glyphs
	}

	[Test]
	static void TestFontLoadOptionsSmall()
	{
		let options = FontLoadOptions.Small;

		Test.Assert(options.PixelHeight == 16.0f);
		Test.Assert(options.AtlasWidth == 256);
		Test.Assert(options.AtlasHeight == 256);
	}

	[Test]
	static void TestFontLoadOptionsLarge()
	{
		let options = FontLoadOptions.Large;

		Test.Assert(options.PixelHeight == 64.0f);
		Test.Assert(options.AtlasWidth >= 1024);
	}

	[Test]
	static void TestFontLoadOptionsCharacterCount()
	{
		let options = FontLoadOptions.Default;

		// Default is 32-126 = 95 characters
		Test.Assert(options.CharacterCount == 95);
	}

	private static bool IsPowerOfTwo(uint32 value)
	{
		return value > 0 && (value & (value - 1)) == 0;
	}
}
