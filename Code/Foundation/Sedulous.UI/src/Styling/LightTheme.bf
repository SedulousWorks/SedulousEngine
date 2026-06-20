namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Factory for creating a light theme as a StyleSheet.
/// Returns a new StyleSheet with refcount 1. Caller must manage the ref.
public static class LightTheme
{
	public static StyleSheet Create()
	{
		return BuildTheme(.Light);
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
		let btnBg = Palette.CreateStateColors(.(220, 222, 230, 255));
		let btnChecked = Palette.CreateStateColors(p.PrimaryAccent);
		sheet.OwnDrawable(btnBg);
		sheet.OwnDrawable(btnChecked);
		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, btnBg)
			.Set(.CheckedBackground, btnChecked)
			.Set(.TextColor, Color(30, 30, 40, 255))
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
		let editBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(editBg);
		sheet.ForType(typeof(EditText))
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 60));

		// === NumericField (shares EditText styling + spin buttons) ===
		let spinBg = Palette.CreateStateColors(Palette.Darken(p.Surface, 0.08f));
		sheet.OwnDrawable(spinBg);
		sheet.ForType(typeof(NumericField))
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 60));
		sheet.ForTypePseudo(typeof(NumericField), "spin-up")
			.Set(.Background, spinBg);
		sheet.ForTypePseudo(typeof(NumericField), "spin-down")
			.Set(.Background, spinBg);

		// === CheckBox ===
		{
			let cbUnchecked = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(cbUnchecked);
			sheet.OwnDrawable(cbChecked);
			sheet.ForTypePseudo(typeof(CheckBox), "box")
				.Set(.Background, cbUnchecked)
				.Set(.Width, 18.0f);
			sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked)
				.Set(.Background, cbChecked);
			sheet.ForType(typeof(CheckBox))
				.Set(.Spacing, 6.0f);
		}

		// === RadioButton ===
		{
			let rbUnchecked = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(rbUnchecked);
			sheet.OwnDrawable(rbChecked);
			sheet.ForTypePseudo(typeof(RadioButton), "box")
				.Set(.Background, rbUnchecked);
			sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
				.Set(.Background, rbChecked);
		}

		// === Slider ===
		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sheet.OwnColor(.(210, 215, 225, 255)))
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent))
			.Set(.Width, 16.0f);

		// === ProgressBar ===
		sheet.ForTypePseudo(typeof(ProgressBar), "track")
			.Set(.Background, sheet.OwnColor(.(210, 215, 225, 255)));
		sheet.ForTypePseudo(typeof(ProgressBar), "fill")
			.Set(.Background, sheet.OwnColor(p.PrimaryAccent));

		// === ToggleSwitch ===
		{
			let swOff = new RoundedRectDrawable(.(200, 205, 215, 255), 0, p.Border, 1);
			let swOn = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(swOff);
			sheet.OwnDrawable(swOn);
			sheet.ForTypePseudo(typeof(ToggleSwitch), "track")
				.Set(.Background, swOff);
			sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
				.Set(.Background, swOn);
			sheet.ForTypePseudo(typeof(ToggleSwitch), "knob")
				.Set(.Background, sheet.OwnColor(p.Surface));
		}

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, comboBg);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow")
			.Set(.TextColor, Color(80, 85, 100, 255));

		// === ScrollBar ===
		sheet.ForTypePseudo(typeof(ScrollBar), "track")
			.Set(.Background, sheet.OwnColor(.(230, 232, 240, 150)));
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb")
			.Set(.Background, sheet.OwnColor(.(160, 165, 180, 200)));

		// === Separator ===
		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		// === Expander ===
		sheet.ForTypePseudo(typeof(Expander), "header")
			.Set(.Background, sheet.OwnColor(.(235, 238, 245, 255)));
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Darken(.(235, 238, 245, 255), 0.05f)));
		sheet.ForTypePseudo(typeof(Expander), "chevron")
			.Set(.TextColor, Color(80, 85, 100, 255));

		// === TabView ===
		sheet.ForTypePseudo(typeof(TabView), "strip")
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.05f)));
		sheet.ForTypePseudo(typeof(TabView), "content")
			.Set(.Background, sheet.OwnColor(p.Surface));
		sheet.ForTypePseudo(typeof(TabView), "tab")
			.Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
			.Set(.Background, sheet.OwnColor(p.Surface))
			.Set(.TextColor, p.Text);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
			.Set(.Background, sheet.OwnColor(Palette.Darken(p.Surface, 0.03f)))
			.Set(.TextColor, Palette.Darken(p.TextDim, 0.2f));
		sheet.ForTypePseudo(typeof(TabView), "close-button")
			.Set(.TextColor, p.TextDim)
			.Set(.Width, 12.0f);
		sheet.ForTypePseudoState(typeof(TabView), "close-button", .Hover)
			.Set(.TextColor, p.Text);
		sheet.ForType(typeof(TabView))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent);

		// === ContextMenu ===
		let menuBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(menuBg);
		let menuHover = new RoundedRectDrawable(.(60, 120, 200, 60), 0);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menuBg)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, Color(60, 120, 200, 60));

		// === Dialog ===
		let dialogBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(dialogBg);
		sheet.ForType(typeof(Dialog))
			.Set(.Background, dialogBg);

		// === Tooltip ===
		let tooltipBg = new RoundedRectDrawable(.(255, 255, 225, 245), 0, .(180, 175, 140, 255), 1);
		sheet.OwnDrawable(tooltipBg);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltipBg)
			.Set(.TextColor, p.Text);

		// === ListView ===
		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 60));

		// === TreeView ===
		sheet.ForType(typeof(TreeView))
			.Set(.Background, sheet.OwnColor(p.Background));

		// === GridView ===
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 60));

		// === Icons ===
		RegisterIcons(sheet);

		// Apply registered extensions.
		ThemeRegistry.ApplyExtensions(sheet, p);

		return sheet;
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		let tint = Color(60, 60, 70, 255); // dark tint for light theme

		// CheckBox checkmark and RadioButton mark use pseudo-elements
		{
			let checkmark = SVGDrawable.FromString(ThemeIcons.Checkmark, tint);
			if (checkmark != null) { sheet.OwnDrawable(checkmark); sheet.ForTypePseudo(typeof(CheckBox), "checkmark").Set(.Background, checkmark); }
			let radioMark = SVGDrawable.FromString(ThemeIcons.RadioMarkSquare, tint);
			if (radioMark != null) { sheet.OwnDrawable(radioMark); sheet.ForTypePseudo(typeof(RadioButton), "mark").Set(.Background, radioMark); }
		}
		// TabView close button uses pseudo-element
		{
			let closeIcon = SVGDrawable.FromString(ThemeIcons.Close, tint);
			if (closeIcon != null) { sheet.OwnDrawable(closeIcon); sheet.ForTypePseudo(typeof(TabView), "close-button").Set(.Background, closeIcon); }
		}
		// Expander chevrons use pseudo-elements (expanded=Checked state)
		{
			let chevExpanded = SVGDrawable.FromString(ThemeIcons.ChevronDown, tint);
			if (chevExpanded != null) { sheet.OwnDrawable(chevExpanded); sheet.ForTypePseudoState(typeof(Expander), "chevron", .Checked).Set(.Background, chevExpanded); }
			let chevCollapsed = SVGDrawable.FromString(ThemeIcons.ChevronRight, tint);
			if (chevCollapsed != null) { sheet.OwnDrawable(chevCollapsed); sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.Background, chevCollapsed); }
		}
		// TreeView chevrons use pseudo-elements
		{
			let tvChevExpanded = SVGDrawable.FromString(ThemeIcons.ChevronDown, tint);
			if (tvChevExpanded != null) { sheet.OwnDrawable(tvChevExpanded); sheet.ForTypePseudoState(typeof(TreeView), "chevron", .Checked).Set(.Background, tvChevExpanded); }
			let tvChevCollapsed = SVGDrawable.FromString(ThemeIcons.ChevronRight, tint);
			if (tvChevCollapsed != null) { sheet.OwnDrawable(tvChevCollapsed); sheet.ForTypePseudo(typeof(TreeView), "chevron").Set(.Background, tvChevCollapsed); }
		}
		// ContextMenu submenu arrow
		{
			let subArrow = SVGDrawable.FromString(ThemeIcons.ChevronRight, tint);
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
			let arrowDown = SVGDrawable.FromString(ThemeIcons.ArrowDown, tint);
			if (arrowDown != null) { sheet.OwnDrawable(arrowDown); sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.Background, arrowDown); }
			let arrowUp = SVGDrawable.FromString(ThemeIcons.ArrowUp, tint);
			let arrowDn2 = SVGDrawable.FromString(ThemeIcons.ArrowDown, tint);
			if (arrowUp != null) { sheet.OwnDrawable(arrowUp); sheet.ForTypePseudo(typeof(NumericField), "arrow-up").Set(.Background, arrowUp); }
			if (arrowDn2 != null) { sheet.OwnDrawable(arrowDn2); sheet.ForTypePseudo(typeof(NumericField), "arrow-down").Set(.Background, arrowDn2); }
		}
	}
}
