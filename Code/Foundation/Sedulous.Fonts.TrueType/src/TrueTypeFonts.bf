using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// Brings the backend up and takes it back down.
///
/// The two slots are what make this pair honest. Initialize is IDEMPOTENT, so a host
/// bringing the backend up twice does not end up consulted twice; and Shutdown removes
/// only THIS backend's entries, so a process running several font backends does not lose
/// the others when one of them goes down.
static class TrueTypeFonts
{
	private static TrueTypeFontParser sParser;
	private static TrueTypeFontAtlasBaker sBaker;

	/// Registers the parser and the baker, so a load of a .ttf routes here without anything
	/// naming this library.
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

	/// Takes both back out and frees them, leaving anything else registered alone.
	///
	/// The unregister return is what guards the delete: somebody may have emptied the
	/// registry wholesale, which already deleted what we handed over, and the slot is then
	/// a dangling pointer to drop rather than a thing to free.
	public static void Shutdown()
	{
		if (sParser != null)
		{
			if (FontParserFactory.UnregisterParser(sParser))
				delete sParser;
			sParser = null;
		}
		if (sBaker != null)
		{
			if (FontAtlasBakerFactory.UnregisterBaker(sBaker))
				delete sBaker;
			sBaker = null;
		}
	}

	/// Whether the backend is currently registered.
	public static bool IsInitialized => sParser != null;
}
