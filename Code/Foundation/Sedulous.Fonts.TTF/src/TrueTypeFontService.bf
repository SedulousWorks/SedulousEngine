namespace Sedulous.Fonts.TTF;

using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;
using Sedulous.Fonts.TTF;
using Sedulous.Images;

/// IFontService implementation that loads TrueType / OpenType fonts.
///
/// `LoadFont(name, path, options)` runs the source-format pipeline: parse
/// via `FontParserFactory`, then bake the atlas via `FontAtlasBakerFactory`.
/// The parse + bake steps are TTF-specific and don't appear in
/// `IFontService` itself - that contract is purely about querying cached
/// fonts and their atlas textures.
///
/// Baked `.font` resources go through `BakedFontService` instead. Both
/// implement `IFontService`; consumers don't care which service they're
/// talking to.
public class TrueTypeFontService : IFontService
{
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

	public this()
	{
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

	/// Loads a font from a file path and creates its atlas texture data.
	/// The first font loaded becomes the default.
	public Result<void> LoadFont(StringView familyName, StringView filePath, FontLoadOptions options = .ExtendedLatin)
	{
		// Parse the source font into an IFont via the parser factory.
		IFont font;
		if (FontParserFactory.ParseFromFile(filePath, options) case .Ok(let f))
			font = f;
		else
			return .Err;

		// Bake an atlas for the parsed font via the baker factory.
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
