namespace Sedulous.UI.Resources;

using System;
using Sedulous.Xml;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

/// Parses a Theme from an XML string. Theme XML format:
///
/// ```xml
/// <Theme name="MyTheme">
///   <Palette primary="60,120,215" background="30,30,35" ... />
///   <Color key="Button.Background" value="60,120,215"/>
///   <Color key="Button.Background.Hover" value="80,150,240"/>
///   <Dimension key="Button.CornerRadius" value="4"/>
///   <Padding key="Button.Padding" value="12,8"/>
///   <FontSize key="Label.FontSize" value="16"/>
///   <String key="App.Title" value="My App"/>
/// </Theme>
/// ```
public static class ThemeXmlParser
{
	/// Optional callback for loading images referenced by drawable elements.
	/// Returns an OwnedImageData for the given path, or null on failure.
	/// The theme takes ownership of returned images via OwnResource.
	public typealias ImageLoader = delegate OwnedImageData(StringView path);

	/// Parse a Theme from an XML string.
	public static Theme Parse(StringView xml) => Parse(xml, null);

	/// Parse a Theme from an XML string with optional image loading support.
	/// The imageLoader callback resolves file paths for Image/NineSlice drawables.
	public static Theme Parse(StringView xml, ImageLoader imageLoader)
	{
		let doc = scope XmlDocument();
		let result = doc.Parse(xml);
		if (result != .Ok)
		{
			Console.WriteLine(scope $"ThemeXmlParser: parse error: {result}");
			return null;
		}

		let root = doc.RootElement;
		if (root == null || root.TagName != "Theme")
		{
			Console.WriteLine("ThemeXmlParser: root element must be <Theme>");
			return null;
		}

		let theme = new Theme();

		// Name attribute.
		let name = root.GetAttribute("name");
		if (name.Length > 0)
			theme.Name.Set(name);

		// Process child elements.
		for (let childNode in root.Children)
		{
			let elem = childNode as XmlElement;
			if (elem == null) continue;

			let tag = elem.TagName;
			let key = elem.GetAttribute("key");
			let value = elem.GetAttribute("value");

			if (tag == "Palette")
			{
				ParsePalette(elem, ref theme.Palette);
			}
			else if (tag == "Color" && key.Length > 0)
			{
				if (UIRegistry.ParseColor(value, let col))
					theme.SetColor(key, col);
			}
			else if (tag == "Dimension" && key.Length > 0)
			{
				if (float.Parse(value) case .Ok(let f))
					theme.SetDimension(key, f);
			}
			else if (tag == "Padding" && key.Length > 0)
			{
				let thickness = ParseThickness(value);
				theme.SetPadding(key, thickness);
			}
			else if (tag == "FontSize" && key.Length > 0)
			{
				if (float.Parse(value) case .Ok(let f))
					theme.SetFontSize(key, f);
			}
			else if (tag == "String" && key.Length > 0)
			{
				theme.SetString(key, value);
			}
			else if (tag == "Drawable" && key.Length > 0)
			{
				let drawable = ParseDrawable(elem, imageLoader, theme);
				if (drawable != null)
					theme.SetDrawable(key, drawable);
			}
		}

		theme.ApplyExtensions();
		return theme;
	}

	private static void ParsePalette(XmlElement elem, ref Palette palette)
	{
		void TrySetColor(StringView attrName, ref Color target)
		{
			let val = elem.GetAttribute(attrName);
			if (val.Length > 0)
				if (UIRegistry.ParseColor(val, let col))
					target = col;
		}

		TrySetColor("primary", ref palette.Primary);
		TrySetColor("primaryAccent", ref palette.PrimaryAccent);
		TrySetColor("background", ref palette.Background);
		TrySetColor("surface", ref palette.Surface);
		TrySetColor("surfaceBright", ref palette.SurfaceBright);
		TrySetColor("border", ref palette.Border);
		TrySetColor("text", ref palette.Text);
		TrySetColor("textDim", ref palette.TextDim);
		TrySetColor("error", ref palette.Error);
		TrySetColor("success", ref palette.Success);
		TrySetColor("warning", ref palette.Warning);
	}

	/// Parse a <Drawable> element. Supported types:
	///   <Drawable key="..." type="Color" color="R,G,B,A"/>
	///   <Drawable key="..." type="RoundedRect" fill="R,G,B,A" radius="4" border="R,G,B,A" borderWidth="1"/>
	///   <Drawable key="..." type="Image" src="path/to/image.png"/>
	///   <Drawable key="..." type="NineSlice" src="path/to/image.png" slices="4,4,4,4"/>
	///   <Drawable key="..." type="SVG"><![CDATA[<svg>...</svg>]]></Drawable>
	///   <Drawable key="..." type="StateList">
	///     <State state="Normal" type="Image" src="button_normal.png"/>
	///     <State state="Hover" type="Image" src="button_hover.png"/>
	///   </Drawable>
	private static Drawable ParseDrawable(XmlElement elem, ImageLoader imageLoader, Theme theme)
	{
		let type = elem.GetAttribute("type");

		if (type == "Color")
		{
			let colorStr = elem.GetAttribute("color");
			if (UIRegistry.ParseColor(colorStr, let col))
				return new ColorDrawable(col);
		}
		else if (type == "RoundedRect")
		{
			Color fill = .Transparent;
			Color border = .Transparent;
			float radius = 0;
			float borderWidth = 0;

			let fillStr = elem.GetAttribute("fill");
			if (fillStr.Length > 0) UIRegistry.ParseColor(fillStr, out fill);

			let borderStr = elem.GetAttribute("border");
			if (borderStr.Length > 0) UIRegistry.ParseColor(borderStr, out border);

			let radiusStr = elem.GetAttribute("radius");
			if (radiusStr.Length > 0 && float.Parse(radiusStr) case .Ok(let r)) radius = r;

			let bwStr = elem.GetAttribute("borderWidth");
			if (bwStr.Length > 0 && float.Parse(bwStr) case .Ok(let bw)) borderWidth = bw;

			return new RoundedRectDrawable(fill, radius, border, borderWidth);
		}
		else if (type == "Image")
		{
			let src = elem.GetAttribute("src");
			if (src.Length > 0 && imageLoader != null)
			{
				let img = imageLoader(src);
				if (img != null)
				{
					theme.OwnResource(img);
					Color tint = .White;
					let tintStr = elem.GetAttribute("tint");
					if (tintStr.Length > 0) UIRegistry.ParseColor(tintStr, out tint);
					return new ImageDrawable(img, tint);
				}
			}
		}
		else if (type == "NineSlice")
		{
			let src = elem.GetAttribute("src");
			if (src.Length > 0 && imageLoader != null)
			{
				let img = imageLoader(src);
				if (img != null)
				{
					theme.OwnResource(img);
					let slices = ParseNineSlice(elem.GetAttribute("slices"));
					Color tint = .White;
					let tintStr = elem.GetAttribute("tint");
					if (tintStr.Length > 0) UIRegistry.ParseColor(tintStr, out tint);
					return new NineSliceDrawable(img, slices, tint);
				}
			}
		}
		else if (type == "SVG")
		{
			// SVG content embedded as CDATA:
			// <Drawable key="..." type="SVG"><![CDATA[<svg>...</svg>]]></Drawable>
			let text = scope String();
			elem.GetTextContent(text);
			if (text.Length > 0)
				return SVGDrawable.FromString(text);
		}
		else if (type == "StateList")
		{
			let stateList = new StateListDrawable(true);
			for (let childNode in elem.Children)
			{
				let stateElem = childNode as XmlElement;
				if (stateElem == null || stateElem.TagName != "State") continue;

				let stateStr = stateElem.GetAttribute("state");
				ControlState state = .Normal;
				if (stateStr == "Hover") state = .Hover;
				else if (stateStr == "Pressed") state = .Pressed;
				else if (stateStr == "Focused") state = .Focused;
				else if (stateStr == "Disabled") state = .Disabled;

				let childDrawable = ParseDrawable(stateElem, imageLoader, theme);
				if (childDrawable != null)
					stateList.Set(state, childDrawable);
			}
			return stateList;
		}

		return null;
	}

	private static NineSlice ParseNineSlice(StringView value)
	{
		float[4] v = .(0, 0, 0, 0);
		int i = 0;
		for (let part in value.Split(','))
		{
			if (i >= 4) break;
			let s = scope String();
			s.Append(part);
			s.Trim();
			if (float.Parse(s) case .Ok(let f))
				v[i] = f;
			i++;
		}
		if (i == 1) return .(v[0]);
		if (i == 2) return .(v[0], v[1]);
		return .(v[0], v[1], v[2], v[3]);
	}

	private static Thickness ParseThickness(StringView value)
	{
		float[4] v = .(0, 0, 0, 0);
		int i = 0;
		for (let part in value.Split(','))
		{
			if (i >= 4) break;
			let s = scope String();
			s.Append(part);
			s.Trim();
			if (float.Parse(s) case .Ok(let f))
				v[i] = f;
			i++;
		}
		if (i == 1) return .(v[0]);
		if (i == 2) return .(v[0], v[1]);
		if (i >= 4) return .(v[0], v[1], v[2], v[3]);
		return .();
	}
}
