using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// A cache of loaded fonts keyed by path and size, safe to use from several threads.
///
/// A font load is expensive (parse, then bake a whole atlas) and the same font at the same
/// size is asked for every frame, so the cache is not an optimisation but the normal path.
class FontManager
{
	private Monitor mLock = new .() ~ delete _;
	private Dictionary<FontCacheKey, CachedFont> mCache = new .() ~ delete _;
	private FontLoadOptions mDefaultOptions;
	private delegate ITextShaper() mShaperFactory ~ delete _;

	public this(FontLoadOptions defaultOptions = .())
	{
		mDefaultOptions = defaultOptions;
	}

	public ~this()
	{
		DeleteCache();
	}

	/// Sets what makes a shaper for each loaded font, replacing any previous one. Owned
	/// here.
	public void SetShaperFactory(delegate ITextShaper() factory)
	{
		delete mShaperFactory;
		mShaperFactory = factory;
	}

	/// The cached font for this path and size, loading it if it is not there yet.
	///
	/// The load happens OUTSIDE the lock, because a bake is slow and holding the lock
	/// across it would stall every other thread asking for any font at all. The cost is
	/// that two threads can load the same font at once, which the insert below resolves.
	public CachedFont GetFont(StringView path, float pixelHeight)
	{
		let lookupPath = scope String(path);
		let lookupKey = FontCacheKey(lookupPath, pixelHeight);

		using (mLock.Enter())
		{
			if (mCache.TryGetValue(lookupKey, let cached))
			{
				cached.RefCount++;
				return cached;
			}
		}

		var options = mDefaultOptions;
		options.PixelHeight = pixelHeight;

		let parsed = FontParserFactory.ParseFromFile(path, options);
		if (parsed case .Err)
			return null;
		let font = parsed.Value;

		let baked = FontAtlasBakerFactory.Bake(font, options);
		if (baked case .Err)
		{
			delete font;
			return null;
		}

		let shaper = (mShaperFactory != null) ? mShaperFactory() : null;
		let entry = new CachedFont(font, baked.Value, shaper);

		using (mLock.Enter())
		{
			// Another thread may have loaded the same font while this one was working.
			// Theirs is already handed out, so this one is the duplicate and it goes.
			if (mCache.TryGetValue(lookupKey, let existing))
			{
				delete entry; // Frees its font, atlas and shaper too.
				existing.RefCount++;
				return existing;
			}
			// The key OWNS its path string: the caller's view does not outlive this call.
			let key = FontCacheKey(new String(path), pixelHeight);
			mCache[key] = entry;
			return entry;
		}
	}

	public CachedFont GetFont(StringView path) => GetFont(path, mDefaultOptions.PixelHeight);

	/// Gives a reference back. The font stays cached, because whatever wanted it once will
	/// very likely want it again; ClearUnused is what actually frees.
	public void ReleaseFont(CachedFont font)
	{
		if (font == null)
			return;
		using (mLock.Enter())
			font.RefCount--;
	}

	/// Frees every cached font nothing holds a reference to.
	public void ClearUnused()
	{
		using (mLock.Enter())
		{
			let toRemove = scope List<FontCacheKey>();
			for (let pair in mCache)
			{
				if (pair.value.RefCount <= 0)
					toRemove.Add(pair.key);
			}
			for (let key in toRemove)
			{
				if (mCache.GetAndRemove(key) case .Ok(let removed))
				{
					delete removed.value;
					delete removed.key.Path;
				}
			}
		}
	}

	/// Frees everything, references outstanding or not. Only for a teardown that knows
	/// nothing is still drawing.
	public void ClearAll()
	{
		using (mLock.Enter())
			DeleteCache();
	}

	public int CacheCount
	{
		get
		{
			using (mLock.Enter())
				return mCache.Count;
		}
	}

	public bool IsCached(StringView path, float pixelHeight)
	{
		let lookupPath = scope String(path);
		let key = FontCacheKey(lookupPath, pixelHeight);
		using (mLock.Enter())
			return mCache.ContainsKey(key);
	}

	private void DeleteCache()
	{
		for (let pair in mCache)
		{
			delete pair.value;
			delete pair.key.Path;
		}
		mCache.Clear();
	}
}
