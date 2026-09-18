using System.Threading;
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

	/// Serialises Initialize and Shutdown against each other. The font asset builder calls
	/// Initialize per build and the cook runs builds on job workers, so the null check alone
	/// let two of them each construct a baker and register it twice.
	private static Monitor sLock = new .() ~ delete _;

	public static void Initialize()
	{
		using (sLock.Enter())
		{
			if (sBaker != null)
				return;
			sBaker = new DistanceFieldFontAtlasBaker();
			FontAtlasBakerFactory.RegisterBaker(sBaker);
		}
	}

	/// The unregister return guards the delete: somebody may have emptied the registry
	/// wholesale, which already freed what we handed over.
	public static void Shutdown()
	{
		using (sLock.Enter())
		{
			if (sBaker == null)
				return;
			if (FontAtlasBakerFactory.UnregisterBaker(sBaker))
				delete sBaker;
			sBaker = null;
		}
	}

	public static bool IsInitialized => sBaker != null;
}
