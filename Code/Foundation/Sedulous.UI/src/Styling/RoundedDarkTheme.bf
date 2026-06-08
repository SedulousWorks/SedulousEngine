namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Dark theme variant with consistent rounded corners everywhere.
/// Demonstrates that the drawable-based styling system supports
/// different visual styles from the same control set.
public static class RoundedDarkTheme
{
	public static StyleSheet Create()
	{
		return BuildTheme(.Dark);
	}

	private static StyleSheet BuildTheme(ThemePalette p)
	{
		let sheet = new StyleSheet();
		let R = 6.0f; // consistent corner radius

		// === Global defaults ===
		sheet.ForType(typeof(View))
			.Set(.TextColor, p.Text)
			.Set(.FontSize, 16.0f);

		// === Button - rounded state drawables ===
		let btnBg = new StateListDrawable(true);
		btnBg.Set(.Normal, new RoundedRectDrawable(p.SurfaceBright, R));
		btnBg.Set(.Hover, new RoundedRectDrawable(Palette.ComputeHover(p.SurfaceBright), R));
		btnBg.Set(.Pressed, new RoundedRectDrawable(Palette.ComputePressed(p.SurfaceBright), R));
		btnBg.Set(.Disabled, new RoundedRectDrawable(Palette.ComputeDisabled(p.SurfaceBright), R));
		btnBg.Set(.Focused, new RoundedRectDrawable(Palette.ComputeFocused(p.SurfaceBright), R));
		sheet.OwnDrawable(btnBg);

		let btnChecked = new StateListDrawable(true);
		btnChecked.Set(.Normal, new RoundedRectDrawable(p.PrimaryAccent, R));
		btnChecked.Set(.Hover, new RoundedRectDrawable(Palette.ComputeHover(p.PrimaryAccent), R));
		btnChecked.Set(.Pressed, new RoundedRectDrawable(Palette.ComputePressed(p.PrimaryAccent), R));
		btnChecked.Set(.Disabled, new RoundedRectDrawable(Palette.ComputeDisabled(p.PrimaryAccent), R));
		btnChecked.Set(.Focused, new RoundedRectDrawable(Palette.ComputeFocused(p.PrimaryAccent), R));
		sheet.OwnDrawable(btnChecked);

		sheet.ForType(typeof(ButtonBase))
			.Set(.Background, btnBg)
			.Set(.CheckedBackground, btnChecked)
			.Set(.TextColor, Color(240, 240, 245, 255))
			.Set(.Padding, Thickness(12, 8));

		// === Panel ===
		let panelBg = new RoundedRectDrawable(p.Surface, R, p.Border, 1);
		sheet.OwnDrawable(panelBg);
		sheet.ForClass("panel")
			.Set(.Background, panelBg);

		// === Label ===
		sheet.ForClass("label")
			.Set(.TextColor, p.Text);
		sheet.ForClass("label-dim")
			.Set(.TextColor, p.TextDim);

		// === EditText ===
		let editBg = new RoundedRectDrawable(.(30, 32, 42, 255), R, p.Border, 1);
		sheet.OwnDrawable(editBg);
		sheet.ForType(typeof(EditText))
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === NumericField (shares EditText styling + rounded spin buttons) ===
		{
			let spinColor = Color(50, 55, 68, 255);
			let spinUp = Palette.CreateStateRounded(spinColor, .(0, R, 0, 0));
			let spinDown = Palette.CreateStateRounded(spinColor, .(0, 0, R, 0));
			sheet.OwnDrawable(spinUp);
			sheet.OwnDrawable(spinDown);
			sheet.ForType(typeof(NumericField))
				.Set(.Background, editBg)
				.Set(.TextColor, p.Text)
				.Set(.PlaceholderColor, p.TextDim)
				.Set(.FontSize, 14.0f)
				.Set(.Padding, Thickness(6, 4))
				.Set(.CursorColor, p.PrimaryAccent)
				.Set(.SelectionColor, Color(60, 120, 200, 80));
			sheet.ForTypePseudo(typeof(NumericField), "spin-up")
				.Set(.Background, spinUp);
			sheet.ForTypePseudo(typeof(NumericField), "spin-down")
				.Set(.Background, spinDown);
		}

		// === CheckBox - rounded ===
		let cbBorder = Color(100, 105, 120, 255);
		let cbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 3, cbBorder, 1);
		let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 3, cbBorder, 1);
		sheet.OwnDrawable(cbUnchecked);
		sheet.OwnDrawable(cbChecked);
		sheet.ForTypePseudo(typeof(CheckBox), "box")
			.Set(.Background, cbUnchecked)
			.Set(.Width, 18.0f);
		sheet.ForTypePseudoState(typeof(CheckBox), "box", .Checked)
			.Set(.Background, cbChecked);
		sheet.ForType(typeof(CheckBox))
			.Set(.Spacing, 6.0f);

		// === RadioButton - circular ===
		let rbBorder = Color(100, 105, 120, 255);
		let rbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 9, rbBorder, 1);
		let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 9, rbBorder, 1);
		sheet.OwnDrawable(rbUnchecked);
		sheet.OwnDrawable(rbChecked);
		sheet.ForTypePseudo(typeof(RadioButton), "box")
			.Set(.Background, rbUnchecked);
		sheet.ForTypePseudoState(typeof(RadioButton), "box", .Checked)
			.Set(.Background, rbChecked);

		// === Slider - rounded track and thumb ===
		let sliderTrack = new RoundedRectDrawable(.(50, 52, 62, 255), 2);
		let sliderFill = new RoundedRectDrawable(p.PrimaryAccent, 2);
		let sliderThumb = new RoundedRectDrawable(.(220, 220, 230, 255), 8);
		sheet.OwnDrawable(sliderTrack);
		sheet.OwnDrawable(sliderFill);
		sheet.OwnDrawable(sliderThumb);
		sheet.ForTypePseudo(typeof(Slider), "track")
			.Set(.Background, sliderTrack)
			.Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "fill")
			.Set(.Background, sliderFill);
		sheet.ForTypePseudo(typeof(Slider), "thumb")
			.Set(.Background, sliderThumb)
			.Set(.Width, 16.0f);

		// === ProgressBar - rounded ===
		let progTrack = new RoundedRectDrawable(.(50, 52, 62, 255), 4);
		let progFill = new RoundedRectDrawable(p.PrimaryAccent, 4);
		sheet.OwnDrawable(progTrack);
		sheet.OwnDrawable(progFill);
		sheet.ForTypePseudo(typeof(ProgressBar), "track")
			.Set(.Background, progTrack);
		sheet.ForTypePseudo(typeof(ProgressBar), "fill")
			.Set(.Background, progFill);

		// === ToggleSwitch - pill-shaped track (with border) and round knob ===
		let switchTrackOff = new RoundedRectDrawable(p.Surface, 12, p.Border, 1);
		let switchTrackOn = new RoundedRectDrawable(p.PrimaryAccent, 12, p.Border, 1);
		let switchKnob = new RoundedRectDrawable(.(230, 230, 235, 255), 10);
		sheet.OwnDrawable(switchTrackOff);
		sheet.OwnDrawable(switchTrackOn);
		sheet.OwnDrawable(switchKnob);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "track")
			.Set(.Background, switchTrackOff);
		sheet.ForTypePseudoState(typeof(ToggleSwitch), "track", .Checked)
			.Set(.Background, switchTrackOn);
		sheet.ForTypePseudo(typeof(ToggleSwitch), "knob")
			.Set(.Background, switchKnob);
		sheet.ForType(typeof(ToggleSwitch))
			.Set(.BorderColor, p.Border);

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(.(40, 42, 52, 255), R, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, comboBg);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow")
			.Set(.TextColor, Color(180, 185, 200, 255));

		// === ScrollBar - rounded ===
		let scrollTrack = new RoundedRectDrawable(.(40, 42, 50, 150), 5);
		let scrollThumb = new RoundedRectDrawable(.(100, 110, 130, 200), 5);
		sheet.OwnDrawable(scrollTrack);
		sheet.OwnDrawable(scrollThumb);
		sheet.ForTypePseudo(typeof(ScrollBar), "track")
			.Set(.Background, scrollTrack);
		sheet.ForTypePseudo(typeof(ScrollBar), "thumb")
			.Set(.Background, scrollThumb);

		// === Separator ===
		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		// === Expander ===
		let expanderHeader = new RoundedRectDrawable(.(50, 55, 68, 255), R);
		let expanderHover = new RoundedRectDrawable(Palette.Lighten(.(50, 55, 68, 255), 0.1f), R);
		sheet.OwnDrawable(expanderHeader);
		sheet.OwnDrawable(expanderHover);
		sheet.ForTypePseudo(typeof(Expander), "header")
			.Set(.Background, expanderHeader);
		sheet.ForTypePseudoState(typeof(Expander), "header", .Hover)
			.Set(.Background, expanderHover);
		sheet.ForTypePseudo(typeof(Expander), "chevron")
			.Set(.TextColor, Color(180, 185, 200, 255));

		// === TabView - rounded tab backgrounds ===
		{
			let tabR = 4.0f;
			let stripBg = new RoundedRectDrawable(Palette.Darken(p.Surface, 0.15f), tabR);
			let contentBg = new RoundedRectDrawable(p.Surface, tabR);
			let activeTab = new RoundedRectDrawable(p.Surface, tabR);
			let hoverTab = new RoundedRectDrawable(Palette.Lighten(p.Surface, 0.05f), tabR);
			sheet.OwnDrawable(stripBg);
			sheet.OwnDrawable(contentBg);
			sheet.OwnDrawable(activeTab);
			sheet.OwnDrawable(hoverTab);
			sheet.ForTypePseudo(typeof(TabView), "strip")
				.Set(.Background, stripBg);
			sheet.ForTypePseudo(typeof(TabView), "content")
				.Set(.Background, contentBg);
			sheet.ForTypePseudo(typeof(TabView), "tab")
				.Set(.TextColor, p.TextDim);
			sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked)
				.Set(.Background, activeTab)
				.Set(.TextColor, p.Text);
			sheet.ForTypePseudoState(typeof(TabView), "tab", .Hover)
				.Set(.Background, hoverTab)
				.Set(.TextColor, Palette.Lighten(p.TextDim, 0.3f));
			sheet.ForTypePseudo(typeof(TabView), "close-button")
				.Set(.TextColor, p.TextDim)
				.Set(.Width, 12.0f);
			sheet.ForTypePseudoState(typeof(TabView), "close-button", .Hover)
				.Set(.TextColor, p.Text);
			sheet.ForType(typeof(TabView))
				.Set(.BorderColor, p.Border)
				.Set(.AccentColor, p.PrimaryAccent);
		}

		// === ContextMenu ===
		let menuBg = new RoundedRectDrawable(.(45, 48, 58, 255), R, .(70, 75, 90, 255), 1);
		sheet.OwnDrawable(menuBg);
		let menuHover = new RoundedRectDrawable(.(60, 120, 200, 100), 3);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menuBg)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, Color(70, 75, 90, 255))
			.Set(.AccentColor, Color(60, 120, 200, 100));

		// === Dialog ===
		let dialogBg = new RoundedRectDrawable(.(50, 52, 62, 255), R, .(80, 85, 100, 255), 1);
		sheet.OwnDrawable(dialogBg);
		sheet.ForType(typeof(Dialog))
			.Set(.Background, dialogBg);

		// === Tooltip ===
		let tooltipBg = new RoundedRectDrawable(.(40, 42, 50, 230), R, .(70, 75, 85, 255), 1);
		sheet.OwnDrawable(tooltipBg);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltipBg)
			.Set(.TextColor, p.Text);

		// === ListView ===
		sheet.ForType(typeof(ListView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === TreeView ===
		sheet.ForType(typeof(TreeView))
			.Set(.Background, sheet.OwnColor(p.Background));

		// === GridView ===
		sheet.ForType(typeof(GridView))
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === Icons ===
		RegisterIcons(sheet);

		ThemeRegistry.ApplyExtensions(sheet, p);
		return sheet;
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		// CheckBox checkmark and RadioButton mark use pseudo-elements
		{
			let checkmark = SVGDrawable.FromString(ThemeIcons.Checkmark);
			if (checkmark != null) { sheet.OwnDrawable(checkmark); sheet.ForTypePseudo(typeof(CheckBox), "checkmark").Set(.Background, checkmark); }
			let radioMark = SVGDrawable.FromString(ThemeIcons.RadioMarkRound);
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
