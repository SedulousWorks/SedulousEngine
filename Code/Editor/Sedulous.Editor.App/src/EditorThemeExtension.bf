namespace Sedulous.Editor.App;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Registers default theme styles for editor-specific controls.
/// Register before creating themes:
///   ThemeRegistry.RegisterExtension(new EditorThemeExtension());
class EditorThemeExtension : IThemeExtension
{
	public void Apply(StyleSheet sheet, ThemePalette p)
	{
		let isDark = p.Background.R < 128;

		// === LogView ===
		sheet.ForType(typeof(View), "logview")
			.Set(.Background, sheet.OwnColor(isDark ? Color32(25, 27, 35, 255) : Color32(245, 246, 250, 255)));

		// === Grid content view (asset browser grid) ===
		sheet.ForType(typeof(View), "gridcontentview")
			.Set(.SelectionColor, Color32(60, 120, 200, 80));

		// === Grid cell (asset browser tile) ===
		sheet.ForType(typeof(View), "gridcell")
			.Set(.Background, sheet.OwnColor(isDark ? Color32(35, 38, 48, 255) : Color32(230, 232, 240, 255)));

		// === Scene hierarchy ===
		sheet.ForType(typeof(View), "scenehierarchy")
			.Set(.AccentColor, p.PrimaryAccent);

		// === Hierarchy item (entity name in tree) ===
		{
			let editBg = isDark ? Color32(30, 32, 42, 255) : Color32(240, 242, 250, 255);
			sheet.ForType(typeof(View), "hierarchyitem")
				.Set(.Background, sheet.OwnColor(editBg))
				.Set(.AccentColor, p.PrimaryAccent)
				.Set(.TextColor, p.Text)
				.Set(.SelectionColor, Color32(60, 120, 200, 100))
				.Set(.CursorColor, p.Text);
		}
	}
}
