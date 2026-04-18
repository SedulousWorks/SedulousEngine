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

		// === ContextMenu ===
		theme.SetColor("ContextMenu.Background", .(248, 248, 252, 255));
		theme.SetColor("ContextMenu.Border", .(190, 195, 205, 255));
		theme.SetColor("ContextMenu.Hover", .(40, 100, 200, 60));
		theme.SetColor("ContextMenu.Text", p.Text);

		// === Modal ===
		theme.SetColor("Modal.Backdrop", .(0, 0, 0, 100));

		// === Dialog ===
		theme.SetColor("Dialog.Background", .(252, 252, 255, 255));
		theme.SetColor("Dialog.Border", .(190, 195, 210, 255));
		theme.SetDimension("Dialog.CornerRadius", 6);
		theme.SetDimension("Dialog.BorderWidth", 1);
		theme.SetPadding("Dialog.Padding", .(12, 10));

		// === Tooltip ===
		theme.SetColor("Tooltip.Background", .(255, 255, 245, 255));
		theme.SetColor("Tooltip.Border", .(180, 185, 195, 255));

		// === Focus ===
		theme.SetColor("Focus.Ring", .(40, 100, 220, 200));

		// === CheckBox ===
		theme.SetColor("CheckBox.BoxBackground", .(245, 245, 248, 255));
		theme.SetColor("CheckBox.BoxBorder", .(180, 185, 200, 255));
		theme.SetColor("CheckBox.CheckColor", p.PrimaryAccent);
		theme.SetColor("CheckBox.Text", p.Text);

		// === RadioButton ===
		theme.SetColor("RadioButton.CircleBackground", .(245, 245, 248, 255));
		theme.SetColor("RadioButton.CircleBorder", .(180, 185, 200, 255));
		theme.SetColor("RadioButton.DotColor", p.PrimaryAccent);
		theme.SetColor("RadioButton.Text", p.Text);

		// === ToggleButton ===
		theme.SetColor("ToggleButton.Background", .(220, 225, 230, 255));
		theme.SetColor("ToggleButton.CheckedBackground", p.PrimaryAccent);
		theme.SetColor("ToggleButton.Text", p.Text);
		theme.SetColor("ToggleButton.CheckedText", .White);
		theme.SetDimension("ToggleButton.CornerRadius", 4);

		// === ToggleSwitch ===
		theme.SetColor("ToggleSwitch.TrackOff", .(210, 215, 225, 255));
		theme.SetColor("ToggleSwitch.TrackOn", p.PrimaryAccent);
		theme.SetColor("ToggleSwitch.Border", p.Border);
		theme.SetColor("ToggleSwitch.Knob", .White);
		theme.SetColor("ToggleSwitch.Text", p.Text);

		// === ProgressBar ===
		theme.SetColor("ProgressBar.Track", .(220, 225, 230, 255));
		theme.SetColor("ProgressBar.Fill", p.PrimaryAccent);

		// === Slider ===
		theme.SetColor("Slider.Track", .(210, 215, 225, 255));
		theme.SetColor("Slider.Fill", p.PrimaryAccent);
		theme.SetColor("Slider.Thumb", .(250, 250, 255, 255));
		theme.SetColor("Slider.ThumbHover", .White);

		// === TabView ===
		theme.SetColor("TabView.StripBackground", .(235, 237, 242, 255));
		theme.SetColor("TabView.ContentBackground", p.Surface);
		theme.SetColor("TabView.ActiveTabBackground", p.Surface);
		theme.SetColor("TabView.ActiveTabText", p.Text);
		theme.SetColor("TabView.InactiveTabText", .(p.Text.R, p.Text.G, p.Text.B, 130));
		theme.SetColor("TabView.HoverTabText", p.Text);
		theme.SetColor("TabView.TabHover", .(p.PrimaryAccent.R, p.PrimaryAccent.G, p.PrimaryAccent.B, 40));
		theme.SetColor("TabView.Border", p.Border);

		// === ComboBox ===
		theme.SetColor("ComboBox.Background", .(248, 248, 252, 255));
		theme.SetColor("ComboBox.Border", p.Border);
		theme.SetColor("ComboBox.Text", p.Text);
		theme.SetColor("ComboBox.ArrowColor", .(100, 110, 130, 255));
		theme.SetDimension("ComboBox.CornerRadius", 4);

		// === EditText ===
		theme.SetColor("EditText.Background", .(248, 248, 252, 255));
		theme.SetColor("EditText.Border", p.Border);
		theme.SetColor("EditText.Border.Focused", p.PrimaryAccent);
		theme.SetColor("EditText.Foreground", p.Text);
		theme.SetColor("EditText.Placeholder", p.TextDim);
		theme.SetColor("EditText.Selection", .(40, 100, 200, 80));
		theme.SetColor("EditText.Cursor", p.Text);
		theme.SetDimension("EditText.CornerRadius", 4);
		theme.SetDimension("EditText.FontSize", 14);
		theme.SetPadding("EditText.Padding", .(6, 4));

		// === Expander ===
		theme.SetColor("Expander.Header", .(228, 230, 238, 255));

		// === NumericField ===
		theme.SetColor("NumericField.ButtonBackground", .(235, 237, 242, 255));
		theme.SetColor("NumericField.ButtonBorder", p.Border);

		// === Section header ===
		theme.SetColor("SectionLabel.Foreground", .(180, 120, 30, 255));

		theme.ApplyExtensions();

		return theme;
	}
}
