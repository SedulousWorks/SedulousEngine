using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Fonts.Importer;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

/// Editor-time baking pipeline: feed a real TTF through FontImporter.Bake
/// and confirm the produced BakedFont + BakedFontAtlas carry usable data
/// (family name, metrics, populated glyph table, populated atlas, kerning).
///
/// Skipped at runtime if no system font is found - same convention as the
/// existing TrueTypeFont tests.
class FontImporterTests
{
	private static StringView[?] sSystemFontPaths = .(
		"C:/Windows/Fonts/arial.ttf",
		"C:/Windows/Fonts/segoeui.ttf",
		"C:/Windows/Fonts/tahoma.ttf",
		"C:/Windows/Fonts/verdana.ttf"
	);

	private static StringView GetAvailableSystemFont()
	{
		for (let path in sSystemFontPaths)
		{
			if (File.Exists(path))
				return path;
		}
		return .();
	}

	/// Read a font file directly off disk. Tests that drive the baker live
	/// outside the VFS world, so a raw FileStream is the right tool here.
	private static Result<void> ReadFontBytes(StringView path, List<uint8> outBytes)
	{
		let fs = scope FileStream();
		if (fs.Open(path, .Read, .Read) case .Err)
			return .Err;
		let length = (int32)fs.Length;
		outBytes.Count = length;
		if (fs.TryRead(.(outBytes.Ptr, length)) case .Err)
			return .Err;
		return .Ok;
	}

	[Test]
	static void TestBakeSystemFontProducesGlyphs()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		let result = FontImporter.Bake(.(bytes.Ptr, bytes.Count), .Default);
		Test.Assert(result case .Ok);
		let baked = result.Value;
		defer delete baked;

		// Family name and metrics should be carried over from the TTF parse.
		Test.Assert(baked.Font.FamilyName != null);
		Test.Assert(baked.Font.Metrics.Ascent > 0);
		Test.Assert(baked.Font.Metrics.Descent < 0);
		Test.Assert(baked.Font.Metrics.LineHeight > 0);
		Test.Assert(baked.Font.PixelHeight == FontLoadOptions.Default.PixelHeight);

		// Default options cover the ASCII printable range; every common letter
		// should have both a glyph entry and an atlas region.
		Test.Assert(baked.Font.HasGlyph((int32)'A'));
		Test.Assert(baked.Font.HasGlyph((int32)'z'));
		Test.Assert(baked.Font.HasGlyph((int32)'0'));
		Test.Assert(baked.Atlas.Contains((int32)'A'));
		Test.Assert(baked.Atlas.Contains((int32)'z'));
		Test.Assert(baked.Atlas.Contains((int32)'0'));

		// Advance widths should be positive for visible letters.
		let a = baked.Font.GetGlyphInfo((int32)'A');
		Test.Assert(a.AdvanceWidth > 0);
	}

	[Test]
	static void TestBakedAtlasMatchesRequestedDimensions()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		// Custom atlas dims with a small codepoint range that packs easily.
		var opts = FontLoadOptions.Default;
		opts.AtlasWidth = 256;
		opts.AtlasHeight = 256;
		opts.FirstCodepoint = (int32)'A';
		opts.LastCodepoint = (int32)'Z';
		let result = FontImporter.Bake(.(bytes.Ptr, bytes.Count), opts);
		Test.Assert(result case .Ok);
		let baked = result.Value;
		defer delete baked;

		Test.Assert(baked.Atlas.Width == 256);
		Test.Assert(baked.Atlas.Height == 256);
		Test.Assert(baked.Atlas.PixelData.Length == 256 * 256);
	}

	[Test]
	static void TestBakeFailureOnGarbageBytes()
	{
		// Random non-font bytes. Bake should fail cleanly without crashing.
		let junk = scope List<uint8>();
		junk.Count = 256;
		for (int i = 0; i < 256; i++) junk[i] = 0xAB;
		let result = FontImporter.Bake(.(junk.Ptr, junk.Count), .Default);
		Test.Assert(result case .Err);
	}

	[Test]
	static void TestTakeOwnershipNullsBakedDataFields()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		let result = FontImporter.Bake(.(bytes.Ptr, bytes.Count), .Default);
		Test.Assert(result case .Ok);
		let bakedData = result.Value;

		let (takenFont, takenAtlas) = bakedData.TakeOwnership();
		Test.Assert(takenFont != null);
		Test.Assert(takenAtlas != null);
		Test.Assert(bakedData.Font == null);
		Test.Assert(bakedData.Atlas == null);

		// bakedData destructor should not touch the now-null fields.
		delete bakedData;
		delete takenFont;
		delete takenAtlas;
	}
}
