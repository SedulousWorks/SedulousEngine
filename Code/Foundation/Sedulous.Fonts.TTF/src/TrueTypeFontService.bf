namespace Sedulous.Fonts.TTF;

using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;
using Sedulous.Fonts.TTF;
using Sedulous.Images;
using Sedulous.VFS;

/// IFontService implementation that loads TrueType / OpenType fonts.
///
/// `LoadFont(name, locator, options)` runs the source-format pipeline:
/// parse via `FontParserFactory`, then bake the atlas via
/// `FontAtlasBakerFactory`. The parse + bake steps are TTF-specific and
/// don't appear in `IFontService` itself - that contract is purely about
/// querying cached fonts and their atlas textures.
///
/// When constructed with an `IMount`, the `locator` argument to `LoadFont`
/// is interpreted as a VFS path relative to that mount and the bytes are
/// opened through the mount. With a null mount the service falls back to
/// reading from disk, treating `locator` as a file path - kept around for
/// sandboxes / tools / tests that don't have VFS set up.
///
/// Baked `.font` resources go through `BakedFontService` instead. Both
/// implement `IFontService`; consumers don't care which service they're
/// talking to.
public class TrueTypeFontService : IFontService
{
	// Optional VFS mount. When set, LoadFont treats locator as a path
	// relative to this mount; otherwise locator is a disk path.
	// Non-owning - the application owns the mount.
	private IMount mMount;

	// Key format: "FamilyName@PixelHeight" (e.g., "Roboto@16", "Roboto@32")
	private Dictionary<String, FontEntry> mFonts = new .() ~ { for (let kv in _) { delete kv.key; delete kv.value; } delete _; };
	private String mDefaultFontFamily = new .("Default") ~ delete _;
	private CachedFont mDefaultFont;
	private float mDefaultFontSize = 16;

	/// A loaded font entry with its atlas texture.
	private class FontEntry
	{
		public CachedFont CachedFont;
		public OwnedImageData Texture ~ delete _;

		public ~this()
		{
			delete CachedFont;
		}
	}

	public this(IMount mount)
	{
		mMount = mount;
		TrueTypeFonts.Initialize();
	}

	/// Helper to create a composite key from family name and pixel height.
	private void MakeKey(StringView familyName, float pixelHeight, String outKey)
	{
		outKey.AppendF("{}@{}", familyName, (int32)pixelHeight);
	}

	/// Helper to extract family name from a composite key.
	private void ExtractFamilyName(StringView key, String outFamily)
	{
		let atIndex = key.IndexOf('@');
		if (atIndex >= 0)
			outFamily.Append(key.Substring(0, atIndex));
		else
			outFamily.Append(key);
	}

	/// Helper to extract pixel height from a composite key.
	private float ExtractPixelHeight(StringView key)
	{
		let atIndex = key.IndexOf('@');
		if (atIndex >= 0 && atIndex < key.Length - 1)
		{
			let heightStr = key.Substring(atIndex + 1);
			if (int32.Parse(heightStr) case .Ok(let h))
				return (float)h;
		}
		return 16; // Default
	}

	/// Loads a font from `locator` and creates its atlas texture data.
	/// When this service was constructed with a mount, `locator` is a VFS
	/// path relative to that mount. Otherwise `locator` is a disk path.
	/// The first font loaded becomes the default.
	public Result<void> LoadFont(StringView familyName, StringView locator, FontLoadOptions options = .ExtendedLatin)
	{
		IFont font;
		if (mMount != null)
		{
			// Open through the mount and parse from the resulting stream.
			let openResult = mMount.Open(locator);
			if (openResult case .Err)
				return .Err;
			let stream = openResult.Value;
			defer delete stream;

			// Format hint from the locator extension - the parser factory
			// uses it to pick the matching parser.
			let ext = Path.GetExtension(locator, .. scope .());
			if (FontParserFactory.ParseFromStream(stream, ext, options) case .Ok(let f))
				font = f;
			else
				return .Err;
		}
		else
		{
			// Disk-path fallback for sandboxes / tools / tests that don't
			// have VFS set up.
			if (FontParserFactory.ParseFromFile(locator, options) case .Ok(let f))
				font = f;
			else
				return .Err;
		}

		return CacheFont(familyName, font, options);
	}

	/// Bakes an atlas for the parsed font, wraps everything in a
	/// CachedFont, inserts it into the cache, and updates the default
	/// font tracking. Takes ownership of `font` - on failure it's
	/// deleted before returning.
	private Result<void> CacheFont(StringView familyName, IFont font, FontLoadOptions options)
	{
		IFontAtlas atlas;
		if (FontAtlasBakerFactory.Bake(font, options) case .Ok(let a))
			atlas = a;
		else
		{
			delete (Object)font;
			return .Err;
		}

		// Expand the R8 atlas into an RGBA8 texture for the renderer.
		let texture = FontAtlasTexture.ExpandR8ToRGBA8(atlas);
		if (texture == null)
		{
			delete (Object)atlas;
			delete (Object)font;
			return .Err;
		}

		// Wrap font + atlas + shaper in a CachedFont for IFontService queries.
		let shaper = new TrueTypeTextShaper();
		let cachedFont = new CachedFont(font, atlas, shaper);

		let entry = new FontEntry();
		entry.CachedFont = cachedFont;
		entry.Texture = texture;

		let key = new String();
		MakeKey(familyName, options.PixelHeight, key);
		mFonts[key] = entry;

		// First font loaded becomes the default.
		if (mDefaultFont == null)
		{
			mDefaultFont = cachedFont;
			mDefaultFontFamily.Set(familyName);
			mDefaultFontSize = options.PixelHeight;
		}

		return .Ok;
	}

	// ==================== IFontService Implementation ====================

	public StringView DefaultFontFamily => mDefaultFontFamily;

	/// Change the default font family used when GetFont(pixelHeight) is called.
	public void SetDefaultFamily(StringView name)
	{
		mDefaultFontFamily.Set(name);
	}

	public CachedFont GetFont(float pixelHeight)
	{
		return GetFont(mDefaultFontFamily, pixelHeight);
	}

	public CachedFont GetFont(StringView familyName, float pixelHeight)
	{
		// First try exact match
		let exactKey = scope String();
		MakeKey(familyName, pixelHeight, exactKey);
		if (mFonts.TryGetValue(exactKey, let entry))
			return entry.CachedFont;

		// Find closest available size for this family
		CachedFont bestMatch = null;
		float bestDiff = float.MaxValue;

		for (let kv in mFonts)
		{
			let keyFamily = scope String();
			ExtractFamilyName(kv.key, keyFamily);

			if (StringView.Compare(keyFamily, familyName, true) == 0)
			{
				let keySize = ExtractPixelHeight(kv.key);
				let diff = Math.Abs(keySize - pixelHeight);
				if (diff < bestDiff)
				{
					bestDiff = diff;
					bestMatch = kv.value.CachedFont;
				}
			}
		}

		if (bestMatch != null)
			return bestMatch;

		return mDefaultFont;
	}

	public IImageData GetAtlasTexture(CachedFont font)
	{
		for (let kv in mFonts)
		{
			if (kv.value.CachedFont == font)
				return kv.value.Texture;
		}
		return null;
	}

	public IImageData GetAtlasTexture(StringView familyName, float pixelHeight)
	{
		// First try exact match
		let exactKey = scope String();
		MakeKey(familyName, pixelHeight, exactKey);
		if (mFonts.TryGetValue(exactKey, let entry))
			return entry.Texture;

		// Find closest available size for this family
		FontEntry bestMatch = null;
		float bestDiff = float.MaxValue;

		for (let kv in mFonts)
		{
			let keyFamily = scope String();
			ExtractFamilyName(kv.key, keyFamily);

			if (StringView.Compare(keyFamily, familyName, true) == 0)
			{
				let keySize = ExtractPixelHeight(kv.key);
				let diff = Math.Abs(keySize - pixelHeight);
				if (diff < bestDiff)
				{
					bestDiff = diff;
					bestMatch = kv.value;
				}
			}
		}

		if (bestMatch != null)
			return bestMatch.Texture;

		// Fall back to default
		for (let kv in mFonts)
		{
			if (kv.value.CachedFont == mDefaultFont)
				return kv.value.Texture;
		}
		return null;
	}

	public void ReleaseFont(CachedFont font)
	{
		// Fonts are managed by this service - no-op
	}
}
