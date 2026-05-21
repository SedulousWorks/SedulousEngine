using Sedulous.Fonts;
using Sedulous.Fonts.IO;

namespace Sedulous.Fonts.TTF;

/// Static helper for initializing TrueType / OpenType font support.
///
/// Registers a `TrueTypeFontParser` with `FontParserFactory` (for parsing
/// .ttf/.ttc/.otf bytes into a queryable IFont) and a
/// `TrueTypeFontAtlasBaker` with `FontAtlasBakerFactory` (for producing
/// renderable atlases from those parsed fonts). Mirrors the
/// `BakedFonts.Initialize(rs)` entry in `Sedulous.Fonts.Resources`.
public static class TrueTypeFonts
{
	private static TrueTypeFontParser sParser = null;
	private static TrueTypeFontAtlasBaker sBaker = null;

	/// Register the TrueType parser + atlas baker with their factories.
	/// Idempotent.
	public static void Initialize()
	{
		if (sParser == null)
		{
			sParser = new TrueTypeFontParser();
			FontParserFactory.RegisterParser(sParser);
		}
		if (sBaker == null)
		{
			sBaker = new TrueTypeFontAtlasBaker();
			FontAtlasBakerFactory.RegisterBaker(sBaker);
		}
	}

	/// Unregister and cleanup.
	public static void Shutdown()
	{
		if (sParser != null)
		{
			FontParserFactory.UnregisterParser(sParser);
			delete sParser;
			sParser = null;
		}
		if (sBaker != null)
		{
			FontAtlasBakerFactory.UnregisterBaker(sBaker);
			delete sBaker;
			sBaker = null;
		}
	}

	/// Returns true once Initialize has registered the TTF parser + baker.
	public static bool IsInitialized => sParser != null && sBaker != null;
}
