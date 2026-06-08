namespace Sedulous.GUI.Toolkit;

using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Registers default theme styles for all Sedulous.GUI.Toolkit controls.
/// Register before creating themes:
///   ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());
public class ToolkitThemeExtension : IThemeExtension
{
	public void Apply(StyleSheet sheet, ThemePalette p)
	{
		let isDark = p.Background.R < 128;

		// === DockManager ===
		sheet.ForType(typeof(View), "dockmanager")
			.Set(.Background, sheet.OwnColor(p.Background));

		// === DockablePanel ===
		{
			let headerBg = isDark ? Palette.Darken(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.05f);
			let headerDrawable = new RoundedRectDrawable(headerBg, 0);
			sheet.OwnDrawable(headerDrawable);
			sheet.ForType(typeof(View), "dockablepanel")
				.Set(.HeaderDrawable, headerDrawable)
				.Set(.ContentDrawable, sheet.OwnColor(p.Surface))
				.Set(.TextColor, p.Text)
				.Set(.Background, sheet.OwnColor(p.Surface))
				.Set(.CloseButtonColor, Color(p.Text.R, p.Text.G, p.Text.B, 150))
				.Set(.CloseButtonHoverColor, p.Error);
		}

		// === DockTabGroup ===
		{
			let tabBg = isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.08f);
			let activeTab = isDark ? p.Surface : Palette.Lighten(p.Surface, 0.03f);
			let hoverTab = isDark ? Palette.Lighten(tabBg, 0.05f) : Palette.Darken(p.Surface, 0.04f);
			let inactiveText = Color(p.Text.R, p.Text.G, p.Text.B, 153);

			sheet.ForType(typeof(View), "docktabgroup")
				.Set(.StripDrawable, sheet.OwnColor(tabBg))
				.Set(.ContentDrawable, sheet.OwnColor(p.Surface))
				.Set(.ActiveTabDrawable, sheet.OwnColor(activeTab))
				.Set(.HoverTabDrawable, sheet.OwnColor(hoverTab))
				.Set(.ActiveTabTextColor, p.Text)
				.Set(.InactiveTabTextColor, inactiveText)
				.Set(.HoverTabTextColor, Palette.Lighten(inactiveText, 0.3f))
				.Set(.BorderColor, p.Border)
				.Set(.AccentColor, p.PrimaryAccent)
				.Set(.CloseButtonColor, inactiveText)
				.Set(.CloseButtonHoverColor, p.Error);
		}

		// === DockSplit ===
		{
			let divColor = isDark ? Palette.Lighten(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.1f);
			let divHover = isDark ? Palette.Lighten(p.Surface, 0.25f) : Palette.Darken(p.Surface, 0.2f);
			sheet.ForType(typeof(View), "docksplit")
				.Set(.BorderColor, divColor)
				.Set(.AccentColor, divHover);
		}

		// === DockableWindow ===
		{
			let dwBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			sheet.OwnDrawable(dwBg);
			sheet.ForType(typeof(View), "dockablewindow")
				.Set(.Background, dwBg);
		}

		// === MenuBar ===
		{
			let menuBg = isDark ? Palette.Darken(p.Surface, 0.15f) : p.Surface;
			sheet.ForType(typeof(View), "menubar")
				.Set(.Background, sheet.OwnColor(menuBg))
				.Set(.TextColor, p.Text)
				.Set(.BorderColor, p.Border);
		}

		// === Toolbar ===
		{
			let toolbarBg = isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.05f);
			let toggleOn = isDark ? Palette.Darken(p.PrimaryAccent, 0.3f) : Palette.Lighten(p.PrimaryAccent, 0.3f);
			sheet.ForType(typeof(View), "toolbar")
				.Set(.Background, sheet.OwnColor(toolbarBg))
				.Set(.BorderColor, p.Border)
				.Set(.SelectionColor, toggleOn);
		}

		// === StatusBar ===
		{
			let statusBg = isDark ? Palette.Darken(p.Surface, 0.2f) : Palette.Darken(p.Surface, 0.05f);
			sheet.ForType(typeof(View), "statusbar")
				.Set(.Background, sheet.OwnColor(statusBg))
				.Set(.BorderColor, p.Border)
				.Set(.TextColor, isDark ? Color(p.Text.R, p.Text.G, p.Text.B, 200) : p.Text);
		}

		// === SplitView ===
		{
			let divColor = isDark ? Palette.Lighten(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.1f);
			let divHover = isDark ? Palette.Lighten(p.Surface, 0.25f) : Palette.Darken(p.Surface, 0.2f);
			sheet.ForType(typeof(View), "splitview")
				.Set(.BorderColor, divColor)
				.Set(.AccentColor, divHover)
				.Set(.TextDimColor, isDark ? Color(100, 105, 120, 180) : Color(160, 165, 180, 180));
		}

		// === BreadcrumbBar ===
		sheet.ForType(typeof(View), "breadcrumbbar")
			.Set(.Background, sheet.OwnColor(isDark ? Palette.Darken(p.Surface, 0.1f) : p.Surface))
			.Set(.TextColor, p.Text)
			.Set(.AccentColor, p.PrimaryAccent);

		// === ColorPicker ===
		sheet.ForType(typeof(View), "colorpicker")
			.Set(.Background, sheet.OwnColor(p.Surface))
			.Set(.BorderColor, p.Border);

		// === PropertyGrid ===
		sheet.ForType(typeof(View), "propertygrid")
			.Set(.Background, sheet.OwnColor(p.Surface))
			.Set(.BorderColor, p.Border);
	}
}
