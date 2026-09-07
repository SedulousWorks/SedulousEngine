using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Resource;
using Sedulous.Resource;

namespace Sedulous.Fonts.Resource.Tests;

/// Resolving (family, size) over bound products, which is what the UI actually asks of a
/// font: a name and a size, never a file.
class ResourceFontServiceTests
{
	private static int32 Cp(char8 c) => (int32)c;

	[Test]
	public static void TheServiceResolvesAFamilyAndASize()
	{
		let fixture = scope FontFixture("scratch_fontsvc");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		Test.Assert(proxy.Get != null);

		let service = scope ResourceFontService();
		service.AddFont(proxy.Get);

		let family = scope String();
		service.GetDefaultFontFamily(family);
		Test.Assert(family == "TestFamily", "the first font registered names the default");

		// Exact.
		let at12 = service.GetFont("TestFamily", 12.0f);
		Test.Assert(at12 != null);
		Test.Assert(at12.Font.PixelHeight == 12.0f);
		Test.Assert(at12.Shaper != null, "a shaper came with it");

		// Closest, through the default family, for a size nothing was baked at.
		let at100 = service.GetFont(100.0f);
		Test.Assert(at100 != null);
		Test.Assert(at100.Font.PixelHeight == 24.0f);

		// A family nobody registered falls back to the default rather than returning null,
		// so a missing font renders in something rather than not at all.
		Test.Assert(service.GetFont("NoSuchFamily", 12.0f) === at12);
	}

	[Test]
	public static void TheAtlasTextureResolvesBothWays()
	{
		let fixture = scope FontFixture("scratch_fontsvc_tex");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let service = scope ResourceFontService();
		service.AddFont(proxy.Get);

		let at12 = service.GetFont("TestFamily", 12.0f);
		Test.Assert(service.GetAtlasTexture(at12) != null);
		Test.Assert(service.GetAtlasTexture("TestFamily", 24.0f) != null);

		// The two sizes are separate bakes, so separate textures.
		Test.Assert(service.GetAtlasTexture(at12) !== service.GetAtlasTexture("TestFamily", 24.0f));

		// An unregistered CachedFont has no texture rather than the first one that fits.
		let stranger = scope CachedFont(null, null, null);
		Test.Assert(service.GetAtlasTexture(stranger) == null);
	}

	/// End to end over the baked tables: the shaper reads only metrics and glyph info, so
	/// it works on a font that came off disk exactly as it does on a parsed one.
	[Test]
	public static void ShapingRunsOverTheBakedTables()
	{
		let fixture = scope FontFixture("scratch_fontsvc_shape");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let service = scope ResourceFontService();
		service.AddFont(proxy.Get);

		let at12 = service.GetFont("TestFamily", 12.0f);
		Test.Assert(at12 != null);

		let positions = scope List<GlyphPosition>();
		Test.Assert(at12.Shaper.ShapeText(at12.Font, "A", positions) case .Ok(let width));
		Test.Assert(width == 6.0f, "12 pixels at the half advance the record carries");
		Test.Assert(positions.Count == 1);
	}

	/// A distance field serves every size from ONE bake, so a size nothing was baked at
	/// gets a scaled view rather than the bake-size tables.
	[Test]
	public static void DistanceFieldFamiliesSynthesizeScaledViews()
	{
		let fixture = scope FontFixture("scratch_fontsvc_df");

		let pixels = scope List<uint8>();
		FontFixture.DistanceFieldPixels(pixels);
		let id = fixture.Cook("font", .DistanceField, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let service = scope ResourceFontService();
		service.AddFont(proxy.Get);

		// A baked size resolves to the product itself, with nothing wrapped.
		let at12 = service.GetFont("TestFamily", 12.0f);
		Test.Assert(at12 != null);
		Test.Assert(at12.Font.PixelHeight == 12.0f);

		// A size nothing was baked at gets a view over the nearest bake.
		let at16 = service.GetFont("TestFamily", 16.0f);
		Test.Assert(at16 != null);
		Test.Assert(at16 !== at12);
		Test.Assert(at16.Font.PixelHeight == 16.0f);
		Test.Assert(at16.Atlas.Mode == .DistanceField);
		Test.Assert(at16.Atlas.DistanceFieldRange == 3.0f, "the range came through the view");

		// The metrics scale with it: a 6 unit advance at the 12 pixel bake is 8 at 16.
		Test.Assert(at16.Font.GetGlyphInfo(Cp('A')).AdvanceWidth == 8.0f);

		// CACHED, so asking again returns the same one rather than building another.
		Test.Assert(service.GetFont("TestFamily", 16.0f) === at16);

		// And it shares the base bake's texture, because it is the same atlas read at a
		// different scale.
		Test.Assert(service.GetAtlasTexture(at16) != null);
		Test.Assert(service.GetAtlasTexture(at16) === service.GetAtlasTexture(at12));

		// Shaping runs over the view too.
		let positions = scope List<GlyphPosition>();
		Test.Assert(at16.Shaper.ShapeText(at16.Font, "A", positions) case .Ok(let width));
		Test.Assert(width == 8.0f);
	}

	/// A coverage family does NOT get scaled views: a coverage atlas is sharp only near the
	/// size it was baked at, so an unbaked size resolves to the nearest bake as it is.
	[Test]
	public static void CoverageFamiliesDoNotSynthesize()
	{
		let fixture = scope FontFixture("scratch_fontsvc_nosynth");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let service = scope ResourceFontService();
		service.AddFont(proxy.Get);

		let before = service.EntryCount;
		let at16 = service.GetFont("TestFamily", 16.0f);
		Test.Assert(at16 != null);
		Test.Assert(at16.Font.PixelHeight == 12.0f, "the nearest bake, unscaled");
		Test.Assert(service.EntryCount == before, "and nothing was added to the table");
	}

	/// Nothing registered resolves to nothing, rather than crashing on an empty table.
	[Test]
	public static void AnEmptyServiceResolvesToNothing()
	{
		let service = scope ResourceFontService();

		Test.Assert(service.GetFont(12.0f) == null);
		Test.Assert(service.GetFont("Anything", 12.0f) == null);
		Test.Assert(service.GetAtlasTexture("Anything", 12.0f) == null);

		let family = scope String();
		service.GetDefaultFontFamily(family);
		Test.Assert(family.IsEmpty);

		service.AddFont(null); // and a null registration is ignored
		Test.Assert(service.EntryCount == 0);
	}

	/// Clear releases the service's own wrappers and leaves the PRODUCT intact, which is
	/// what makes rebinding a font mid-session safe.
	[Test]
	public static void ClearReleasesTheWrappersAndNotTheProduct()
	{
		let fixture = scope FontFixture("scratch_fontsvc_clear");

		let pixels = scope List<uint8>();
		FontFixture.DistanceFieldPixels(pixels);
		let id = fixture.Cook("font", .DistanceField, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let product = proxy.Get;
		Test.Assert(product != null);

		let service = scope ResourceFontService();
		service.AddFont(product);
		service.GetFont("TestFamily", 16.0f); // a synthesized entry as well as the bases
		Test.Assert(service.EntryCount == 3);

		service.Clear();
		Test.Assert(service.EntryCount == 0);

		// The product still holds its own tables: the service owned only the wrappers.
		Test.Assert(product.EntryCount == 2);
		Test.Assert(product.EntryAt(0).Font.HasGlyph(Cp('A')));
		Test.Assert(product.EntryAt(0).Atlas.Contains(Cp('A')));

		// And it can be registered again afterwards.
		service.AddFont(product);
		Test.Assert(service.GetFont("TestFamily", 12.0f) != null);
	}
}
