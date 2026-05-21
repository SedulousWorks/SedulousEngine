using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Fonts.Importer;
using Sedulous.Fonts.Resources;
using Sedulous.OpenDDL;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;

namespace Sedulous.Fonts.Tests;

/// End-to-end test: bake a real TTF, write a FontResource through the
/// serializer + atlas pixel sidecar, read it back, and verify every piece
/// of data round-trips. Mirrors what FontResourceManager does at load time
/// but stays in-memory so the test doesn't need a VFS or temp dir.
class FontResourceRoundTripTests
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
	static void TestFontResourceMetadataRoundTrip()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		// Bake from a real TTF so the test covers a realistic populated
		// resource (hundreds of glyphs, real kerning pairs).
		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		let bakeResult = FontImporter.Bake(.(bytes.Ptr, bytes.Count), .Default);
		Test.Assert(bakeResult case .Ok);
		let bakedData = bakeResult.Value;

		let (font, atlas) = bakedData.TakeOwnership();
		delete bakedData;

		let original = scope FontResource(font, atlas, .Default);
		// Capture a few values before serializing so the asserts can compare
		// against the original baked data and not against the loaded copy.
		let origFamily = scope String();
		origFamily.Set(original.BakedFont.FamilyName);
		let origMetrics = original.BakedFont.Metrics;
		let origGlyphCount = original.BakedFont.Glyphs.Count;
		let origKernCount = original.BakedFont.Kerning.Count;
		let origAtlasW = original.BakedAtlas.Width;
		let origAtlasH = original.BakedAtlas.Height;
		let origAdvanceA = original.BakedFont.GetGlyphInfo((int32)'A').AdvanceWidth;
		AtlasRegion origRegionA;
		Test.Assert(original.BakedAtlas.TryGetRegion((int32)'A', out origRegionA));

		// --- Serialize metadata. ---
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		Test.Assert(original.Serialize(writer) == .Ok);

		let output = scope String();
		writer.GetOutput(output);
		Test.Assert(output.Length > 0);

		// --- Serialize atlas pixels through the sidecar stream. ---
		let pixelStream = scope MemoryStream();
		Test.Assert(original.WriteAtlasPixelsToStream(pixelStream) case .Ok);
		Test.Assert(pixelStream.Length == origAtlasW * origAtlasH);

		// --- Deserialize metadata. ---
		// SerializerDataDescription (not the base DataDescription) is required
		// because the OpenDDL parser otherwise drops Obj_/Arr_ structures as
		// unknown - matching what OpenDDLSerializerProvider does at runtime.
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ProcessText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope FontResource();
		Test.Assert(loaded.Serialize(reader) == .Ok);

		// Verify font metadata round-tripped.
		Test.Assert(loaded.BakedFont.FamilyName == origFamily);
		Test.Assert(loaded.BakedFont.Metrics.Ascent == origMetrics.Ascent);
		Test.Assert(loaded.BakedFont.Metrics.Descent == origMetrics.Descent);
		Test.Assert(loaded.BakedFont.Metrics.LineGap == origMetrics.LineGap);
		Test.Assert(loaded.BakedFont.Metrics.LineHeight == origMetrics.LineHeight);
		Test.Assert(loaded.BakedFont.Metrics.PixelHeight == origMetrics.PixelHeight);
		Test.Assert(loaded.BakedFont.Metrics.Scale == origMetrics.Scale);

		// Verify glyph + kerning table sizes match.
		Test.Assert(loaded.BakedFont.Glyphs.Count == origGlyphCount);
		Test.Assert(loaded.BakedFont.Kerning.Count == origKernCount);

		// Verify atlas dims came through (these are stored in options + on
		// the BakedFontAtlas).
		Test.Assert(loaded.BakedAtlas.Width == origAtlasW);
		Test.Assert(loaded.BakedAtlas.Height == origAtlasH);

		// Spot-check a specific glyph + region.
		Test.Assert(loaded.BakedFont.HasGlyph((int32)'A'));
		Test.Assert(loaded.BakedFont.GetGlyphInfo((int32)'A').AdvanceWidth == origAdvanceA);

		AtlasRegion loadedRegionA;
		Test.Assert(loaded.BakedAtlas.TryGetRegion((int32)'A', out loadedRegionA));
		Test.Assert(loadedRegionA.X == origRegionA.X);
		Test.Assert(loadedRegionA.Y == origRegionA.Y);
		Test.Assert(loadedRegionA.Width == origRegionA.Width);
		Test.Assert(loadedRegionA.Height == origRegionA.Height);
		Test.Assert(loadedRegionA.OffsetX == origRegionA.OffsetX);
		Test.Assert(loadedRegionA.OffsetY == origRegionA.OffsetY);
		Test.Assert(loadedRegionA.AdvanceX == origRegionA.AdvanceX);
	}

	[Test]
	static void TestFontResourceKerningRoundTrip()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		let bakeResult = FontImporter.Bake(.(bytes.Ptr, bytes.Count), .Default);
		Test.Assert(bakeResult case .Ok);
		let bakedData = bakeResult.Value;
		let (font, atlas) = bakedData.TakeOwnership();
		delete bakedData;

		let original = scope FontResource(font, atlas, .Default);

		// Some fonts have no kerning pairs at all (notably mono / very simple
		// fonts). For pairs that do exist in the original, the round-tripped
		// resource must produce identical adjustments.
		let kernSamples = scope List<(int32 first, int32 second, float adj)>();
		for (let kv in original.BakedFont.Kerning)
		{
			let first = (int32)(kv.key >> 32);
			let second = (int32)(kv.key & 0xFFFFFFFF);
			kernSamples.Add((first, second, kv.value));
			if (kernSamples.Count >= 16) break;
		}

		// Serialize / deserialize.
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		Test.Assert(original.Serialize(writer) == .Ok);

		let output = scope String();
		writer.GetOutput(output);

		// SerializerDataDescription (not the base DataDescription) is required
		// because the OpenDDL parser otherwise drops Obj_/Arr_ structures as
		// unknown - matching what OpenDDLSerializerProvider does at runtime.
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ProcessText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope FontResource();
		Test.Assert(loaded.Serialize(reader) == .Ok);

		// Every sampled pair must come back with the same adjustment.
		for (let sample in kernSamples)
		{
			let got = loaded.BakedFont.GetKerning(sample.first, sample.second);
			Test.Assert(got == sample.adj);
		}
	}

	[Test]
	static void TestFontResourceAtlasPixelSidecar()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty) return;

		let bytes = scope List<uint8>();
		Test.Assert(ReadFontBytes(fontPath, bytes) case .Ok);

		let bakeResult = FontImporter.Bake(.(bytes.Ptr, bytes.Count), .Default);
		Test.Assert(bakeResult case .Ok);
		let bakedData = bakeResult.Value;
		let (font, atlas) = bakedData.TakeOwnership();
		delete bakedData;

		let original = scope FontResource(font, atlas, .Default);
		let origW = original.BakedAtlas.Width;
		let origH = original.BakedAtlas.Height;

		// Capture a hash-like sample of the pixel buffer so we can compare
		// without holding two large arrays in scope.
		let origPixels = original.BakedAtlas.PixelData;
		var origSum = 0u;
		for (int i = 0; i < origPixels.Length; i++)
			origSum += origPixels[i];

		// Round-trip metadata.
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		Test.Assert(original.Serialize(writer) == .Ok);
		let output = scope String();
		writer.GetOutput(output);

		// Round-trip pixels via the sidecar stream.
		let pixelStream = scope MemoryStream();
		Test.Assert(original.WriteAtlasPixelsToStream(pixelStream) case .Ok);

		// Now load. FontResourceManager copies sidecar bytes into a fresh
		// uint8[] and hands it to BakedFontAtlas.SetPixels; mirror that here.
		let doc = scope DataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;
		let loaded = scope FontResource();
		Test.Assert(loaded.Serialize(reader) == .Ok);

		let expected = (int)loaded.Options.AtlasWidth * (int)loaded.Options.AtlasHeight;
		Test.Assert(expected == (int)origW * (int)origH);

		let loadedPixels = new uint8[expected];
		let pixelBytes = pixelStream.Memory;
		let copyCount = Math.Min(expected, pixelBytes.Count);
		for (int i = 0; i < copyCount; i++)
			loadedPixels[i] = pixelBytes[i];
		loaded.BakedAtlas.SetPixels(loaded.Options.AtlasWidth, loaded.Options.AtlasHeight, loadedPixels);

		Test.Assert(loaded.BakedAtlas.Width == origW);
		Test.Assert(loaded.BakedAtlas.Height == origH);
		Test.Assert(loaded.BakedAtlas.PixelData.Length == origPixels.Length);

		var loadedSum = 0u;
		let lp = loaded.BakedAtlas.PixelData;
		for (int i = 0; i < lp.Length; i++)
			loadedSum += lp[i];
		Test.Assert(loadedSum == origSum);
	}
}
