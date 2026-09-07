using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.TrueType.Tests;

/// The wiring: what this backend claims, and that bringing it up is enough for a .ttf to
/// load without anything naming this library.
///
/// The two factories are process global, so every case here EMPTIES them first and again
/// on the way out. That is what makes these independent of the order the runner picks, and
/// it is safe because no other test in this project touches the registries.
class TrueTypeLoaderTests
{
	/// TrueTypeFonts first, so its slots are dropped and a later Initialize really does
	/// register again; then the registries, to take out anything a case added by hand.
	private static void ClearRegistries()
	{
		TrueTypeFonts.Shutdown();
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();
	}

	[Test]
	public static void TheParserClaimsTheTrueTypeExtensions()
	{
		ClearRegistries();
		defer ClearRegistries();

		let parser = scope TrueTypeFontParser();
		Test.Assert(parser.SupportsExtension(".ttf"));
		Test.Assert(parser.SupportsExtension(".ttc"), "a TrueType collection");
		Test.Assert(parser.SupportsExtension(".otf"), "and OpenType, which stb also reads");

		// Case comes from the filesystem, not from us.
		Test.Assert(parser.SupportsExtension(".TTF"));
		Test.Assert(parser.SupportsExtension(".Otf"));

		Test.Assert(!parser.SupportsExtension(".png"));
		Test.Assert(!parser.SupportsExtension(".fnt"), "a bitmap font is another backend's");
		Test.Assert(!parser.SupportsExtension("ttf"), "the dot is part of it");
		Test.Assert(!parser.SupportsExtension(""));
	}

	[Test]
	public static void TheBakerClaimsTheSameExtensions()
	{
		ClearRegistries();
		defer ClearRegistries();

		let baker = scope TrueTypeFontAtlasBaker();
		Test.Assert(baker.SupportsExtension(".ttf"));
		Test.Assert(baker.SupportsExtension(".otf"));
		Test.Assert(baker.SupportsExtension(".TTC"));
		Test.Assert(!baker.SupportsExtension(".png"));
	}

	/// Initialize puts BOTH in place, and Shutdown takes both back out. A backend that
	/// registered only its parser would parse a font and then fail to bake it.
	[Test]
	public static void InitializeWiresBothFactoriesAndShutdownEmptiesThem()
	{
		ClearRegistries();
		defer ClearRegistries();

		Test.Assert(!FontParserFactory.HasParsers, "starting empty");
		Test.Assert(!FontAtlasBakerFactory.HasBakers);

		TrueTypeFonts.Initialize();

		Test.Assert(FontParserFactory.ParserCount == 1);
		Test.Assert(FontAtlasBakerFactory.BakerCount == 1);
		Test.Assert(FontParserFactory.GetParserForExtension(".ttf") != null);
		Test.Assert(FontAtlasBakerFactory.GetBakerForExtension(".ttf") != null);
		Test.Assert(FontParserFactory.GetParserForExtension(".png") == null,
			"and nothing it does not claim");

		TrueTypeFonts.Shutdown();

		Test.Assert(FontParserFactory.ParserCount == 0);
		Test.Assert(FontAtlasBakerFactory.BakerCount == 0);
	}

	/// Bringing the backend up twice leaves one of each, or a load would consult the same
	/// parser twice and Shutdown would free one of two instances it handed over.
	[Test]
	public static void InitializingTwiceStillLeavesOneOfEach()
	{
		ClearRegistries();
		defer ClearRegistries();

		TrueTypeFonts.Initialize();
		TrueTypeFonts.Initialize();
		TrueTypeFonts.Initialize();

		Test.Assert(FontParserFactory.ParserCount == 1);
		Test.Assert(FontAtlasBakerFactory.BakerCount == 1);
		Test.Assert(TrueTypeFonts.IsInitialized);

		TrueTypeFonts.Shutdown();
		Test.Assert(FontParserFactory.ParserCount == 0, "and both were freed");
		Test.Assert(FontAtlasBakerFactory.BakerCount == 0);
		Test.Assert(!TrueTypeFonts.IsInitialized);
	}

	/// Shutdown takes out THIS backend and leaves the rest of the process alone. A host
	/// running several font backends must not lose the others when one goes down.
	[Test]
	public static void ShutdownLeavesAnotherBackendRegistered()
	{
		ClearRegistries();
		defer ClearRegistries();

		let other = new StubParser();
		FontParserFactory.RegisterParser(other);
		TrueTypeFonts.Initialize();
		Test.Assert(FontParserFactory.ParserCount == 2);

		TrueTypeFonts.Shutdown();

		Test.Assert(FontParserFactory.ParserCount == 1, "the other backend is still there");
		Test.Assert(FontParserFactory.GetParserForExtension(".stub") === other);
		Test.Assert(FontParserFactory.GetParserForExtension(".ttf") == null, "and ours is gone");
	}

	/// Somebody emptying the registry wholesale deletes what we handed over. Our Shutdown
	/// must then drop the slot rather than free it a second time.
	[Test]
	public static void ShutdownAfterTheRegistryWasEmptiedDoesNotDoubleFree()
	{
		ClearRegistries();
		defer ClearRegistries();

		TrueTypeFonts.Initialize();
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();

		TrueTypeFonts.Shutdown();
		Test.Assert(!TrueTypeFonts.IsInitialized);

		// And the backend comes back up cleanly afterwards.
		TrueTypeFonts.Initialize();
		Test.Assert(FontParserFactory.ParserCount == 1);
	}

	/// Registering the SAME instance twice is what the registry does deduplicate, so a
	/// module brought up twice is not consulted twice and not deleted twice.
	[Test]
	public static void RegisteringOneInstanceTwiceIsIgnored()
	{
		ClearRegistries();
		defer ClearRegistries();

		let parser = new TrueTypeFontParser();
		FontParserFactory.RegisterParser(parser);
		FontParserFactory.RegisterParser(parser);
		Test.Assert(FontParserFactory.ParserCount == 1);

		FontParserFactory.RegisterParser(null);
		Test.Assert(FontParserFactory.ParserCount == 1, "null is not an entry");
	}

	/// A stand in for another backend, claiming an extension this one never will.
	private class StubParser : IFontParser
	{
		private static StringView[1] sExtensions = .(".stub");

		public override Span<StringView> SupportedExtensions => .(&sExtensions[0], 1);

		public override bool SupportsExtension(StringView fileExtension) => fileExtension == ".stub";

		public override Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options)
			=> .Err(.UnsupportedFormat);

		public override Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options)
			=> .Err(.UnsupportedFormat);

		public override Result<IFont, FontLoadResult> ParseFromStream(Sedulous.Core.IO.IStream stream,
			FontLoadOptions options) => .Err(.UnsupportedFormat);
	}

	/// With nothing registered a load is refused rather than crashing on an empty table.
	[Test]
	public static void WithNoParsersALoadIsRefused()
	{
		ClearRegistries();
		defer ClearRegistries();

		let options = FontLoadOptions.Default();

		Test.Assert(FontParserFactory.ParseFromFile("anything.ttf", options)
			case .Err(let fileError));
		Test.Assert(fileError == .UnsupportedFormat);

		uint8[4] bytes = .(0, 1, 0, 0);
		Test.Assert(FontParserFactory.ParseFromMemory(.(&bytes[0], 4), ".ttf", options)
			case .Err(let memoryError));
		Test.Assert(memoryError == .UnsupportedFormat);
	}

	/// A format nobody claims is refused even with the backend up, and the extension is what
	/// decides: the file is never opened.
	[Test]
	public static void AnUnclaimedExtensionIsRefusedWithTheBackendUp()
	{
		ClearRegistries();
		defer ClearRegistries();

		TrueTypeFonts.Initialize();

		Test.Assert(FontParserFactory.ParseFromFile("nonexistent.png", FontLoadOptions.Default())
			case .Err(let error));
		Test.Assert(error == .UnsupportedFormat, "not a file error: it never got that far");
	}

	/// The whole point of the seam: a real font loads through the factory, with the caller
	/// naming only a path.
	[Test]
	public static void ARealFontLoadsThroughTheFactoryAndBakesThroughIt()
	{
		ClearRegistries();
		defer ClearRegistries();

		let path = scope String();
		Test.Assert(TestFont.FindPath(path), "the Roboto fixture is present");

		TrueTypeFonts.Initialize();

		var options = FontLoadOptions.Default();
		options.PixelHeight = 24.0f;

		Test.Assert(FontParserFactory.ParseFromFile(path, options) case .Ok(let font));
		defer delete font;

		Test.Assert(font.BackendTypeId == TrueTypeCommon.BackendTypeId,
			"and it came from this backend");
		Test.Assert(font.Metrics.LineHeight > 0);

		// And the baker registered alongside it recognises what that parser produced.
		let baker = FontAtlasBakerFactory.GetBakerForFont(font, options);
		Test.Assert(baker != null);
		Test.Assert(baker.CanBake(font, options));

		Test.Assert(FontAtlasBakerFactory.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;
		Test.Assert(atlas.Width > 0);
	}
}
