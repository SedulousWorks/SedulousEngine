using Sedulous.Core;

namespace Sedulous.UI;

/// The light theme, authored as light.sss beside this file.
static class LightTheme
{
	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create() => Create(ThemePalette.Light());

	public static StyleSheet Create(ThemePalette palette)
	{
		let loader = scope StyleSheetLoader();
		loader.SetPalette(palette);

		let sheet = loader.Load(EmbeddedThemes.Light);
		if (sheet == null)
			return null;

		ThemeRegistry.ApplyExtensions(sheet, palette);
		return sheet;
	}
}
