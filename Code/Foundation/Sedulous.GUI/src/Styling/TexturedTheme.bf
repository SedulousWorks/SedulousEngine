namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Entry for a single image in a ThemeImageSet.
public struct ThemeImageEntry
{
	public IImageData Image;
	public NineSlice Slices;
	public bool IsNineSlice;
}

/// Generic container for theme images, keyed by style property + style class.
/// Pass to TexturedTheme.Create() to build a fully image-skinned StyleSheet.
public class ThemeImageSet
{
	/// Key: "styleClass:propertyName", Value: ThemeImageEntry
	private Dictionary<String, ThemeImageEntry> mImages = new .() ~
		{
			for (let kv in _) delete kv.key;
			delete _;
		};

	/// State image groups: "styleClass:propertyName" -> list of (state, internal image key).
	private Dictionary<String, List<(ControlState, String)>> mStateGroups = new .() ~
		{
			for (let kv in _)
			{
				delete kv.key;
				for (let entry in kv.value) delete entry.1;
				delete kv.value;
			}
			delete _;
		};

	/// Add a single image for a drawable key. Uses 9-slice if slices are non-zero.
	public void AddImage(StringView drawableKey, IImageData image, NineSlice slices = default)
	{
		if (image == null) return;
		ThemeImageEntry entry;
		entry.Image = image;
		entry.Slices = slices;
		entry.IsNineSlice = slices.IsValid;
		mImages[new String(drawableKey)] = entry;
	}

	/// Add state-variant images for a drawable key (creates a StateListDrawable).
	public void AddStateImages(StringView drawableKey,
		IImageData normal, IImageData hover = null,
		IImageData pressed = null, IImageData disabled = null,
		IImageData focused = null, NineSlice slices = default)
	{
		let group = new List<(ControlState, String)>();

		void AddState(ControlState state, IImageData img, StringView suffix)
		{
			if (img == null) return;
			let internalKey = scope String();
			internalKey.AppendF("{}_{}", drawableKey, suffix);
			AddImage(internalKey, img, slices);
			group.Add((state, new String(internalKey)));
		}

		AddState(.Normal, normal, "Normal");
		AddState(.Hover, hover, "Hover");
		AddState(.Pressed, pressed, "Pressed");
		AddState(.Disabled, disabled, "Disabled");
		AddState(.Focused, focused, "Focused");

		mStateGroups[new String(drawableKey)] = group;
	}

	/// Iterate all image entries.
	public Dictionary<String, ThemeImageEntry>.Enumerator GetImages() => mImages.GetEnumerator();

	/// Iterate all state groups.
	public Dictionary<String, List<(ControlState, String)>>.Enumerator GetStateGroups() => mStateGroups.GetEnumerator();

	/// Get a single image entry by key.
	public ThemeImageEntry? GetEntry(StringView key)
	{
		for (let kv in mImages)
			if (StringView(kv.key) == key)
				return kv.value;
		return null;
	}
}

/// Creates a fully image-skinned StyleSheet from a ThemeImageSet.
/// All provided images are packed into a single atlas for optimal
/// GPU batching (zero texture switches during UI rendering).
///
/// The image set uses string keys in the format "styleClass:propertyName"
/// (e.g., "button:Background", "checkbox:BoxDrawable"). TexturedTheme
/// maps these to StyleProperty enum values and style class selectors.
///
/// Starts from DarkTheme colors as a base, then overlays image drawables.
public static class TexturedTheme
{
	/// Create a textured theme with dark base colors.
	public static StyleSheet Create(ThemeImageSet images)
	{
		return Create(images, .Dark);
	}

	/// Create a textured theme with a specific palette for base colors.
	/// Only sets non-drawable properties (text colors, font sizes, padding) from
	/// the palette. All drawable properties come from the image set.
	public static StyleSheet Create(ThemeImageSet images, ThemePalette p)
	{
		let sheet = new StyleSheet();

		// Global text defaults.
		sheet.ForType(typeof(View))
			.Set(.TextColor, p.Text)
			.Set(.FontSize, 16.0f);

		// Per-control non-drawable properties (colors, padding, sizes).
		sheet.ForType(typeof(ButtonBase))
			.Set(.TextColor, Color(30, 30, 40, 255))
			.Set(.Padding, Thickness(12, 8));

		sheet.ForClass("label")
			.Set(.TextColor, p.Text);
		sheet.ForClass("label-dim")
			.Set(.TextColor, p.TextDim);

		sheet.ForType(typeof(EditText))
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 80))
			.Set(.CornerRadius, 4.0f);

		sheet.ForType(typeof(NumericField))
			.Set(.TextColor, p.Text)
			.Set(.PlaceholderColor, p.TextDim)
			.Set(.FontSize, 14.0f)
			.Set(.Padding, Thickness(6, 4))
			.Set(.CursorColor, p.PrimaryAccent)
			.Set(.SelectionColor, Color(60, 120, 200, 80))
			.Set(.CornerRadius, 4.0f);

		sheet.ForType(typeof(CheckBox))
			.Set(.BoxSize, 18.0f)
			.Set(.Spacing, 6.0f);

		sheet.ForType(typeof(Slider))
			.Set(.ThumbSize, 16.0f)
			.Set(.TrackHeight, 4.0f);

		sheet.ForType(typeof(Separator))
			.Set(.BorderColor, p.Border);

		sheet.ForType(typeof(TabView))
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, p.PrimaryAccent)
			.Set(.ActiveTabTextColor, p.Text)
			.Set(.InactiveTabTextColor, p.TextDim)
			.Set(.HoverTabTextColor, Palette.Darken(p.TextDim, 0.2f))
			.Set(.CloseButtonColor, p.TextDim)
			.Set(.CloseButtonHoverColor, p.Text);

		sheet.ForClass("contextmenu")
			.Set(.TextColor, p.Text)
			.Set(.BorderColor, p.Border)
			.Set(.AccentColor, Color(60, 120, 200, 80));

		sheet.ForType(typeof(Expander))
			.Set(.ArrowColor, Color(80, 85, 100, 255));

		sheet.ForType(typeof(ComboBox))
			.Set(.ArrowColor, Color(80, 85, 100, 255))
			.Set(.CornerRadius, 4.0f);

		sheet.ForType(typeof(TooltipView))
			.Set(.TextColor, Color(240, 240, 245, 255));

		sheet.ForType(typeof(ListView))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		sheet.ForType(typeof(GridView))
			.Set(.SelectionColor, Color(60, 120, 200, 80));

		// Register icons with appropriate tint for the palette.
		RegisterIcons(sheet, p);

		ThemeRegistry.ApplyExtensions(sheet, p);

		let atlas = new ThemeAtlas();

		// Add all images to atlas.
		for (let kv in images.GetImages())
			atlas.AddImage(kv.key, kv.value.Image);

		if (!atlas.Build())
		{
			delete atlas;
			return sheet;
		}

		// Create drawables for state groups (StateListDrawable).
		for (let kv in images.GetStateGroups())
		{
			let drawableKey = kv.key;
			let states = kv.value;
			let stateList = new StateListDrawable(true);

			for (let (state, internalKey) in states)
			{
				let entry = images.GetEntry(internalKey);
				if (!entry.HasValue) continue;

				Drawable drawable;
				if (entry.Value.IsNineSlice)
					drawable = atlas.CreateNineSliceDrawable(internalKey, entry.Value.Slices);
				else
					drawable = atlas.CreateImageDrawable(internalKey);

				if (drawable != null)
					stateList.Set(state, drawable);
			}

			sheet.OwnDrawable(stateList);
			SetDrawableByKey(sheet, drawableKey, stateList);
		}

		// Create drawables for non-grouped images.
		for (let kv in images.GetImages())
		{
			let key = StringView(kv.key);

			// Skip internal state images.
			bool isStateImage = false;
			for (let sg in images.GetStateGroups())
			{
				for (let (_, internalKey) in sg.value)
				{
					if (key == StringView(internalKey))
					{
						isStateImage = true;
						break;
					}
				}
				if (isStateImage) break;
			}
			if (isStateImage) continue;

			let entry = kv.value;
			Drawable drawable;
			if (entry.IsNineSlice)
				drawable = atlas.CreateNineSliceDrawable(key, entry.Slices);
			else
				drawable = atlas.CreateImageDrawable(key);

			if (drawable != null)
			{
				sheet.OwnDrawable(drawable);
				SetDrawableByKey(sheet, key, drawable);
			}
		}

		// Theme owns the atlas so it lives as long as the drawables that reference it.
		sheet.OwnResource(atlas);

		return sheet;
	}

	/// Map a string key ("typeName:propertyName") to a StyleSheet rule.
	private static void SetDrawableByKey(StyleSheet sheet, StringView key, Drawable drawable)
	{
		// Parse "typeName:propertyName" format.
		let colonIdx = key.IndexOf(':');
		if (colonIdx < 0) return;

		let typeName = key.Substring(0, colonIdx);
		let propName = key.Substring(colonIdx + 1);

		let prop = ParsePropertyName(propName);
		if (prop == null) return;

		let type = ResolveTypeName(typeName);
		if (type != null)
			sheet.ForType(type).Set(prop.Value, drawable);
		else if (typeName.IsEmpty)
			sheet.ForType(typeof(View)).Set(prop.Value, drawable);
		else
			sheet.ForClass(typeName).Set(prop.Value, drawable);
	}

	/// Map a property name string to a StyleProperty enum value.
	private static StyleProperty? ParsePropertyName(StringView name)
	{
		if (name == "Background") return .Background;
		if (name == "CheckedBackground") return .CheckedBackground;
		if (name == "TrackDrawable") return .TrackDrawable;
		if (name == "ThumbDrawable") return .ThumbDrawable;
		if (name == "FillDrawable") return .FillDrawable;
		if (name == "KnobDrawable") return .KnobDrawable;
		if (name == "TrackOnDrawable") return .TrackOnDrawable;
		if (name == "BoxDrawable") return .BoxDrawable;
		if (name == "StripDrawable") return .StripDrawable;
		if (name == "ContentDrawable") return .ContentDrawable;
		if (name == "ActiveTabDrawable") return .ActiveTabDrawable;
		if (name == "HoverTabDrawable") return .HoverTabDrawable;
		if (name == "HeaderDrawable") return .HeaderDrawable;
		if (name == "HeaderHoverDrawable") return .HeaderHoverDrawable;
		if (name == "SpinUpDrawable") return .SpinUpDrawable;
		if (name == "SpinDownDrawable") return .SpinDownDrawable;
		if (name == "MenuItemHoverDrawable") return .MenuItemHoverDrawable;
		return null;
	}

	/// Map old style class name to concrete Beef type for type-based selectors.
	private static Type ResolveTypeName(StringView name)
	{
		if (name == "button")       return typeof(ButtonBase);
		if (name == "edittext")     return typeof(EditText);
		if (name == "checkbox")     return typeof(CheckBox);
		if (name == "radiobutton")  return typeof(RadioButton);
		if (name == "slider")       return typeof(Slider);
		if (name == "progressbar")  return typeof(ProgressBar);
		if (name == "toggleswitch") return typeof(ToggleSwitch);
		if (name == "combobox")     return typeof(ComboBox);
		if (name == "scrollbar")    return typeof(ScrollBar);
		if (name == "separator")    return typeof(Separator);
		if (name == "expander")     return typeof(Expander);
		if (name == "tabview")      return typeof(TabView);
		// "contextmenu" is class-based (shared by ContextMenu and ComboBoxDropdown)
		if (name == "dialog")       return typeof(Dialog);
		if (name == "tooltip")      return typeof(TooltipView);
		if (name == "listview")     return typeof(ListView);
		if (name == "treeview")     return typeof(TreeView);
		if (name == "gridview")     return typeof(GridView);
		if (name == "numericfield") return typeof(NumericField);
		return null;
	}

	/// Register SVG icons with appropriate tint for the palette.
	private static void RegisterIcons(StyleSheet sheet, ThemePalette p)
	{
		// Use dark tint for light palettes, no tint for dark.
		let isLight = p.Background.R > 128;
		Color? tint = null;
		if (isLight) tint =  Color(60, 60, 70, 255);

		void Reg(StyleProperty prop, StringView svg, Type type = null)
		{
			SVGDrawable d;
			if (tint.HasValue)
				d = SVGDrawable.FromString(svg, tint.Value);
			else
				d = SVGDrawable.FromString(svg);
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
		Reg(.RadioMarkIcon, ThemeIcons.RadioMarkRound, typeof(RadioButton));
		Reg(.CloseIcon, ThemeIcons.Close, typeof(TabView));
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, typeof(Expander));
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, typeof(Expander));
		Reg(.ChevronExpandedIcon, ThemeIcons.ChevronDown, typeof(TreeView));
		Reg(.ChevronCollapsedIcon, ThemeIcons.ChevronRight, typeof(TreeView));
		Reg(.ArrowDownIcon, ThemeIcons.ArrowDown);
		Reg(.ArrowUpIcon, ThemeIcons.ArrowUp);
	}
}
