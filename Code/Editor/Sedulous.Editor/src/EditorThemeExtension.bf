namespace Sedulous.Editor;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Registers default theme styles for editor-specific controls.
/// Register before creating themes:
///   ThemeRegistry.RegisterExtension(new EditorThemeExtension());
class EditorThemeExtension : IThemeExtension
{
	public void Apply(StyleSheet sheet, ThemePalette p)
	{
		let isDark = p.Background.R < 0.5f;

		// === LogView ===
		sheet.ForType(typeof(View), "logview")
			.Set(.Background, sheet.OwnColor(isDark ? Color(25, 27, 35, 255) : Color(245, 246, 250, 255)));

		// === Grid content view (asset browser grid) ===
		sheet.ForType(typeof(View), "gridcontentview")
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === Grid cell (asset browser tile) ===
		sheet.ForType(typeof(View), "gridcell")
			.Set(.Background, sheet.OwnColor(isDark ? Color(35, 38, 48, 255) : Color(230, 232, 240, 255)));

		// === Scene hierarchy ===
		sheet.ForType(typeof(View), "scenehierarchy")
			.Set(.AccentColor, p.PrimaryAccent);

		// === Hierarchy item (entity name in tree) ===
		{
			let editBg = isDark ? Color(30, 32, 42, 255) : Color(240, 242, 250, 255);
			sheet.ForType(typeof(View), "hierarchyitem")
				.Set(.Background, sheet.OwnColor(editBg))
				.Set(.AccentColor, p.PrimaryAccent)
				.Set(.TextColor, p.Text)
				.Set(.SelectionColor, Color(60, 120, 200, 100))
				.Set(.CursorColor, p.Text);
		}
	}
}
