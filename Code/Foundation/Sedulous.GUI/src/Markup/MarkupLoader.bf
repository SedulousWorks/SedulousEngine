using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Fonts;
using Sedulous.Xml;

namespace Sedulous.GUI;

// MarkupLoader: inflate a widget tree from XML markup. Modeled on eepp's layout loading (role
// only). An element name is a tag the loader's ElementSet resolves to a registered element type
// (ElementTypes: the GUI's widgets and any library's); nested elements become children; an element
// it does not know is left out with a warning.
// Attributes are applied in tiers:
//   - `id` / `class` set the widget's CSS identity,
//   - a value starting with `@` on a translatable property is a translation key, with
//     `<prop>-count` and `<prop>-args` beside it; `@@` is a literal @,
//   - a value with `{{name}}` in it binds the reflected property of that name to the loader's
//     data model: `value="{{volume}}"` follows `volume`, and writes it back when the property is
//     one the user changes (a slider's value, a checkbox, a text field's text);
//     `text="Score: {{score}}"` follows the text built from it,
//   - an attribute a widget claims (via UINode.SetMarkupAttribute - e.g. Label "text" and
//     "rich") is consumed structurally,
//   - everything else is treated as an inline CSS property and run through the StyleApplier (one
//     naming no style property, shorthand or reflected property is warned about),
//   - a `<template type="...">` child is markup kept by its parent (UINode.SetMarkupTemplate) to
//     make nodes from later (an item view's rows); loaded with item bindings, a value with
//     `{{item}}`, `{{item.Column}}` or `{{index}}` in it is recorded for the row to fill,
// so the whole CSS property vocabulary (width/height/padding/margin/background-color/border/
// text-align/units/...) works in markup for free. Given a diagnostics list, what it drops and a
// parse error go there, for a cook; without one they are logged.
//
// Example:
//   <Panel flex-direction="row" gap="8" padding="12" class="panel">
//     <Label text="Hello" text-align="center"/>
//     <Button text="OK" width="120" class="accent"/>
//   </Panel>

/// A run of a `{{...}}` template: literal text, or a name. A class: it owns its text.
class MarkupTemplatePart
{
	public String Text = new .() ~ delete _;
	public bool IsName = false;

	public void Set(MarkupTemplatePart other)
	{
		Text.Set(other.Text);
		IsName = other.IsName;
	}
}

/// An attribute an item view's row fills from its item (`text="{{item.Name}}"`). A class: it
/// owns its text and its parts; Set copies another deeply.
class ItemBinding
{
	/// In the row's content, which owns it.
	public Node Target = null;
	public String Attribute = new .() ~ delete _;
	public List<MarkupTemplatePart> Parts = new .() ~ DeleteContainerAndItems!(_);

	public void Set(ItemBinding other)
	{
		Target = other.Target;
		Attribute.Set(other.Attribute);
		ClearAndDeleteItems!(Parts);
		for (let part in other.Parts)
		{
			let copy = new MarkupTemplatePart();
			copy.Set(part);
			Parts.Add(copy);
		}
	}
}

class MarkupLoader
{
	private ElementSet mElements; // borrowed
	private IResourceProvider mResources; // borrowed
	private IFontService mFontService; // borrowed
	private LengthContext mLengths;
	private DataModel mData = null ~ _?.ReleaseRef();
	private List<ItemBinding> mItemBindings = null; // borrowed
	private List<GuiDiagnostic> mDiagnostics = null; // borrowed: where what it drops goes (null: the log)

	/// `elements` (borrowed, kept alive by the caller while the loader is used) is what the markup
	/// may create; `resources` and `fontService` (borrowed, may be null) are what the inline style
	/// loads images and resolves fonts with.
	public this(ElementSet elements, IResourceProvider resources = null, IFontService fontService = null)
	{
		mElements = elements;
		mResources = resources;
		mFontService = fontService;
		mLengths = LengthContext();
	}

	public this(ElementSet elements, IResourceProvider resources, IFontService fontService, LengthContext lengths)
	{
		mElements = elements;
		mResources = resources;
		mFontService = fontService;
		mLengths = lengths;
	}

	/// Where what it drops (an element no type makes, an attribute nothing takes) and a parse
	/// error go, instead of the log (a cook's warnings and errors); the list owns what is added.
	/// Null: the log.
	public void SetDiagnostics(List<GuiDiagnostic> diagnostics)
	{
		mDiagnostics = diagnostics;
	}

	/// The data model `{{name}}` values bind to (a GUIContext's Data); without one they stay as
	/// written. The loader holds a reference.
	public void SetDataModel(DataModel model)
	{
		if (model != null)
			model.AddRef();
		if (mData != null)
			mData.ReleaseRef();
		mData = model;
	}

	/// Records `{{item...}}` and `{{index}}` attributes here (borrowed; it owns what is added), for
	/// a row to fill (an item view's template), instead of applying them.
	public void SetItemBindings(List<ItemBinding> bindings)
	{
		mItemBindings = bindings;
	}

	/// Applies one attribute as markup does (a widget's own, else inline CSS, which the style pass
	/// applies): what a row's item binding writes.
	public static void ApplyAttribute(Node node, StringView name, StringView value)
	{
		let uinode = node as UINode;
		if (uinode == null)
			return;
		if (!uinode.SetMarkupAttribute(name, value))
			uinode.SetInlineStyle(name, value);
	}

	/// Inflate the root element of `markup` into a widget tree; null on a parse error or an
	/// unknown root element. The node comes with one reference, the caller's.
	public Node LoadFromString(StringView markup)
	{
		let document = scope XmlDocument();
		let result = document.Parse(markup);
		if (result != .Ok)
		{
			Report(.Error, (uint32)Math.Max(document.ErrorLine, 0),
				scope String()..AppendF("the markup does not parse: {}", result.Describe));
			return null;
		}
		let root = FirstElementChild(document);
		if (root == null)
		{
			Report(.Error, 0, "the markup has no element");
			return null;
		}
		return Inflate(root);
	}

	private Node Inflate(XmlElement element)
	{
		let widget = mElements.Create(element.TagName);
		if (widget == null)
		{
			// An element this GUI does not make (a typo, or one its element set leaves out): said,
			// rather than the subtree vanishing without a word.
			Report(.Warning, element.Line,
				scope String()..AppendF("no element <{}>; it and what it holds are left out", element.TagName));
			return null;
		}

		let uinode = widget as UINode;
		let uiwidget = widget as UIWidget;

		let inlineStyle = scope ResolvedStyle();
		for (let attr in element.Attributes)
		{
			let name = attr.Name;
			var value = attr.Value;
			// A translated text: `text="@menu.play"`, its count and arguments in `text-count` and
			// `text-args` (each a value or a {{binding}}); `@@` is a literal @.
			if (IsTranslationExtra(element, name))
				continue;
			if ((value.Length > 1) && (value[0] == '@'))
			{
				if (value[1] == '@')
					value = value.Substring(1, value.Length - 1);
				else if (BindTranslated(element, widget, name, value.Substring(1, value.Length - 1)))
					continue;
			}
			if (name == "id")
			{
				if (uiwidget != null)
					uiwidget.Id = value;
				continue;
			}
			if (name == "class")
			{
				AddClasses(uiwidget, value);
				continue;
			}
			if ((mItemBindings != null) && IsItemTemplate(value))
			{
				let binding = new ItemBinding();
				binding.Target = widget;
				binding.Attribute.Set(name);
				if (SplitTemplate(value, binding.Parts))
				{
					mItemBindings.Add(binding);
					continue;
				}
				delete binding;
			}
			if ((mData != null) && (FindFrom(value, "{{", 0) < value.Length) && Bind(widget, name, value))
				continue;
			if ((uinode != null) && uinode.SetMarkupAttribute(name, value))
				continue;
			if (!IsStyleName(uinode, name, value))
				Report(.Warning, attr.Line,
					scope String()..AppendF("<{}> has no attribute or style property '{}'", element.TagName, name));
			inlineStyle.Set(name, value); // an inline CSS property
			if (uinode != null)
				uinode.SetInlineStyle(name, value); // kept: it outranks the sheets at every restyle
		}
		if (uinode != null)
			ApplyStyle(uinode, inlineStyle, mResources, mFontService, mLengths);

		for (var child = element.FirstChildElement; child != null; child = child.NextSiblingElement)
		{
			if (child.TagName == "template")
			{
				// Kept as markup by its parent, to make nodes from later.
				let body = child.FirstChildElement;
				if ((uinode != null) && (body != null))
				{
					let text = scope String();
					let writer = scope XmlWriter(text);
					writer.WriteNode(body);
					uinode.SetMarkupTemplate(child.GetAttribute("type"), writer.Output);
				}
				continue;
			}
			let childWidget = Inflate(child);
			if (childWidget != null)
			{
				widget.ChildHost.AddChild(childWidget); // a scroller's content, a window's
				childWidget.ReleaseRef(); // its parent holds it
			}
		}

		return widget;
	}

	// Said: into the diagnostics when given, else to the log.
	private void Report(GuiDiagnostic.Severity level, uint32 line, StringView message)
	{
		if (mDiagnostics != null)
		{
			let d = new GuiDiagnostic();
			d.Level = level;
			d.Line = line;
			d.Message.Set(message);
			mDiagnostics.Add(d);
			return;
		}
		GlobalLog(.Warning, "GUI: markup: {}", message);
	}

	// Whether an attribute names something a style sets: a property the sheets know, a shorthand
	// of them, a custom property, or a property the widget's type takes by its CSS name.
	private static bool IsStyleName(UINode node, StringView name, StringView value)
	{
		if ((FindStyleProperty(name) != null) || ((name.Length > 2) && (name[0] == '-') && (name[1] == '-')))
			return true;
		let longhands = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems!(longhands); }
		if (ExpandStyleShorthand(name, value, longhands) && !((longhands.Count == 1) && (longhands[0].Name == name)))
			return true;
		return (node != null) && (node.GuiType.FindCss(name) != null);
	}

	/// Where `needle` starts in `text` at or after `from`; text.Length when it does not.
	public static int FindFrom(StringView text, StringView needle, int from)
	{
		for (int i = from; i + needle.Length <= text.Length; i++)
		{
			if (text.Substring(i, needle.Length) == needle)
				return i;
		}
		return text.Length;
	}

	/// Splits `text` into its literal runs and `{{name}}`s (names trimmed), added to `parts`, which
	/// owns them; false when a `{{` is not closed or a name is empty.
	public static bool SplitTemplate(StringView text, List<MarkupTemplatePart> parts)
	{
		int at = 0;
		while (at < text.Length)
		{
			let open = FindFrom(text, "{{", at);
			if (open > at)
			{
				let literal = new MarkupTemplatePart();
				literal.Text.Set(text.Substring(at, open - at));
				parts.Add(literal);
			}
			if (open == text.Length)
				break;
			let start = open + 2;
			let close = FindFrom(text, "}}", start);
			if (close == text.Length)
				return false;
			let name = ParseUtil.Trim(text.Substring(start, close - start));
			if (name.Length == 0)
				return false;
			let part = new MarkupTemplatePart();
			part.Text.Set(name);
			part.IsName = true;
			parts.Add(part);
			at = close + 2;
		}
		return true;
	}

	/// `<prop>-count` or `<prop>-args` beside a `<prop>="@key"`: the translation's count and
	/// arguments, which BindTranslated reads. Any other attribute so named is the widget's own
	/// (`animation-iteration-count`).
	public static bool IsTranslationExtra(XmlElement element, StringView name)
	{
		StringView @base = default;
		StringView[2] suffixes = .("-count", "-args");
		for (let suffix in suffixes)
		{
			if ((name.Length > suffix.Length) && (name.Substring(name.Length - suffix.Length, suffix.Length) == suffix))
				@base = name.Substring(0, name.Length - suffix.Length);
		}
		if (@base.Length == 0)
			return false;
		let value = element.GetAttribute(@base);
		return (value.Length > 1) && (value[0] == '@') && (value[1] != '@');
	}

	/// One argument: {{name}} reads the GUI's data, anything else is itself. The caller owns what
	/// comes back.
	public static Node.TranslationArgument TranslationArgumentOf(StringView text)
	{
		let trimmed = ParseUtil.Trim(text);
		let argument = new Node.TranslationArgument();
		if ((trimmed.Length > 4) && (trimmed.Substring(0, 2) == "{{") && (trimmed.Substring(trimmed.Length - 2, 2) == "}}"))
		{
			argument.Text.Set(ParseUtil.Trim(trimmed.Substring(2, trimmed.Length - 4)));
			argument.IsName = true;
			return argument;
		}
		argument.Text.Set(trimmed);
		return argument;
	}

	/// Binds `property` of `node` to the translation `key`, with the count and arguments written
	/// beside it (`<prop>-count`, `<prop>-args`); false when the property is not translatable.
	public bool BindTranslated(XmlElement element, Node node, StringView property, StringView key)
	{
		let countName = scope String(property);
		countName.Append("-count");
		let argsName = scope String(property);
		argsName.Append("-args");
		Node.TranslationArgument count = null;
		defer { delete count; }
		let args = scope List<Node.TranslationArgument>();
		defer { ClearAndDeleteItems!(args); }
		for (let attr in element.Attributes)
		{
			if (attr.Name == countName)
			{
				delete count;
				count = TranslationArgumentOf(attr.Value);
			}
			else if (attr.Name == argsName)
			{
				let list = attr.Value;
				int start = 0;
				for (int i = 0; i <= list.Length; i++)
				{
					if ((i == list.Length) || (list[i] == ','))
					{
						args.Add(TranslationArgumentOf(list.Substring(start, i - start)));
						start = i + 1;
					}
				}
			}
		}
		return node.BindTranslation(property, key, mData, count, args);
	}

	// Binds `property` of `node` to the template `value`: one `{{name}}` alone follows the value as
	// it is (and writes it back where the property allows); text around names follows the text
	// built from them. False when nothing bound (no such property, or a malformed template), so
	// the attribute is handled as written.
	public bool Bind(Node node, StringView property, StringView value)
	{
		let parts = new List<MarkupTemplatePart>();
		if (!SplitTemplate(value, parts) || parts.IsEmpty)
		{
			DeleteContainerAndItems!(parts);
			return false;
		}
		if ((parts.Count == 1) && parts[0].IsName)
		{
			let bound = node.BindData(property, mData, parts[0].Text);
			DeleteContainerAndItems!(parts);
			return bound;
		}
		let model = mData;
		model.AddRef();
		return node.BindProperty(property, new [=model, =parts] () =>
			{
				let text = new String();
				for (let part in parts)
				{
					if (part.IsName)
						FormatVariant(model.Get(part.Text), text);
					else
						text.Append(part.Text);
				}
				return System.Variant.Create(text, true);
			} ~ { model.ReleaseRef(); DeleteContainerAndItems!(parts); });
	}

	public static void AddClasses(UIWidget widget, StringView classes)
	{
		if (widget == null)
			return;
		int start = 0;
		for (int i = 0; i <= classes.Length; i++)
		{
			let boundary = (i == classes.Length) || ParseUtil.IsWhiteSpace(classes[i]);
			if (boundary)
			{
				if (i > start)
					widget.AddClass(classes.Substring(start, i - start));
				start = i + 1;
			}
		}
	}

	public static XmlElement FirstElementChild(XmlNode node)
	{
		for (var c = node.FirstChild; c != null; c = c.NextSibling)
		{
			if (c.NodeType == .Element)
				return (XmlElement)c;
		}
		return null;
	}

	// Whether a value names the item a row shows ({{item}}, {{item.X}}, {{index}}).
	public static bool IsItemTemplate(StringView value)
	{
		return (FindFrom(value, "{{item", 0) < value.Length) ||
			(FindFrom(value, "{{index", 0) < value.Length) ||
			(FindFrom(value, "{{ item", 0) < value.Length) ||
			(FindFrom(value, "{{ index", 0) < value.Length);
	}
}
