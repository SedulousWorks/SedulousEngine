using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A theme skinned entirely from images.
///
/// Unlike the other themes this is NOT authored as a style sheet: the visual regions come from
/// a ThemeImageSet, packed into one atlas, and a sheet cannot name a runtime image set. What
/// the code builds is the non-drawable half - colours, padding, sizes - onto which the packed
/// drawables are then bound.
static class TexturedTheme
{
	/// The key separator for a pseudo element, as in `ComboBox::arrow`.
	private const String PseudoSeparator = "::";

	/// OWNERSHIP of the sheet transfers.
	public static StyleSheet Create(ThemeImageSet images) => Create(images, ThemePalette.Dark());

	public static StyleSheet Create(ThemeImageSet images, ThemePalette palette)
	{
		let sheet = new StyleSheet();

		BuildBaseStyles(sheet, palette);
		RegisterIcons(sheet, palette);
		ThemeRegistry.ApplyExtensions(sheet, palette);

		BindImages(sheet, images);
		return sheet;
	}

	// ---- The non-drawable half ----------------------------------------------------------------

	/// Colours, padding and sizes. Everything visual comes from the atlas instead.
	private static void BuildBaseStyles(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForType(typeof(View))
			.Set(.TextColor, p.Text)
			.Set(.FontSize, 16.0f);

		// A textured button's face is an image, so its text is DARK: the skin is assumed light
		// where the flat themes assume a dark surface.
		sheet.ForType(typeof(ButtonBase))
			.Set(.TextColor, Rgb(30, 30, 40))
			.Set(.Padding, Thickness(12, 8));

		sheet.ForClass("label").Set(.TextColor, p.Text);
		sheet.ForClass("label-dim").Set(.TextColor, p.TextDim);

		BuildTextInputStyles(sheet, p);

		sheet.ForTypePseudo(typeof(CheckBox), "box").Set(.Width, 18.0f);
		sheet.ForType(typeof(CheckBox)).Set(.Spacing, 6.0f);

		sheet.ForTypePseudo(typeof(Slider), "track").Set(.Height, 4.0f);
		sheet.ForTypePseudo(typeof(Slider), "thumb").Set(.Width, 16.0f);

		sheet.ForType(typeof(Separator)).Set(.BorderColor, p.Border);

		BuildTabStyles(sheet, p);

		sheet.ForClass("contextmenu")
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, Rgb(60, 120, 200, 80));

		sheet.ForTypePseudo(typeof(Expander), "chevron").Set(.TextColor, Rgb(80, 85, 100));

		sheet.ForType(typeof(ComboBox)).Set(.CornerRadius, 4.0f);
		sheet.ForTypePseudo(typeof(ComboBox), "arrow").Set(.TextColor, Rgb(80, 85, 100));

		sheet.ForType(typeof(TooltipView)).Set(.TextColor, p.Text);
		sheet.ForType(typeof(ListView)).Set(.SelectionColor, Rgb(60, 120, 200, 80));
		sheet.ForType(typeof(GridView)).Set(.SelectionColor, Rgb(60, 120, 200, 80));
	}

	/// EditText and NumericField take the same treatment: the numeric field is a text field
	/// with buttons, so it would look wrong styled differently.
	private static void BuildTextInputStyles(StyleSheet sheet, ThemePalette p)
	{
		for (let type in Type[](typeof(EditText), typeof(NumericField)))
		{
			sheet.ForType(type)
				.Set(.TextColor, p.Text)
				.Set(.PlaceholderColor, p.TextDim)
				.Set(.FontSize, 14.0f)
				.Set(.Padding, Thickness(6, 4))
				.Set(.CursorColor, p.PrimaryAccent)
				.Set(.SelectionColor, Rgb(60, 120, 200, 80))
				.Set(.CornerRadius, 4.0f);
		}
	}

	private static void BuildTabStyles(StyleSheet sheet, ThemePalette p)
	{
		sheet.ForTypePseudo(typeof(TabView), "tab").Set(.TextColor, p.TextDim);
		sheet.ForTypePseudoState(typeof(TabView), "tab", .Checked).Set(.TextColor, p.Text);
		// Hovering DARKENS the dim colour rather than brightening toward the selected one, so
		// hover and selected stay distinguishable.
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

	// ---- The atlas ----------------------------------------------------------------------------

	/// Packs the image set into one atlas and binds each entry to the rule its key names.
	///
	/// A failed pack leaves the sheet as built: the colours and metrics still apply, so the
	/// interface is plain rather than invisible.
	private static void BindImages(StyleSheet sheet, ThemeImageSet images)
	{
		let atlas = new ThemeAtlas();

		for (let pair in images.Images)
			atlas.AddImage(pair.key, pair.value.Image);

		if (!atlas.Build())
		{
			delete atlas;
			return;
		}

		sheet.OwnResource(atlas);

		BindStateGroups(sheet, images, atlas);
		BindSingleImages(sheet, images, atlas);
	}

	/// A state group becomes ONE StateListDrawable, so a control's normal, hover and pressed
	/// skins are a single value the cascade can carry.
	private static void BindStateGroups(StyleSheet sheet, ThemeImageSet images, ThemeAtlas atlas)
	{
		for (let pair in images.StateGroups)
		{
			let stateList = new StateListDrawable();

			for (let state in pair.value)
			{
				let entry = images.GetEntry(state.Key);
				if (entry == null)
					continue;

				let drawable = CreateDrawable(atlas, state.Key, entry.Value);
				if (drawable != null)
					stateList.Set(state.State, drawable);
			}

			sheet.OwnDrawable(stateList);
			BindDrawable(sheet, pair.key, stateList);
		}
	}

	private static void BindSingleImages(StyleSheet sheet, ThemeImageSet images, ThemeAtlas atlas)
	{
		for (let pair in images.Images)
		{
			// Anything already bound as part of a state group is not bound again on its own.
			if (IsInAStateGroup(images, pair.key))
				continue;

			let drawable = CreateDrawable(atlas, pair.key, pair.value);
			if (drawable == null)
				continue;

			sheet.OwnDrawable(drawable);
			BindDrawable(sheet, pair.key, drawable);
		}
	}

	private static bool IsInAStateGroup(ThemeImageSet images, StringView key)
	{
		for (let group in images.StateGroups)
		{
			for (let state in group.value)
			{
				if (state.Key == key)
					return true;
			}
		}
		return false;
	}

	/// A nine slice keeps its insets; anything else is drawn whole.
	private static Drawable CreateDrawable(ThemeAtlas atlas, StringView key, ThemeImageEntry entry)
	{
		if (entry.IsNineSlice)
			return atlas.CreateNineSliceDrawable(key, entry.Slices);

		return atlas.CreateImageDrawable(key);
	}

	// ---- Keys ---------------------------------------------------------------------------------

	/// Binds a drawable to whatever its key names.
	///
	/// Two spellings are understood. `Type::pseudo` and `Type::pseudo:state` address a
	/// control's parts, which is how a skin dresses a scroll bar's thumb separately from its
	/// track. The older `name:Property` form addresses a whole control, or a class when the
	/// name is not a known type.
	private static void BindDrawable(StyleSheet sheet, StringView key, Drawable drawable)
	{
		let pseudoAt = key.IndexOf(PseudoSeparator);
		if (pseudoAt >= 0)
		{
			BindPseudoKey(sheet, key.Substring(0, pseudoAt),
				key.Substring(pseudoAt + PseudoSeparator.Length), drawable);
			return;
		}

		BindLegacyKey(sheet, key, drawable);
	}

	private static void BindPseudoKey(StyleSheet sheet, StringView typeName, StringView remainder,
		Drawable drawable)
	{
		let type = ResolveTypeName(typeName);
		if (type == null)
			return;

		// A `:state` suffix on the pseudo name narrows it further.
		let stateAt = remainder.IndexOf(':');
		if (stateAt < 0)
		{
			sheet.ForTypePseudo(type, remainder).Set(.Background, drawable);
			return;
		}

		let state = ParseStateName(remainder.Substring(stateAt + 1));
		if (state == null)
			return;

		sheet.ForTypePseudoState(type, remainder.Substring(0, stateAt), state.Value)
			.Set(.Background, drawable);
	}

	private static void BindLegacyKey(StyleSheet sheet, StringView key, Drawable drawable)
	{
		let colonAt = key.IndexOf(':');
		if (colonAt < 0)
			return;

		let property = ParsePropertyName(key.Substring(colonAt + 1));
		if (property == null)
			return;

		let typeName = key.Substring(0, colonAt);
		if (let type = ResolveTypeName(typeName))
		{
			sheet.ForType(type).Set(property.Value, drawable);
			return;
		}

		// An empty name is the base of everything; anything else unrecognised is a class,
		// which is how contextmenu is addressed - it is shared by the menu and the dropdown.
		if (typeName.IsEmpty)
			sheet.ForType(typeof(View)).Set(property.Value, drawable);
		else
			sheet.ForClass(typeName).Set(property.Value, drawable);
	}

	private static ControlState? ParseStateName(StringView name)
	{
		switch (name)
		{
		case "hover": return ControlState.Hover;
		case "pressed": return ControlState.Pressed;
		case "checked": return ControlState.Checked;
		case "disabled": return ControlState.Disabled;
		case "focused": return ControlState.Focused;
		default: return null;
		}
	}

	/// Only the two drawable-valued properties a skin can address.
	private static StyleProperty? ParsePropertyName(StringView name)
	{
		switch (name)
		{
		case "Background": return StyleProperty.Background;
		case "MenuItemHoverDrawable": return StyleProperty.MenuItemHoverDrawable;
		default: return null;
		}
	}

	/// The skin's own lower-case names for controls. Not every control is here: contextmenu is
	/// deliberately absent, being addressed as a class because the menu and the combo box
	/// dropdown share it.
	private static Type ResolveTypeName(StringView name)
	{
		switch (name)
		{
		case "button": return typeof(ButtonBase);
		case "edittext": return typeof(EditText);
		case "numericfield": return typeof(NumericField);
		case "checkbox": return typeof(CheckBox);
		case "radiobutton": return typeof(RadioButton);
		case "slider": return typeof(Slider);
		case "progressbar": return typeof(ProgressBar);
		case "toggleswitch": return typeof(ToggleSwitch);
		case "combobox": return typeof(ComboBox);
		case "scrollbar": return typeof(ScrollBar);
		case "separator": return typeof(Separator);
		case "expander": return typeof(Expander);
		case "tabview": return typeof(TabView);
		case "dialog": return typeof(Dialog);
		case "tooltip": return typeof(TooltipView);
		case "listview": return typeof(ListView);
		case "treeview": return typeof(TreeView);
		case "gridview": return typeof(GridView);
		default: return null;
		}
	}

	// ---- Icons --------------------------------------------------------------------------------

	/// The glyph icons, tinted for the palette.
	///
	/// A LIGHT palette tints them dark; a dark one leaves them alone, since the icons are
	/// authored light.
	private static void RegisterIcons(StyleSheet sheet, ThemePalette p)
	{
		let isLight = p.Background.R > 0.5f;
		Color? tint = null;
		if (isLight)
			tint = Rgb(60, 60, 70);

		BindIcon(sheet, ThemeIcons.Checkmark, tint, typeof(CheckBox), "checkmark", null);
		BindIcon(sheet, ThemeIcons.RadioMarkRound, tint, typeof(RadioButton), "mark", null);
		BindIcon(sheet, ThemeIcons.Close, tint, typeof(TabView), "close-button", null);

		// Expanded reads as Checked, so one part carries both directions.
		BindIcon(sheet, ThemeIcons.ChevronDown, tint, typeof(Expander), "chevron", ControlState.Checked);
		BindIcon(sheet, ThemeIcons.ChevronRight, tint, typeof(Expander), "chevron", null);
		BindIcon(sheet, ThemeIcons.ChevronDown, tint, typeof(TreeView), "chevron", ControlState.Checked);
		BindIcon(sheet, ThemeIcons.ChevronRight, tint, typeof(TreeView), "chevron", null);

		BindIcon(sheet, ThemeIcons.ArrowDown, tint, typeof(ComboBox), "arrow", null);
		BindIcon(sheet, ThemeIcons.ArrowUp, tint, typeof(NumericField), "arrow-up", null);
		BindIcon(sheet, ThemeIcons.ArrowDown, tint, typeof(NumericField), "arrow-down", null);

		BindSubmenuArrow(sheet, tint);
	}

	private static void BindIcon(StyleSheet sheet, StringView svg, Color? tint, Type type,
		StringView pseudo, ControlState? state)
	{
		let icon = MakeIcon(svg, tint);
		if (icon == null)
			return;

		sheet.OwnDrawable(icon);

		if (state != null)
			sheet.ForTypePseudoState(type, pseudo, state.Value).Set(.Background, icon);
		else
			sheet.ForTypePseudo(type, pseudo).Set(.Background, icon);
	}

	/// The submenu arrow is on a CLASS rather than a type, so it is built by hand: the menu and
	/// the combo box dropdown share the class and neither owns the rule.
	private static void BindSubmenuArrow(StyleSheet sheet, Color? tint)
	{
		let icon = MakeIcon(ThemeIcons.ChevronRight, tint);
		if (icon == null)
			return;

		sheet.OwnDrawable(icon);

		let rule = new StyleRule();
		rule.Selector.AddClass("contextmenu");
		rule.Selector.SetPseudoElement("submenu-arrow");
		rule.Set(.Background, icon);
		sheet.AddRule(rule);
	}

	private static SVGDrawable MakeIcon(StringView svg, Color? tint)
	{
		if (tint != null)
			return SVGDrawable.FromString(svg, tint.Value);

		return SVGDrawable.FromString(svg);
	}

	/// A byte colour, as the theme data is authored.
	private static Color Rgb(int r, int g, int b, int a = 255) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
}
