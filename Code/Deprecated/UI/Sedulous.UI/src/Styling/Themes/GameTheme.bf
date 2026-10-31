using Sedulous.Core;

namespace Sedulous.UI;

/// The dark theme with a game's accent rather than the editor's.
///
/// A game's interface sits over arbitrary scene footage rather than a neutral dock, so it
/// takes a cooler, higher contrast accent than the editor's warm orange.
static class GameTheme
{
	public static ThemePalette Palette()
	{
		var palette = ThemePalette.Dark();
		palette.PrimaryAccent = Color(64 / 255.0f, 200 / 255.0f, 190 / 255.0f, 1.0f);
		return palette;
	}

	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create() => DarkTheme.Create(Palette());
}
