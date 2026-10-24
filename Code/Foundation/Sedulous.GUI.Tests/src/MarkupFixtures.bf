using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What the markup tests share.
static class MarkupFixtures
{
	/// `markup` inflated from every registered element type (the GUI's own registered first); null
	/// when it does not load. The caller releases what comes back.
	public static Node Load(StringView markup)
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(markup);
	}

	/// The widget in `node`'s subtree (`node` first, depth first) whose id is `id`, or null.
	public static Node Find(Node node, StringView id)
	{
		if (let w = node as UIWidget)
		{
			if (w.Id == id)
				return node;
		}
		for (int i = 0; i < node.ChildCount; i++)
		{
			let found = Find(node.GetChildAt(i), id);
			if (found != null)
				return found;
		}
		return null;
	}

	/// Whether `text` holds `part`.
	public static bool Has(StringView text, StringView part) => MarkupLoader.FindFrom(text, part, 0) < text.Length;

	/// Whether one of `all` says `part`.
	public static bool Says(List<GuiDiagnostic> all, StringView part)
	{
		for (let d in all)
		{
			if (Has(d.Message, part))
				return true;
		}
		return false;
	}
}
