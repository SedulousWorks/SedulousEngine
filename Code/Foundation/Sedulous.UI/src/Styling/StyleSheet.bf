namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Inheritable style properties - these walk the parent chain if not
/// found on the view itself.
public static class StyleInheritance
{
	public static bool IsInheritable(StyleProperty prop)
	{
		switch (prop)
		{
		case .TextColor, .FontSize:
			return true;
		default:
			return false;
		}
	}
}

/// Rule-based cascading style system. Replaces flat theme dictionaries.
/// Rules match views by type, style class, and control state.
/// Most specific match wins (cascade). RefCounted so it can be shared
/// between multiple UIContexts (e.g., screen-space and world-space).
///
/// Resolution order (highest priority first):
/// 1. Inline (set directly on view instance)
/// 2. StyleClass + State match (specificity 12)
/// 3. StyleClass match (specificity 11)
/// 4. Type + State match (specificity 2)
/// 5. Type match (specificity 1)
/// 6. For inheritable properties: walk parent chain
public class StyleSheet : RefCounted
{
	private List<StyleRule> mRules = new .();

	/// Owned drawables - StyleSheet deletes these on destruction.
	private List<Drawable> mOwnedDrawables = new .();

	/// Owned resources (e.g., atlas textures that back drawables).
	private List<Object> mOwnedResources = new .();

	// === Rule management ===

	/// Add a rule. StyleSheet takes ownership.
	public void AddRule(StyleRule rule)
	{
		mRules.Add(rule);
	}

	/// Number of rules.
	public int RuleCount => mRules.Count;

	// === Convenience rule builders ===

	/// Create a rule matching a view type.
	public StyleRule ForType(Type viewType)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule matching a view type + style class.
	public StyleRule ForType(Type viewType, StringView styleClass)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.AddClass(styleClass);
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule matching a view type + state.
	public StyleRule ForTypeState(Type viewType, ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.State = state;
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule matching a view type + style class + state.
	public StyleRule ForTypeClassState(Type viewType, StringView styleClass, ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.AddClass(styleClass);
		rule.Selector.State = state;
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule matching a style class (any view type).
	public StyleRule ForClass(StringView styleClass)
	{
		let rule = new StyleRule();
		rule.Selector.AddClass(styleClass);
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule targeting a pseudo-element on a view type.
	/// e.g., ForTypePseudo(typeof(Slider), "thumb") -> Slider::thumb { ... }
	public StyleRule ForTypePseudo(Type viewType, StringView pseudoElement)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.SetPseudoElement(pseudoElement);
		mRules.Add(rule);
		return rule;
	}

	/// Create a rule targeting a pseudo-element + state.
	/// e.g., Slider:disabled::thumb { ... }
	public StyleRule ForTypePseudoState(Type viewType, StringView pseudoElement, ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.SetPseudoElement(pseudoElement);
		rule.Selector.State = state;
		mRules.Add(rule);
		return rule;
	}

	// === Resource ownership ===

	/// Take ownership of a drawable (deleted when StyleSheet is released).
	/// Use for drawables created outside of rules (e.g., shared atlas drawables).
	public void OwnDrawable(Drawable drawable)
	{
		mOwnedDrawables.Add(drawable);
	}

	/// Take ownership of an arbitrary resource (e.g., a ThemeAtlas).
	public void OwnResource(Object resource)
	{
		mOwnedResources.Add(resource);
	}

	/// Create a ColorDrawable, take ownership, and return it.
	/// Convenience for flat themes that need many color drawables.
	public ColorDrawable OwnColor(Color color)
	{
		let d = new ColorDrawable(color);
		mOwnedDrawables.Add(d);
		return d;
	}

	// === Resolution ===

	/// Resolve a style property for a view. Walks rules in specificity order,
	/// returns the first match. For inheritable properties, walks the parent
	/// chain if no match on the view itself.
	public StyleValue Resolve(View view, StyleProperty prop)
	{
		// Inline overrides beat every rule-based match - the CSS
		// `style="..."` analogue, specificity infinity.
		let @inline = view.GetInlineStyle(prop);
		if (!(@inline case .None))
			return @inline;

		let state = view.GetControlState();

		// Find the best matching rule with this property.
		StyleValue bestValue = .None;
		int32 bestSpecificity = -1;

		for (let rule in mRules)
		{
			if (!rule.Selector.Matches(view, state))
				continue;

			let val = rule.GetValue(prop);
			if (val == null)
				continue;

			let specificity = rule.Selector.Specificity;
			if (specificity > bestSpecificity)
			{
				bestSpecificity = specificity;
				bestValue = val.Value;
			}
		}

		if (bestValue case .None)
		{
			// For inheritable properties, try parent chain. The recursion
			// re-enters this method, so the parent's inline overrides are
			// consulted before its rules.
			if (StyleInheritance.IsInheritable(prop) && view.Parent != null)
				return Resolve(view.Parent, prop);
		}

		return bestValue;
	}

	/// Resolve a Color property. Returns defaultVal if not found.
	public Color ResolveColor(View view, StyleProperty prop, Color defaultVal = .White)
	{
		let val = Resolve(view, prop);
		if (let c = val.AsColor) return c;
		return defaultVal;
	}

	/// Resolve a float property. Returns defaultVal if not found.
	public float ResolveFloat(View view, StyleProperty prop, float defaultVal = 0)
	{
		let val = Resolve(view, prop);
		if (let f = val.AsFloat) return f;
		return defaultVal;
	}

	/// Resolve a Thickness property. Returns defaultVal if not found.
	public Thickness ResolveThickness(View view, StyleProperty prop, Thickness defaultVal = .())
	{
		let val = Resolve(view, prop);
		if (let t = val.AsThickness) return t;
		return defaultVal;
	}

	/// Resolve a Drawable property. Returns null if not found.
	public Drawable ResolveDrawable(View view, StyleProperty prop)
	{
		let val = Resolve(view, prop);
		return val.AsDrawable;
	}

	/// Resolve a bool property. Returns defaultVal if not found.
	public bool ResolveBool(View view, StyleProperty prop, bool defaultVal = false)
	{
		let val = Resolve(view, prop);
		if (let b = val.AsBool) return b;
		return defaultVal;
	}

	// === Pseudo-element (part) resolution ===

	/// Resolve a style property for a pseudo-element on a view.
	/// The partState is the part's interaction state (e.g., thumb hovered).
	public StyleValue ResolvePart(View view, StringView pseudoElement, StyleProperty prop, ControlState partState)
	{
		// Inline pseudo-element overrides win over any rule.
		let @inline = view.GetInlinePartStyle(pseudoElement, prop);
		if (!(@inline case .None))
			return @inline;

		StyleValue bestValue = .None;
		int32 bestSpecificity = -1;

		for (let rule in mRules)
		{
			if (!rule.Selector.Matches(view, partState, pseudoElement))
				continue;

			let val = rule.GetValue(prop);
			if (val == null)
				continue;

			let specificity = rule.Selector.Specificity;
			if (specificity > bestSpecificity)
			{
				bestSpecificity = specificity;
				bestValue = val.Value;
			}
		}

		return bestValue;
	}

	public Drawable ResolvePartDrawable(View view, StringView part, StyleProperty prop, ControlState partState)
	{
		return ResolvePart(view, part, prop, partState).AsDrawable;
	}

	public Color ResolvePartColor(View view, StringView part, StyleProperty prop, ControlState partState, Color defaultVal = .White)
	{
		if (let c = ResolvePart(view, part, prop, partState).AsColor) return c;
		return defaultVal;
	}

	public float ResolvePartFloat(View view, StringView part, StyleProperty prop, ControlState partState, float defaultVal = 0)
	{
		if (let f = ResolvePart(view, part, prop, partState).AsFloat) return f;
		return defaultVal;
	}

	// === Destructor ===

	public ~this()
	{
		for (let rule in mRules)
			delete rule;
		delete mRules;

		for (let d in mOwnedDrawables)
			d.ReleaseRef();
		delete mOwnedDrawables;

		for (let r in mOwnedResources)
			delete r;
		delete mOwnedResources;
	}
}
