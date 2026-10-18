using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.HarfBuzz;

/// Real text shaping behind the engine's ITextShaper: ligatures, Arabic joining, Indic
/// reordering, marks placed by the font's own tables. Install makes it the shaper every font
/// service hands out (TextShaperFactory); a font whose file is not at hand (a hand-built table)
/// is shaped by the basic shaper instead. No HarfBuzz type crosses this interface.
static class HarfBuzzShaping
{
	private static bool sInstalled = false;

	/// Registers the HarfBuzz shaper with TextShaperFactory (idempotent): fonts made after this
	/// shape through it.
	public static void Install()
	{
		TextShaperFactory.Register(=> CreateShaper);
		sInstalled = true;
	}

	/// Unregisters it: fonts made after this get the basic shaper again.
	public static void Uninstall()
	{
		TextShaperFactory.Unregister(=> CreateShaper);
		sInstalled = false;
	}

	public static bool IsInstalled => sInstalled;

	/// A HarfBuzz shaper, which the caller owns.
	public static ITextShaper CreateShaper() => new HarfBuzzTextShaper();
}
