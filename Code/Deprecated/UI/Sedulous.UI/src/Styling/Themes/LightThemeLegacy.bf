using Sedulous.Core;

namespace Sedulous.UI;

/// The light theme as it was before it was authored as a sheet: every rule built in code.
///
/// The PARITY ORACLE, as with [[DarkTheme]]'s. Nothing in the engine calls it.
extension LightTheme
{
	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet CreateLegacyForParity(ThemePalette palette)
	{
		let sheet = new StyleSheet();

		sheet.ForType(typeof(View))
			.Set(.TextColor, palette.Text)
			.Set(.FontSize, 16.0f);

		BuildButton(sheet, palette);
		BuildSurfaces(sheet, palette);
		BuildTextInput(sheet, palette);
		BuildToggles(sheet, palette);
		BuildRangeControls(sheet, palette);
		BuildChrome(sheet, palette);
		BuildTabs(sheet, palette);
		BuildOverlays(sheet, palette);
		BuildItemViews(sheet, palette);
		RegisterIcons(sheet);

		ThemeRegistry.ApplyExtensions(sheet, palette);
		return sheet;
	}

	/// Selection is fainter than the dark theme's: the same alpha over a light surface reads
	/// far stronger.
	private static Color Selection => Rgb(60, 120, 200, 60);

	private static void BuildButton(StyleSheet sheet, ThemePalette p)
	{
		let background = Palette.CreateStateColors(Rgb(220, 222, 230));
		let checkedBackground = Palette.CreateStateColors(p.PrimaryAccent);
		sheet.OwnDrawable(background);
		sheet.OwnDrawable(checkedBackground);

		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, background)
			.Set(.CheckedBackground, checkedBackground)
			.Set(.TextColor, Rgb(30, 30, 40))
			.Set(.Padding, Thickness(12, 8))
			.Set(.CornerRadius, 0.0f);
	}

	private static void BuildSurfaces(StyleSheet sheet, ThemePalette p)
	{
		let panel = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(panel);
		sheet.ForClass("panel").Set(.Background, panel);

		sheet.ForClass("label").Set(.TextColor, p.Text);
		sheet.ForClass("label-dim").Set(.TextColor, p.TextDim);
	}

	private static void BuildTextInput(StyleSheet sheet, ThemePalette p)
	{
		let background = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(background);

		sheet.ForType(typeof(EditText))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Selection);

		let spin = Palette.CreateStateColors(Palette.Darken(p.Surface, 0.08f));
		sheet.OwnDrawable(spin);

		sheet.ForType(typeof(NumericField))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Selection);
		sheet.ForTypePseudo(typeof(NumericField), "spin-up").Set(.Background, spin);
		sheet.ForTypePseudo(typeof(NumericField), "spin-down").Set(.Background, spin);
	}

	private static void BuildToggles(StyleSheet sheet, ThemePalette p)
	{
		let checkUnchecked = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		let checkChecked = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(checkUnchecked);
		sheet.OwnDrawable(checkChecked);
		sheet.ForTypePseudo(typeof(CheckBox), "box")
			.Set(.Background, checkUnchecked)
			.Set(.Width, 18.0f);
		sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked).Set(.Background, checkChecked);
		sheet.ForType(typeof(CheckBox)).Set(.Spacing, 6.0f);

		let radioUnchecked = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		let radioChecked = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(radioUnchecked);
		sheet.OwnDrawable(radioChecked);
		sheet.ForTypePseudo(typeof(RadioButton), "box").Set(.Background, radioUnchecked);
		sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
			.Set(.Background, radioChecked);

		let switchOff = new RoundedRectDrawable(Rgb(200, 205, 215), 0.0f, p.Border, 1.0f);
		let switchOn = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(switchOff);
		sheet.OwnDrawable(switchOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "track").Set(.Background, switchOff);
		sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
			.Set(.Background, switchOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "knob")
			.Set(.Background, sheet.OwnColor(p.Surface));
	}

	private static void BuildRangeControls(StyleSheet sheet, ThemePalette p)
	{
		let track = Rgb(210, 215, 225);

		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sheet.OwnColor(track))
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
		// The thumb takes the ACCENT here rather than a near white, which would vanish against
		// the light track.
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent))
			.Set(.Width, 16.0f);

		sheet.ForTypePseudo(typeof(ProgressBar), "track").Set(.Background, sheet.OwnColor(track));
		sheet.ForTypePseudo(typeof(ProgressBar), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
	}

	private static void BuildChrome(StyleSheet sheet, ThemePalette p)
	{
		let combo = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(combo);
		sheet.ForType(typeof(ComboBox)).Set(.Background, combo);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.TextColor, Rgb(80, 85, 100));

		sheet.ForTypePseudo(typeof(ScrollBar), "track")
			.Set(.Background, sheet.OwnColor(Rgb(230, 232, 240, 150)));
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb")
			.Set(.Background, sheet.OwnColor(Rgb(160, 165, 180, 200)));

		sheet.ForType(typeof(Separator)).Set(.BorderColor, p.Border);

		let header = Rgb(235, 238, 245);
		sheet.ForTypePseudo(typeof(Expander), "header").Set(.Background, sheet.OwnColor(header));
		// The light branch DARKENS on hover where the dark one lightens.
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Darken(header, 0.05f)));
		sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.TextColor, Rgb(80, 85, 100));
	}

	private static void BuildTabs(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForTypePseudo(typeof(TabView), "strip")
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.05f)));
		sheet.ForTypePseudo(typeof(TabView), "content")
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.03f)));
		sheet.ForTypePseudo(typeof(TabView), "tab").Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked).Set(.TextColor, p.Text);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.TextColor, Palette.Darken(p.TextDim, 0.2f));
		sheet.ForTypePseudo(typeof(TabView), "close-button")
			.Set(.TextColor, p.TextDim)
			.Set(.Width, 12.0f);
		sheet.ForTypePseudoState(typeof(TabView), "close-button", .Hover).Set(.TextColor, p.Text);
		sheet.ForType(typeof(TabView))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent);
	}

	private static void BuildOverlays(StyleSheet sheet, ThemePalette p)
	{
		let menu = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(menu);
		let menuHover = new RoundedRectDrawable(Selection, 0.0f);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menu)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, Selection);

		let dialog = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(dialog);
		sheet.ForType(typeof(Dialog)).Set(.Background, dialog);

		// A warm near white, which is the one place the light theme departs from its surface.
		let tooltip = new RoundedRectDrawable(Rgb(255, 255, 225, 245), 0.0f,
			Rgb(180, 175, 140), 1.0f);
		sheet.OwnDrawable(tooltip);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltip)
			.Set(.TextColor, p.Text);
	}

	private static void BuildItemViews(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Selection);
		sheet.ForType(typeof(TreeView)).Set(.Background, sheet.OwnColor(p.Background));
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Selection);
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		// The glyphs are authored light, so the light theme TINTS them dark.
		Color? tint = Rgb(60, 60, 70);

		ThemeBuilderIcons.Bind(sheet, .Checkmark, tint, typeof(CheckBox), "checkmark", null);
		ThemeBuilderIcons.Bind(sheet, .RadioMarkSquare, tint, typeof(RadioButton), "mark", null);
		ThemeBuilderIcons.Bind(sheet, .Close, tint, typeof(TabView), "close-button", null);

		ThemeBuilderIcons.Bind(sheet, .ChevronDown, tint, typeof(Expander), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, tint, typeof(Expander), "chevron", null);
		ThemeBuilderIcons.Bind(sheet, .ChevronDown, tint, typeof(TreeView), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, tint, typeof(TreeView), "chevron", null);

		ThemeBuilderIcons.BindSubmenuArrow(sheet, tint);

		ThemeBuilderIcons.Bind(sheet, .ArrowDown, tint, typeof(ComboBox), "arrow", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowUp, tint, typeof(NumericField), "arrow-up", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowDown, tint, typeof(NumericField), "arrow-down", null);
	}

	/// A byte colour, as the theme data is authored.
	private static Color Rgb(int r, int g, int b, int a = 255) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
}
