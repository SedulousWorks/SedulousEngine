namespace Sedulous.GUI;

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
			.Set(.TextColor, Color(240, 240, 245, 255))
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
			.Set(.SelectionColor, Color(60, 120, 200, 80));

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
			.Set(.SelectionColor, Color(60, 120, 200, 80))
			.Set(.SpinUpDrawable, spinBg)
			.Set(.SpinDownDrawable, spinBg);

		// === CheckBox ===
		let cbBorder = Color(100, 105, 120, 255);
		let cbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 0, cbBorder, 1);
		let cbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, cbBorder, 1);
		sheet.OwnDrawable(cbUnchecked);
		sheet.OwnDrawable(cbChecked);
		sheet.ForType(typeof(CheckBox))
			.Set(.BoxDrawable, cbUnchecked)
			.Set(.CheckedBackground, cbChecked)
			.Set(.BoxSize, 18.0f)
			.Set(.Spacing, 6.0f);

		// === RadioButton ===
		let rbBorder = Color(100, 105, 120, 255);
		let rbUnchecked = new RoundedRectDrawable(.(30, 32, 42, 255), 0, rbBorder, 1);
		let rbChecked = new RoundedRectDrawable(p.PrimaryAccent, 0, rbBorder, 1);
		sheet.OwnDrawable(rbUnchecked);
		sheet.OwnDrawable(rbChecked);
		sheet.ForType(typeof(RadioButton))
			.Set(.BoxDrawable, rbUnchecked)
			.Set(.CheckedBackground, rbChecked);

		// === Slider ===
		sheet.ForType(typeof(Slider))
			.Set(.TrackDrawable, sheet.OwnColor(.(50, 52, 62, 255)))
			.Set(.FillDrawable, sheet.OwnColor(p.PrimaryAccent))
			.Set(.ThumbDrawable, sheet.OwnColor(.(220, 220, 230, 255)))
			.Set(.ThumbSize, 16.0f)
			.Set(.TrackHeight, 4.0f);

		// === ProgressBar ===
		sheet.ForType(typeof(ProgressBar))
			.Set(.TrackDrawable, sheet.OwnColor(.(50, 52, 62, 255)))
			.Set(.FillDrawable, sheet.OwnColor(p.PrimaryAccent));

		// === ToggleSwitch ===
		{
			let swOff = new RoundedRectDrawable(p.Surface, 0, p.Border, 1);
			let swOn = new RoundedRectDrawable(p.PrimaryAccent, 0, p.Border, 1);
			sheet.OwnDrawable(swOff);
			sheet.OwnDrawable(swOn);
			sheet.ForType(typeof(ToggleSwitch))
				.Set(.TrackDrawable, swOff)
				.Set(.TrackOnDrawable, swOn)
				.Set(.KnobDrawable, sheet.OwnColor(.(230, 230, 235, 255)));
		}

		// === ComboBox ===
		let comboBg = new RoundedRectDrawable(.(40, 42, 52, 255), 0, p.Border, 1);
		sheet.OwnDrawable(comboBg);
		sheet.ForType(typeof(ComboBox))
			.Set(.Background, comboBg)
			.Set(.ArrowColor, Color(180, 185, 200, 255));

		// === ScrollBar ===
		sheet.ForType(typeof(ScrollBar))
			.Set(.TrackDrawable, sheet.OwnColor(.(40, 42, 50, 150)))
			.Set(.ThumbDrawable, sheet.OwnColor(.(100, 110, 130, 200)));

		// === Separator ===
		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		// === Expander ===
		sheet.ForType(typeof(Expander))
			.Set(.HeaderDrawable, sheet.OwnColor(.(50, 55, 68, 255)))
			.Set(.HeaderHoverDrawable, sheet.OwnColor(Palette.Lighten(.(50, 55, 68, 255), 0.1f)))
			.Set(.ArrowColor, Color(180, 185, 200, 255));

		// === TabView ===
		sheet.ForType(typeof(TabView))
			.Set(.StripDrawable, sheet.OwnColor(Palette.Darken(p.Surface, 0.15f)))
			.Set(.ContentDrawable, sheet.OwnColor(p.Surface))
			.Set(.ActiveTabDrawable, sheet.OwnColor(p.Surface))
			.Set(.HoverTabDrawable, sheet.OwnColor(Palette.Lighten(p.Surface, 0.05f)))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent)
			.Set(.ActiveTabTextColor, p.Text)
			.Set(.InactiveTabTextColor, p.TextDim)
			.Set(.HoverTabTextColor, Palette.Lighten(p.TextDim, 0.3f))
			.Set(.CloseButtonColor, p.TextDim)
			.Set(.CloseButtonHoverColor, p.Text);

		// === ContextMenu ===
		let menuBg = new RoundedRectDrawable(.(45, 48, 58, 255), 0, .(70, 75, 90, 255), 1);
		sheet.OwnDrawable(menuBg);
		let menuHover = new RoundedRectDrawable(.(60, 120, 200, 100), 0);
		sheet.OwnDrawable(menuHover);
		sheet.ForClass("contextmenu")
			.Set(.Background, menuBg)
			.Set(.MenuItemHoverDrawable, menuHover)
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, Color(70, 75, 90, 255))
			.Set(.AccentColor, Color(60, 120, 200, 100));

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

		// Apply registered extensions.
		ThemeRegistry.ApplyExtensions(sheet, p);

		return sheet;
	}

	private static void RegisterIcons(StyleSheet sheet)
	{
		void Reg(StyleProperty prop, StringView svg, Type type = null)
		{
			let d = SVGDrawable.FromString(svg);
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
