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
///
/// A distance field family serves every size from one bake, through scaled views. A coverage
/// family is baked again at each size asked for (once, rounded to whole pixels, from its kept
/// source), so a label's font size is the size it draws at.
class TrueTypeFontService : IFontService
{
	/// Where a family came from, to bake it again at another size.
	private class FamilySource
	{
		public String Family = new .() ~ delete _;
		/// A LoadFont locator; empty for in-memory bytes.
		public String Locator = new .() ~ delete _;
		/// A LoadFontFromMemory face, the service's own copy.
		public List<uint8> Bytes = new .() ~ delete _;
		public FontLoadOptions Options;
	}

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
	private List<FamilySource> mSources = new .() ~ DeleteContainerAndItems!(_);

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
		let result = LoadFontUnremembered(familyName, locator, options);
		if (result == .Success)
			Remember(familyName, locator, default, options);
		return result;
	}

	/// Parses `locator` and bakes it at `options`: LoadFont, and a coverage family's next size.
	private FontLoadResult LoadFontUnremembered(StringView familyName, StringView locator,
		FontLoadOptions options)
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
		let result = BakeFromMemory(familyName, bytes, options);
		if (result == .Success)
			Remember(familyName, "", bytes, options);
		return result;
	}

	private FontLoadResult BakeFromMemory(StringView familyName, Span<uint8> bytes,
		FontLoadOptions options)
	{
		switch (FontParserFactory.ParseFromMemory(bytes, ".ttf", options))
		{
		case .Ok(let font): return CacheFont(familyName, font, options);
		case .Err(let error): return error;
		}
	}

	/// The first load names the family's source; a later one, another size of it, does not.
	private void Remember(StringView familyName, StringView locator, Span<uint8> bytes,
		FontLoadOptions options)
	{
		for (let source in mSources)
		{
			if (FamilyEquals(source.Family, familyName))
				return;
		}
		let source = new FamilySource();
		source.Family.Set(familyName);
		source.Locator.Set(locator);
		source.Bytes.AddRange(bytes);
		source.Options = options;
		mSources.Add(source);
	}

	/// A coverage family baked at `pixelHeight`, rounded to whole pixels from 4 to 256, its atlas
	/// grown until the glyphs fit (to 4096 a side). Null when the family has no kept source or
	/// the bake fails, and the caller then draws with the closest bake.
	private CachedFont BakeSize(StringView familyName, float pixelHeight)
	{
		FamilySource source = null;
		for (let candidate in mSources)
		{
			if (FamilyEquals(candidate.Family, familyName))
			{
				source = candidate;
				break;
			}
		}
		if ((source == null) || (source.Options.AtlasMode == .DistanceField))
			return null;

		let rounded = Clamp(Math.Round(pixelHeight), 4.0f, 256.0f);
		if (FindExact(familyName, rounded) case .Ok(let exact))
			return exact.Cached;

		var options = source.Options;
		options.PixelHeight = rounded;
		// The atlas the family loaded with, grown with the size: glyph area goes with its square.
		let grow = Math.Max(1.0f, rounded / Math.Max(source.Options.PixelHeight, 1.0f));
		var side = Math.Max(source.Options.AtlasWidth, source.Options.AtlasHeight);
		while (((float)side < (float)source.Options.AtlasWidth * grow) && (side < 4096))
			side *= 2;
		while (true)
		{
			options.AtlasWidth = side;
			options.AtlasHeight = side;
			var result = FontLoadResult.Unknown;
			if (!source.Bytes.IsEmpty)
				result = BakeFromMemory(familyName, source.Bytes, options);
			else if (!source.Locator.IsEmpty)
				result = LoadFontUnremembered(familyName, source.Locator, options);
			if (result == .Success)
				return (FindExact(familyName, rounded) case .Ok(let made)) ? made.Cached : null;
			if ((result != .AtlasPackingFailed) || (side >= 4096))
				return null;
			side *= 2;
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

			// A coverage atlas holds glyphs at its one size: drawn at another, the text came out
			// at the bake's size whatever was asked (every label in a game without a UI font drew
			// alike). Bake the size asked for, once, from the family's source.
			if (let baked = BakeSize(familyName, pixelHeight))
				return baked;
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
		// The size's own bake, if it wants one.
		GetFont(familyName, pixelHeight);
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
