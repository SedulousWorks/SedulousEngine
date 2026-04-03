using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Fonts;

/// Font manager with caching for multiple sizes
/// Thread-safe for concurrent access
public class FontManager
{
	private Monitor mLock = new .() ~ delete _;
	private Dictionary<FontCacheKey, CachedFont> mCache = new .() ~ DeleteCache();
	private FontLoadOptions mDefaultOptions;
	private delegate ITextShaper() mShaperFactory ~ delete _;

	public this(FontLoadOptions defaultOptions = .Default)
	{
		mDefaultOptions = defaultOptions;
	}

	private void DeleteCache()
	{
		for (var kv in mCache)
		{
			var key = kv.key;
			key.Dispose();
			delete kv.value;
		}
		delete mCache;
	}

	/// Set a factory function for creating text shapers
	public void SetShaperFactory(delegate ITextShaper() factory)
	{
		delete mShaperFactory;
		mShaperFactory = factory;
	}

	/// Get or load a font at the specified pixel height
	/// Returns null if loading fails
	public CachedFont GetFont(StringView path, float pixelHeight)
	{
		var lookupKey = FontCacheKey(path, pixelHeight);
		defer lookupKey.Dispose();

		// Check cache first
		using (mLock.Enter())
		{
			if (mCache.TryGetValue(lookupKey, let cached))
			{
				cached.RefCount++;
				return cached;
			}
		}

		// Load outside lock to avoid blocking other threads
		var options = mDefaultOptions;
		options.PixelHeight = pixelHeight;

		IFont font = null;
		IFontAtlas atlas = null;
		ITextShaper shaper = null;

		if (FontLoaderFactory.LoadFont(path, options) case .Ok(let loadedFont))
		{
			font = loadedFont;

			if (FontLoaderFactory.CreateAtlas(font, options) case .Ok(let loadedAtlas))
			{
				atlas = loadedAtlas;

				// Create shaper if factory is set
				if (mShaperFactory != null)
					shaper = mShaperFactory();
			}
			else
			{
				delete (Object)font;
				return null;
			}
		}
		else
		{
			return null;
		}

		let entry = new CachedFont(font, atlas, shaper);

		// Insert into cache with double-check
		using (mLock.Enter())
		{
			var storeKey = FontCacheKey(path, pixelHeight);

			// Check if another thread loaded it while we were loading
			if (mCache.TryGetValue(storeKey, let existing))
			{
				storeKey.Dispose();
				delete entry;
				existing.RefCount++;
				return existing;
			}

			mCache[storeKey] = entry;
			return entry;
		}
	}

	/// Get font with default size from options
	public CachedFont GetFont(StringView path)
	{
		return GetFont(path, mDefaultOptions.PixelHeight);
	}

	/// Release a reference to a cached font
	/// The font stays in cache for potential reuse
	public void ReleaseFont(CachedFont font)
	{
		if (font == null)
			return;

		using (mLock.Enter())
		{
			font.RefCount--;
		}
	}

	/// Clear fonts with zero references from cache
	public void ClearUnused()
	{
		using (mLock.Enter())
		{
			let toRemove = scope List<FontCacheKey>();

			for (var kv in mCache)
			{
				if (kv.value.RefCount <= 0)
					toRemove.Add(kv.key);
			}

			for (var key in toRemove)
			{
				if (mCache.TryGetValue(key, let entry))
				{
					mCache.Remove(key);
					var k = key;
					k.Dispose();
					delete entry;
				}
			}
		}
	}

	/// Clear all cached fonts (use with caution)
	public void ClearAll()
	{
		using (mLock.Enter())
		{
			for (var kv in mCache)
			{
				var key = kv.key;
				key.Dispose();
				delete kv.value;
			}
			mCache.Clear();
		}
	}

	/// Get number of cached fonts
	public int CacheCount
	{
		get
		{
			using (mLock.Enter())
				return mCache.Count;
		}
	}

	/// Check if a font is already cached
	public bool IsCached(StringView path, float pixelHeight)
	{
		var key = FontCacheKey(path, pixelHeight);
		defer key.Dispose();

		using (mLock.Enter())
			return mCache.ContainsKey(key);
	}
}
