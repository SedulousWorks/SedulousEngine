namespace Sedulous.UI.Resources;

using System;
using Sedulous.Xml;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

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
	/// Parse a Theme from an XML string.
	public static Theme Parse(StringView xml)
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
