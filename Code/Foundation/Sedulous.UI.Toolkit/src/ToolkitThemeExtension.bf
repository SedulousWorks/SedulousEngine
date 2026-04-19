namespace Sedulous.UI.Toolkit;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Registers default theme colors for all Sedulous.UI.Toolkit controls.
/// Register before creating UISubsystem:
///   Theme.RegisterExtension(new ToolkitThemeExtension());
public class ToolkitThemeExtension : IThemeExtension
{
	public void Apply(Theme theme)
	{
		let p = theme.Palette;
		let isDark = p.Background.R < 128;

		// === SplitView ===
		theme.SetColor("SplitView.Divider", isDark ? Palette.Lighten(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.1f));
		theme.SetColor("SplitView.DividerHover", isDark ? Palette.Lighten(p.Surface, 0.25f) : Palette.Darken(p.Surface, 0.2f));
		theme.SetColor("SplitView.Grip", isDark ? .(100, 105, 120, 180) : .(160, 165, 180, 180));
		theme.SetDimension("SplitView.DividerSize", 6);

		// === Toolbar ===
		theme.SetColor("Toolbar.Background", isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.05f));
		theme.SetColor("Toolbar.Border", p.Border);
		theme.SetColor("Toolbar.ButtonHover", isDark ? Palette.Lighten(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.1f));
		theme.SetColor("Toolbar.ButtonPressed", isDark ? Palette.Lighten(p.Surface, 0.05f) : Palette.Darken(p.Surface, 0.15f));
		theme.SetColor("Toolbar.ToggleOn", isDark ? Palette.Darken(p.PrimaryAccent, 0.3f) : Palette.Lighten(p.PrimaryAccent, 0.3f));
		theme.SetColor("Toolbar.Separator", p.Border);

		// === StatusBar ===
		theme.SetColor("StatusBar.Background", isDark ? Palette.Darken(p.Surface, 0.2f) : Palette.Darken(p.Surface, 0.05f));
		theme.SetColor("StatusBar.Border", p.Border);
		theme.SetColor("StatusBar.Text", isDark ? .(p.Text.R, p.Text.G, p.Text.B, 200) : p.Text);

		// === MenuBar ===
		theme.SetColor("MenuBar.Background", isDark ? Palette.Darken(p.Surface, 0.15f) : p.Surface);
		theme.SetColor("MenuBar.Border", p.Border);
		theme.SetColor("MenuBar.Text", p.Text);
		theme.SetColor("MenuBar.ItemHover", isDark ? Palette.Lighten(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.08f));

		// === ColorPicker ===
		theme.SetColor("ColorPicker.Background", p.Surface);
		theme.SetColor("ColorPicker.Border", p.Border);
		theme.SetColor("ColorPicker.Indicator", .White);

		// === DraggableTreeView ===
		theme.SetColor("DraggableTreeView.DropIndicator", p.PrimaryAccent);

		// === PropertyGrid ===
		theme.SetColor("PropertyGrid.Background", p.Surface);
		theme.SetColor("PropertyGrid.Label", p.Text);
		theme.SetColor("PropertyGrid.CategoryBackground", isDark ? Palette.Darken(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.03f));
		theme.SetColor("PropertyGrid.Divider", p.Border);
		theme.SetColor("PropertyGrid.RowBackground", p.Surface);
		theme.SetColor("PropertyGrid.RowAlt", isDark ? Palette.Lighten(p.Surface, 0.03f) : Palette.Darken(p.Surface, 0.02f));

		// === DockManager ===
		theme.SetColor("DockManager.Background", p.Background);

		// === DockTabGroup ===
		theme.SetColor("DockTabGroup.Background", isDark ? Palette.Darken(p.Surface, 0.15f) : p.Surface);
		theme.SetColor("DockTabGroup.ActiveTab", p.Surface);
		theme.SetColor("DockTabGroup.InactiveTab", isDark ? Palette.Darken(p.Surface, 0.15f) : Palette.Darken(p.Surface, 0.05f));
		theme.SetColor("DockTabGroup.ActiveText", p.Text);
		theme.SetColor("DockTabGroup.InactiveText", .(p.Text.R, p.Text.G, p.Text.B, 153));
		theme.SetColor("DockTabGroup.Border", p.Border);

		// === DockSplit ===
		theme.SetColor("DockSplit.Divider", p.Border);
		theme.SetColor("DockSplit.DividerHover", p.PrimaryAccent);

		// === FloatingWindow ===
		theme.SetColor("FloatingWindow.Background", p.Surface);
		theme.SetColor("FloatingWindow.Border", p.Border);

		// === DockZoneIndicator ===
		theme.SetColor("DockZone.Indicator", .(p.PrimaryAccent.R, p.PrimaryAccent.G, p.PrimaryAccent.B, 80));
		theme.SetColor("DockZone.Border", p.PrimaryAccent);

		// === DockablePanel ===
		theme.SetColor("DockablePanel.HeaderBackground", isDark ? Palette.Darken(p.Surface, 0.1f) : Palette.Darken(p.Surface, 0.05f));
		theme.SetColor("DockablePanel.HeaderText", p.Text);
		theme.SetColor("DockablePanel.ContentBackground", p.Surface);
		theme.SetColor("DockablePanel.CloseButton", .(p.Text.R, p.Text.G, p.Text.B, 150));
		theme.SetColor("DockablePanel.CloseButtonHover", p.Error);
	}
}
