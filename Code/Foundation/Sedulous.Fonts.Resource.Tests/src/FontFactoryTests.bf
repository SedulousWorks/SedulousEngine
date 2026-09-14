using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Resource;
using Sedulous.Image;
using Sedulous.Resource;

namespace Sedulous.Fonts.Resource.Tests;

/// Cooking a font record into a content database and loading it back as the runtime
/// product, with no rasterizer anywhere in the path.
class FontFactoryTests
{
	private static int32 Cp(char8 c) => (int32)c;

	[Test]
	public static void ACoverageRecordLoadsAsARasterizerFreeProduct()
	{
		let fixture = scope FontFixture("scratch_font_coverage");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let font = proxy.Get;
		Test.Assert(font != null);
		Test.Assert(font.Family == "TestFamily");
		Test.Assert(font.EntryCount == 2);

		// Closest, not exact: 13 is nearer the 12 bake, and 100 is nearer the 24.
		let closest = font.ClosestEntry(13.0f);
		Test.Assert(closest != null);
		Test.Assert(closest.PixelHeight == 12.0f);
		Test.Assert(font.ClosestEntry(100.0f).PixelHeight == 24.0f);

		// The tables round tripped.
		Test.Assert(closest.Font != null);
		Test.Assert(closest.Font.HasGlyph(Cp('A')));
		Test.Assert(closest.Font.GetGlyphInfo(Cp('A')).AdvanceWidth == 6.0f);
		Test.Assert(closest.Font.GetKerning(Cp('A'), Cp('V')) == -1.5f);
		Test.Assert(closest.Font.Metrics.Ascent == 12.0f * 0.8f);
		Test.Assert(closest.Font.Metrics.Descent == -12.0f * 0.2f);

		Test.Assert(closest.Atlas != null);
		Test.Assert(closest.Atlas.Mode == .Coverage);
		Test.Assert(closest.Atlas.TryGetRegion(Cp('A'), let region));
		Test.Assert(region.Width == 2);
		Test.Assert(region.AdvanceX == 6.0f);

		// Coverage expands to RGBA8, so a renderer sees one format whichever mode it was
		// baked in, and the coverage byte lands in ALPHA.
		Test.Assert(closest.AtlasImage != null);
		Test.Assert(closest.AtlasImage.Format == .RGBA8);
		Test.Assert(closest.AtlasImage.PixelData.Length == 2 * 2 * 4);
		Test.Assert(closest.AtlasImage.PixelData[3] == 0x10, "entry zero starts at offset zero");
	}

	/// Each entry reads ITS OWN slice of the shared pixel stream. Entry one starts where
	/// entry zero ended, and a factory that ignored the offset would give both the same
	/// atlas.
	[Test]
	public static void EachEntryReadsItsOwnSliceOfTheStream()
	{
		let fixture = scope FontFixture("scratch_font_slices");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let font = proxy.Get;
		Test.Assert(font != null);

		let first = font.EntryAt(0);
		let second = font.EntryAt(1);

		// Four alpha texels each, expanded to RGBA: the alpha of texel zero is the first
		// byte of that entry's slice.
		Test.Assert(first.AtlasImage.PixelData[3] == 0x10);
		Test.Assert(second.AtlasImage.PixelData[3] == 0x50, "entry one starts four bytes in");
	}

	[Test]
	public static void ADistanceFieldRecordKeepsItsRangeAndStaysLinear()
	{
		let fixture = scope FontFixture("scratch_font_df");

		let pixels = scope List<uint8>();
		FontFixture.DistanceFieldPixels(pixels);
		let id = fixture.Cook("font", .DistanceField, pixels);

		let proxy = fixture.Manager.Bind<Font>(id);
		let font = proxy.Get;
		Test.Assert(font != null);
		Test.Assert(font.EntryCount == 2);

		let entry = font.EntryAt(1);
		Test.Assert(entry.Atlas != null);
		Test.Assert(entry.Atlas.Mode == .DistanceField);
		Test.Assert(entry.Atlas.DistanceFieldRange == 3.0f, "the range travelled with the pixels");

		// LINEAR: these are distances, and gamma decoding them would bend the field.
		Test.Assert(entry.AtlasImage != null);
		Test.Assert(entry.AtlasImage.ColorSpace == .Linear);
		Test.Assert(entry.AtlasImage.Format == .RGBA8);
		Test.Assert(entry.AtlasImage.PixelData[0] == 16, "entry one's slice starts at offset 16");

		// And no expansion happened: the payload was already four bytes per texel.
		Test.Assert(entry.AtlasImage.PixelData.Length == 2 * 2 * 4);
	}

	/// The async path builds the SAME product as the synchronous one. The whole build is a
	/// pure function of the stored bytes, which is the reason it is allowed on a worker at
	/// all, so the two must not be able to disagree.
	[Test]
	public static void AnAsyncLoadMatchesTheSyncProduct()
	{
		let jobs = scope JobSystem(2);
		let fixture = scope FontFixture("scratch_font_async", jobs);

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let syncProxy = fixture.Manager.Bind<Font>(id);
		let expected = syncProxy.Get;
		Test.Assert(expected != null);

		let asyncFixture = scope FontFixture("scratch_font_async2", jobs);
		let asyncId = asyncFixture.Cook("font", .Coverage, pixels);

		let asyncProxy = asyncFixture.Manager.BindAsync<Font>(asyncId);

		// It really went ASYNC rather than falling back to a synchronous build: the load is
		// pending until something pumps it. Without this the test would still pass if the
		// factory quietly stopped supporting the two stage path.
		Test.Assert(asyncFixture.Manager.PendingCount == 1, "the decode was handed to a worker");
		Test.Assert(asyncProxy.Get == null, "and nothing is built until it is pumped");

		asyncFixture.Manager.WaitAll();
		Test.Assert(asyncFixture.Manager.PendingCount == 0);

		let actual = asyncProxy.Get;
		Test.Assert(actual != null, "the async load resolved");
		Test.Assert(actual.EntryCount == expected.EntryCount);
		Test.Assert(actual.Family == expected.Family);

		for (int i < actual.EntryCount)
		{
			let a = actual.EntryAt(i);
			let b = expected.EntryAt(i);
			Test.Assert(a.PixelHeight == b.PixelHeight);
			Test.Assert(a.Font.GetGlyphInfo(Cp('A')).AdvanceWidth
				== b.Font.GetGlyphInfo(Cp('A')).AdvanceWidth);
			Test.Assert(a.Font.GetKerning(Cp('A'), Cp('V')) == b.Font.GetKerning(Cp('A'), Cp('V')));
			Test.Assert(a.AtlasImage.PixelData.Length == b.AtlasImage.PixelData.Length);
			Test.Assert(Internal.MemCmp(a.AtlasImage.PixelData.Ptr, b.AtlasImage.PixelData.Ptr,
				a.AtlasImage.PixelData.Length) == 0, scope $"entry {i} decoded differently");
		}
	}

	/// A record whose tables are shorter than the counts its entries claim is REFUSED. It
	/// is data from disk, so a truncated or hand edited one must not be read past the end
	/// of its own lists.
	[Test]
	public static void ATruncatedRecordIsRefused()
	{
		let record = scope FontResource();
		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		FontFixture.Author(record, .Coverage);
		Test.Assert(record.IsWellFormed());

		// One glyph row short of what the entries claim.
		record.GlyphCodepoint.PopBack();
		Test.Assert(!record.IsWellFormed());

		// And an entry row short of the entry count.
		let intact = scope FontResource();
		FontFixture.Author(intact, .Coverage);
		intact.EntryAscent.PopBack();
		Test.Assert(!intact.IsWellFormed());
	}

	/// Every entry reads its OWN row of the flattened tables, not entry zero's. The rows sit
	/// in entry order and each entry names how many are its, so a factory that lost the
	/// running start would give every size the first size's glyphs.
	[Test]
	public static void EachEntryReadsItsOwnRowsOfTheTables()
	{
		let fixture = scope FontFixture("scratch_font_rows");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels);

		let font = fixture.Manager.Bind<Font>(id).Get;
		Test.Assert(font != null);

		// The two entries carry DIFFERENT advances, being half of 12 and half of 24, so
		// reading the wrong row is visible.
		Test.Assert(font.EntryAt(0).Font.GetGlyphInfo(Cp('A')).AdvanceWidth == 6.0f);
		Test.Assert(font.EntryAt(1).Font.GetGlyphInfo(Cp('A')).AdvanceWidth == 12.0f);

		// And so do the regions, through the advance the cursor steps by.
		Test.Assert(font.EntryAt(0).Atlas.TryGetRegion(Cp('A'), let first));
		Test.Assert(font.EntryAt(1).Atlas.TryGetRegion(Cp('A'), let second));
		Test.Assert(first.AdvanceX == 6.0f);
		Test.Assert(second.AdvanceX == 12.0f);
		Test.Assert(first.OffsetY != second.OffsetY, "and the ascents they hang from differ");
	}

	/// The oversampling travels with the record and reaches the atlas. Region spans are raw
	/// texels at that multiple of the logical glyph size, so a record that lost it draws
	/// every glyph oversized.
	[Test]
	public static void TheOversamplingReachesTheAtlas()
	{
		let fixture = scope FontFixture("scratch_font_oversample");

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		let id = fixture.Cook("font", .Coverage, pixels, 2.0f);

		let font = fixture.Manager.Bind<Font>(id).Get;
		Test.Assert(font != null);

		let entry = font.EntryAt(0);
		float cursorX = 0;
		Test.Assert(entry.Atlas.GetGlyphQuad(Cp('A'), ref cursorX, 0, let quad));

		// The region is two texels wide, packed at twice the logical size, so it draws one
		// pixel wide. Dropping the oversampling would draw it two.
		Test.Assert((quad.X1 - quad.X0) == 1.0f,
			scope $"the quad spans {quad.X1 - quad.X0}, expected the span halved by the oversampling");

		// The advance is NOT divided: it is a layout metric, not an atlas span.
		Test.Assert(cursorX == 6.0f);
	}

	/// The factory REFUSES a malformed record end to end, not merely somewhere it could
	/// have checked. This is data off disk, and reading past the end of a list is the
	/// failure mode the check exists to prevent.
	[Test]
	public static void AMalformedRecordIsRefusedByTheFactory()
	{
		let fixture = scope FontFixture("scratch_font_malformed");

		let instance = fixture.Database.RootGroup.CreateInstance("font",
			"Sedulous.Fonts.Resource.FontResource");

		let record = scope FontResource();
		FontFixture.Author(record, .Coverage);
		// One glyph row short of what the two entries between them claim.
		record.GlyphCodepoint.PopBack();
		record.GlyphAdvanceWidth.PopBack();
		instance.WriteObject(record).IgnoreError();

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);
		instance.WriteData("data", pixels).IgnoreError();

		Test.Assert(fixture.Manager.Bind<Font>(instance.Id).Get == null,
			"a truncated record builds nothing rather than reading past its tables");
	}

	/// An empty record produces NO product rather than an empty one: a font that exists but
	/// has no sizes would resolve to nothing at every request and look like a missing glyph.
	[Test]
	public static void ARecordWithNoEntriesProducesNoProduct()
	{
		let fixture = scope FontFixture("scratch_font_empty");

		let instance = fixture.Database.RootGroup.CreateInstance("font",
			"Sedulous.Fonts.Resource.FontResource");
		let record = scope FontResource();
		record.Family.Set("Empty");
		instance.WriteObject(record).IgnoreError();

		let proxy = fixture.Manager.Bind<Font>(instance.Id);
		Test.Assert(proxy.Get == null);
	}

	/// Many decodes in flight at once, which is the case a single async load cannot reach.
	///
	/// A factory that keeps any state between the decode and the finalize stage passes the
	/// one-at-a-time test and corrupts under load, because the second decode overwrites what
	/// the first had not yet finalised. Twelve fonts over four workers is enough contention
	/// for that to show, and each product is checked individually rather than by count.
	[Test]
	public static void ManyConcurrentDecodesEachProduceTheirOwnFont()
	{
		let jobs = scope JobSystem(4);
		let fixture = scope FontFixture("scratch_font_concurrent", jobs);

		let pixels = scope List<uint8>();
		FontFixture.CoveragePixels(pixels);

		let ids = scope List<Guid>();
		for (int i = 0; i < 12; i++)
			ids.Add(fixture.Cook(scope $"font{i:00}", .Coverage, pixels));

		let fonts = scope List<Proxy<Font>>();
		for (let id in ids)
			fonts.Add(fixture.Manager.BindAsync<Font>(id));
		fixture.Manager.WaitAll();

		for (let font in fonts)
		{
			Test.Assert(font.Get != null, "every font arrived");
			Test.Assert(font.State == .Ready);

			// Its OWN tables, not a half finalised neighbour's: a factory holding state
			// between the decode and the finalize stage hands back the wrong entry here.
			Test.Assert(font.Get.Family == "TestFamily");
			Test.Assert(font.Get.EntryCount == 2);
			let closest = font.Get.ClosestEntry(13.0f);
			Test.Assert(closest != null);
			Test.Assert(closest.PixelHeight == 12.0f);
			Test.Assert(closest.Font != null);
			Test.Assert(closest.Font.HasGlyph(Cp('A')));
		}
	}
}
