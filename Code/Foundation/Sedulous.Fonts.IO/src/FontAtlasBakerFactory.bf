using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.IO;

/// Registry + dispatcher for `IFontAtlasBaker` implementations. Bakers are
/// typically registered alongside their matching parsers (see
/// `TrueTypeFonts.Initialize()`); the factory matches a parsed `IFont` to a
/// baker that can produce its atlas.
///
/// Bakers can claim either by extension (format-driven dispatch, used by
/// `BakeFromExtension`) or by capability over the actual IFont type
/// (`Bake`, which walks `CanBake` on each baker).
public static class FontAtlasBakerFactory
{
	private static List<IFontAtlasBaker> sBakers = new .() ~ DeleteContainerAndItems!(_);

	public static void RegisterBaker(IFontAtlasBaker baker)
	{
		if (baker != null && !sBakers.Contains(baker))
			sBakers.Add(baker);
	}

	public static void UnregisterBaker(IFontAtlasBaker baker)
	{
		sBakers.Remove(baker);
	}

	/// First baker that claims the given extension, or null.
	public static IFontAtlasBaker GetBakerForExtension(StringView fileExtension)
	{
		for (let baker in sBakers)
		{
			if (baker.SupportsExtension(fileExtension))
				return baker;
		}
		return null;
	}

	/// Bake an atlas for the given font + options. Picks the first
	/// registered baker that reports `CanBake(font) == true`.
	public static Result<IFontAtlasBaker> GetBakerForFont(IFont font)
	{
		for (let baker in sBakers)
		{
			if (baker.CanBake(font))
				return .Ok(baker);
		}
		return .Err;
	}

	/// Bake an atlas for the given font. Walks registered bakers and picks
	/// the first one that reports `CanBake(font) == true`.
	public static Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options = .Default)
	{
		if (GetBakerForFont(font) case .Ok(let baker))
			return baker.Bake(font, options);
		return .Err(.UnsupportedFormat);
	}

	/// Bake an atlas using the baker registered for the given file
	/// extension. Useful when extension-based dispatch is already in play
	/// (e.g., FontService.LoadFont knows the source format and wants the
	/// matching baker explicitly).
	public static Result<IFontAtlas, FontLoadResult> BakeFromExtension(StringView fileExtension, IFont font, FontLoadOptions options = .Default)
	{
		let baker = GetBakerForExtension(fileExtension);
		if (baker == null)
			return .Err(.UnsupportedFormat);
		return baker.Bake(font, options);
	}

	/// Number of registered bakers.
	public static int BakerCount => sBakers.Count;

	/// Any bakers registered?
	public static bool HasBakers => sBakers.Count > 0;

	/// Clear the registry and free the bakers it owned.
	public static void Shutdown()
	{
		DeleteContainerAndItems!(sBakers);
		sBakers = new .();
	}
}
