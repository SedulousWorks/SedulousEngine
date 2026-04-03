using System;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class TrueTypeFontLoaderTests
{
	[Test]
	static void TestTrueTypeFontLoaderSupportsExtension()
	{
		let loader = scope TrueTypeFontLoader();

		Test.Assert(loader.SupportsExtension(".ttf"));
		Test.Assert(loader.SupportsExtension(".TTF"));
		Test.Assert(loader.SupportsExtension(".ttc"));
		Test.Assert(loader.SupportsExtension(".otf"));
		Test.Assert(!loader.SupportsExtension(".woff"));
		Test.Assert(!loader.SupportsExtension(".png"));
		Test.Assert(!loader.SupportsExtension(".txt"));
	}

	[Test]
	static void TestTrueTypeFontsInitializeShutdown()
	{
		// Test that we can initialize and shutdown without errors
		Test.Assert(!TrueTypeFonts.IsInitialized);

		TrueTypeFonts.Initialize();
		Test.Assert(TrueTypeFonts.IsInitialized);
		Test.Assert(FontLoaderFactory.HasLoaders);

		TrueTypeFonts.Shutdown();
		Test.Assert(!TrueTypeFonts.IsInitialized);
	}

	[Test]
	static void TestFontLoaderFactoryNoLoaders()
	{
		// Ensure factory returns error when no loaders registered
		// First make sure we're in a clean state
		FontLoaderFactory.Shutdown();

		let result = FontLoaderFactory.LoadFont("nonexistent.ttf", .Default);
		Test.Assert(result case .Err(.UnsupportedFormat));
	}
}
