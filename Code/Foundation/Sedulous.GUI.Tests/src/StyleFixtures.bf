using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A parent widget holding a child per letter of its tags ('b' button, 'l' label), in order. The
/// parent and the children go with it.
class Row
{
	public UIWidget Parent = new .();
	public List<UIWidget> Kids = new .() ~ delete _;

	public this(StringView tags)
	{
		for (let t in tags)
		{
			let w = StyleFixtures.Widget((t == 'b') ? "button" : "label");
			Parent.AddChild(w);
			Kids.Add(w);
		}
	}

	public ~this()
	{
		for (let k in Kids)
			k.ReleaseRef();
		Parent.ReleaseRef();
	}

	public UIWidget this[int i] => Kids[i];
}

/// What the selector, sheet and cascade tests share.
static class StyleFixtures
{
	/// A new widget tagged `tag`, held by the caller: it releases it.
	public static UIWidget Widget(StringView tag)
	{
		let w = new UIWidget();
		w.Tag = tag;
		return w;
	}

	/// A new widget tagged `tag` with the id `id`, held by the caller.
	public static UIWidget Widget(StringView tag, StringView id)
	{
		let w = Widget(tag);
		w.Id = id;
		return w;
	}

	/// Whether `selector` matches `element`.
	public static bool Selects(StringView selector, UIWidget element, bool applyPseudo = true)
	{
		let s = scope StyleSelector(selector);
		return s.Select(element, applyPseudo);
	}

	/// `selector`'s specificity.
	public static int64 SpecificityOf(StringView selector)
	{
		let s = scope StyleSelector(selector);
		return s.Specificity;
	}

	/// How many rules `css` parses into.
	public static int RuleCountOf(StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		return sheet.RuleCount;
	}

	/// Whether any of `all` says something holding `part`.
	public static bool Says(List<GuiDiagnostic> all, StringView part)
	{
		for (let d in all)
		{
			if (d.Message.Contains(part))
				return true;
		}
		return false;
	}
}
