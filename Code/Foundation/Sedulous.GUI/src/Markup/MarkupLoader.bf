namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Xml;
using Sedulous.Core.Mathematics;

/// Loads a View tree from an XML (.sml) string or file.
/// Uses MarkupRegistry for element type resolution and property binding.
///
/// Usage:
///   MarkupRegistry.RegisterBuiltins();
///   let root = MarkupLoader.LoadFromString(smlText, context);
///   let btn = context.FindByName<Button>("resume-btn");
///   btn.OnClick.Add(new (b) => OnResume());
public static class MarkupLoader
{
	/// Parse an XML string and return the root View.
	/// The context is used for name registration (id attributes).
	public static View LoadFromString(StringView xml, UIContext context = null)
	{
		let doc = scope XmlDocument();
		let result = doc.Parse(xml);
		if (result != .Ok)
			return null;

		let rootElem = doc.RootElement;
		if (rootElem == null)
			return null;

		return BuildView(rootElem, null, null, context);
	}

	/// Parse XML from an IResourceProvider path.
	public static View LoadFromFile(StringView path, IResourceProvider provider, UIContext context = null)
	{
		if (provider == null) return null;

		let xml = scope String();
		if (provider.LoadText(path, xml) case .Err)
			return null;

		return LoadFromString(xml, context);
	}

	/// Build a View from an XML element, recursing into children.
	private static View BuildView(XmlElement element, ViewGroup parent, StringView parentTagName, UIContext context)
	{
		let tagName = element.TagName;

		// Handle <Include> directive
		if (tagName == "Include")
		{
			// Not implemented yet — requires IResourceProvider
			return null;
		}

		let view = MarkupRegistry.CreateView(tagName);
		if (view == null)
			return null;

		// Create appropriate LayoutParams if parent is a registered layout container
		LayoutParams lp = null;
		if (!parentTagName.IsEmpty && MarkupRegistry.IsLayoutRegistered(parentTagName))
			lp = MarkupRegistry.CreateLayoutParams(parentTagName);

		// Apply attributes
		ApplyAttributes(element, tagName, view, parentTagName, lp, context);

		// If LayoutParams were created and any param was set, assign to view
		if (lp != null)
		{
			delete view.LayoutParams;
			view.LayoutParams = lp;
		}

		// Recurse into children
		if (let viewGroup = view as ViewGroup)
		{
			for (let childNode in element.Children)
			{
				if (let childElem = childNode as XmlElement)
				{
					let childView = BuildView(childElem, viewGroup, tagName, context);
					if (childView != null)
						viewGroup.AddView(childView);
				}
			}
		}

		// Handle text content: <Button>Click Me</Button>
		// Set as text property if the view has one
		let textContent = scope String();
		GetTextContent(element, textContent);
		if (!textContent.IsEmpty)
		{
			// Try to set "text" property via registry
			if (!MarkupRegistry.SetProperty(tagName, view, "text", textContent))
			{
				// Fallback: try SetText method pattern
			}
		}

		return view;
	}

	/// Apply XML attributes to a view, routing to properties, layout params, or special attributes.
	private static void ApplyAttributes(XmlElement element, StringView tagName, View view,
		StringView parentTagName, LayoutParams lp, UIContext context)
	{
		for (let attr in element.Attributes)
		{
			let name = attr.Name;
			let value = attr.Value;

			// === Special attributes ===

			if (name == "id" || name == "name")
			{
				view.Name = new String(value);
				continue;
			}

			if (name == "class")
			{
				for (let cls in value.Split(' '))
				{
					let trimmed = scope String();
					trimmed.Append(cls);
					trimmed.Trim();
					if (!trimmed.IsEmpty)
						view.AddClass(trimmed);
				}
				continue;
			}

			// === Common View properties ===

			if (name == "visibility")
			{
				if (value == "visible") view.Visibility = .Visible;
				else if (value == "hidden") view.Visibility = .Hidden;
				else if (value == "gone") view.Visibility = .Gone;
				continue;
			}

			if (name == "is-enabled")
			{ view.IsEnabled = (value == "true"); continue; }

			if (name == "opacity")
			{ if (float.Parse(value) case .Ok(let f)) view.Opacity = f; continue; }

			if (name == "cursor")
			{
				if (value == "hand") view.Cursor = .Hand;
				else if (value == "ibeam") view.Cursor = .IBeam;
				else if (value == "crosshair") view.Cursor = .Crosshair;
				else if (value == "arrow") view.Cursor = .Arrow;
				else if (value == "move") view.Cursor = .Move;
				continue;
			}

			if (name == "tooltip")
			{ view.TooltipText = new String(value); continue; }

			if (name == "is-focusable")
			{ view.IsFocusable = (value == "true"); continue; }

			if (name == "is-tab-stop")
			{ view.IsTabStop = (value == "true"); continue; }

			if (name == "tab-index")
			{ if (int32.Parse(value) case .Ok(let idx)) view.TabIndex = idx; continue; }

			if (name == "padding")
			{
				if (let vg = view as ViewGroup)
					vg.Padding = MarkupRegistry.ParseThickness(value);
				continue;
			}

			if (name == "clips-content")
			{ view.ClipsContent = (value == "true"); continue; }

			// === Layout params (width, height, margin + container-specific) ===

			if (name == "width" && lp != null)
			{ lp.Width = MarkupRegistry.ParseSizeSpec(value); continue; }

			if (name == "height" && lp != null)
			{ lp.Height = MarkupRegistry.ParseSizeSpec(value); continue; }

			if (name == "margin" && lp != null)
			{ lp.Margin = MarkupRegistry.ParseThickness(value); continue; }

			// Try container-specific layout params
			if (lp != null && !parentTagName.IsEmpty)
			{
				if (MarkupRegistry.SetLayoutParam(parentTagName, lp, name, value))
					continue;
			}

			// === Control-specific properties via registry ===

			if (MarkupRegistry.SetProperty(tagName, view, name, value))
				continue;

			// Unknown attribute — silently ignore
		}
	}

	/// Extract direct text content from an element (not child elements).
	private static void GetTextContent(XmlElement element, String outText)
	{
		for (let child in element.Children)
		{
			if (let textNode = child as XmlText)
			{
				let text = textNode.Text;
				let trimmed = scope String(text);
				trimmed.Trim();
				if (!trimmed.IsEmpty)
				{
					if (outText.Length > 0) outText.Append(' ');
					outText.Append(trimmed);
				}
			}
		}
	}

	/// Initialize the markup system. Call once at startup.
	public static void Initialize()
	{
		MarkupRegistry.RegisterBuiltins();
	}
}
