namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Xml;
using Sedulous.Core.Mathematics;

/// Loads a View tree from an XML string using UIRegistry for element
/// type resolution and property binding.
public static class UIXmlLoader
{
	/// Parse an XML string and return the root View.
	public static View LoadFromString(StringView xml)
	{
		let doc = scope XmlDocument();
		let result = doc.Parse(xml);
		if (result != .Ok)
		{
			Console.WriteLine(scope $"UIXmlLoader: XML parse error: {result} at line {doc.ErrorLine}:{doc.ErrorColumn}");
			return null;
		}

		let rootElem = doc.RootElement;
		if (rootElem == null)
		{
			Console.WriteLine("UIXmlLoader: No root element found");
			return null;
		}

		return BuildView(rootElem, null);
	}

	private static View BuildView(XmlElement element, ViewGroup parent)
	{
		let tagName = element.TagName;

		let view = UIRegistry.CreateView(tagName);
		if (view == null)
		{
			Console.WriteLine(scope $"UIXmlLoader: Unknown element '{tagName}'");
			return null;
		}

		ApplyAttributes(element, tagName, view, parent);

		if (let viewGroup = view as ViewGroup)
		{
			for (let childNode in element.Children)
			{
				if (let childElem = childNode as XmlElement)
				{
					let childView = BuildView(childElem, viewGroup);
					if (childView != null)
						viewGroup.AddView(childView);
				}
			}
		}

		return view;
	}

	private static void ApplyAttributes(XmlElement element, StringView tagName, View view, ViewGroup parent)
	{
		for (let attr in element.Attributes)
		{
			let name = attr.Name;
			let value = attr.Value;

			if (name == "x:Name" || name == "name")
			{ view.Name = new String(value); continue; }

			if (name == "styleId")
			{ view.StyleId = new String(value); continue; }

			if (name == "visibility")
			{
				if (value == "Visible") view.Visibility = .Visible;
				else if (value == "Invisible") view.Visibility = .Invisible;
				else if (value == "Gone") view.Visibility = .Gone;
				continue;
			}

			if (name == "enabled")
			{ view.IsEnabled = (value == "true"); continue; }

			if (name == "focusable")
			{ view.IsFocusable = (value == "true"); continue; }

			if (name == "tabIndex")
			{ if (int32.Parse(value) case .Ok(let idx)) view.TabIndex = idx; continue; }

			if (name.StartsWith("layout_"))
			{ ApplyLayoutParam(view, parent, name, value); continue; }

			if (name == "padding")
			{
				if (let vg = view as ViewGroup)
					if (float.Parse(value) case .Ok(let p)) vg.Padding = .(p);
				continue;
			}

			if (!UIRegistry.SetProperty(tagName, view, name, value))
				Console.WriteLine(scope $"UIXmlLoader: Unknown property '{name}' on '{tagName}'");
		}
	}

	private static void ApplyLayoutParam(View view, ViewGroup parent, StringView name, StringView value)
	{
		if (view.LayoutParams == null && parent != null)
			view.LayoutParams = parent.CreateDefaultLayoutParams();
		if (view.LayoutParams == null)
			view.LayoutParams = new LayoutParams();

		let lp = view.LayoutParams;
		let param = name.Substring(7);

		if (param == "width")
		{
			if (value == "match_parent") lp.Width = LayoutParams.MatchParent;
			else if (value == "wrap_content") lp.Width = LayoutParams.WrapContent;
			else if (float.Parse(value) case .Ok(let f)) lp.Width = f;
		}
		else if (param == "height")
		{
			if (value == "match_parent") lp.Height = LayoutParams.MatchParent;
			else if (value == "wrap_content") lp.Height = LayoutParams.WrapContent;
			else if (float.Parse(value) case .Ok(let f)) lp.Height = f;
		}
		else if (param == "weight")
		{
			if (let llp = lp as LinearLayout.LayoutParams)
				if (float.Parse(value) case .Ok(let f)) llp.Weight = f;
		}
		else if (param == "gravity")
		{
			if (let flp = lp as FrameLayout.LayoutParams)
				flp.Gravity = ParseGravity(value);
			else if (let llp = lp as LinearLayout.LayoutParams)
				llp.Gravity = ParseGravity(value);
		}
		else if (param == "margin")
		{
			if (float.Parse(value) case .Ok(let f)) lp.Margin = .(f);
		}
	}

	public static Gravity ParseGravity(StringView value)
	{
		Gravity result = .None;
		for (let part in value.Split('|'))
		{
			let s = scope String();
			s.Append(part);
			s.Trim();

			if (s == "Left") result |= .Left;
			else if (s == "Right") result |= .Right;
			else if (s == "CenterH") result |= .CenterH;
			else if (s == "FillH") result |= .FillH;
			else if (s == "Top") result |= .Top;
			else if (s == "Bottom") result |= .Bottom;
			else if (s == "CenterV") result |= .CenterV;
			else if (s == "FillV") result |= .FillV;
			else if (s == "Center") result |= .Center;
			else if (s == "Fill") result |= .Fill;
		}
		return result;
	}
}
