namespace Sedulous.Drawing.Fonts;

using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Drawing;

/// Font service implementation that loads fonts and creates atlas textures.
/// This service manages CPU-side font data and atlas pixel data.
/// GPU texture creation is handled by the renderer.
public class FontService : IFontService
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
		// Load font
		IFont font;
		if (FontLoaderFactory.LoadFont(filePath, options) case .Ok(let f))
			font = f;
		else
			return .Err;

		// Create atlas
		IFontAtlas atlas;
		if (FontLoaderFactory.CreateAtlas(font, options) case .Ok(let a))
			atlas = a;
		else
		{
			delete (Object)font;
			return .Err;
		}

		// Get atlas dimensions and pixel data
		let atlasWidth = atlas.Width;
		let atlasHeight = atlas.Height;
		let r8Data = atlas.PixelData;

		// Convert R8 to RGBA8 (white with alpha from R8)
		let pixelCount = (int)(atlasWidth * atlasHeight);
		uint8[] rgba8Data = new uint8[pixelCount * 4];

		for (int i = 0; i < pixelCount; i++)
		{
			rgba8Data[i * 4 + 0] = 255;       // R
			rgba8Data[i * 4 + 1] = 255;       // G
			rgba8Data[i * 4 + 2] = 255;       // B
			rgba8Data[i * 4 + 3] = r8Data[i]; // A
		}

		// Create texture with owned pixel data
		let texture = new OwnedImageData(atlasWidth, atlasHeight, .RGBA8, rgba8Data);

		// Create text shaper for word wrapping support
		let shaper = new TrueTypeTextShaper();
		let cachedFont = new CachedFont(font, atlas, shaper);

		let entry = new FontEntry();
		entry.CachedFont = cachedFont;
		entry.Texture = texture;

		// Use composite key: "FamilyName@PixelHeight"
		let key = new String();
		MakeKey(familyName, options.PixelHeight, key);
		mFonts[key] = entry;

		// First font becomes the default
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
