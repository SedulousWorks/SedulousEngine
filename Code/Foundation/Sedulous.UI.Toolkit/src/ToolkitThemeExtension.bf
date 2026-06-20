namespace Sedulous.UI.Toolkit;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Registers default theme styles for all Sedulous.UI.Toolkit controls.
/// Register before creating themes:
///   ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());
public class ToolkitThemeExtension : IThemeExtension
{
	public void Apply(StyleSheet sheet, ThemePalette p)
	{
		let isDark = p.Background.R < 128;

		// === DockManager ===
		sheet.ForType(typeof(DockManager))
			.Set(.Background, sheet.OwnColor(p.Background));

		// === DockablePanel ===
		{
			let headerBg = isDark ? Palette.Darken(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.05f);
			let headerDrawable = new RoundedRectDrawable(headerBg, 0);
			sheet.OwnDrawable(headerDrawable);
			sheet.ForType(typeof(DockablePanel))
				.Set(.TextColor, p.Text)
				.Set(.Background, sheet.OwnColor(p.Surface));
			sheet.ForTypePseudo(typeof(DockablePanel), "header")
				.Set(.Background, headerDrawable);
			sheet.ForTypePseudo(typeof(DockablePanel), "content")
				.Set(.Background, sheet.OwnColor(p.Surface));
			sheet.ForTypePseudo(typeof(DockablePanel), "close-button")
				.Set(.TextColor, Color32(p.Text.R, p.Text.G, p.Text.B, 150));
			sheet.ForTypePseudoState(typeof(DockablePanel), "close-button", .Hover)
				.Set(.TextColor, p.Error);
		}

		// === DockTabGroup ===
		{
			let tabBg = isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.08f);
			let activeTab = isDark ? p.Surface : Palette.Lighten(p.Surface, 0.03f);
			let hoverTab = isDark ? Palette.Lighten(tabBg, 0.05f) : Palette.Darken(p.Surface, 0.04f);
			let inactiveText = Color32(p.Text.R, p.Text.G, p.Text.B, 153);

			sheet.ForType(typeof(DockTabGroup))
				.Set(.BorderColor, p.Border)
				.Set(.AccentColor, p.PrimaryAccent);
			sheet.ForTypePseudo(typeof(DockTabGroup), "strip")
				.Set(.Background, sheet.OwnColor(tabBg));
			sheet.ForTypePseudo(typeof(DockTabGroup), "content")
				.Set(.Background, sheet.OwnColor(p.Surface));
			sheet.ForTypePseudo(typeof(DockTabGroup), "tab")
				.Set(.TextColor, inactiveText);
			sheet.ForTypePseudoState(typeof(DockTabGroup), "tab", .Checked)
				.Set(.Background, sheet.OwnColor(activeTab))
				.Set(.TextColor, p.Text);
			sheet.ForTypePseudoState(typeof(DockTabGroup), "tab", .Hover)
				.Set(.Background, sheet.OwnColor(hoverTab))
				.Set(.TextColor, Palette.Lighten(inactiveText, 0.3f));
			sheet.ForTypePseudo(typeof(DockTabGroup), "close-button")
				.Set(.TextColor, inactiveText);
			sheet.ForTypePseudoState(typeof(DockTabGroup), "close-button", .Hover)
				.Set(.TextColor, p.Error);
		}

		// === DockSplit ===
		{
			let divColor = isDark ? Palette.Lighten(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.1f);
			let divHover = isDark ? Palette.Lighten(p.Surface, 0.25f) : Palette.Darken(p.Surface, 0.2f);
			sheet.ForType(typeof(DockSplit))
				.Set(.BorderColor, divColor)
				.Set(.AccentColor, divHover);
		}

		// === DockableWindow ===
		{
			let dwBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			sheet.OwnDrawable(dwBg);
			sheet.ForType(typeof(DockableWindow))
				.Set(.Background, dwBg);
		}

		// === MenuBar ===
		{
			let menuBg = isDark ? Palette.Darken(p.Surface, 0.15f) : p.Surface;
			sheet.ForType(typeof(MenuBar))
				.Set(.Background, sheet.OwnColor(menuBg))
				.Set(.TextColor, p.Text)
				.Set(.BorderColor, p.Border);
		}

		// === Toolbar ===
		{
			let toolbarBg = isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.05f);
			let toggleOn = isDark ? Palette.Darken(p.PrimaryAccent, 0.3f) : Palette.Lighten(p.PrimaryAccent, 0.3f);
			sheet.ForType(typeof(Toolbar))
				.Set(.Background, sheet.OwnColor(toolbarBg))
				.Set(.BorderColor, p.Border)
				.Set(.SelectionColor, toggleOn);
		}

		// === StatusBar ===
		{
			let statusBg = isDark ? Palette.Darken(p.Surface, 0.2f) : Palette.Darken(p.Surface, 0.05f);
			sheet.ForType(typeof(StatusBar))
				.Set(.Background, sheet.OwnColor(statusBg))
				.Set(.BorderColor, p.Border)
				.Set(.TextColor, isDark ? Color32(p.Text.R, p.Text.G, p.Text.B, 200) : p.Text);
		}

		// === SplitView ===
		{
			let divColor = isDark ? Palette.Lighten(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.1f);
			let divHover = isDark ? Palette.Lighten(p.Surface, 0.25f) : Palette.Darken(p.Surface, 0.2f);
			sheet.ForType(typeof(SplitView))
				.Set(.BorderColor, divColor)
				.Set(.AccentColor, divHover)
				.Set(.TextDimColor, isDark ? Color32(100, 105, 120, 180) : Color32(160, 165, 180, 180));
		}

		// === BreadcrumbBar ===
		sheet.ForType(typeof(BreadcrumbBar))
			.Set(.Background, sheet.OwnColor(isDark ? Palette.Darken(p.Surface, 0.1f) : p.Surface))
			.Set(.TextColor, p.Text)
			.Set(.AccentColor, p.PrimaryAccent);

		// === ColorPicker ===
		sheet.ForType(typeof(ColorPicker))
			.Set(.Background, sheet.OwnColor(p.Surface))
			.Set(.BorderColor, p.Border);

		// === PropertyGrid ===
		sheet.ForType(typeof(PropertyGrid))
			.Set(.Background, sheet.OwnColor(p.Surface))
			.Set(.BorderColor, p.Border);
	}
}
