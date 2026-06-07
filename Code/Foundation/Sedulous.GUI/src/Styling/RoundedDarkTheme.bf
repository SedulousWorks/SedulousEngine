namespace Sedulous.GUI;

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

		sheet.ForType(typeof(View), "button")
			.Set(.Background, btnBg)
			.Set(.CheckedBackground, btnChecked)
			.Set(.TextColor, Color(240, 240, 245, 255))
			.Set(.Padding, Thickness(12, 8));

		// === Panel ===
		let panelBg = new RoundedRectDrawable(p.Surface, R, p.Border, 1);
		sheet.OwnDrawable(panelBg);
		sheet.ForType(typeof(View), "panel")
			.Set(.Background, panelBg);

		// === Label ===
		sheet.ForType(typeof(View), "label")
			.Set(.TextColor, p.Text);
		sheet.ForType(typeof(View), "label-dim")
			.Set(.TextColor, p.TextDim);

		// === EditText ===
		let editBg = new RoundedRectDrawable(.(30, 32, 42, 255), R, p.Border, 1);
		sheet.OwnDrawable(editBg);
		sheet.ForType(typeof(View), "edittext")
			.Set(.Background, editBg)
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === NumericField spin buttons - rounded right corners ===
		{
			let spinColor = Color(50, 55, 68, 255);
			let spinUp = Palette.CreateStateRounded(spinColor, .(0, R, 0, 0));
			let spinDown = Palette.CreateStateRounded(spinColor, .(0, 0, R, 0));
			sheet.OwnDrawable(spinUp);
			sheet.OwnDrawable(spinDown);
			sheet.ForType(typeof(View), "edittext")
				.Set(.SpinUpDrawable, spinUp)
				.Set(.SpinDownDrawable, spinDown);
		}

		// === CheckBox - rounded ===
		let cbBorder = Color(100, 105, 120, 255);
		let cbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 3, cbBorder, 1);
		let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 3, cbBorder, 1);
		sheet.OwnDrawable(cbUnchecked);
		sheet.OwnDrawable(cbChecked);
		sheet.ForType(typeof(View), "checkbox")
			.Set(.BoxDrawable, cbUnchecked)
			.Set(.CheckedBackground, cbChecked)
			.Set(.BoxSize, 18.0f)
			.Set(.Spacing, 6.0f);

		// === RadioButton - circular ===
		let rbBorder = Color(100, 105, 120, 255);
		let rbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 9, rbBorder, 1);
		let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 9, rbBorder, 1);
		sheet.OwnDrawable(rbUnchecked);
		sheet.OwnDrawable(rbChecked);
		sheet.ForType(typeof(View), "radiobutton")
			.Set(.BoxDrawable, rbUnchecked)
			.Set(.CheckedBackground, rbChecked);

		// === Slider - rounded track and thumb ===
		let sliderTrack = new RoundedRectDrawable(.(50, 52, 62, 255), 2);
		let sliderFill = new RoundedRectDrawable(p.PrimaryAccent, 2);
		let sliderThumb = new RoundedRectDrawable(.(220, 220, 230, 255), 8);
		sheet.OwnDrawable(sliderTrack);
		sheet.OwnDrawable(sliderFill);
		sheet.OwnDrawable(sliderThumb);
		sheet.ForType(typeof(View), "slider")
			.Set(.TrackDrawable, sliderTrack)
			.Set(.FillDrawable, sliderFill)
			.Set(.ThumbDrawable, sliderThumb)
			.Set(.ThumbSize, 16.0f)
			.Set(.TrackHeight, 4.0f);

		// === ProgressBar - rounded ===
		let progTrack = new RoundedRectDrawable(.(50, 52, 62, 255), 4);
		let progFill = new RoundedRectDrawable(p.PrimaryAccent, 4);
		sheet.OwnDrawable(progTrack);
		sheet.OwnDrawable(progFill);
		sheet.ForType(typeof(View), "progressbar")
			.Set(.TrackDrawable, progTrack)
			.Set(.FillDrawable, progFill);

		// === ToggleSwitch - pill-shaped track (with border) and round knob ===
		let switchTrackOff = new RoundedRectDrawable(p.Surface, 12, p.Border, 1);
		let switchTrackOn = new RoundedRectDrawable(p.PrimaryAccent, 12, p.Border, 1);
		let switchKnob = new RoundedRectDrawable(.(230, 230, 235, 255), 10);
		sheet.OwnDrawable(switchTrackOff);
		sheet.OwnDrawable(switchTrackOn);
		sheet.OwnDrawable(switchKnob);
		sheet.ForType(typeof(View), "toggleswitch")
			.Set(.TrackDrawable, switchTrackOff)
			.Set(.TrackOnDrawable, switchTrackOn)
			.Set(.KnobDrawable, switchKnob)
			.Set(.BorderColor, p.Border);

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(.(40, 42, 52, 255), R, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(View), "combobox")
			.Set(.Background, comboBg)
			.Set(.ArrowColor, Color(180, 185, 200, 255));

		// === ScrollBar - rounded ===
		let scrollTrack = new RoundedRectDrawable(.(40, 42, 50, 150), 5);
		let scrollThumb = new RoundedRectDrawable(.(100, 110, 130, 200), 5);
		sheet.OwnDrawable(scrollTrack);
		sheet.OwnDrawable(scrollThumb);
		sheet.ForType(typeof(View), "scrollbar")
			.Set(.TrackDrawable, scrollTrack)
			.Set(.ThumbDrawable, scrollThumb);

		// === Separator ===
		sheet.ForType(typeof(View), "separator")
			.Set(.BorderColor, p.Border);

		// === Expander ===
		let expanderHeader = new RoundedRectDrawable(.(50, 55, 68, 255), R);
		let expanderHover = new RoundedRectDrawable(Palette.Lighten(.(50, 55, 68, 255), 0.1f), R);
		sheet.OwnDrawable(expanderHeader);
		sheet.OwnDrawable(expanderHover);
		sheet.ForType(typeof(View), "expander")
			.Set(.HeaderDrawable, expanderHeader)
			.Set(.HeaderHoverDrawable, expanderHover)
			.Set(.ArrowColor, Color(180, 185, 200, 255));

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
			sheet.ForType(typeof(View), "tabview")
				.Set(.StripDrawable, stripBg)
				.Set(.ContentDrawable, contentBg)
				.Set(.ActiveTabDrawable, activeTab)
				.Set(.HoverTabDrawable, hoverTab)
				.Set(.BorderColor, p.Border)
				.Set(.AccentColor, p.PrimaryAccent)
				.Set(.ActiveTabTextColor, p.Text)
				.Set(.InactiveTabTextColor, p.TextDim)
				.Set(.HoverTabTextColor, Palette.Lighten(p.TextDim, 0.3f))
				.Set(.CloseButtonColor, p.TextDim)
				.Set(.CloseButtonHoverColor, p.Text);
		}

		// === ContextMenu ===
		let menuBg = new RoundedRectDrawable(.(45, 48, 58, 255), R, .(70, 75, 90, 255), 1);
		sheet.OwnDrawable(menuBg);
		let menuHover = new RoundedRectDrawable(.(60, 120, 200, 100), 3);
		sheet.OwnDrawable(menuHover);
		sheet.ForType(typeof(View), "contextmenu")
			.Set(.Background, menuBg)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, Color(70, 75, 90, 255))
			.Set(.AccentColor, Color(60, 120, 200, 100));

		// === Dialog ===
		let dialogBg = new RoundedRectDrawable(.(50, 52, 62, 255), R, .(80, 85, 100, 255), 1);
		sheet.OwnDrawable(dialogBg);
		sheet.ForType(typeof(View), "dialog")
			.Set(.Background, dialogBg);

		// === Tooltip ===
		let tooltipBg = new RoundedRectDrawable(.(40, 42, 50, 230), R, .(70, 75, 85, 255), 1);
		sheet.OwnDrawable(tooltipBg);
		sheet.ForType(typeof(View), "tooltip")
			.Set(.Background, tooltipBg)
			.Set(.TextColor, p.Text);

		// === ListView ===
		sheet.ForType(typeof(View), "listview")
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === TreeView ===
		sheet.ForType(typeof(View), "treeview")
			.Set(.Background, sheet.OwnColor(p.Background));

		// === GridView ===
		sheet.ForType(typeof(View), "gridview")
			.Set(.Background, sheet.OwnColor(p.Background))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// === Icons ===
		RegisterIcons(sheet);

		ThemeRegistry.ApplyExtensions(sheet, p);
		return sheet;
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		void Reg(StyleProperty prop, StringView svg, StringView styleId = default)
		{
			let d = SVGDrawable.FromString(svg);
			if (d != null)
			{
				sheet.OwnDrawable(d);
				if (styleId.IsEmpty)
					sheet.ForType(typeof(View)).Set(prop, d);
				else
					sheet.ForType(typeof(View), styleId).Set(prop, d);
			}
		}

		Reg(.CheckmarkIcon, ThemeIcons.Checkmark, "checkbox");
		Reg(.RadioMarkIcon, ThemeIcons.RadioMarkRound, "radiobutton");
		Reg(.CloseIcon, ThemeIcons.Close, "tabview");
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, "expander");
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, "expander");
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, "treeview");
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, "treeview");
		Reg(.ArrowDownIcon, ThemeIcons.ArrowDown);
		Reg(.ArrowUpIcon, ThemeIcons.ArrowUp);
	}
}
