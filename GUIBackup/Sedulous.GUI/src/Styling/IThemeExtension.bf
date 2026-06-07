namespace Sedulous.GUI;

/// Allows external libraries to inject style rules into a theme StyleSheet
/// after base theme initialization.
public interface IThemeExtension
{
	void Apply(StyleSheet sheet, ThemePalette palette);
}
