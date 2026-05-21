using System;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;

namespace Sedulous.Fonts.TTF;

/// IFontAtlasBaker implementation for TrueType / OpenType fonts.
///
/// Bakes a `TrueTypeFont` into a `TrueTypeFontAtlas` by running
/// stb_truetype's pack-font-range. Requires the IFont to be a concrete
/// `TrueTypeFont`; falls back with `.UnsupportedFormat` otherwise.
///
/// Typically registered alongside `TrueTypeFontParser` via
/// `TrueTypeFonts.Initialize()`.
public class TrueTypeFontAtlasBaker : IFontAtlasBaker
{
	private static StringView[?] sSupportedExtensions = .(".ttf", ".ttc", ".otf");

	public Span<StringView> SupportedExtensions => sSupportedExtensions;

	public bool SupportsExtension(StringView fileExtension)
	{
		let lowerExt = scope String(fileExtension);
		lowerExt.ToLower();

		for (let ext in sSupportedExtensions)
		{
			if (lowerExt == ext)
				return true;
		}
		return false;
	}

	public bool CanBake(IFont font)
	{
		return font is TrueTypeFont;
	}

	public Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
	{
		let ttfFont = font as TrueTypeFont;
		if (ttfFont == null)
			return .Err(.UnsupportedFormat);

		let atlas = new TrueTypeFontAtlas();
		if (atlas.Create(ttfFont, options) case .Err(let err))
		{
			delete atlas;
			return .Err(err);
		}

		return .Ok(atlas);
	}
}
