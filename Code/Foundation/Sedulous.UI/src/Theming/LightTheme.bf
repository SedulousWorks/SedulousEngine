namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Factory for the built-in light theme.
public static class LightTheme
{
	public static Theme Create()
	{
		let theme = new Theme();
		theme.Name.Set("Light");

		var p = Palette();
		p.Background = .(235, 237, 240, 255);
		p.Surface = .(250, 250, 252, 255);
		p.SurfaceBright = .(255, 255, 255, 255);
		p.Border = .(190, 195, 205, 255);
		p.Text = .(30, 35, 45, 255);
		p.TextDim = .(100, 110, 130, 255);
		p.Primary = .(50, 110, 210, 255);
		p.PrimaryAccent = .(70, 140, 240, 255);
		theme.Palette = p;

		// === Button ===
		theme.SetColor("Button.Background", p.Primary);
		theme.SetColor("Button.Background.Hover", Palette.ComputeHover(p.Primary));
		theme.SetColor("Button.Background.Pressed", Palette.ComputePressed(p.Primary));
		theme.SetColor("Button.Background.Disabled", Palette.ComputeDisabled(p.Primary));
		theme.SetColor("Button.Foreground", .White);
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
		theme.SetColor("ScrollBar.Track", .(200, 205, 215, 150));
		theme.SetColor("ScrollBar.Thumb", .(140, 150, 170, 200));

		// === ListView ===
		theme.SetColor("ListView.Selection", .(40, 100, 200, 60));

		// === Focus ===
		theme.SetColor("Focus.Ring", .(40, 100, 220, 200));

		// === Section header ===
		theme.SetColor("SectionLabel.Foreground", .(180, 120, 30, 255));

		theme.ApplyExtensions();

		return theme;
	}
}
