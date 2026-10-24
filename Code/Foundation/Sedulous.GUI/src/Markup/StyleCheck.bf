using System;
using System.Collections;

namespace Sedulous.GUI;

// What a sheet's declarations name that nothing takes: a cook warns of a typo (`colour: red`) the
// style pass would drop without a word. A name stands when the style table has it (a property or
// a shorthand), when it is a custom property (`--accent`), or when an element type registered now
// takes it by its CSS name (`nav-up`, a gamekit screen's `covers`): so the check asks the element
// types the tools register, not a list.

static
{
	/// The CSS names the registered element types take as reflected properties (with their
	/// bases'), each once, added to `outNames`, which owns them.
	public static void RegisteredCssNames(List<String> outNames)
	{
		ElementTypes.ForEach(scope [&] (tag, element) =>
			{
				for (var type = element; type != null; type = type.Base)
				{
					for (let property in type.OwnProperties)
					{
						if (!property.Css.IsEmpty && !outNames.ContainsAlt(property.Css))
							outNames.Add(new String(property.Css));
					}
				}
			});
	}

	/// Whether a declaration's `name` is one a style takes (see the file's note).
	public static bool IsKnownStyleName(StringView name, StringView value, Span<String> cssNames)
	{
		if ((name.Length > 2) && (name[0] == '-') && (name[1] == '-'))
			return true; // a custom property
		if (FindStyleProperty(name) != null)
			return true;
		let longhands = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems!(longhands); }
		if (ExpandStyleShorthand(name, value, longhands) && !((longhands.Count == 1) && (longhands[0].Name == name)))
			return true;
		for (let known in cssNames)
		{
			if (known == name)
				return true;
		}
		return false;
	}

	/// Says each declaration of `sheet`'s rules and keyframe stops whose name nothing takes, with
	/// its rule's line, added to `outDiagnostics`, which owns them.
	public static void CheckStyleSheetNames(StyleSheet sheet, List<GuiDiagnostic> outDiagnostics)
	{
		let cssNames = scope List<String>();
		defer { ClearAndDeleteItems!(cssNames); }
		RegisteredCssNames(cssNames);
		void Say(uint32 line, StringView message)
		{
			let d = new GuiDiagnostic();
			d.Level = .Warning;
			d.Line = line;
			d.Message.Set(message);
			outDiagnostics.Add(d);
		}
		for (let rule in sheet.Rules)
		{
			for (let property in rule.Properties)
			{
				if (!IsKnownStyleName(property.Name, property.Value, cssNames))
					Say(rule.Line, scope String()..AppendF("{} sets '{}', which no style or element takes", rule.SelectorText, property.Name));
			}
		}
		for (let keyframes in sheet.AllKeyframes)
		{
			for (let stop in keyframes.Stops)
			{
				for (let property in stop.Properties)
				{
					if ((property.Name != "animation-timing-function") && !IsKnownStyleName(property.Name, property.Value, cssNames))
						Say(0, scope String()..AppendF("@keyframes {} sets '{}', which no style takes", keyframes.Name, property.Name));
				}
			}
		}
	}
}
