using Sedulous.Core;

namespace Sedulous.UI;

/// The editor's dark theme: the same design system as DarkTheme with rounded corners
/// throughout, authored as rounded-dark.sss beside this file.
static class RoundedDarkTheme
{
	/// OWNERSHIP of the sheet transfers.
	///
	/// The DARK palette, the same one the flat dark theme takes, because the two differ in
	/// geometry and nothing else: this is that theme with its corners rounded. A warm palette
	/// is a caller's choice through the overload, not what "rounded dark" means.
	public static StyleSheet Create() => Create(ThemePalette.Dark());

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
