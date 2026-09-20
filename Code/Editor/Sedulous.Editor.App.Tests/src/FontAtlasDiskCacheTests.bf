using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField.Baker;

namespace Sedulous.Editor.App.Tests;

/// The editor's startup MSDF bake cache: a real Roboto bake round-trips byte-identically
/// through Store and TryLoad, any option change misses, a corrupt file fails closed.
static class FontAtlasDiskCacheTests
{
	private static void CacheDir(StringView name, String outDir)
	{
		GetCurrentDirectory(outDir);
		PathJoin(outDir, name, outDir);
		RemoveDirectoryRecursive(outDir);
	}

	[Test]
	public static void DfBakesRoundTripByteIdenticallyThroughTheDiskCache()
	{
		let dir = CacheDir(".fontcache_roundtrip", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let options = TestFont.SmallDF();

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		let cache = scope FontAtlasDiskCache(dir);
		Test.Assert(cache.TryLoad(font, options) == null, "cold: a miss");
		cache.Store(font, options, atlas);

		let loaded = cache.TryLoad(font, options);
		Test.Assert(loaded != null);
		defer delete loaded;
		Test.Assert(loaded.Mode == .DistanceField);
		Test.Assert(loaded.Width == atlas.Width);
		Test.Assert(loaded.Height == atlas.Height);
		Test.Assert(loaded.DistanceFieldRange == atlas.DistanceFieldRange);
		Test.Assert(loaded.WhitePixelUV.X == atlas.WhitePixelUV.X);
		Test.Assert(loaded.WhitePixelUV.Y == atlas.WhitePixelUV.Y);

		for (int32 cp = options.FirstCodepoint; cp <= options.LastCodepoint; cp++)
		{
			let ha = atlas.TryGetRegion(cp, let a);
			let hb = loaded.TryGetRegion(cp, let b);
			Test.Assert(ha == hb);
			if (ha && hb)
			{
				Test.Assert(a.X == b.X);
				Test.Assert(a.Y == b.Y);
				Test.Assert(a.Width == b.Width);
				Test.Assert(a.Height == b.Height);
				Test.Assert(a.AdvanceX == b.AdvanceX);
			}
		}
		let pa = atlas.PixelData;
		let pb = loaded.PixelData;
		Test.Assert(pa.Length == pb.Length);
		Test.Assert(Internal.MemCmp(pa.Ptr, pb.Ptr, pa.Length) == 0);
	}

	[Test]
	public static void AnyOptionChangeMissesAndCoverageBakesAreDeclined()
	{
		let dir = CacheDir(".fontcache_keys", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let options = TestFont.SmallDF();

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		let cache = scope FontAtlasDiskCache(dir);
		cache.Store(font, options, atlas);

		var differentSize = options;
		differentSize.PixelHeight = 48.0f;
		Test.Assert(cache.TryLoad(font, differentSize) == null);

		var differentRange = options;
		differentRange.LastCodepoint = 255;
		Test.Assert(cache.TryLoad(font, differentRange) == null);

		var coverage = options;
		coverage.AtlasMode = .Coverage;
		Test.Assert(cache.TryLoad(font, coverage) == null, "declined");
	}

	[Test]
	public static void ATruncatedCacheFileFailsClosed()
	{
		let dir = CacheDir(".fontcache_corrupt", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;
		let options = TestFont.SmallDF();

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		let cache = scope FontAtlasDiskCache(dir);
		cache.Store(font, options, atlas);

		// Truncate the stored file to half: the header parses but the pixel read must fail.
		let fs = scope NativeFileSystem(dir);
		let entries = scope List<DirEntry>();
		defer { for (var e in entries) e.Dispose(); }
		Test.Assert(fs.Enumerate("", entries) case .Ok);
		Test.Assert(entries.Count == 1);
		let bytes = scope List<uint8>();
		{
			let stream = fs.Open(entries[0].Name, .Read);
			Test.Assert(stream != null);
			defer delete stream;
			bytes.Resize((int)stream.Size() / 2);
			Test.Assert(stream.Read(.(bytes.Ptr, bytes.Count)) == bytes.Count);
		}
		Test.Assert(fs.Save(entries[0].Name, bytes) case .Ok);
		Test.Assert(cache.TryLoad(font, options) == null, "a miss, never a bad atlas");
	}
}
