using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// The registered bakers, dispatch to them, and the optional bake cache.
///
/// Owns what is registered, exactly as FontParserFactory does.
static class FontAtlasBakerFactory
{
	private static List<IFontAtlasBaker> sBakers = new .() ~ DeleteContainerAndItems!(_);
	/// NOT owned: the app installs this and the app frees it.
	private static IFontAtlasCache sCache = null;

	public static void RegisterBaker(IFontAtlasBaker baker)
	{
		if (baker == null)
			return;
		for (let existing in sBakers)
		{
			if (existing === baker)
				return;
		}
		sBakers.Add(baker);
	}

	/// Takes a baker back out AND gives ownership back: the caller deletes it.
	public static void UnregisterBaker(IFontAtlasBaker baker)
	{
		for (int i < sBakers.Count)
		{
			if (sBakers[i] === baker)
			{
				sBakers.RemoveAt(i);
				return;
			}
		}
	}

	public static IFontAtlasBaker GetBakerForExtension(StringView fileExtension)
	{
		for (let baker in sBakers)
		{
			if (baker.SupportsExtension(fileExtension))
				return baker;
		}
		return null;
	}

	public static IFontAtlasBaker GetBakerForFont(IFont font)
	{
		for (let baker in sBakers)
		{
			if (baker.CanBake(font))
				return baker;
		}
		return null;
	}

	/// The options aware pick, which routes a distance field request to the distance field
	/// baker and a coverage request to the raster one even though both take the same font.
	public static IFontAtlasBaker GetBakerForFont(IFont font, FontLoadOptions options)
	{
		for (let baker in sBakers)
		{
			if (baker.CanBake(font, options))
				return baker;
		}
		return null;
	}

	/// Installs the bake cache, or clears it with null. App owned; never freed here.
	public static void SetAtlasCache(IFontAtlasCache cache) => sCache = cache;
	public static IFontAtlasCache AtlasCache => sCache;

	/// Bakes an atlas, consulting the cache first.
	///
	/// The baker is picked BEFORE the cache is asked, so an unbakeable font is refused
	/// rather than answered out of a cache that happens to hold something for it.
	public static Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
	{
		let baker = GetBakerForFont(font, options);
		if (baker == null)
			return .Err(.UnsupportedFormat);

		if (sCache != null)
		{
			let cached = sCache.TryLoad(font, options);
			if (cached != null)
				return .Ok(cached);
		}

		let baked = baker.Bake(font, options);
		if (baked case .Ok(let atlas))
		{
			if (sCache != null)
				sCache.Store(font, options, atlas);
		}
		return baked;
	}

	public static Result<IFontAtlas, FontLoadResult> BakeFromExtension(StringView fileExtension,
		IFont font, FontLoadOptions options)
	{
		let baker = GetBakerForExtension(fileExtension);
		if (baker == null)
			return .Err(.UnsupportedFormat);
		return baker.Bake(font, options);
	}

	public static int BakerCount => sBakers.Count;
	public static bool HasBakers => !sBakers.IsEmpty;

	/// Empties the registry and deletes the bakers it still owns. Leaves the cache alone,
	/// which the app owns.
	public static void Shutdown()
	{
		ClearAndDeleteItems!(sBakers);
	}
}
