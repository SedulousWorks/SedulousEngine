namespace Sedulous.Fonts.Resources;

using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Images;
using Sedulous.Resources;

/// IFontService implementation that loads `.font` baked resources.
///
/// Mirrors `TrueTypeFontService` in cache shape and IFontService surface,
/// but the underlying font + atlas come from a serialized resource (loaded
/// through the resource system) instead of TTF parse + atlas bake. No
/// stb_truetype dependency.
///
/// `LoadFont(name, uri)` keys the cache by `FamilyName@PixelHeight`, where
/// PixelHeight is read from the resource (it was decided at bake time, not
/// at load time).
public class BakedFontService : IFontService
{
	private ResourceSystem mResourceSystem; // not owned

	// Key format: "FamilyName@PixelHeight" (e.g., "Roboto@16", "Roboto@32")
	private Dictionary<String, FontEntry> mFonts = new .() ~ { for (let kv in _) { delete kv.key; delete kv.value; } delete _; };
	private String mDefaultFontFamily = new .("Default") ~ delete _;
	private CachedFont mDefaultFont;
	private float mDefaultFontSize = 16;

	/// One loaded font + its atlas texture. Holds the ResourceHandle that
	/// keeps the underlying FontResource alive; on destruction we null out
	/// the CachedFont's Font/Atlas pointers (they're owned by the resource,
	/// not us) before disposing it, then release the handle so the resource
	/// system can free the actual BakedFont + BakedFontAtlas.
	private class FontEntry
	{
		public CachedFont CachedFont;
		public OwnedImageData Texture ~ delete _;
		public ResourceHandle<FontResource> Handle;

		public ~this()
		{
			// Disown the borrowed font + atlas before CachedFont's destructor
			// runs - the resource owns them, not us.
			if (CachedFont != null)
			{
				CachedFont.Font = null;
				CachedFont.Atlas = null;
				delete CachedFont;
			}
			Handle.Release();
		}
	}

	public this(ResourceSystem resourceSystem)
	{
		mResourceSystem = resourceSystem;
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

	/// Load a baked font from a resource URI. The pixel height is read from
	/// the resource itself (baked at edit time). The first font loaded
	/// becomes the default.
	public Result<void> LoadFont(StringView familyName, StringView uri)
	{
		if (mResourceSystem == null)
			return .Err;

		// Acquire a refcounted handle to the FontResource. We hold it on the
		// FontEntry so the resource (and its owned BakedFont/BakedFontAtlas)
		// stays alive for the service's lifetime.
		ResourceHandle<FontResource> handle;
		if (mResourceSystem.LoadResource<FontResource>(uri) case .Ok(let h))
			handle = h;
		else
			return .Err;

		let fontRes = handle.Resource;
		if (fontRes == null || !fontRes.IsValid)
		{
			handle.Release();
			return .Err;
		}

		// Expand the R8 atlas to RGBA8 for the renderer.
		let texture = FontAtlasTexture.ExpandR8ToRGBA8(fontRes.Atlas);
		if (texture == null)
		{
			handle.Release();
			return .Err;
		}

		// Wrap the (borrowed) font + atlas in a CachedFont. The entry's
		// destructor nulls these pointers before disposing CachedFont to
		// avoid double-freeing what the resource owns.
		let cachedFont = new CachedFont(fontRes.Font, fontRes.Atlas, null);

		let entry = new FontEntry();
		entry.CachedFont = cachedFont;
		entry.Texture = texture;
		entry.Handle = handle;

		let pixelHeight = fontRes.BakedFont.PixelHeight;
		let key = new String();
		MakeKey(familyName, pixelHeight, key);
		mFonts[key] = entry;

		// First font loaded becomes the default.
		if (mDefaultFont == null)
		{
			mDefaultFont = cachedFont;
			mDefaultFontFamily.Set(familyName);
			mDefaultFontSize = pixelHeight;
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
