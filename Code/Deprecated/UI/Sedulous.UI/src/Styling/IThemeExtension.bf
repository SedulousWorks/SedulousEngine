namespace Sedulous.UI;

/// Lets a library inject its own style rules into a theme after the base rules are set.
///
/// Injected and held by reference: an extension is registered with ThemeRegistry and applied
/// to every theme built afterwards.
interface IThemeExtension
{
	/// Applies custom rules to a theme sheet. Called AFTER the base rules, so an extension can
	/// override them.
	void Apply(StyleSheet sheet, ThemePalette palette);
}
