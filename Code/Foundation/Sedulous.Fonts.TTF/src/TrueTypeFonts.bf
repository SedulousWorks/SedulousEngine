using Sedulous.Fonts;

namespace Sedulous.Fonts.TTF;

/// Static helper for initializing TrueType font support
public static class TrueTypeFonts
{
	private static TrueTypeFontLoader sLoader = null;

	/// Register the TrueType font loader with FontLoaderFactory
	public static void Initialize()
	{
		if (sLoader == null)
		{
			sLoader = new TrueTypeFontLoader();
			FontLoaderFactory.RegisterLoader(sLoader);
		}
	}

	/// Unregister and cleanup
	public static void Shutdown()
	{
		if (sLoader != null)
		{
			FontLoaderFactory.UnregisterLoader(sLoader);
			delete sLoader;
			sLoader = null;
		}
	}

	/// Check if TrueType fonts are initialized
	public static bool IsInitialized => sLoader != null;
}
