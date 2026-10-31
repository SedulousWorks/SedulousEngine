using Sedulous.Core;

namespace Sedulous.UI;

/// The default dark theme.
///
/// AUTHORED as dark.sss beside this file and parsed here, rather than built rule by rule in
/// code. The sheet is the theme; this is only the door to it.
static class DarkTheme
{
	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create() => Create(ThemePalette.Dark());

	/// The same theme against a different palette, which is how one sheet serves several
	/// looks: the .sss names palette variables and the loader binds them.
	public static StyleSheet Create(ThemePalette palette)
	{
		let loader = scope StyleSheetLoader();
		loader.SetPalette(palette);

		let sheet = loader.Load(EmbeddedThemes.Dark);
		if (sheet == null)
			return null;

		// Extensions last, so a registered one can override what the sheet declared.
		ThemeRegistry.ApplyExtensions(sheet, palette);
		return sheet;
	}
}
