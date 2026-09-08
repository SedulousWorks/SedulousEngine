using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VFS;

namespace Sedulous.Fonts.TrueType;

/// A font service over real TrueType and OpenType files.
///
/// Loads through the source format pipeline: parse, bake an atlas, expand it to something a
/// renderer can upload. With a file system set, a locator is a path opened through it;
/// without one it is a disk path, which is what a sandbox or a tool wants.
class TrueTypeFontService : IFontService
{
	/// One family at one baked size, with the texture its atlas expanded to.
	private class FontEntry
	{
		public String Family = new String() ~ delete _;
		public float PixelHeight;
		/// Owns its font, atlas and shaper.
		public CachedFont Cached;
		/// Owned unless SharedTexture, in which case it belongs to the base entry.
		public OwnedImageData Texture;
		public bool SharedTexture;
	}

	private IFileSystem mFileSystem;
	private List<FontEntry> mFonts = new .() ~ delete _;
	private String mDefaultFamily = new String("Default") ~ delete _;
	private CachedFont mDefaultFont;

	/// `fileSystem` is optional and BORROWED.
	public this(IFileSystem fileSystem = null)
	{
		mFileSystem = fileSystem;
		TrueTypeFonts.Initialize();
	}

	public ~this()
	{
		for (let entry in mFonts)
			DeleteEntry(entry);
		mFonts.Clear();
	}

	/// Loads a family from a locator and bakes its atlas. The FIRST font loaded becomes the
	/// default, so a host that loads one never has to name it again.
	public FontLoadResult LoadFont(StringView familyName, StringView locator,
		FontLoadOptions options = .ExtendedLatin())
	{
		IFont font = null;
		if (mFileSystem != null)
		{
			let stream = mFileSystem.Open(locator, .Read);
			if (stream == null)
				return .FileNotFound;
			defer delete stream;

			let fileExtension = PathExtension(locator, .. scope String());
			switch (FontParserFactory.ParseFromStream(stream, fileExtension, options))
			{
			case .Ok(let parsed): font = parsed;
			case .Err(let error): return error;
			}
		}
		else
		{
			switch (FontParserFactory.ParseFromFile(locator, options))
			{
			case .Ok(let parsed): font = parsed;
			case .Err(let error): return error;
			}
		}

		return CacheFont(familyName, font, options);
	}

	/// Loads a family from TTF or OTF bytes already in memory: the EMBEDDED fallback, so a
	/// relocated build still has a face whatever the disk looks like.
	public FontLoadResult LoadFontFromMemory(StringView familyName, Span<uint8> bytes,
		FontLoadOptions options = .ExtendedLatin())
	{
		switch (FontParserFactory.ParseFromMemory(bytes, ".ttf", options))
		{
		case .Ok(let font): return CacheFont(familyName, font, options);
		case .Err(let error): return error;
		}
	}

	/// Changes which family GetFont(pixelHeight) answers with.
	public void SetDefaultFamily(StringView name) => mDefaultFamily.Set(name);

	// ---- IFontService ----

	public override void GetDefaultFontFamily(String outFamily) => outFamily.Set(mDefaultFamily);

	public override CachedFont GetFont(float pixelHeight) => GetFont(mDefaultFamily, pixelHeight);

	public override CachedFont GetFont(StringView familyName, float pixelHeight)
	{
		if (FindExact(familyName, pixelHeight) case .Ok(let exact))
			return exact.Cached;

		if (FindClosest(familyName, pixelHeight) case .Ok(let closest))
		{
			// A distance field family serves EVERY size from one bake, so a request for a
			// size it was not baked at gets a scaled view rather than the bake's own
			// tables, which would shape glyphs at the bake size and place them at this one.
			if ((closest.Cached != null) && (closest.Cached.Atlas != null)
				&& (closest.Cached.Atlas.Mode == .DistanceField)
				&& (closest.PixelHeight != pixelHeight))
				return SynthesizeScaled(closest, familyName, pixelHeight);

			return closest.Cached;
		}
		return mDefaultFont;
	}

	public override ImageData GetAtlasTexture(CachedFont font)
	{
		for (let entry in mFonts)
		{
			if (entry.Cached == font)
				return entry.Texture;
		}
		return null;
	}

	public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight)
	{
		if (FindExact(familyName, pixelHeight) case .Ok(let exact))
			return exact.Texture;
		if (FindClosest(familyName, pixelHeight) case .Ok(let closest))
			return closest.Texture;

		for (let entry in mFonts)
		{
			if (entry.Cached == mDefaultFont)
				return entry.Texture;
		}
		return null;
	}

	/// The service owns its fonts, so giving one back is nothing to do.
	public override void ReleaseFont(CachedFont font) {}

	public int FontCount => mFonts.Count;

	// ---- internals ----

	private void DeleteEntry(FontEntry entry)
	{
		if (entry == null)
			return;

		// Frees the font, the atlas and the shaper as one.
		delete entry.Cached;
		if (!entry.SharedTexture)
			delete entry.Texture;
		delete entry;
	}

	/// A per size entry over a distance field base: the views BORROW the base's font and
	/// atlas, the CachedFont owns the views and its own shaper, and the entry shares the
	/// base's texture. Kept in the list so the next request for this size finds it exactly.
	private CachedFont SynthesizeScaled(FontEntry @base, StringView familyName, float pixelHeight)
	{
		let fontView = new ScaledFontView(@base.Cached.Font, pixelHeight);
		let atlasView = new ScaledFontAtlasView(@base.Cached.Atlas, fontView.Scale);
		let cached = new CachedFont(fontView, atlasView, new TrueTypeTextShaper());

		let entry = new FontEntry();
		entry.Family.Set(familyName);
		entry.PixelHeight = pixelHeight;
		entry.Cached = cached;
		entry.Texture = @base.Texture;
		entry.SharedTexture = true;
		mFonts.Add(entry);
		return cached;
	}

	/// Bakes, expands and records. TAKES OWNERSHIP of `font`, which it deletes on any
	/// failure.
	private FontLoadResult CacheFont(StringView familyName, IFont font, FontLoadOptions options)
	{
		IFontAtlas atlas = null;
		switch (FontAtlasBakerFactory.Bake(font, options))
		{
		case .Ok(let baked): atlas = baked;
		case .Err(let error):
			delete font;
			return error;
		}

		// A distance field atlas already holds RGBA texels, the signed distance channels,
		// and is wrapped LINEAR: the field is geometry, not colour, and an sRGB decode
		// would bend it. A coverage atlas is single channel and expands to RGBA8.
		let texture = (atlas.Mode == .DistanceField)
			? new OwnedImageData(atlas.Width, atlas.Height, .RGBA8, atlas.PixelData, .Linear)
			: FontAtlasTexture.ExpandR8ToRGBA8(atlas);
		if (texture == null)
		{
			delete atlas;
			delete font;
			return .OutOfMemory;
		}

		let entry = new FontEntry();
		entry.Family.Set(familyName);
		entry.PixelHeight = options.PixelHeight;
		entry.Cached = new CachedFont(font, atlas, new TrueTypeTextShaper());
		entry.Texture = texture;
		mFonts.Add(entry);

		if (mDefaultFont == null)
		{
			mDefaultFont = entry.Cached;
			mDefaultFamily.Set(familyName);
		}
		return .Success;
	}

	/// Case insensitive, because a family is written however the caller felt like writing it.
	private static bool FamilyEquals(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;

		for (int i < a.Length)
		{
			if (a[i].ToLower != b[i].ToLower)
				return false;
		}
		return true;
	}

	private Result<FontEntry> FindExact(StringView family, float pixelHeight)
	{
		for (let entry in mFonts)
		{
			if (FamilyEquals(entry.Family, family) && (Abs(entry.PixelHeight - pixelHeight) < 0.001f))
				return .Ok(entry);
		}
		return .Err;
	}

	/// The nearest BAKED size. A synthesized entry is skipped: scaling a scaled view would
	/// compound the two scales.
	private Result<FontEntry> FindClosest(StringView family, float pixelHeight)
	{
		FontEntry best = null;
		var bestDifference = FloatMax;

		for (let entry in mFonts)
		{
			if (entry.SharedTexture || !FamilyEquals(entry.Family, family))
				continue;

			let difference = Abs(entry.PixelHeight - pixelHeight);
			if (difference < bestDifference)
			{
				bestDifference = difference;
				best = entry;
			}
		}

		if (best == null)
			return .Err;
		return .Ok(best);
	}
}
