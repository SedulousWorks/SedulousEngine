namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Factory for creating the default dark theme as a StyleSheet.
/// All visual regions use Drawable properties (ColorDrawable for flat theme).
/// Game themes replace these with NineSlice/Atlas drawables.
/// Returns a new StyleSheet with refcount 1. Caller must manage the ref.
public static class DarkTheme
{
	public static StyleSheet Create()
	{
		return BuildTheme(.Dark);
	}

	public static StyleSheet Create(ThemePalette palette)
	{
		return BuildTheme(palette);
	}

	private static StyleSheet BuildTheme(ThemePalette p)
	{
		let sheet = new StyleSheet();

		// === Global defaults (View base type) ===
		sheet.ForType(typeof(View))
			.Set(.TextColor, p.Text)
			.Set(.FontSize, 16.0f);

		// === Button ===
		let btnBg = Palette.CreateStateColors(p.SurfaceBright);
		let btnChecked = Palette.CreateStateColors(p.PrimaryAccent);
		sheet.OwnDrawable(btnBg);
		sheet.OwnDrawable(btnChecked);
		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, btnBg)
			.Set(.CheckedBackground, btnChecked)
			.Set(.TextColor, Color32(240, 240, 245, 255))
			.Set(.Padding, Thickness(12, 8))
			.Set(.CornerRadius, 0.0f);

		// === Panel ===
		let panelBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(panelBg);
		sheet.ForClass("panel")
			.Set(.Background, panelBg);

		// === Label ===
		sheet.ForClass("label")
			.Set(.TextColor, p.Text);

		sheet.ForClass("label-dim")
			.Set(.TextColor, p.TextDim);

		// === EditText ===
		let editBg = new RoundedRectDrawable(.(30, 32, 42, 255), 0, p.Border, 1);
		sheet.OwnDrawable(editBg);
		sheet.ForType(typeof(EditText))
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color32(60, 120, 200, 80));

		// === NumericField (shares EditText styling + spin buttons) ===
		let spinBg = Palette.CreateStateColors(.(50, 55, 68, 255));
		sheet.OwnDrawable(spinBg);
		sheet.ForType(typeof(NumericField))
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color32(60, 120, 200, 80));
		sheet.ForTypePseudo(typeof(NumericField), "spin-up")
			.Set(.Background, spinBg);
		sheet.ForTypePseudo(typeof(NumericField), "spin-down")
			.Set(.Background, spinBg);

		// === CheckBox ===
		let cbBorder = Color32(100, 105, 120, 255);
		let cbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 0, cbBorder, 1);
		let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, cbBorder, 1);
		sheet.OwnDrawable(cbUnchecked);
		sheet.OwnDrawable(cbChecked);
		sheet.ForTypePseudo(typeof(CheckBox), "box")
			.Set(.Background, cbUnchecked)
			.Set(.Width, 18.0f);
		sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked)
			.Set(.Background, cbChecked);
		sheet.ForType(typeof(CheckBox))
			.Set(.Spacing, 6.0f);

		// === RadioButton ===
		let rbBorder = Color32(100, 105, 120, 255);
		let rbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 0, rbBorder, 1);
		let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, rbBorder, 1);
		sheet.OwnDrawable(rbUnchecked);
		sheet.OwnDrawable(rbChecked);
		sheet.ForTypePseudo(typeof(RadioButton), "box")
			.Set(.Background, rbUnchecked);
		sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
			.Set(.Background, rbChecked);

		// === Slider ===
		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sheet.OwnColor(.(50, 52, 62, 255)))
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sheet.OwnColor(.(220, 220, 230, 255)))
			.Set(.Width, 16.0f);

		// === ProgressBar ===
		sheet.ForTypePseudo(typeof(ProgressBar), "track")
			.Set(.Background, sheet.OwnColor(.(50, 52, 62, 255)));
		sheet.ForTypePseudo(typeof(ProgressBar), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));

		// === ToggleSwitch ===
		{
			let swOff = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let swOn = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(swOff);
			sheet.OwnDrawable(swOn);
			sheet.ForTypePseudo(typeof(ToggleSwitch), "track")
				.Set(.Background, swOff);
			sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
				.Set(.Background, swOn);
			sheet.ForTypePseudo(typeof(ToggleSwitch), "knob")
				.Set(.Background, sheet.OwnColor(.(230, 230, 235, 255)));
		}

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(.(40, 42, 52, 255), 0, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, comboBg);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow")
			.Set(.TextColor, Color32(180, 185, 200, 255));

		// === ScrollBar ===
		sheet.ForTypePseudo(typeof(ScrollBar), "track")
			.Set(.Background, sheet.OwnColor(.(40, 42, 50, 150)));
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb")
			.Set(.Background, sheet.OwnColor(.(100, 110, 130, 200)));

		// === Separator ===
		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		// === Expander ===
		sheet.ForTypePseudo(typeof(Expander), "header")
			.Set(.Background, sheet.OwnColor(.(50, 55, 68, 255)));
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Lighten(.(50, 55, 68, 255), 0.1f)));
		sheet.ForTypePseudo(typeof(Expander), "chevron")
			.Set(.TextColor, Color32(180, 185, 200, 255));

		// === TabView ===
		sheet.ForTypePseudo(typeof(TabView), "strip")
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.15f)));
		sheet.ForTypePseudo(typeof(TabView), "content")
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Lighten(p.Surface, 0.05f)));
		sheet.ForTypePseudo(typeof(TabView), "tab")
			.Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.TextColor, p.Text);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.TextColor, Palette.Lighten(p.TextDim, 0.3f));
		sheet.ForTypePseudo(typeof(TabView), "close-button")
			.Set(.TextColor, p.TextDim)
			.Set(.Width, 12.0f);
		sheet.ForTypePseudoState(typeof(TabView), "close-button", .Hover)
			.Set(.TextColor, p.Text);
		sheet.ForType(typeof(TabView))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent);

		// === ContextMenu ===
		let menuBg = new RoundedRectDrawable(.(45, 48, 58, 255), 0, .(70, 75, 90, 255), 1);
		sheet.OwnDrawable(menuBg);
		let menuHover = new RoundedRectDrawable(.(60, 120, 200, 100), 0);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menuBg)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, Color32(70, 75, 90, 255))
			.Set(.AccentColor, Color32(60, 120, 200, 100));

		// === Dialog ===
		let dialogBg = new RoundedRectDrawable(.(50, 52, 62, 255), 0, .(80, 85, 100, 255), 1);
		sheet.OwnDrawable(dialogBg);
		sheet.ForType(typeof(Dialog))
			.Set(.Background, dialogBg);

		// === Tooltip ===
		let tooltipBg = new RoundedRectDrawable(.(40, 42, 50, 230), 0, .(70, 75, 85, 255), 1);
		sheet.OwnDrawable(tooltipBg);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltipBg)
			.Set(.TextColor, p.Text);

		// === ListView ===
		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color32(60, 120, 200, 80));

		// === TreeView ===
		sheet.ForType(typeof(TreeView))
			.Set(.Background, sheet.OwnColor(p.Background));

		// === GridView ===
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color32(60, 120, 200, 80));

		// === Icons ===
		RegisterIcons(sheet);

		// Apply registered extensions.
		ThemeRegistry.ApplyExtensions(sheet, p);

		return sheet;
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		// CheckBox checkmark and RadioButton mark use pseudo-elements
		{
			let checkmark = SVGDrawable.FromString(ThemeIcons.Checkmark);
			if (checkmark != null) { sheet.OwnDrawable(checkmark); sheet.ForTypePseudo(typeof(CheckBox), "checkmark").Set(.Background, checkmark); }
			let radioMark = SVGDrawable.FromString(ThemeIcons.RadioMarkSquare);
			if (radioMark != null) { sheet.OwnDrawable(radioMark); sheet.ForTypePseudo(typeof(RadioButton), "mark").Set(.Background, radioMark); }
		}
		// TabView close button uses pseudo-element
		{
			let closeIcon = SVGDrawable.FromString(ThemeIcons.Close);
			if (closeIcon != null) { sheet.OwnDrawable(closeIcon); sheet.ForTypePseudo(typeof(TabView), "close-button").Set(.Background, closeIcon); }
		}
		// Expander chevrons use pseudo-elements (expanded=Checked state)
		{
			let chevExpanded = SVGDrawable.FromString(ThemeIcons.ChevronDown);
			if (chevExpanded != null) { sheet.OwnDrawable(chevExpanded); sheet.ForTypePseudoState(typeof(Expander), "chevron", .Checked).Set(.Background, chevExpanded); }
			let chevCollapsed = SVGDrawable.FromString(ThemeIcons.ChevronRight);
			if (chevCollapsed != null) { sheet.OwnDrawable(chevCollapsed); sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.Background, chevCollapsed); }
		}
		// TreeView chevrons use pseudo-elements
		{
			let tvChevExpanded = SVGDrawable.FromString(ThemeIcons.ChevronDown);
			if (tvChevExpanded != null) { sheet.OwnDrawable(tvChevExpanded); sheet.ForTypePseudoState(typeof(TreeView), "chevron", .Checked).Set(.Background, tvChevExpanded); }
			let tvChevCollapsed = SVGDrawable.FromString(ThemeIcons.ChevronRight);
			if (tvChevCollapsed != null) { sheet.OwnDrawable(tvChevCollapsed); sheet.ForTypePseudo(typeof(TreeView), "chevron").Set(.Background, tvChevCollapsed); }
		}
		// ContextMenu submenu arrow
		{
			let subArrow = SVGDrawable.FromString(ThemeIcons.ChevronRight);
			if (subArrow != null)
			{
				sheet.OwnDrawable(subArrow);
				let rule = new StyleRule();
				rule.Selector.AddClass("contextmenu");
				rule.Selector.SetPseudoElement("submenu-arrow");
				rule.Set(.Background, subArrow);
				sheet.AddRule(rule);
			}
		}
		// ComboBox and NumericField arrow icons use pseudo-elements
		{
			let arrowDown = SVGDrawable.FromString(ThemeIcons.ArrowDown);
			if (arrowDown != null) { sheet.OwnDrawable(arrowDown); sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.Background, arrowDown); }
			let arrowUp = SVGDrawable.FromString(ThemeIcons.ArrowUp);
			let arrowDn2 = SVGDrawable.FromString(ThemeIcons.ArrowDown);
			if (arrowUp != null) { sheet.OwnDrawable(arrowUp); sheet.ForTypePseudo(typeof(NumericField), "arrow-up").Set(.Background, arrowUp); }
			if (arrowDn2 != null) { sheet.OwnDrawable(arrowDn2); sheet.ForTypePseudo(typeof(NumericField), "arrow-down").Set(.Background, arrowDn2); }
		}
	}
}
