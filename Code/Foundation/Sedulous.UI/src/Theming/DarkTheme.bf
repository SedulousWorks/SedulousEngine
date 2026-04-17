namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Factory for the built-in dark theme. Creates a Theme populated from
/// a dark Palette with auto-computed state variants.
public static class DarkTheme
{
	public static Theme Create()
	{
		let theme = new Theme();
		theme.Name.Set("Dark");

		var p = Palette();
		// Dark palette defaults are already suitable.
		theme.Palette = p;

		// === Button ===
		theme.SetColor("Button.Background", p.Primary);
		theme.SetColor("Button.Background.Hover", Palette.ComputeHover(p.Primary));
		theme.SetColor("Button.Background.Pressed", Palette.ComputePressed(p.Primary));
		theme.SetColor("Button.Background.Disabled", Palette.ComputeDisabled(p.Primary));
		theme.SetColor("Button.Foreground", .(240, 240, 245, 255));
		theme.SetPadding("Button.Padding", .(12, 8));
		theme.SetDimension("Button.CornerRadius", 4);
		theme.SetDimension("Button.FontSize", 16);

		// === Label ===
		theme.SetColor("Label.Foreground", p.Text);
		theme.SetDimension("Label.FontSize", 16);

		// === Panel ===
		theme.SetColor("Panel.Background", p.Surface);
		theme.SetColor("Panel.Border", p.Border);
		theme.SetDimension("Panel.CornerRadius", 6);
		theme.SetDimension("Panel.BorderWidth", 1);

		// === General text ===
		theme.SetColor("Text", p.Text);
		theme.SetColor("TextDim", p.TextDim);

		// === Separator ===
		theme.SetColor("Separator.Color", p.Border);

		// === ScrollBar ===
		theme.SetColor("ScrollBar.Track", .(40, 42, 50, 150));
		theme.SetColor("ScrollBar.Thumb", .(100, 110, 130, 200));

		// === ListView ===
		theme.SetColor("ListView.Selection", .(60, 120, 200, 80));

		// === Focus ===
		theme.SetColor("Focus.Ring", .(100, 160, 255, 180));

		// === Section header ===
		theme.SetColor("SectionLabel.Foreground", .(255, 200, 100, 255));

		// Apply registered extensions.
		theme.ApplyExtensions();

		return theme;
	}
}
