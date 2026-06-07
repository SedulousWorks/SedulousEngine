namespace Sedulous.GUI;

/// Allows external libraries to inject style rules into a theme StyleSheet
/// after base theme initialization. Register via Theme.RegisterExtension().
public interface IThemeExtension
{
	/// Apply custom style rules to the theme stylesheet.
	/// Called during theme creation after base rules are set.
	void Apply(StyleSheet sheet, ThemePalette palette);
}
