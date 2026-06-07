namespace Sedulous.GUI;

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
			.Set(.SelectionColor, Color(60, 120, 200, 60))
			.Set(.SpinUpDrawable, spinBg)
			.Set(.SpinDownDrawable, spinBg);

		// === CheckBox ===
		{
			let cbUnchecked = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(cbUnchecked);
			sheet.OwnDrawable(cbChecked);
			sheet.ForType(typeof(CheckBox))
				.Set(.BoxDrawable, cbUnchecked)
				.Set(.CheckedBackground, cbChecked)
				.Set(.BoxSize, 18.0f)
				.Set(.Spacing, 6.0f);
		}

		// === RadioButton ===
		{
			let rbUnchecked = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(rbUnchecked);
			sheet.OwnDrawable(rbChecked);
			sheet.ForType(typeof(RadioButton))
				.Set(.BoxDrawable, rbUnchecked)
				.Set(.CheckedBackground, rbChecked);
		}

		// === Slider ===
		sheet.ForType(typeof(Slider))
			.Set(.TrackDrawable, sheet.OwnColor(.(210, 215, 225, 255)))
			.Set(.FillDrawable, sheet.OwnColor(p.PrimaryAccent))
			.Set(.ThumbDrawable, sheet.OwnColor(p.PrimaryAccent))
			.Set(.ThumbSize, 16.0f)
			.Set(.TrackHeight, 4.0f);

		// === ProgressBar ===
		sheet.ForType(typeof(ProgressBar))
			.Set(.TrackDrawable, sheet.OwnColor(.(210, 215, 225, 255)))
			.Set(.FillDrawable, sheet.OwnColor(p.PrimaryAccent));

		// === ToggleSwitch ===
		{
			let swOff = new RoundedRectDrawable(.(200, 205, 215, 255), 0, p.Border, 1);
			let swOn = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(swOff);
			sheet.OwnDrawable(swOn);
			sheet.ForType(typeof(ToggleSwitch))
				.Set(.TrackDrawable, swOff)
				.Set(.TrackOnDrawable, swOn)
				.Set(.KnobDrawable, sheet.OwnColor(p.Surface));
		}

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, comboBg)
			.Set(.ArrowColor, Color(80, 85, 100, 255));

		// === ScrollBar ===
		sheet.ForType(typeof(ScrollBar))
			.Set(.TrackDrawable, sheet.OwnColor(.(230, 232, 240, 150)))
			.Set(.ThumbDrawable, sheet.OwnColor(.(160, 165, 180, 200)));

		// === Separator ===
		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		// === Expander ===
		sheet.ForType(typeof(Expander))
			.Set(.HeaderDrawable, sheet.OwnColor(.(235, 238, 245, 255)))
			.Set(.HeaderHoverDrawable, sheet.OwnColor(Palette.Darken(.(235, 238, 245, 255), 0.05f)))
			.Set(.ArrowColor, Color(80, 85, 100, 255));

		// === TabView ===
		sheet.ForType(typeof(TabView))
			.Set(.StripDrawable, sheet.OwnColor(Palette.Darken(p.Surface, 0.05f)))
			.Set(.ContentDrawable, sheet.OwnColor(p.Surface))
			.Set(.ActiveTabDrawable, sheet.OwnColor(p.Surface))
			.Set(.HoverTabDrawable, sheet.OwnColor(Palette.Darken(p.Surface, 0.03f)))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent)
			.Set(.ActiveTabTextColor, p.Text)
			.Set(.InactiveTabTextColor, p.TextDim)
			.Set(.HoverTabTextColor, Palette.Darken(p.TextDim, 0.2f))
			.Set(.CloseButtonColor, p.TextDim)
			.Set(.CloseButtonHoverColor, p.Text);

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
		let tooltipBg = new RoundedRectDrawable(.(50, 55, 65, 230), 0, .(70, 75, 85, 255), 1);
		sheet.OwnDrawable(tooltipBg);
		sheet.ForType(typeof(TooltipView))
			.Set(.Background, tooltipBg)
			.Set(.TextColor, Color(240, 240, 245, 255));

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

		void Reg(StyleProperty prop, StringView svg, Type type = null)
		{
			let d = SVGDrawable.FromString(svg, tint);
			if (d != null)
			{
				sheet.OwnDrawable(d);
				if (type != null)
					sheet.ForType(type).Set(prop, d);
				else
					sheet.ForType(typeof(View)).Set(prop, d);
			}
		}

		Reg(.CheckmarkIcon, ThemeIcons.Checkmark, typeof(CheckBox));
		Reg(.RadioMarkIcon, ThemeIcons.RadioMarkSquare, typeof(RadioButton));
		Reg(.CloseIcon, ThemeIcons.Close, typeof(TabView));
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, typeof(Expander));
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, typeof(Expander));
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, typeof(TreeView));
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, typeof(TreeView));
		Reg(.ArrowDownIcon, ThemeIcons.ArrowDown);
		Reg(.ArrowUpIcon, ThemeIcons.ArrowUp);
	}
}
