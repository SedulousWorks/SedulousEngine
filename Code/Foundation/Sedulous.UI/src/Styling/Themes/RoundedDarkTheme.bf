using Sedulous.Core;

namespace Sedulous.UI;

/// The editor's dark theme: the same design system as DarkTheme with rounded corners
/// throughout, authored as rounded-dark.sss beside this file.
static class RoundedDarkTheme
{
	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create() => Create(ThemePalette.GraphiteOrange());

	public static StyleSheet Create(ThemePalette palette)
	{
		let loader = scope StyleSheetLoader();
		loader.SetPalette(palette);

		let sheet = loader.Load(EmbeddedThemes.RoundedDark);
		if (sheet == null)
			return null;

		ThemeRegistry.ApplyExtensions(sheet, palette);
		return sheet;
	}
}
