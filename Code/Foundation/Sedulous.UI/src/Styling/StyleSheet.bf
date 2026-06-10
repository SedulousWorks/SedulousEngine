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
		case .TextColor, .FontSize, .FontFamily:
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

	// === Inline-sheet rule helpers ===
	//
	// Inline sheets (held by `View.mInlineSheet`) host a single
	// "element" rule with an empty selector that matches the owning
	// view unconditionally, plus per-pseudo-element rules. These
	// helpers find or create those rules. Specificity in the inline
	// sheet doesn't matter - `StyleSheet.Resolve` short-circuits on
	// any non-`.None` value from the inline sheet, treating the inline
	// path as specificity infinity.

	/// Find or create the element-level inline rule (empty selector).
	public StyleRule GetOrCreateInlineElementRule()
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsEmpty)
				return rule;
		}
		let rule = new StyleRule();
		mRules.Add(rule);
		return rule;
	}

	/// Find the element-level inline rule, or null if none has been
	/// created yet.
	public StyleRule FindInlineElementRule()
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsEmpty)
				return rule;
		}
		return null;
	}

	/// Find or create the inline rule for a specific pseudo-element.
	public StyleRule GetOrCreateInlinePartRule(StringView part)
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsPseudoElementOnly(part))
				return rule;
		}
		let rule = new StyleRule();
		rule.Selector.SetPseudoElement(part);
		mRules.Add(rule);
		return rule;
	}

	/// Find an existing inline rule for a specific pseudo-element,
	/// or null if none exists.
	public StyleRule FindInlinePartRule(StringView part)
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsPseudoElementOnly(part))
				return rule;
		}
		return null;
	}

	/// True if this sheet has no rules.
	public bool IsEmpty => mRules.Count == 0;

	// === Convenience rule builders ===

	/// Create a rule whose selector matches every view (empty
	/// selector, specificity 0). Useful for "set this for the whole
	/// subtree" patterns on a LocalStyleSheet - e.g. a single
	/// FontFamily that every descendant inherits, regardless of type.
	public StyleRule ForAll()
	{
		let rule = new StyleRule();
		mRules.Add(rule);
		return rule;
	}

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

	/// Register a drawable for sheet-lifetime ownership. By default the
	/// sheet consumes the caller's ref. Pass `consumeRef: false` to
	/// AddRef instead - useful when the caller wants to hold its own
	/// ref alongside the sheet's. Released on sheet destruction.
	public void OwnDrawable(Drawable drawable, bool consumeRef = true)
	{
		if (drawable == null) return;
		if (!consumeRef)
			drawable.AddRef();
		mOwnedDrawables.Add(drawable);
	}

	/// Take ownership of an arbitrary resource (e.g., a ThemeAtlas).
	public void OwnResource(Object resource)
	{
		mOwnedResources.Add(resource);
	}

	/// Create a ColorDrawable, take ownership for the sheet's
	/// lifetime, and return it. The returned drawable is sheet-owned
	/// (one ref, held by `mOwnedDrawables`); pass it to consumers
	/// that AddRef on capture (`StyleRule.Set` default, `View.SetStyle`
	/// with `consumeRef: false`) or release explicitly when done.
	public ColorDrawable OwnColor(Color color)
	{
		let d = new ColorDrawable(color);
		mOwnedDrawables.Add(d);
		return d;
	}

	// === Resolution ===

	/// Resolve a style property by walking rules on THIS sheet in
	/// specificity order. Returns the best match (`.None` if no rule
	/// matches). Inline-style and inheritance handling live on the
	/// orchestrator (`View.ResolveStyle`); this method is a pure
	/// per-sheet primitive.
	public StyleValue Resolve(View view, StyleProperty prop)
	{
		let state = view.GetControlState();

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

	/// Resolve a style property for a pseudo-element by walking the
	/// rules on THIS sheet. Per-sheet primitive paired with
	/// `View.ResolvePartStyle`, which orchestrates inline +
	/// ancestor-LocalStyleSheets + context across multiple sheets.
	public StyleValue ResolvePart(View view, StringView pseudoElement, StyleProperty prop, ControlState partState)
	{
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
