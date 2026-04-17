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

		// === ContextMenu ===
		theme.SetColor("ContextMenu.Background", .(45, 48, 58, 240));
		theme.SetColor("ContextMenu.Border", .(70, 75, 90, 255));
		theme.SetColor("ContextMenu.Hover", .(60, 120, 200, 100));
		theme.SetColor("ContextMenu.Text", p.Text);

		// === Dialog ===
		theme.SetColor("Dialog.Background", .(50, 52, 62, 245));
		theme.SetColor("Dialog.Border", .(80, 85, 100, 255));
		theme.SetDimension("Dialog.CornerRadius", 8);

		// === Tooltip ===
		theme.SetColor("Tooltip.Background", .(40, 42, 50, 230));
		theme.SetColor("Tooltip.Border", .(70, 75, 85, 255));

		// === Focus ===
		theme.SetColor("Focus.Ring", .(100, 160, 255, 180));

		// === CheckBox ===
		theme.SetColor("CheckBox.BoxBackground", .(30, 32, 42, 255));
		theme.SetColor("CheckBox.BoxBorder", .(100, 105, 120, 255));
		theme.SetColor("CheckBox.CheckColor", p.PrimaryAccent);
		theme.SetColor("CheckBox.Text", p.Text);

		// === RadioButton ===
		theme.SetColor("RadioButton.CircleBackground", .(30, 32, 42, 255));
		theme.SetColor("RadioButton.CircleBorder", .(100, 105, 120, 255));
		theme.SetColor("RadioButton.DotColor", p.PrimaryAccent);
		theme.SetColor("RadioButton.Text", p.Text);

		// === ToggleButton ===
		theme.SetColor("ToggleButton.Background", p.Surface);
		theme.SetColor("ToggleButton.CheckedBackground", p.PrimaryAccent);
		theme.SetColor("ToggleButton.Text", .(240, 240, 245, 255));
		theme.SetDimension("ToggleButton.CornerRadius", 4);

		// === ToggleSwitch ===
		theme.SetColor("ToggleSwitch.TrackOff", p.Surface);
		theme.SetColor("ToggleSwitch.TrackOn", p.PrimaryAccent);
		theme.SetColor("ToggleSwitch.Border", p.Border);
		theme.SetColor("ToggleSwitch.Knob", .(230, 230, 235, 255));
		theme.SetColor("ToggleSwitch.Text", p.Text);

		// === ProgressBar ===
		theme.SetColor("ProgressBar.Track", .(50, 52, 62, 255));
		theme.SetColor("ProgressBar.Fill", p.PrimaryAccent);

		// === Slider ===
		theme.SetColor("Slider.Track", .(50, 52, 62, 255));
		theme.SetColor("Slider.Fill", p.PrimaryAccent);
		theme.SetColor("Slider.Thumb", .(220, 220, 230, 255));
		theme.SetColor("Slider.ThumbHover", .(240, 240, 250, 255));

		// === TabView ===
		theme.SetColor("TabView.StripBackground", Palette.Darken(p.Surface, 0.15f));
		theme.SetColor("TabView.ContentBackground", p.Surface);
		theme.SetColor("TabView.ActiveTabBackground", p.Surface);
		theme.SetColor("TabView.ActiveTabText", p.Text);
		theme.SetColor("TabView.InactiveTabText", .(p.Text.R, p.Text.G, p.Text.B, 153));
		theme.SetColor("TabView.HoverTabText", p.Text);
		theme.SetColor("TabView.TabHover", .(p.PrimaryAccent.R, p.PrimaryAccent.G, p.PrimaryAccent.B, 50));
		theme.SetColor("TabView.Border", p.Border);

		// === ComboBox ===
		theme.SetColor("ComboBox.Background", .(40, 42, 52, 255));
		theme.SetColor("ComboBox.Border", p.Border);
		theme.SetColor("ComboBox.Text", p.Text);
		theme.SetColor("ComboBox.ArrowColor", .(180, 185, 200, 255));
		theme.SetDimension("ComboBox.CornerRadius", 4);

		// === Section header ===
		theme.SetColor("SectionLabel.Foreground", .(255, 200, 100, 255));

		// Apply registered extensions.
		theme.ApplyExtensions();

		return theme;
	}
}
