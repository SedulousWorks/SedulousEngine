using Sedulous.Fonts;

namespace Sedulous.Fonts.DistanceField.Baker;

/// Registers the distance-field baker, and takes only it back out.
///
/// Only a BAKER, no parser: a distance field is produced from a TrueType font that the
/// TrueType backend parsed, so this rides alongside TrueTypeFonts rather than replacing
/// it. Bring both up, and a .ttf loaded with AtlasMode.DistanceField routes here while
/// the same file loaded for coverage still routes to the raster baker.
static class DistanceFieldFonts
{
	private static DistanceFieldFontAtlasBaker sBaker;

	public static void Initialize()
	{
		if (sBaker != null)
			return;
		sBaker = new DistanceFieldFontAtlasBaker();
		FontAtlasBakerFactory.RegisterBaker(sBaker);
	}

	/// The unregister return guards the delete: somebody may have emptied the registry
	/// wholesale, which already freed what we handed over.
	public static void Shutdown()
	{
		if (sBaker == null)
			return;
		if (FontAtlasBakerFactory.UnregisterBaker(sBaker))
			delete sBaker;
		sBaker = null;
	}

	public static bool IsInitialized => sBaker != null;
}
