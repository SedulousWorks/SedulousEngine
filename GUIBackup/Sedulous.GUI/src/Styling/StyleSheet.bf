namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Inheritable style properties — walk the parent chain if not found
/// on the view itself.
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

/// Rule-based cascading style system. Rules match views by Beef type,
/// style classes, control state flags, and pseudo-element names.
/// Most specific match wins.
public class StyleSheet : RefCounted
{
	private List<StyleRule> mRules = new .();
	private List<Drawable> mOwnedDrawables = new .();
	private List<Object> mOwnedResources = new .();

	// === Rule management ===

	public void AddRule(StyleRule rule)
	{
		mRules.Add(rule);
	}

	public int RuleCount => mRules.Count;

	// === Convenience rule builders ===

	public StyleRule ForType(Type viewType)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		mRules.Add(rule);
		return rule;
	}

	public StyleRule ForTypeClass(Type viewType, StringView styleClass)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.AddClass(styleClass);
		mRules.Add(rule);
		return rule;
	}

	public StyleRule ForTypeState(Type viewType, ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.State = state;
		mRules.Add(rule);
		return rule;
	}

	public StyleRule ForTypeClassState(Type viewType, StringView styleClass, ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.ViewType = viewType;
		rule.Selector.AddClass(styleClass);
		rule.Selector.State = state;
		mRules.Add(rule);
		return rule;
	}

	public StyleRule ForClass(StringView styleClass)
	{
		let rule = new StyleRule();
		rule.Selector.AddClass(styleClass);
		mRules.Add(rule);
		return rule;
	}

	public StyleRule ForState(ControlState state)
	{
		let rule = new StyleRule();
		rule.Selector.State = state;
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

	public void OwnDrawable(Drawable drawable)
	{
		mOwnedDrawables.Add(drawable);
	}

	public void OwnResource(Object resource)
	{
		mOwnedResources.Add(resource);
	}

	// === Resolution (element-level) ===

	/// Resolve a style property for a view (no pseudo-element).
	public StyleValue Resolve(View view, StyleProperty prop)
	{
		return ResolveInternal(view, prop, default);
	}

	/// Resolve a style property for a pseudo-element on a view.
	/// The state is the part's state (e.g., thumb hovered), not the parent's.
	public StyleValue ResolvePart(View view, StringView pseudoElement, StyleProperty prop, ControlState partState)
	{
		return ResolveInternalWithState(view, prop, pseudoElement, partState);
	}

	/// Core resolution: find the highest-specificity matching rule.
	private StyleValue ResolveInternal(View view, StyleProperty prop, StringView pseudoElement)
	{
		let state = view.GetControlState();
		return ResolveInternalWithState(view, prop, pseudoElement, state);
	}

	private StyleValue ResolveInternalWithState(View view, StyleProperty prop, StringView pseudoElement, ControlState state)
	{
		StyleValue bestValue = .None;
		int32 bestSpecificity = -1;

		for (let rule in mRules)
		{
			if (!rule.Selector.Matches(view, state, pseudoElement))
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
			// Inheritance only for element-level (not pseudo-elements)
			if (pseudoElement.IsEmpty && StyleInheritance.IsInheritable(prop) && view.Parent != null)
				return Resolve(view.Parent, prop);
		}

		return bestValue;
	}

	// === Typed resolution helpers (element-level) ===

	public Color ResolveColor(View view, StyleProperty prop, Color defaultVal = .White)
	{
		if (let c = Resolve(view, prop).AsColor) return c;
		return defaultVal;
	}

	public float ResolveFloat(View view, StyleProperty prop, float defaultVal = 0)
	{
		if (let f = Resolve(view, prop).AsFloat) return f;
		return defaultVal;
	}

	public Thickness ResolveThickness(View view, StyleProperty prop, Thickness defaultVal = .())
	{
		if (let t = Resolve(view, prop).AsThickness) return t;
		return defaultVal;
	}

	public Drawable ResolveDrawable(View view, StyleProperty prop)
	{
		return Resolve(view, prop).AsDrawable;
	}

	public bool ResolveBool(View view, StyleProperty prop, bool defaultVal = false)
	{
		if (let b = Resolve(view, prop).AsBool) return b;
		return defaultVal;
	}

	// === Typed resolution helpers (pseudo-element) ===

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

	public Drawable ResolvePartDrawable(View view, StringView part, StyleProperty prop, ControlState partState)
	{
		return ResolvePart(view, part, prop, partState).AsDrawable;
	}

	// === Destructor ===

	public ~this()
	{
		for (let rule in mRules)
			delete rule;
		delete mRules;

		for (let d in mOwnedDrawables)
			delete d;
		delete mOwnedDrawables;

		for (let r in mOwnedResources)
			delete r;
		delete mOwnedResources;
	}
}
