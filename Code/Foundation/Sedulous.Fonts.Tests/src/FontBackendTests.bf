using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// The backend seam: the registries that route a load to a format's parser and baker, and
/// the manager that caches the result.
class FontBackendTests
{
	[Test]
	public static void ParsersRegisterOnceAndRouteByExtension()
	{
		FontParserFactory.Shutdown();
		Test.Assert(!FontParserFactory.HasParsers);

		let parser = new FakeParser();
		FontParserFactory.RegisterParser(parser);
		FontParserFactory.RegisterParser(parser); // The same one again is ignored.
		FontParserFactory.RegisterParser(null);
		Test.Assert(FontParserFactory.ParserCount == 1, "registering twice would delete twice");

		Test.Assert(FontParserFactory.GetParserForExtension(".fake") == parser);
		Test.Assert(FontParserFactory.GetParserForExtension(".nope") == null);

		FontParserFactory.Shutdown();
		Test.Assert(FontParserFactory.ParserCount == 0);
	}

	[Test]
	public static void AnUnclaimedExtensionIsRefusedRatherThanGuessed()
	{
		FontParserFactory.Shutdown();
		FontParserFactory.RegisterParser(new FakeParser());

		let miss = FontParserFactory.ParseFromMemory(.(), ".nope", .Default());
		Test.Assert(miss case .Err(.UnsupportedFormat));

		let hit = FontParserFactory.ParseFromMemory(.(), ".fake", .Default());
		Test.Assert(hit case .Ok);
		let font = hit.Value;
		Test.Assert(font.HasGlyph((int32)'A'));
		delete font; // The caller owns what a parser returns.

		FontParserFactory.Shutdown();
	}

	/// The routing is by extension, and the path is what the extension comes from.
	[Test]
	public static void LoadingFromAPathTakesTheExtensionFromIt()
	{
		FontParserFactory.Shutdown();
		FontParserFactory.RegisterParser(new FakeParser());

		let hit = FontParserFactory.ParseFromFile("fonts/Something.fake", .Default());
		Test.Assert(hit case .Ok);
		delete hit.Value;

		let miss = FontParserFactory.ParseFromFile("fonts/Something.ttf", .Default());
		Test.Assert(miss case .Err(.UnsupportedFormat));

		// No extension at all is not the same as an unknown one, but it routes the same way.
		let bare = FontParserFactory.ParseFromFile("fonts/Something", .Default());
		Test.Assert(bare case .Err(.UnsupportedFormat));

		FontParserFactory.Shutdown();
	}

	[Test]
	public static void BakersDispatchByFontAndByExtension()
	{
		FontAtlasBakerFactory.Shutdown();
		FontAtlasBakerFactory.SetAtlasCache(null);
		let baker = new FakeBaker();
		FontAtlasBakerFactory.RegisterBaker(baker);
		FontAtlasBakerFactory.RegisterBaker(baker);
		Test.Assert(FontAtlasBakerFactory.BakerCount == 1);

		let font = scope StubFont();
		Test.Assert(FontAtlasBakerFactory.GetBakerForFont(font) == baker);

		let byFont = FontAtlasBakerFactory.Bake(font, .Default());
		Test.Assert(byFont case .Ok);
		delete byFont.Value;

		let byExtension = FontAtlasBakerFactory.BakeFromExtension(".fake", font, .Default());
		Test.Assert(byExtension case .Ok);
		delete byExtension.Value;

		let miss = FontAtlasBakerFactory.BakeFromExtension(".nope", font, .Default());
		Test.Assert(miss case .Err(.UnsupportedFormat));

		FontAtlasBakerFactory.Shutdown();
	}

	/// A hit skips the bake entirely; a miss bakes and offers the result back.
	[Test]
	public static void TheAtlasCacheIsConsultedAndFed()
	{
		FontAtlasBakerFactory.Shutdown();
		FontAtlasBakerFactory.RegisterBaker(new FakeBaker());

		let cache = scope CountingAtlasCache();
		FontAtlasBakerFactory.SetAtlasCache(cache);
		defer FontAtlasBakerFactory.SetAtlasCache(null);

		let font = scope StubFont();

		// A miss: the bake runs and the fresh atlas is offered for storage.
		let baked = FontAtlasBakerFactory.Bake(font, .Default());
		Test.Assert(baked case .Ok);
		Test.Assert(cache.LoadAttempts == 1);
		Test.Assert(cache.Stores == 1);
		delete baked.Value;

		// A hit: the cached atlas comes straight back and nothing is stored.
		let preloaded = new StubAtlas();
		cache.Preloaded = preloaded;
		let fromCache = FontAtlasBakerFactory.Bake(font, .Default());
		Test.Assert(fromCache case .Ok);
		Test.Assert(fromCache.Value === preloaded);
		Test.Assert(cache.Stores == 1, "a hit stores nothing");
		delete fromCache.Value;

		FontAtlasBakerFactory.Shutdown();
	}

	/// A font nothing can bake is refused BEFORE the cache is asked, so a stale entry
	/// cannot answer for a format the process can no longer render.
	[Test]
	public static void AnUnbakeableFontIsRefusedWithoutAskingTheCache()
	{
		FontAtlasBakerFactory.Shutdown();

		let cache = scope CountingAtlasCache();
		FontAtlasBakerFactory.SetAtlasCache(cache);
		defer FontAtlasBakerFactory.SetAtlasCache(null);

		let font = scope StubFont();
		let refused = FontAtlasBakerFactory.Bake(font, .Default());
		Test.Assert(refused case .Err(.UnsupportedFormat));
		Test.Assert(cache.LoadAttempts == 0);
	}

	/// Unregistering hands ownership back, so Shutdown must not free what was taken out.
	[Test]
	public static void UnregisteringTakesOwnershipBack()
	{
		FontParserFactory.Shutdown();
		let parser = new FakeParser();
		FontParserFactory.RegisterParser(parser);
		FontParserFactory.UnregisterParser(parser);
		Test.Assert(FontParserFactory.ParserCount == 0);
		FontParserFactory.Shutdown();
		delete parser; // Ours again; a double free here would be caught.
	}

	[Test]
	public static void TheManagerCachesByPathAndSize()
	{
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();
		FontAtlasBakerFactory.SetAtlasCache(null);
		FontParserFactory.RegisterParser(new FakeParser());
		FontAtlasBakerFactory.RegisterBaker(new FakeBaker());
		defer
		{
			FontParserFactory.Shutdown();
			FontAtlasBakerFactory.Shutdown();
		}

		let manager = scope FontManager();
		Test.Assert(manager.CacheCount == 0);
		Test.Assert(!manager.IsCached("font.fake", 16));

		let first = manager.GetFont("font.fake", 16);
		Test.Assert(first != null);
		Test.Assert(manager.CacheCount == 1);
		Test.Assert(manager.IsCached("font.fake", 16));
		Test.Assert(first.RefCount == 1);
		Test.Assert(first.Font != null && first.Atlas != null);

		// The same key hands back the SAME instance, with another reference on it.
		let again = manager.GetFont("font.fake", 16);
		Test.Assert(again === first);
		Test.Assert(first.RefCount == 2);

		// A different size is a different bake and so a different entry.
		let larger = manager.GetFont("font.fake", 32);
		Test.Assert(larger !== first);
		Test.Assert(manager.CacheCount == 2);
	}

	/// Releasing does not free: the next frame will very likely want the font again.
	/// ClearUnused is what actually evicts, and only what nothing holds.
	[Test]
	public static void ReleasingKeepsTheFontUntilClearUnused()
	{
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();
		FontAtlasBakerFactory.SetAtlasCache(null);
		FontParserFactory.RegisterParser(new FakeParser());
		FontAtlasBakerFactory.RegisterBaker(new FakeBaker());
		defer
		{
			FontParserFactory.Shutdown();
			FontAtlasBakerFactory.Shutdown();
		}

		let manager = scope FontManager();
		let small = manager.GetFont("font.fake", 16);
		manager.GetFont("font.fake", 16); // A second reference on the same entry.
		manager.GetFont("font.fake", 32);

		manager.ReleaseFont(small);
		manager.ClearUnused();
		Test.Assert(manager.CacheCount == 2, "one reference still outstanding, so nothing goes");

		manager.ReleaseFont(small);
		manager.ClearUnused();
		Test.Assert(manager.CacheCount == 1, "only the 16px entry, which is now unreferenced");
		Test.Assert(!manager.IsCached("font.fake", 16));
		Test.Assert(manager.IsCached("font.fake", 32));

		manager.ClearAll();
		Test.Assert(manager.CacheCount == 0);
	}

	/// A load that cannot happen answers null rather than caching a broken entry, so the
	/// next attempt tries again instead of returning the same failure forever.
	[Test]
	public static void AFailedLoadCachesNothing()
	{
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();
		FontAtlasBakerFactory.SetAtlasCache(null);

		let manager = scope FontManager();

		// No parser registered at all.
		Test.Assert(manager.GetFont("font.fake", 16) == null);
		Test.Assert(manager.CacheCount == 0);

		// A parser but no baker: parsed, then nothing can bake it.
		FontParserFactory.RegisterParser(new FakeParser());
		Test.Assert(manager.GetFont("font.fake", 16) == null);
		Test.Assert(manager.CacheCount == 0);

		FontParserFactory.Shutdown();
	}
}
