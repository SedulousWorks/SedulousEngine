using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The CSS properties the GUI knows, as one table instead of a chain of string compares: each
// property's name, how its value parses into a typed StyleValue, and the shorthands that expand
// into longhands (`border` into twelve, `border-radius` into four) so the cascade works per
// longhand, as CSS's does. A property the table does not name may still reach a widget: a
// reflected property that declares its CSS name (the `css` property attribute) takes it, parsed
// by its type, so a library's widget gets CSS for its own properties with no applier code
// (StyleApplier).

enum StyleValueKind : uint8
{
	/// Not parsed (an unknown property's text, a custom property).
	None,
	/// opacity.
	Number,
	/// width, border-top-width, font-size, a corner radius.
	Length,
	/// color, background-color, border-top-color.
	ColorValue,
	/// text-align, visibility, border-top-style, enabled.
	Keyword,
	/// box-shadow.
	Shadows,
	/// transform.
	Transforms,
	/// transform-origin (two lengths).
	Origin,
	/// background-image.
	Layers,
	/// filter, backdrop-filter.
	Filters,
}

/// A declaration's value once parsed. A class, not a struct: it owns its keyword and its lists
/// (the background layers among them). Set copies another one deeply.
class StyleValue
{
	public StyleValueKind Kind = .None;
	public float Number = 0.0f;
	public LengthValue Length = .();
	public Color ColorValue = .();
	public String Keyword = new .() ~ delete _;
	public List<ShadowValue> Shadows = new .() ~ delete _;
	public List<TransformFunction> Transforms = new .() ~ delete _;
	public LengthValue OriginX = .(50.0f, .Percent);
	public LengthValue OriginY = .(50.0f, .Percent);
	public List<BackgroundLayer> Layers = new .() ~ DeleteContainerAndItems!(_);
	public List<FilterFunction> Filters = new .() ~ delete _;

	/// Makes this a copy of `other`, its text and lists included.
	public void Set(StyleValue other)
	{
		if (other === this)
			return;
		Kind = other.Kind;
		Number = other.Number;
		Length = other.Length;
		ColorValue = other.ColorValue;
		Keyword.Set(other.Keyword);
		Shadows.Clear();
		Shadows.AddRange(other.Shadows);
		Transforms.Clear();
		Transforms.AddRange(other.Transforms);
		OriginX = other.OriginX;
		OriginY = other.OriginY;
		ClearAndDeleteItems(Layers);
		for (let layer in other.Layers)
		{
			let copy = new BackgroundLayer();
			copy.Set(layer);
			Layers.Add(copy);
		}
		Filters.Clear();
		Filters.AddRange(other.Filters);
	}
}

/// How a property's value parses.
enum StyleGrammar : uint8
{
	Number,
	Length,
	Color,
	Keyword,
	Shadows,
	Transforms,
	Origin,
	Layers,
	Filters,
	/// `<width> [color]`, a Shadows value (the width as the spread).
	TextOutline,
	/// `<radius> [color]`, a Shadows value (the radius as the blur).
	TextGlow,
	/// Kept as written (font-family, transition, animation).
	Text,
	/// A length or percentage, or auto, fit-content, min-content, max-content, none (a Keyword).
	Size,
}

/// A row of the property table. Its text is literals', never owned.
struct StylePropertySpec
{
	public String Name;
	public StyleGrammar Grammar;
	/// CSS's initial value, what `initial` sets (null: the node's own value). A property no rule
	/// sets returns to the node's own value, not to this.
	public String Initial;
	/// Inherited, as CSS's is: a node the sheet sets none for takes its parent's.
	public bool Inherited;

	public this(String name, StyleGrammar grammar, String initial = null, bool inherited = false)
	{
		Name = name;
		Grammar = grammar;
		Initial = initial;
		Inherited = inherited;
	}
}

/// One longhand a declaration sets. A class: it owns its two strings.
class StyleLonghand
{
	public String Name = new .() ~ delete _;
	public String Text = new .() ~ delete _;

	public this() { }

	public this(StringView name, StringView text)
	{
		Name.Set(name);
		Text.Set(text);
	}
}

/// What StyleProperties.bf keeps out of the public surface: the table and the shorthands' pieces.
internal static class StylePropertiesDetail
{
	public static String[10] sPaintOnly = .("opacity", "color", "background-color", "background-image", "border-top-color",
		"border-right-color", "border-bottom-color", "border-left-color", "caret-color", "accent-color");

	public static StylePropertySpec[113] sProperties = .(
		.("opacity", .Number, "1"),
		.("width", .Size, "auto"),
		.("height", .Size, "auto"),
		.("min-width", .Size, "auto"),
		.("min-height", .Size, "auto"),
		.("max-width", .Size, "none"),
		.("max-height", .Size, "none"),
		.("padding-top", .Length, "0"),
		.("padding-right", .Length, "0"),
		.("padding-bottom", .Length, "0"),
		.("padding-left", .Length, "0"),
		.("margin-top", .Length, "0"),
		.("margin-right", .Length, "0"),
		.("margin-bottom", .Length, "0"),
		.("margin-left", .Length, "0"),
		.("margin-inline-start", .Length),
		.("margin-inline-end", .Length),
		.("padding-inline-start", .Length),
		.("padding-inline-end", .Length),
		.("inset-inline-start", .Size),
		.("inset-inline-end", .Size),
		.("enabled", .Keyword),
		.("visibility", .Keyword, "visible", true),
		.("color", .Color, null, true),
		.("text-align", .Keyword, null, true),
		.("vertical-align", .Keyword),
		.("font-family", .Text, null, true),
		.("font-size", .Length, null, true),
		.("font-weight", .Text, "normal", true),
		.("font-style", .Keyword, "normal", true),
		.("overflow-wrap", .Keyword, "normal", true),
		.("white-space", .Keyword, null, true),
		.("line-height", .Text, "normal", true),
		.("letter-spacing", .Text, "normal", true),
		.("direction", .Keyword),
		.("background-color", .Color, "transparent"),
		.("background-image", .Layers),
		.("background-size", .Text),
		.("background-position", .Text),
		.("border-image", .Text),
		.("border-top-width", .Length),
		.("border-right-width", .Length),
		.("border-bottom-width", .Length),
		.("border-left-width", .Length),
		.("border-top-color", .Color),
		.("border-right-color", .Color),
		.("border-bottom-color", .Color),
		.("border-left-color", .Color),
		.("border-top-style", .Keyword),
		.("border-right-style", .Keyword),
		.("border-bottom-style", .Keyword),
		.("border-left-style", .Keyword),
		.("border-top-left-radius", .Length),
		.("border-top-right-radius", .Length),
		.("border-bottom-right-radius", .Length),
		.("border-bottom-left-radius", .Length),
		.("box-shadow", .Shadows, "none"),
		.("transform", .Transforms),
		.("transform-origin", .Origin),
		.("filter", .Filters, "none"),
		.("text-shadow", .Shadows),
		.("text-outline", .TextOutline),
		.("text-glow", .TextGlow),
		.("backdrop-filter", .Filters, "none"),
		.("mix-blend-mode", .Keyword, "normal"),
		// Layout: the node's box, out of flow, how it lays out its children, and how its
		// container places it.
		.("overflow-x", .Keyword, "visible"),
		.("overflow-y", .Keyword, "visible"),
		.("scroll-behavior", .Keyword, "auto"),
		.("overscroll-behavior", .Keyword, "auto"),
		.("scrollbar-width", .Keyword, "auto"),
		.("scrollbar-visibility", .Keyword, "auto"),
		.("box-sizing", .Keyword),
		.("display", .Keyword),
		.("position", .Keyword),
		.("top", .Size),
		.("right", .Size),
		.("bottom", .Size),
		.("left", .Size),
		.("z-index", .Number),
		.("flex-direction", .Keyword),
		.("flex-wrap", .Keyword),
		.("justify-content", .Keyword),
		.("align-items", .Keyword),
		.("align-content", .Keyword),
		.("justify-items", .Keyword),
		.("row-gap", .Length),
		.("column-gap", .Length),
		.("flex-grow", .Number),
		.("flex-shrink", .Number),
		.("flex-basis", .Size),
		.("align-self", .Keyword),
		.("justify-self", .Keyword),
		.("order", .Number),
		.("grid-template-columns", .Text),
		.("grid-template-rows", .Text),
		.("grid-auto-columns", .Text),
		.("grid-auto-rows", .Text),
		.("grid-auto-flow", .Keyword),
		.("grid-column", .Text),
		.("grid-row", .Text),
		.("dock", .Keyword),
		.("transition-property", .Text),
		.("transition-duration", .Text),
		.("transition-timing-function", .Text),
		.("transition-delay", .Text),
		.("animation-name", .Text),
		.("animation-duration", .Text),
		.("animation-timing-function", .Text),
		.("animation-delay", .Text),
		.("animation-iteration-count", .Text),
		.("animation-direction", .Text),
		.("animation-fill-mode", .Text),
		.("animation-play-state", .Text));

	public static String[4] sSides = .("top", "right", "bottom", "left");
	public static String[4] sCorners = .("top-left", "top-right", "bottom-right", "bottom-left");

	public static void Push(List<StyleLonghand> outLonghands, StringView name, StringView text)
	{
		outLonghands.Add(new StyleLonghand(name, text));
	}

	public static bool IsBorderStyle(StringView t) =>
		(t == "solid") || (t == "none") || (t == "hidden") || (t == "dashed") || (t == "dotted") || (t == "double");

	/// `<width> || <style> || <color>`, any order: the three parts, CSS's initial values where
	/// unsaid (medium is 3px; the colour, black here).
	public static bool SplitBorder(StringView value, String width, String style, String color)
	{
		width.Set("3px");
		style.Set("none");
		color.Set("#000000");
		bool w = false;
		bool s = false;
		bool c = false;
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		for (let token in tokens)
		{
			if (!s && IsBorderStyle(token))
			{
				style.Set(token);
				s = true;
			}
			else if (!w && ParseLengthValue(token).HasValue)
			{
				width.Set(token);
				w = true;
			}
			else if (!c && ParseColor(token).HasValue)
			{
				color.Set(token);
				c = true;
			}
			else
			{
				return false;
			}
		}
		return w || s || c; // no style: none, so nothing draws (CSS)
	}

	/// `a`, `b` and `c` joined into `outText` (cleared first).
	public static void Joined(StringView a, StringView b, StringView c, String outText)
	{
		outText.Set(a);
		outText.Append(b);
		outText.Append(c);
	}

	/// The value's one to four sides as `<prefix><side><suffix>` longhands.
	public static bool Sides(StringView value, StringView prefix, StringView suffix, List<StyleLonghand> outLonghands)
	{
		let parts = scope List<StringView>();
		if (!ParseSides<StringView>(value, scope (t) => (StringView?)t, parts))
			return false;
		let name = scope String();
		for (int k = 0; k < 4; k++)
		{
			Joined(prefix, sSides[k], suffix, name);
			Push(outLonghands, name, parts[k]);
		}
		return true;
	}

	/// A plain number's characters only: digits, '.', '-' and '+'.
	public static bool PlainNumber(StringView t)
	{
		if (t.Length == 0)
			return false;
		for (int i = 0; i < t.Length; i++)
			if (!(((t[i] >= '0') && (t[i] <= '9')) || (t[i] == '.') || (t[i] == '-') || (t[i] == '+')))
				return false;
		return true;
	}
}

static
{
	/// A longhand that changes only how a node is painted where it already is: never its place,
	/// its size or how far its drawing reaches (animating one out of view asks for no frames).
	public static bool IsPaintOnlyStyleProperty(StringView name)
	{
		for (let p in StylePropertiesDetail.sPaintOnly)
			if (name == p)
				return true;
		return false;
	}

	/// The longhands the GUI knows.
	public static Span<StylePropertySpec> AllStyleProperties() =>
		.(&StylePropertiesDetail.sProperties[0], StylePropertiesDetail.sProperties.Count);

	/// A longhand the GUI knows, by name (null for one it does not).
	public static StylePropertySpec* FindStyleProperty(StringView name)
	{
		for (int i = 0; i < StylePropertiesDetail.sProperties.Count; i++)
			if (StylePropertiesDetail.sProperties[i].Name == name)
				return &StylePropertiesDetail.sProperties[i];
		return null;
	}

	/// `text` as a value of `grammar`, into `outValue`; false when it does not parse.
	public static bool ParseStyleValue(StyleGrammar grammar, StringView text, StyleValue outValue)
	{
		let v = ParseUtil.Trim(text);
		switch (grammar)
		{
		case .Number:
			// A plain number, or a percentage of one (`opacity: 50%` is 0.5); a unit is no number.
			let percent = (v.Length > 1) && (v[v.Length - 1] == '%');
			let digits = percent ? v.Substring(0, v.Length - 1) : v;
			for (int i = 0; i < digits.Length; i++)
			{
				let ch = digits[i];
				if (((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z')) || (ch == '%'))
					return false;
			}
			let n = ParseLength(digits);
			if (n.HasValue)
			{
				outValue.Kind = .Number;
				outValue.Number = percent ? n.Value * 0.01f : n.Value;
				return true;
			}
			return false;
		case .Length:
			let l = ParseLengthValue(v);
			if (l.HasValue)
			{
				outValue.Kind = .Length;
				outValue.Length = l.Value;
				return true;
			}
			return false;
		case .Color:
			let c = ParseColor(v);
			if (c.HasValue)
			{
				outValue.Kind = .ColorValue;
				outValue.ColorValue = c.Value;
				return true;
			}
			return false;
		case .Size:
			let size = ParseLengthValue(v);
			if (size.HasValue)
			{
				outValue.Kind = .Length;
				outValue.Length = size.Value;
				return true;
			}
			if ((v == "auto") || (v == "fit-content") || (v == "min-content") || (v == "max-content") || (v == "none"))
			{
				outValue.Kind = .Keyword;
				outValue.Keyword.Set(v);
				return true;
			}
			return false;
		case .Keyword, .Text:
			if (v.Length == 0)
				return false;
			outValue.Kind = .Keyword;
			outValue.Keyword.Set(v);
			return true;
		case .Shadows:
			let shadows = scope List<ShadowValue>();
			if (ParseShadows(v, shadows))
			{
				outValue.Kind = .Shadows;
				outValue.Shadows.Clear();
				outValue.Shadows.AddRange(shadows);
				return true;
			}
			return false;
		case .Transforms:
			let transforms = scope List<TransformFunction>();
			if (ParseTransforms(v, transforms))
			{
				outValue.Kind = .Transforms;
				outValue.Transforms.Clear();
				outValue.Transforms.AddRange(transforms);
				return true;
			}
			return false;
		case .Origin:
			let o = ParseTransformOrigin(v);
			if (o.HasValue)
			{
				outValue.Kind = .Origin;
				outValue.OriginX = o.Value.X;
				outValue.OriginY = o.Value.Y;
				return true;
			}
			return false;
		case .Layers:
			let layers = scope List<BackgroundLayer>();
			if (ParseBackgroundLayers(v, layers))
			{
				outValue.Kind = .Layers;
				ClearAndDeleteItems(outValue.Layers);
				outValue.Layers.AddRange(layers); // handed over
				return true;
			}
			return false;
		case .TextOutline, .TextGlow:
			let effects = scope List<ShadowValue>();
			if (ParseTextEffectShadow(v, grammar == .TextOutline, effects))
			{
				outValue.Kind = .Shadows;
				outValue.Shadows.Clear();
				outValue.Shadows.AddRange(effects);
				return true;
			}
			return false;
		case .Filters:
			let filters = scope List<FilterFunction>();
			if (ParseFilters(v, filters))
			{
				outValue.Kind = .Filters;
				outValue.Filters.Clear();
				outValue.Filters.AddRange(filters);
				return true;
			}
			return false;
		}
	}

	/// The longhands `name: text` sets, added to `outLonghands` (which owns them): itself when it
	/// is one, its longhands when it is a shorthand (border, border-<side>, border-width,
	/// border-color, border-style, border-radius, padding, margin, margin-inline,
	/// padding-inline, inset-inline, inset, overflow, gap, flex, flex-flow, background,
	/// transition, animation). False when a shorthand's value does not parse.
	public static bool ExpandStyleShorthand(StringView name, StringView text, List<StyleLonghand> outLonghands)
	{
		let value = ParseUtil.Trim(text);
		let joined = scope String();
		if (name == "border")
		{
			let w = scope String();
			let s = scope String();
			let c = scope String();
			if (!StylePropertiesDetail.SplitBorder(value, w, s, c))
				return false;
			for (let side in StylePropertiesDetail.sSides)
			{
				StylePropertiesDetail.Joined("border-", side, "-width", joined);
				StylePropertiesDetail.Push(outLonghands, joined, w);
				StylePropertiesDetail.Joined("border-", side, "-style", joined);
				StylePropertiesDetail.Push(outLonghands, joined, s);
				StylePropertiesDetail.Joined("border-", side, "-color", joined);
				StylePropertiesDetail.Push(outLonghands, joined, c);
			}
			return true;
		}
		for (let side in StylePropertiesDetail.sSides)
		{
			StylePropertiesDetail.Joined("border-", side, "", joined);
			if (name == joined)
			{
				let w = scope String();
				let s = scope String();
				let c = scope String();
				if (!StylePropertiesDetail.SplitBorder(value, w, s, c))
					return false;
				StylePropertiesDetail.Joined("border-", side, "-width", joined);
				StylePropertiesDetail.Push(outLonghands, joined, w);
				StylePropertiesDetail.Joined("border-", side, "-style", joined);
				StylePropertiesDetail.Push(outLonghands, joined, s);
				StylePropertiesDetail.Joined("border-", side, "-color", joined);
				StylePropertiesDetail.Push(outLonghands, joined, c);
				return true;
			}
		}
		if (name == "border-width")
			return StylePropertiesDetail.Sides(value, "border-", "-width", outLonghands);
		if (name == "border-color")
			return StylePropertiesDetail.Sides(value, "border-", "-color", outLonghands);
		if (name == "border-style")
			return StylePropertiesDetail.Sides(value, "border-", "-style", outLonghands);
		if (name == "padding")
			return StylePropertiesDetail.Sides(value, "padding-", "", outLonghands);
		if (name == "inset")
			return StylePropertiesDetail.Sides(value, "", "", outLonghands);
		if ((name == "overflow") || (name == "gap"))
		{
			// One value for both axes, or two: overflow's x then y, gap's row then column.
			let parts = scope List<StringView>();
			SplitTopLevel(value, ' ', parts);
			if (parts.IsEmpty || (parts.Count > 2))
				return false;
			let overflow = name == "overflow";
			StylePropertiesDetail.Push(outLonghands, overflow ? "overflow-x" : "row-gap", parts[0]);
			StylePropertiesDetail.Push(outLonghands, overflow ? "overflow-y" : "column-gap", parts[parts.Count - 1]);
			return true;
		}
		if (name == "flex")
		{
			// none, auto, <grow>, <grow> <shrink>, <grow> <shrink> <basis>, <grow> <basis>, <basis>.
			let parts = scope List<StringView>();
			SplitTopLevel(value, ' ', parts);
			StringView grow = "0";
			StringView shrink = "1";
			StringView basis = "auto";
			if ((parts.Count == 1) && (parts[0] == "none"))
				shrink = "0";
			else if ((parts.Count == 1) && (parts[0] == "auto"))
				grow = "1";
			else
			{
				// A unitless number is grow, then shrink; anything else is the basis.
				int numbers = 0;
				for (let part in parts)
				{
					if (StylePropertiesDetail.PlainNumber(part) && (numbers == 0))
					{
						grow = part;
						basis = "0px"; // `flex: 1` grows from nothing
						numbers++;
					}
					else if (StylePropertiesDetail.PlainNumber(part) && (numbers == 1))
					{
						shrink = part;
						numbers++;
					}
					else
						basis = part;
				}
			}
			StylePropertiesDetail.Push(outLonghands, "flex-grow", grow);
			StylePropertiesDetail.Push(outLonghands, "flex-shrink", shrink);
			StylePropertiesDetail.Push(outLonghands, "flex-basis", basis);
			return true;
		}
		if (name == "flex-flow")
		{
			let parts = scope List<StringView>();
			SplitTopLevel(value, ' ', parts);
			for (let part in parts)
			{
				let wrap = (part == "wrap") || (part == "nowrap") || (part == "wrap-reverse");
				StylePropertiesDetail.Push(outLonghands, wrap ? "flex-wrap" : "flex-direction", part);
			}
			return true;
		}
		if (name == "margin")
			return StylePropertiesDetail.Sides(value, "margin-", "", outLonghands);
		if ((name == "margin-inline") || (name == "padding-inline") || (name == "inset-inline"))
		{
			// The inline start, then the end (one value for both).
			let parts = scope List<StringView>();
			SplitTopLevel(value, ' ', parts);
			if (parts.IsEmpty || (parts.Count > 2))
				return false;
			StylePropertiesDetail.Joined(name, "-start", "", joined);
			StylePropertiesDetail.Push(outLonghands, joined, parts[0]);
			StylePropertiesDetail.Joined(name, "-end", "", joined);
			StylePropertiesDetail.Push(outLonghands, joined, parts[parts.Count - 1]);
			return true;
		}
		if (name == "border-radius")
		{
			let parts = scope List<StringView>();
			if (!ParseSides<StringView>(value, scope (t) => (StringView?)t, parts))
				return false;
			for (int k = 0; k < 4; k++)
			{
				StylePropertiesDetail.Joined("border-", StylePropertiesDetail.sCorners[k], "-radius", joined);
				StylePropertiesDetail.Push(outLonghands, joined, parts[k]);
			}
			return true;
		}
		if ((name == "transition") || (name == "animation"))
		{
			let names = scope List<String>();
			let values = scope List<String>();
			defer
			{
				ClearAndDeleteItems(names);
				ClearAndDeleteItems(values);
			}
			if (name == "transition")
				ExpandTransition(value, names, values);
			else
				ExpandAnimation(value, names, values);
			for (int i = 0; i < names.Count; i++)
				StylePropertiesDetail.Push(outLonghands, names[i], values[i]);
			return true;
		}
		if (name == "background")
		{
			// Layers, the bottom one possibly a colour: the colour to background-color, the rest
			// (or none) to background-image.
			let layers = scope List<StringView>();
			SplitTopLevel(value, ',', layers);
			if (layers.IsEmpty)
				return false;
			StringView color = "transparent";
			int imageCount = layers.Count;
			if (ParseColor(layers[layers.Count - 1]).HasValue)
			{
				color = layers[layers.Count - 1];
				imageCount--;
			}
			let images = scope String();
			for (int k = 0; k < imageCount; k++)
			{
				if (k > 0)
					images.Append(", ");
				images.Append(layers[k]);
			}
			StylePropertiesDetail.Push(outLonghands, "background-color", color);
			StylePropertiesDetail.Push(outLonghands, "background-image", (imageCount == 0) ? (StringView)"none" : (StringView)images);
			return true;
		}
		StylePropertiesDetail.Push(outLonghands, name, value);
		return true;
	}
}
