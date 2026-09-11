using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// The rounded dark theme as it was before it was authored as a sheet: every rule built in code.
///
/// The PARITY ORACLE, as with [[DarkTheme]]'s. Nothing in the engine calls it.
///
/// Unlike the flat themes, every colour here is DERIVED from the palette rather than written as
/// a literal, so a warm palette applies end to end, selection highlights included.
extension RoundedDarkTheme
{
	/// The one corner radius the whole theme rounds to.
	private const float R = 6.0f;

	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet CreateLegacyForParity(ThemePalette palette)
	{
		let sheet = new StyleSheet();
		let derived = Derived(palette);

		// The accent is a GLOBAL default here: a control that resolves it without a rule of its
		// own, a tree's drop indicator or a node graph's links, then picks up the palette accent
		// instead of its hard coded fallback, and a type rule still wins over it. The global
		// corner radius does the same for anything that rounds itself, which is why the flat
		// dark theme leaves that at nought and those controls stay square there.
		sheet.ForType(typeof(View))
			.Set(.TextColor, palette.Text)
			.Set(.AccentColor, palette.PrimaryAccent)
			.Set(.CornerRadius, R)
			.Set(.FontSize, 16.0f);

		BuildButton(sheet, palette);
		BuildSurfaces(sheet, palette);
		BuildTextInput(sheet, palette, derived);
		BuildToggles(sheet, palette, derived);
		BuildRangeControls(sheet, palette, derived);
		BuildChrome(sheet, palette, derived);
		BuildTabs(sheet, palette);
		BuildOverlays(sheet, palette, derived);
		BuildItemViews(sheet, palette, derived);
		RegisterIcons(sheet);

		ThemeRegistry.ApplyExtensions(sheet, palette);
		return sheet;
	}

	/// The colours the palette implies, named once so the rules below read as intent rather
	/// than as arithmetic.
	private struct DerivedColors
	{
		/// Sunken text field background.
		public Color InputBackground;
		/// Slider and progress tracks.
		public Color Track;
		/// Check box and radio outlines.
		public Color ControlBorder;
		public Color MenuBorder;
		public Color DialogBorder;
		/// Arrows and chevrons.
		public Color IconDim;
		/// Slider thumb and switch knob.
		public Color Knob;
		/// Text and list selection.
		public Color Selection;
		/// Menu item hover.
		public Color MenuHighlight;
	}

	private static DerivedColors Derived(ThemePalette p)
	{
		DerivedColors derived = .();
		derived.InputBackground = Palette.Darken(p.Surface, 0.25f);
		derived.Track = Palette.Lighten(p.Surface, 0.12f);
		derived.ControlBorder = Palette.Lighten(p.Border, 0.35f);
		derived.MenuBorder = Palette.Lighten(p.Border, 0.20f);
		derived.DialogBorder = Palette.Lighten(p.Border, 0.30f);
		derived.IconDim = Palette.Lighten(p.TextDim, 0.15f);
		derived.Knob = p.Text;
		derived.Selection = WithAlpha(p.PrimaryAccent, 90);
		derived.MenuHighlight = WithAlpha(p.PrimaryAccent, 100);
		return derived;
	}

	private static void BuildButton(StyleSheet sheet, ThemePalette p)
	{
		let background = RoundedStates(p.SurfaceBright, R);
		let checkedBackground = RoundedStates(p.PrimaryAccent, R);
		sheet.OwnDrawable(background);
		sheet.OwnDrawable(checkedBackground);

		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, background)
			.Set(.CheckedBackground, checkedBackground)
			.Set(.TextColor, p.Text)
			.Set(.FontSize, 12.0f)
			.Set(.Padding, Thickness(12, 8));
	}

	/// A state list of rounded rectangles at one uniform radius, with the variants derived.
	private static StateListDrawable RoundedStates(Color baseColor, float radius)
	{
		let list = new StateListDrawable();
		list.Set(.Normal, new RoundedRectDrawable(baseColor, radius));
		list.Set(.Hover, new RoundedRectDrawable(Palette.ComputeHover(baseColor), radius));
		list.Set(.Pressed, new RoundedRectDrawable(Palette.ComputePressed(baseColor), radius));
		list.Set(.Disabled, new RoundedRectDrawable(Palette.ComputeDisabled(baseColor), radius));
		list.Set(.Focused, new RoundedRectDrawable(Palette.ComputeFocused(baseColor), radius));
		return list;
	}

	private static void BuildSurfaces(StyleSheet sheet, ThemePalette p)
	{
		let panel = new RoundedRectDrawable(p.Surface, R, p.Border, 1.0f);
		sheet.OwnDrawable(panel);
		sheet.ForClass("panel").Set(.Background, panel);

		sheet.ForClass("label").Set(.TextColor, p.Text);
		sheet.ForClass("label-dim").Set(.TextColor, p.TextDim);
	}

	private static void BuildTextInput(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		let background = new RoundedRectDrawable(d.InputBackground, R, p.Border, 1.0f);
		sheet.OwnDrawable(background);

		sheet.ForType(typeof(EditText))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, d.Selection);

		// The spin buttons round on their OUTER corners only, so the pair reads as one control
		// tucked into the field's right edge.
		let spinUp = Palette.CreateStateRounded(p.SurfaceBright, CornerRadii(0, R, 0, 0));
		let spinDown = Palette.CreateStateRounded(p.SurfaceBright, CornerRadii(0, 0, R, 0));
		sheet.OwnDrawable(spinUp);
		sheet.OwnDrawable(spinDown);

		sheet.ForType(typeof(NumericField))
			.Set(.Background, background)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, d.Selection);
		sheet.ForTypePseudo(typeof(NumericField), "spin-up").Set(.Background, spinUp);
		sheet.ForTypePseudo(typeof(NumericField), "spin-down").Set(.Background, spinDown);
	}

	private static void BuildToggles(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		let checkUnchecked = new RoundedRectDrawable(d.InputBackground, 3.0f, d.ControlBorder, 1.0f);
		let checkChecked = new RoundedRectDrawable(p.PrimaryAccent, 3.0f, d.ControlBorder, 1.0f);
		sheet.OwnDrawable(checkUnchecked);
		sheet.OwnDrawable(checkChecked);
		sheet.ForTypePseudo(typeof(CheckBox), "box")
			.Set(.Background, checkUnchecked)
			.Set(.Width, 18.0f);
		sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked).Set(.Background, checkChecked);
		sheet.ForType(typeof(CheckBox)).Set(.Spacing, 6.0f);

		// Half the box's width, which is what makes the radio a circle rather than a rounded
		// square.
		let radioUnchecked = new RoundedRectDrawable(d.InputBackground, 9.0f, d.ControlBorder, 1.0f);
		let radioChecked = new RoundedRectDrawable(p.PrimaryAccent, 9.0f, d.ControlBorder, 1.0f);
		sheet.OwnDrawable(radioUnchecked);
		sheet.OwnDrawable(radioChecked);
		sheet.ForTypePseudo(typeof(RadioButton), "box").Set(.Background, radioUnchecked);
		sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
			.Set(.Background, radioChecked);

		let switchOff = new RoundedRectDrawable(p.Surface, 12.0f, p.Border, 1.0f);
		let switchOn = new RoundedRectDrawable(p.PrimaryAccent, 12.0f, p.Border, 1.0f);
		let switchKnob = new RoundedRectDrawable(d.Knob, 10.0f);
		sheet.OwnDrawable(switchOff);
		sheet.OwnDrawable(switchOn);
		sheet.OwnDrawable(switchKnob);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "track").Set(.Background, switchOff);
		sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
			.Set(.Background, switchOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "knob").Set(.Background, switchKnob);
		sheet.ForType(typeof(ToggleSwitch)).Set(.BorderColor, p.Border);
	}

	private static void BuildRangeControls(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		let sliderTrack = new RoundedRectDrawable(d.Track, 2.0f);
		let sliderFill = new RoundedRectDrawable(p.PrimaryAccent, 2.0f);
		let sliderThumb = new RoundedRectDrawable(d.Knob, 8.0f);
		sheet.OwnDrawable(sliderTrack);
		sheet.OwnDrawable(sliderFill);
		sheet.OwnDrawable(sliderThumb);
		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sliderTrack)
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill").Set(.Background, sliderFill);
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sliderThumb)
			.Set(.Width, 16.0f);

		let progressTrack = new RoundedRectDrawable(d.Track, 4.0f);
		let progressFill = new RoundedRectDrawable(p.PrimaryAccent, 4.0f);
		sheet.OwnDrawable(progressTrack);
		sheet.OwnDrawable(progressFill);
		sheet.ForTypePseudo(typeof(ProgressBar), "track").Set(.Background, progressTrack);
		sheet.ForTypePseudo(typeof(ProgressBar), "fill").Set(.Background, progressFill);
	}

	private static void BuildChrome(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		let combo = new RoundedRectDrawable(p.SurfaceBright, R, p.Border, 1.0f);
		sheet.OwnDrawable(combo);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, combo)
			// Matching the surrounding editor content density.
			.Set(.FontSize, 12.0f);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.TextColor, d.IconDim);

		let scrollTrack = new RoundedRectDrawable(
			WithAlpha(Palette.Darken(p.Surface, 0.15f), 150), 5.0f);
		let scrollThumb = new RoundedRectDrawable(
			WithAlpha(Palette.Lighten(p.Border, 0.5f), 200), 5.0f);
		sheet.OwnDrawable(scrollTrack);
		sheet.OwnDrawable(scrollThumb);
		sheet.ForTypePseudo(typeof(ScrollBar), "track").Set(.Background, scrollTrack);
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb").Set(.Background, scrollThumb);

		sheet.ForType(typeof(Separator)).Set(.BorderColor, p.Border);

		let header = new RoundedRectDrawable(p.SurfaceBright, R);
		let headerHover = new RoundedRectDrawable(Palette.Lighten(p.SurfaceBright, 0.1f), R);
		sheet.OwnDrawable(header);
		sheet.OwnDrawable(headerHover);
		// Header text, which a property grid's category headers inherit.
		sheet.ForType(typeof(Expander)).Set(.FontSize, 14.0f);
		sheet.ForTypePseudo(typeof(Expander), "header").Set(.Background, header);
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover).Set(.Background, headerHover);
		sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.TextColor, d.IconDim);
	}

	private static void BuildTabs(StyleSheet sheet, ThemePalette p)
	{
		// Tighter than the theme's radius: a tab strip at the full six reads as a row of pills.
		const float TabRadius = 4.0f;

		let strip = new RoundedRectDrawable(Palette.Darken(p.Surface, 0.15f), TabRadius);
		let content = new RoundedRectDrawable(p.Surface, TabRadius);
		let activeTab = new RoundedRectDrawable(p.Surface, TabRadius);
		let hoverTab = new RoundedRectDrawable(Palette.Lighten(p.Surface, 0.05f), TabRadius);
		sheet.OwnDrawable(strip);
		sheet.OwnDrawable(content);
		sheet.OwnDrawable(activeTab);
		sheet.OwnDrawable(hoverTab);

		sheet.ForTypePseudo(typeof(TabView), "strip").Set(.Background, strip);
		sheet.ForTypePseudo(typeof(TabView), "content").Set(.Background, content);
		sheet.ForTypePseudo(typeof(TabView), "tab").Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.Background, activeTab)
			.Set(.TextColor, p.Text);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.Background, hoverTab)
			.Set(.TextColor, Palette.Lighten(p.TextDim, 0.3f));
		sheet.ForTypePseudo(typeof(TabView), "close-button")
			.Set(.TextColor, p.TextDim)
			.Set(.Width, 12.0f);
		sheet.ForTypePseudoState(typeof(TabView), "close-button", .Hover).Set(.TextColor, p.Text);
		sheet.ForType(typeof(TabView))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent);
	}

	private static void BuildOverlays(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		let menu = new RoundedRectDrawable(p.SurfaceBright, R, d.MenuBorder, 1.0f);
		let menuHover = new RoundedRectDrawable(d.MenuHighlight, 3.0f);
		sheet.OwnDrawable(menu);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menu)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, d.MenuBorder)
			.Set(.AccentColor, d.MenuHighlight);

		// The dialog surface sits BELOW the button surface, so a dialog's buttons stand out
		// instead of blending into it as flat text.
		let dialog = new RoundedRectDrawable(p.Surface, R, d.DialogBorder, 1.0f);
		sheet.OwnDrawable(dialog);
		sheet.ForType(typeof(Dialog)).Set(.Background, dialog);

		let tooltip = new RoundedRectDrawable(WithAlpha(p.SurfaceBright, 235), R, p.Border, 1.0f);
		sheet.OwnDrawable(tooltip);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltip)
			.Set(.TextColor, p.Text);
	}

	private static void BuildItemViews(StyleSheet sheet, ThemePalette p, DerivedColors d)
	{
		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, d.Selection);
		sheet.ForType(typeof(TreeView)).Set(.Background, sheet.OwnColor(p.Background));
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, d.Selection);
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		ThemeBuilderIcons.Bind(sheet, .Checkmark, null, typeof(CheckBox), "checkmark", null);
		// ROUND rather than square, to match the circular radio box above.
		ThemeBuilderIcons.Bind(sheet, .RadioMarkRound, null, typeof(RadioButton), "mark", null);
		ThemeBuilderIcons.Bind(sheet, .Close, null, typeof(TabView), "close-button", null);

		ThemeBuilderIcons.Bind(sheet, .ChevronDown, null, typeof(Expander), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, null, typeof(Expander), "chevron", null);
		ThemeBuilderIcons.Bind(sheet, .ChevronDown, null, typeof(TreeView), "chevron", .Checked);
		ThemeBuilderIcons.Bind(sheet, .ChevronRight, null, typeof(TreeView), "chevron", null);

		ThemeBuilderIcons.BindSubmenuArrow(sheet, null);

		ThemeBuilderIcons.Bind(sheet, .ArrowDown, null, typeof(ComboBox), "arrow", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowUp, null, typeof(NumericField), "arrow-up", null);
		ThemeBuilderIcons.Bind(sheet, .ArrowDown, null, typeof(NumericField), "arrow-down", null);
	}

	/// Keeps the colour and overrides its alpha, written as a byte the way the theme data is.
	private static Color WithAlpha(Color color, int alpha) =>
		.(color.R, color.G, color.B, alpha / 255.0f);
}
