using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Xml;

namespace Sedulous.UI;

/// Builds a view tree from a markup document.
///
/// Element names and control properties resolve through MarkupRegistry, so the loader knows
/// about no control in particular. What it does know is the vocabulary every element shares:
/// the identity and styling attributes, and the whole LayoutStyle.
///
/// Unknown elements and attributes are DROPPED at runtime rather than failing the load, but a
/// caller passing a warnings list is told about each one. A camelCase typo, fontSize for
/// font-size, otherwise produces a silently invisible interface.
static class MarkupLoader
{
	/// Registers the built-in markup vocabulary. Call once at startup.
	public static void Initialize()
	{
		MarkupRegistry.RegisterBuiltins();
	}

	/// Builds a tree from markup, or null when the document will not parse or its root element
	/// is not a registered one. OWNERSHIP of the root transfers, and it owns the subtree.
	public static View LoadFromString(StringView markup, UIContext context = null,
		List<String> warnings = null)
	{
		let document = scope XmlDocument();
		if (document.Parse(markup) != .Ok)
			return null;

		let root = document.RootElement;
		if (root == null)
			return null;

		return BuildView(root, context, warnings);
	}

	/// Builds one element and everything under it.
	private static View BuildView(XmlElement element, UIContext context, List<String> warnings)
	{
		let tagName = element.TagName;

		// <Include> needs a resource provider to resolve against, which the loader has no way
		// to reach. Recognised and dropped rather than reported as an unknown element.
		if (tagName == "Include")
			return null;

		let view = MarkupRegistry.CreateView(tagName);
		if (view == null)
			return null;

		ApplyAttributes(element, tagName, view, warnings);
		BuildChildren(element, tagName, view, context, warnings);
		ApplyTextContent(element, tagName, view);

		return view;
	}

	private static void BuildChildren(XmlElement element, StringView tagName, View view,
		UIContext context, List<String> warnings)
	{
		// Only a group can hold children; an element nested inside a leaf is dropped.
		let group = view as ViewGroup;
		if (group == null)
			return;

		for (let node in element.Children)
		{
			if (node.NodeType != .Element)
				continue;

			let childElement = node as XmlElement;
			let child = BuildView(childElement, context, warnings);
			if (child != null)
			{
				group.AddView(child);
				continue;
			}

			if (warnings != null)
			{
				warnings.Add(new $"unknown element <{childElement.TagName}> dropped (inside <{tagName}>)");
			}
		}
	}

	/// An element's own text becomes its `text` property, so <Button>Click Me</Button> works
	/// as well as the attribute. Silently ignored by a control that has no such property.
	private static void ApplyTextContent(XmlElement element, StringView tagName, View view)
	{
		let text = scope String();
		GetTextContent(element, text);
		if (text.IsEmpty)
			return;

		MarkupRegistry.SetProperty(tagName, view, "text", text);
	}

	/// Routes each attribute: the identity and styling ones, then the common view properties,
	/// then the layout vocabulary, then whatever the element registered.
	private static void ApplyAttributes(XmlElement element, StringView tagName, View view,
		List<String> warnings)
	{
		// The layout is read once, written through, and set back at the end: SetLayout marks
		// damage, so doing it per attribute would mark it a dozen times for one element.
		var layout = view.Layout;

		for (let attribute in element.Attributes)
		{
			let name = attribute.Name;
			let value = attribute.Value;

			if (ApplyIdentityAttribute(name, value, view))
				continue;

			if (ApplyViewAttribute(name, value, view))
				continue;

			if (MarkupRegistry.ApplyLayoutAttribute(ref layout, name, value))
				continue;

			if (MarkupRegistry.SetProperty(tagName, view, name, value))
				continue;

			if (warnings != null)
				warnings.Add(new $"unknown attribute '{name}' on <{tagName}>");
		}

		view.SetLayout(layout);
	}

	/// Identity and styling: what the view is called, what classes it carries, and its inline
	/// style. Common to every element, and never registered per control.
	private static bool ApplyIdentityAttribute(StringView name, StringView value, View view)
	{
		switch (name)
		{
		case "id", "name":
			view.Name.Set(value);
		case "class":
			// Space separated, as in HTML, so several classes can be given at once.
			for (let part in value.Split(' '))
			{
				var className = part;
				className.Trim();
				if (!className.IsEmpty)
					view.AddClass(className);
			}
		case "style":
			SSSParser.ApplyInlineStyle(view, value);
		default:
			return false;
		}

		return true;
	}

	/// The properties every view has, whatever it is.
	private static bool ApplyViewAttribute(StringView name, StringView value, View view)
	{
		switch (name)
		{
		case "visibility":
			switch (value)
			{
			case "visible": view.Visibility = .Visible;
			case "hidden": view.Visibility = .Hidden;
			case "gone": view.Visibility = .Gone;
			default:
			}
		case "is-enabled":
			view.IsEnabled = ParseBool(value);
		case "opacity":
			if (double.Parse(value) case .Ok(let d))
				view.Opacity = (float)d;
		case "cursor":
			switch (value)
			{
			case "hand": view.Cursor = .Hand;
			case "ibeam": view.Cursor = .IBeam;
			case "crosshair": view.Cursor = .Crosshair;
			case "arrow": view.Cursor = .Arrow;
			case "move": view.Cursor = .Move;
			default:
			}
		case "tooltip":
			view.TooltipText.Set(value);
		case "is-focusable":
			view.IsFocusable = ParseBool(value);
		case "is-tab-stop":
			view.IsTabStop = ParseBool(value);
		case "tab-index":
			if (int32.Parse(value) case .Ok(let index))
				view.TabIndex = index;
		case "padding":
			// A group's own padding field, which is NOT the styled padding: a group declares
			// it directly, and the box metrics take the larger of the two.
			if (let group = view as ViewGroup)
				group.Padding = MarkupRegistry.ParseThickness(value);
		case "clips-content":
			view.ClipsContent = ParseBool(value);
		default:
			return false;
		}

		return true;
	}

	/// An element's DIRECT text, with any child elements skipped. Several runs are joined by a
	/// space, which is what markup broken across lines produces.
	private static void GetTextContent(XmlElement element, String outText)
	{
		for (let node in element.Children)
		{
			if (node.NodeType != .Text)
				continue;

			var text = (node as XmlText).Text;
			text.Trim();
			if (text.IsEmpty)
				continue;

			if (!outText.IsEmpty)
				outText.Append(' ');

			outText.Append(text);
		}
	}

	private static bool ParseBool(StringView value) => value == "true";
}
