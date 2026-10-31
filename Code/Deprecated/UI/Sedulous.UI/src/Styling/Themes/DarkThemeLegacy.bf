using Sedulous.Core;

namespace Sedulous.UI;

/// The dark theme as it was before it was authored as a sheet: every rule built in code.
///
/// It is kept as the PARITY ORACLE. The sheet is the theme now, and this exists so the two can
/// be diffed rule for rule when the sheet is changed, which is the only way to tell a deliberate
/// re-authoring from an accidental one. Nothing in the engine calls it.
extension DarkTheme
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

	private static void BuildButton(StyleSheet sheet, ThemePalette p)
	{
		let background = Palette.CreateStateColors(p.SurfaceBright);
		let checkedBackground = Palette.CreateStateColors(p.PrimaryAccent);
		sheet.OwnDrawable(background);
		sheet.OwnDrawable(checkedBackground);

		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, background)
			.Set(.CheckedBackground, checkedBackground)
			.Set(.TextColor, Rgb(240, 240, 245))
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
		let background = new RoundedRectDrawable(Rgb(30, 32, 42), 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(background);

		sheet.ForType(typeof(EditText))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Rgb(60, 120, 200, 80));

		// The numeric field shares the text field's styling and adds its spin buttons.
		let spin = Palette.CreateStateColors(Rgb(50, 55, 68));
		sheet.OwnDrawable(spin);

		sheet.ForType(typeof(NumericField))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Rgb(60, 120, 200, 80));
		sheet.ForTypePseudo(typeof(NumericField), "spin-up").Set(.Background, spin);
		sheet.ForTypePseudo(typeof(NumericField), "spin-down").Set(.Background, spin);
	}

	private static void BuildToggles(StyleSheet sheet, ThemePalette p)
	{
		let border = Rgb(100, 105, 120);

		let checkUnchecked = new RoundedRectDrawable(Rgb(30, 32, 42), 0.0f, border, 1.0f);
		let checkChecked = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, border, 1.0f);
		sheet.OwnDrawable(checkUnchecked);
		sheet.OwnDrawable(checkChecked);
		sheet.ForTypePseudo(typeof(CheckBox), "box")
			.Set(.Background, checkUnchecked)
			.Set(.Width, 18.0f);
		sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked).Set(.Background, checkChecked);
		sheet.ForType(typeof(CheckBox)).Set(.Spacing, 6.0f);

		let radioUnchecked = new RoundedRectDrawable(Rgb(30, 32, 42), 0.0f, border, 1.0f);
		let radioChecked = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, border, 1.0f);
		sheet.OwnDrawable(radioUnchecked);
		sheet.OwnDrawable(radioChecked);
		sheet.ForTypePseudo(typeof(RadioButton), "box").Set(.Background, radioUnchecked);
		sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
			.Set(.Background, radioChecked);

		let switchOff = new RoundedRectDrawable(p.Surface, 0.0f, p.Border, 1.0f);
		let switchOn = new RoundedRectDrawable(p.PrimaryAccent, 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(switchOff);
		sheet.OwnDrawable(switchOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "track").Set(.Background, switchOff);
		sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
			.Set(.Background, switchOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "knob")
			.Set(.Background, sheet.OwnColor(Rgb(230, 230, 235)));
	}

	private static void BuildRangeControls(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sheet.OwnColor(Rgb(50, 52, 62)))
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sheet.OwnColor(Rgb(220, 220, 230)))
			.Set(.Width, 16.0f);

		sheet.ForTypePseudo(typeof(ProgressBar), "track")
			.Set(.Background, sheet.OwnColor(Rgb(50, 52, 62)));
		sheet.ForTypePseudo(typeof(ProgressBar), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
	}

	private static void BuildChrome(StyleSheet sheet, ThemePalette p)
	{
		let combo = new RoundedRectDrawable(Rgb(40, 42, 52), 0.0f, p.Border, 1.0f);
		sheet.OwnDrawable(combo);
		sheet.ForType(typeof(ComboBox)).Set(.Background, combo);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.TextColor, Rgb(180, 185, 200));

		sheet.ForTypePseudo(typeof(ScrollBar), "track")
			.Set(.Background, sheet.OwnColor(Rgb(40, 42, 50, 150)));
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb")
			.Set(.Background, sheet.OwnColor(Rgb(100, 110, 130, 200)));

		sheet.ForType(typeof(Separator)).Set(.BorderColor, p.Border);

		let header = Rgb(50, 55, 68);
		sheet.ForTypePseudo(typeof(Expander), "header").Set(.Background, sheet.OwnColor(header));
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Lighten(header, 0.1f)));
		sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.TextColor, Rgb(180, 185, 200));
	}

	private static void BuildTabs(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForTypePseudo(typeof(TabView), "strip")
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.15f)));
		sheet.ForTypePseudo(typeof(TabView), "content")
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Lighten(p.Surface, 0.05f)));
		sheet.ForTypePseudo(typeof(TabView), "tab").Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked).Set(.TextColor, p.Text);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.TextColor, Palette.Lighten(p.TextDim, 0.3f));
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
		let menuBorder = Rgb(70, 75, 90);
		let menuAccent = Rgb(60, 120, 200, 100);

		let menu = new RoundedRectDrawable(Rgb(45, 48, 58), 0.0f, menuBorder, 1.0f);
		sheet.OwnDrawable(menu);
		let menuHover = new RoundedRectDrawable(menuAccent, 0.0f);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menu)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, menuBorder)
			.Set(.AccentColor, menuAccent);

		let dialog = new RoundedRectDrawable(Rgb(50, 52, 62), 0.0f, Rgb(80, 85, 100), 1.0f);
		sheet.OwnDrawable(dialog);
		sheet.ForType(typeof(Dialog)).Set(.Background, dialog);

		let tooltip = new RoundedRectDrawable(Rgb(40, 42, 50, 230), 0.0f, Rgb(70, 75, 85), 1.0f);
		sheet.OwnDrawable(tooltip);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltip)
			.Set(.TextColor, p.Text);
	}

	private static void BuildItemViews(StyleSheet sheet, ThemePalette p)
	{
		let selection = Rgb(60, 120, 200, 80);

		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, selection);
		sheet.ForType(typeof(TreeView)).Set(.Background, sheet.OwnColor(p.Background));
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, selection);
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		ThemeBuilderIcons.Bind(sheet, .Checkmark, null, typeof(CheckBox), "checkmark", null);
		ThemeBuilderIcons.Bind(sheet, .RadioMarkSquare, null, typeof(RadioButton), "mark", null);
		ThemeBuilderIcons.Bind(sheet, .Close, null, typeof(TabView), "close-button", null);

		// Expanded reads as Checked, so one glyph carries each direction.
		ThemeBuilderIcons.Bind(sheet, .ChevronDown, null, typeof(Expander), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, null, typeof(Expander), "chevron", null);
		ThemeBuilderIcons.Bind(sheet, .ChevronDown, null, typeof(TreeView), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, null, typeof(TreeView), "chevron", null);

		ThemeBuilderIcons.BindSubmenuArrow(sheet, null);

		ThemeBuilderIcons.Bind(sheet, .ArrowDown, null, typeof(ComboBox), "arrow", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowUp, null, typeof(NumericField), "arrow-up", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowDown, null, typeof(NumericField), "arrow-down", null);
	}

	/// A byte colour, as the theme data is authored.
	private static Color Rgb(int r, int g, int b, int a = 255) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
}
