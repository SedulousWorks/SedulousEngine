using System;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class TrueTypeFontLoaderTests
{
	[Test]
	static void TestTrueTypeFontParserSupportsExtension()
	{
		let parser = scope TrueTypeFontParser();

		Test.Assert(parser.SupportsExtension(".ttf"));
		Test.Assert(parser.SupportsExtension(".TTF"));
		Test.Assert(parser.SupportsExtension(".ttc"));
		Test.Assert(parser.SupportsExtension(".otf"));
		Test.Assert(!parser.SupportsExtension(".woff"));
		Test.Assert(!parser.SupportsExtension(".png"));
		Test.Assert(!parser.SupportsExtension(".txt"));
	}

	[Test]
	static void TestTrueTypeFontAtlasBakerSupportsExtension()
	{
		let baker = scope TrueTypeFontAtlasBaker();

		Test.Assert(baker.SupportsExtension(".ttf"));
		Test.Assert(baker.SupportsExtension(".otf"));
		Test.Assert(!baker.SupportsExtension(".woff"));
	}

	[Test]
	static void TestTrueTypeFontsInitializeShutdown()
	{
		// Initialize / shutdown must wire up both factories.
		Test.Assert(!TrueTypeFonts.IsInitialized);

		TrueTypeFonts.Initialize();
		Test.Assert(TrueTypeFonts.IsInitialized);
		Test.Assert(FontParserFactory.HasParsers);
		Test.Assert(FontAtlasBakerFactory.HasBakers);

		TrueTypeFonts.Shutdown();
		Test.Assert(!TrueTypeFonts.IsInitialized);
	}

	[Test]
	static void TestFontParserFactoryNoParsers()
	{
		// Ensure parser factory returns error when no parsers registered.
		// First make sure we're in a clean state.
		FontParserFactory.Shutdown();

		let result = FontParserFactory.ParseFromFile("nonexistent.ttf", .Default);
		Test.Assert(result case .Err(.UnsupportedFormat));
	}
}
