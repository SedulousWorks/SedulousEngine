using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Fonts;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.Resource;
using Sedulous.Image;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Fonts.Pipeline.Tests;

/// The font cook: a typeface file baked into a rasteriser free product.
///
/// Rasteriser free is the point. What binds at runtime carries the glyph metrics and the atlas
/// image already, so a player links no font library at all.
class FontAssetCookTests
{
	private const String cSourceRoot = "scratch_fonts_pipeline_src";
	private const String cCookedRoot = "scratch_fonts_pipeline_out";
	private const String cSourceName = "test.ttf";
	private const String cProductType = "Sedulous.Fonts.Resource.FontResource";

	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	private static void MakeRoots()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
	}

	private static void RemoveRoots()
	{
		RemoveDirectoryRecursive(cSourceRoot);
		RemoveDirectoryRecursive(cCookedRoot);
	}

	/// A coverage ramp: one entry per authored size, each with its own baked atlas.
	[Test]
	public static void ARasterRampCooksAnEntryPerSize()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		if (!FontTestFile.StageInto(cSourceRoot, cSourceName))
			return; // no data in this checkout, so nothing to measure

		FontsPipeline.RegisterAll();
		FontResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("uifont", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope FontAsset();
			asset.FileName.Set(cSourceName);
			asset.Family.Set("TestMono");
			asset.Sizes.Clear();
			asset.Sizes.Add(12.0f);
			asset.Sizes.Add(24.0f);
			asset.FirstCodepoint = 32;
			asset.LastCodepoint = 126; // ASCII keeps the bake quick
			asset.AtlasWidth = 512;
			asset.AtlasHeight = 512;

			let builder = scope FontAssetBuilder();
			Test.Assert(builder.AssetType == typeof(FontAsset));
			Test.Assert(builder.ProductType == typeof(FontResource));

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope FontFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<Font>(id);
		let font = bound.Get;
		Test.Assert(font != null);
		Test.Assert(font.Family == "TestMono");
		Test.Assert(font.EntryCount == 2);
		// The font file came along (a shaper reads its tables), and every entry's font lends it.
		Test.Assert(font.SourceData.Length > 1000);
		Test.Assert(font.EntryAt(0).Font.SourceData.Ptr == font.SourceData.Ptr);
		Test.Assert(font.EntryAt(1).Font.SourceData.Length == font.SourceData.Length);

		let entry = font.ClosestEntry(12.0f);
		Test.Assert(entry != null);
		Test.Assert(Near(entry.PixelHeight, 12.0f));

		Test.Assert(entry.Font != null);
		Test.Assert(entry.Font.HasGlyph((int32)'A'));
		Test.Assert(entry.Font.GetGlyphInfo((int32)'A').AdvanceWidth > 0.0f);
		Test.Assert(entry.Font.Metrics.Ascent > 0.0f);

		Test.Assert(entry.Atlas != null);
		Test.Assert(entry.Atlas.Mode == .Coverage);
		Test.Assert(entry.Atlas.Contains(entry.Atlas.GlyphFor((int32)'A')));

		var cursor = 0.0f;
		Test.Assert(entry.Atlas.GetGlyphQuad(entry.Atlas.GlyphFor((int32)'A'), ref cursor, 0.0f, let quad));
		Test.Assert(cursor > 0.0f); // the advance moved

		Test.Assert(entry.AtlasImage != null);
		Test.Assert(entry.AtlasImage.Width == 512);
		Test.Assert(entry.AtlasImage.PixelData.Length == 512 * 512 * 4); // expanded to RGBA
	}

	/// The distance field bake: ONE entry whatever the ramp says, since a field is resolution
	/// independent and scales instead of being re-baked per size.
	[Test]
	public static void ADistanceFieldBakeCooksOneScalableEntry()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		if (!FontTestFile.StageInto(cSourceRoot, cSourceName))
			return;

		FontsPipeline.RegisterAll();
		FontResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("uifont", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope FontAsset();
			asset.FileName.Set(cSourceName);
			asset.Mode = .DistanceField;
			asset.DistanceFieldSize = 32.0f;
			asset.FirstCodepoint = (int32)'A';
			asset.LastCodepoint = (int32)'Z'; // a small range keeps the bake quick
			asset.AtlasWidth = 256;
			asset.AtlasHeight = 256;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(scope FontAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope FontFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<Font>(id);
		let font = bound.Get;
		Test.Assert(font != null);
		Test.Assert(font.EntryCount == 1);

		let entry = font.EntryAt(0);
		Test.Assert(entry.Atlas != null);
		Test.Assert(entry.Atlas.Mode == .DistanceField);
		Test.Assert(entry.Atlas.DistanceFieldRange > 0.0f);
		Test.Assert(entry.Atlas.Contains(entry.Atlas.GlyphFor((int32)'Q')));
		Test.Assert(entry.AtlasImage != null);
		// A distance field carries DISTANCES, not colour, so decoding it as sRGB would bend
		// every edge it describes.
		Test.Assert(entry.AtlasImage.ColorSpace == .Linear);
	}

	/// A cooked distance-field font draws everything HarfBuzz shapes from its range: the joined
	/// Arabic forms no codepoint maps to are baked and their regions kept. A cook that kept only
	/// the codepoints' own glyphs drew joined Arabic, and every fi ligature, as nothing.
	[Test]
	public static void ADistanceFieldCookKeepsTheGlyphsShapingReaches()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		if (!FontTestFile.StageInto(cSourceRoot, cSourceName, FontTestFile.cDejaVuMono))
			return;

		FontsPipeline.RegisterAll();
		FontResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("uifont", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope FontAsset();
			asset.FileName.Set(cSourceName);
			asset.Mode = .DistanceField;
			asset.DistanceFieldSize = 32.0f;
			asset.FirstCodepoint = 0x0621; // the Arabic letters
			asset.LastCodepoint = 0x064A;
			asset.AtlasWidth = 1024;
			asset.AtlasHeight = 1024;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(scope FontAssetBuilder().Build(asset, context) case .Ok);
		}
		defer HarfBuzzShaping.Uninstall(); // the builder installed it

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope FontFactory();
		manager.AddFactory(factory);
		let font = manager.Bind<Font>(id).Get;
		Test.Assert(font != null);
		let entry = font.EntryAt(0);
		Test.Assert((entry.Font != null) && (entry.Atlas != null));

		let shaper = HarfBuzzShaping.CreateShaper();
		defer delete shaper;
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(entry.Font, "\u{0633}\u{0644}\u{0627}\u{0645}", glyphs) case .Ok);
		Test.Assert(glyphs.Count == 3, "joined: shaped from the cooked font's own file");
		int joinedForms = 0;
		for (let glyph in glyphs)
		{
			Test.Assert(entry.Atlas.Contains(glyph.GlyphId), scope $"glyph {glyph.GlyphId} has its place in the atlas");
			bool nominal = false;
			for (int32 codepoint = 0x0621; codepoint <= 0x064A; codepoint++)
				nominal = nominal || (entry.Atlas.GlyphFor(codepoint) == glyph.GlyphId);
			if (!nominal)
				joinedForms++;
		}
		Test.Assert(joinedForms > 0, "and some are forms no codepoint maps to");
	}

	/// Builds run in parallel on job workers; installing HarfBuzz from Build raced another
	/// worker's shaper lookup, so the builder installs it when it is made.
	[Test]
	public static void TheFontBuilderInstallsHarfBuzzWhenMadeNotAsItBuilds()
	{
		HarfBuzzShaping.Uninstall();
		Test.Assert(!HarfBuzzShaping.IsInstalled);
		let builder = scope FontAssetBuilder();
		Test.Assert(HarfBuzzShaping.IsInstalled);
		HarfBuzzShaping.Uninstall();
		Test.Assert(builder != null);
	}

	[Test]
	public static void TheImporterClaimsFontExtensionsOnly()
	{
		let importer = scope FontAssetImporter();
		Test.Assert(importer.Accepts("ttf"));
		Test.Assert(importer.Accepts("otf"));
		Test.Assert(importer.Accepts("ttc"));
		Test.Assert(!importer.Accepts("png"));
		Test.Assert(!importer.Accepts("xasset"));
	}

	/// A source file that is not there is an ERROR rather than an empty font.
	[Test]
	public static void AMissingSourceFileFailsTheBuild()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		FontsPipeline.RegisterAll();
		FontResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("uifont", cProductType);
		Test.Assert(instance != null);

		let asset = scope FontAsset();
		asset.FileName.Set("does_not_exist.ttf");

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope FontAssetBuilder().Build(asset, context) case .Err);
	}
}
