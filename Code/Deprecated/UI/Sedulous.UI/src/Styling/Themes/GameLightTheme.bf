using Sedulous.Core;

namespace Sedulous.UI;

/// The light theme with the same teal game accent, for interfaces sitting on bright scenes.
///
/// Swapped per context rather than chosen once, since a game may want one over a menu and the
/// other over play.
static class GameLightTheme
{
	public static ThemePalette Palette()
	{
		var palette = ThemePalette.Light();
		palette.PrimaryAccent = Color(22 / 255.0f, 142 / 255.0f, 134 / 255.0f, 1.0f);
		return palette;
	}

	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create() => LightTheme.Create(Palette());
}
