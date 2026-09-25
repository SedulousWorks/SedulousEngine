using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Fonts.DistanceField;

namespace Sedulous.Editor.App;

/// The disk-backed IFontAtlasCache for the editor's MSDF UI fonts. The startup bake
/// (msdfgen over two full families) dominates the launch-to-first-frame gap; this caches
/// the baked DistanceFieldFontAtlas keyed by the font's bytes plus the bake options, so
/// every launch after the first loads the atlas in milliseconds. Coverage atlases and
/// non-TTF fonts are declined: cheap, or without a stable byte identity here.
class FontAtlasDiskCache : IFontAtlasCache
{
	/// Bump on any layout change: old cache files then miss and rebake.
	private const uint32 cCacheFormatVersion = 1;
	private const uint32 cCacheMagic = 0x43414644; // 'DFAC'

	[Ordered, Packed]
	private struct CacheHeader
	{
		public uint32 Magic = 0;
		public uint32 Version = 0;
		public uint64 Key = 0;
		public float PixelRange = 0.0f;
		public float WhiteU = 0.0f;
		public float WhiteV = 0.0f;
		public uint32 Width = 0;
		public uint32 Height = 0;
		public uint32 RegionCount = 0;
		public uint32 PixelBytes = 0;
	}

	[Ordered, Packed]
	private struct CacheRegion
	{
		public int32 Codepoint = 0;
		public uint16 X = 0;
		public uint16 Y = 0;
		public uint16 Width = 0;
		public uint16 Height = 0;
		public float OffsetX = 0.0f;
		public float OffsetY = 0.0f;
		public float AdvanceX = 0.0f;
	}

	private String mDirectory = new .() ~ delete _;

	/// The directory is created on the first Store; a missing one just means misses.
	public this(StringView directory)
	{
		mDirectory.Set(directory);
	}

	public override IFontAtlas TryLoad(IFont font, FontLoadOptions options)
	{
		uint64 key = 0;
		if (!KeyFor(font, options, out key))
			return null;
		let fs = scope NativeFileSystem(mDirectory);
		let stream = fs.Open(FileNameFor(key, .. scope .()), .Read);
		if (stream == null)
			return null;
		defer delete stream;

		CacheHeader header = ?;
		if ((stream.Read(.((uint8*)&header, sizeof(CacheHeader))) != sizeof(CacheHeader)) ||
			(header.Magic != cCacheMagic) || (header.Version != cCacheFormatVersion) ||
			(header.Key != key) || (header.Width == 0) || (header.Height == 0) ||
			(header.PixelBytes != header.Width * header.Height * 4))
			return null;

		let atlas = new DistanceFieldFontAtlas();
		atlas.SetPixelRange(header.PixelRange);
		atlas.SetWhitePixelUV(header.WhiteU, header.WhiteV);
		for (uint32 i = 0; i < header.RegionCount; i++)
		{
			CacheRegion r = ?;
			if (stream.Read(.((uint8*)&r, sizeof(CacheRegion))) != sizeof(CacheRegion))
			{
				delete atlas;
				return null;
			}
			atlas.SetRegion(r.Codepoint, AtlasRegion(r.X, r.Y, r.Width, r.Height, r.OffsetX, r.OffsetY, r.AdvanceX));
		}
		let pixels = new List<uint8>();
		pixels.Resize((int)header.PixelBytes);
		if (stream.Read(.(pixels.Ptr, pixels.Count)) != pixels.Count)
		{
			delete pixels;
			delete atlas;
			return null;
		}
		atlas.SetPixels(header.Width, header.Height, pixels);
		return atlas;
	}

	public override void Store(IFont font, FontLoadOptions options, IFontAtlas atlas)
	{
		uint64 key = 0;
		if (!KeyFor(font, options, out key) || (atlas.Mode != .DistanceField))
			return;
		let df = atlas as DistanceFieldFontAtlas;
		if (df == null)
			return;
		let pixels = df.PixelData;
		if (pixels.IsEmpty)
			return;

		// Regions sorted by codepoint: cache files are byte-stable for identical bakes.
		let regions = scope List<CacheRegion>();
		for (let pair in df.Regions)
		{
			var r = CacheRegion();
			r.Codepoint = pair.key;
			r.X = pair.value.X;
			r.Y = pair.value.Y;
			r.Width = pair.value.Width;
			r.Height = pair.value.Height;
			r.OffsetX = pair.value.OffsetX;
			r.OffsetY = pair.value.OffsetY;
			r.AdvanceX = pair.value.AdvanceX;
			regions.Add(r);
		}
		regions.Sort(scope (a, b) => a.Codepoint <=> b.Codepoint);

		var header = CacheHeader();
		header.Magic = cCacheMagic;
		header.Version = cCacheFormatVersion;
		header.Key = key;
		header.PixelRange = df.DistanceFieldRange;
		let white = df.WhitePixelUV;
		header.WhiteU = white.X;
		header.WhiteV = white.Y;
		header.Width = df.Width;
		header.Height = df.Height;
		header.RegionCount = (uint32)regions.Count;
		header.PixelBytes = (uint32)pixels.Length;

		let blob = scope List<uint8>();
		blob.Reserve(sizeof(CacheHeader) + regions.Count * sizeof(CacheRegion) + pixels.Length);
		AppendBytes(blob, &header, sizeof(CacheHeader));
		AppendBytes(blob, regions.Ptr, regions.Count * sizeof(CacheRegion));
		AppendBytes(blob, pixels.Ptr, pixels.Length);

		CreateDirectory(mDirectory);
		let fs = scope NativeFileSystem(mDirectory);
		fs.Save(FileNameFor(key, .. scope .()), blob).IgnoreError();
	}

	/// The key: the font bytes, every option that shapes the bake, and the format version.
	/// Only TTF distance-field bakes are cacheable; RawData is the byte identity.
	private static bool KeyFor(IFont font, FontLoadOptions options, out uint64 outKey)
	{
		outKey = 0;
		if ((options.AtlasMode != .DistanceField) || (font.BackendTypeId != TrueTypeCommon.BackendTypeId))
			return false;
		let ttf = font as TrueTypeFont;
		if (ttf == null)
			return false;
		var key = HashBytes(ttf.RawData, ttf.RawDataSize);
		mixin Mix(uint64 v) { key = HashInteger(key ^ HashInteger(v)); }
		var pixelHeight = options.PixelHeight;
		let heightBits = *(uint32*)&pixelHeight;
		Mix!((uint64)heightBits);
		Mix!((uint64)(uint32)options.FirstCodepoint);
		Mix!((uint64)(uint32)options.LastCodepoint);
		Mix!((uint64)options.AtlasWidth);
		Mix!((uint64)options.AtlasHeight);
		Mix!((uint64)options.Padding);
		Mix!((uint64)cCacheFormatVersion);
		outKey = key;
		return true;
	}

	private static void FileNameFor(uint64 key, String outName)
	{
		const String cHex = "0123456789abcdef";
		for (int32 shift = 60; shift >= 0; shift -= 4)
			outName.Append(cHex[(int)((key >> shift) & 0xF)]);
		outName.Append(".dfatlas");
	}

	private static void AppendBytes(List<uint8> blob, void* data, int size)
	{
		let at = blob.Count;
		blob.Resize(at + size);
		Internal.MemCpy(blob.Ptr + at, data, size);
	}
}
