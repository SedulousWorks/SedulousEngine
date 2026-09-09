using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A rule based cascading style system.
///
/// Rules match views by selector chain; the cascade orders every matching rule by specificity
/// and then source order, and the LAST declaration of a property wins.
///
/// Ref counted, so one sheet can be shared between contexts.
///
/// The resolution methods, which all take a View, are NOT here: their bodies read the view
/// tree and are ported with the View cluster.
class StyleSheet : RefCounted
{
	private List<StyleRule> mRules = new .() ~ ReleaseRules(_);
	private List<Drawable> mOwnedDrawables = new .() ~ ReleaseDrawables(_);
	private List<RefCounted> mOwnedResources = new .() ~ ReleaseResources(_);
	private uint32 mVersion = 1;

	public this() {}

	public ~this()
	{
		// A rule can OUTLIVE the sheet, having been shared into another by MergeFrom, so
		// never leave one pointing at a counter that has gone.
		for (let rule in mRules)
		{
			if (rule.OwnerVersion == &mVersion)
				rule.BindOwnerVersion(null);
		}
	}

	private static void ReleaseRules(List<StyleRule> rules)
	{
		for (let rule in rules)
			rule.ReleaseRef();
		delete rules;
	}

	private static void ReleaseDrawables(List<Drawable> drawables)
	{
		for (let drawable in drawables)
			drawable.ReleaseRef();
		delete drawables;
	}

	private static void ReleaseResources(List<RefCounted> resources)
	{
		for (let resource in resources)
			resource.ReleaseRef();
		delete resources;
	}

	/// This sheet's edit counter, bumped by every rule added and every edit to a rule it owns.
	///
	/// A view's computed style cache keys on the versions of the sheets in ITS OWN chain, so
	/// two contexts with different themes never flush each other's caches.
	public uint32 Version => mVersion;

	// ---- Rules ---------------------------------------------------------------------------------

	/// CONSUMES the caller's reference.
	public void AddRule(StyleRule rule)
	{
		rule.BindOwnerVersion(&mVersion);
		mRules.Add(rule);
		mVersion++;
	}

	/// Inserts a rule BEFORE every existing one, giving it the lowest source order, so a rule
	/// of the same specificity declared in the sheet beats it. This is where the loader's
	/// palette variables go. CONSUMES the caller's reference.
	public void PrependRule(StyleRule rule)
	{
		rule.BindOwnerVersion(&mVersion);
		mRules.Insert(0, rule);
		mVersion++;
	}

	public int RuleCount => mRules.Count;
	public bool IsEmpty => mRules.IsEmpty;
	public StyleRule GetRule(int index) => mRules[index];

	/// Merges another sheet's rules and owned resources into this one, which is what `@import`
	/// does. Both sides then share them, so `other` may be released afterwards.
	public void MergeFrom(StyleSheet other)
	{
		for (let rule in other.mRules)
		{
			// Re-homed, because `other` is transient.
			rule.BindOwnerVersion(&mVersion);
			rule.AddRef();
			mRules.Add(rule);
		}
		for (let drawable in other.mOwnedDrawables)
		{
			drawable.AddRef();
			mOwnedDrawables.Add(drawable);
		}
		for (let resource in other.mOwnedResources)
		{
			resource.AddRef();
			mOwnedResources.Add(resource);
		}
		mVersion++;
	}

	// ---- Inline sheet helpers ------------------------------------------------------------------

	/// The rule with no selector at all, which is what an inline style on the element itself
	/// is. BORROWED.
	public StyleRule GetOrCreateInlineElementRule()
	{
		let existing = FindInlineElementRule();
		if (existing != null)
			return existing;
		return AddNewRule();
	}

	public StyleRule FindInlineElementRule()
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsEmpty)
				return rule;
		}
		return null;
	}

	/// The rule targeting only a named part. BORROWED.
	public StyleRule GetOrCreateInlinePartRule(StringView part)
	{
		let existing = FindInlinePartRule(part);
		if (existing != null)
			return existing;

		let rule = AddNewRule();
		rule.Selector.SetPseudoElement(part);
		return rule;
	}

	public StyleRule FindInlinePartRule(StringView part)
	{
		for (let rule in mRules)
		{
			if (rule.Selector.IsPseudoElementOnly(part))
				return rule;
		}
		return null;
	}

	// ---- Fluent builders -----------------------------------------------------------------------
	// Each answers the sheet owned rule, BORROWED, so a caller can chain Set calls onto it.

	public StyleRule ForAll() => AddNewRule();

	public StyleRule ForType(Type viewType)
	{
		let rule = AddNewRule();
		rule.Selector.ViewType = viewType;
		return rule;
	}

	public StyleRule ForType(Type viewType, StringView styleClass)
	{
		let rule = ForType(viewType);
		rule.Selector.AddClass(styleClass);
		return rule;
	}

	public StyleRule ForTypeState(Type viewType, ControlState state)
	{
		let rule = ForType(viewType);
		rule.Selector.State = state;
		return rule;
	}

	public StyleRule ForTypeClassState(Type viewType, StringView styleClass, ControlState state)
	{
		let rule = ForType(viewType, styleClass);
		rule.Selector.State = state;
		return rule;
	}

	public StyleRule ForClass(StringView styleClass)
	{
		let rule = AddNewRule();
		rule.Selector.AddClass(styleClass);
		return rule;
	}

	public StyleRule ForTypePseudo(Type viewType, StringView pseudoElement)
	{
		let rule = ForType(viewType);
		rule.Selector.SetPseudoElement(pseudoElement);
		return rule;
	}

	public StyleRule ForTypePseudoState(Type viewType, StringView pseudoElement,
		ControlState state)
	{
		let rule = ForTypePseudo(viewType, pseudoElement);
		rule.Selector.State = state;
		return rule;
	}

	// ---- Resource ownership --------------------------------------------------------------------

	/// Keeps a drawable alive for as long as this sheet. CONSUMES the caller's reference.
	///
	/// A drawable handed to a RULE is owned by that rule, since the rule's values borrow it
	/// and a rule can outlive the sheet. So give a drawable to ONE of the two, never both.
	public void OwnDrawable(Drawable drawable)
	{
		if (drawable != null)
			mOwnedDrawables.Add(drawable);
	}

	/// CONSUMES the caller's reference. The sheet is the anchor, as with OwnDrawable.
	public void OwnResource(RefCounted resource)
	{
		if (resource != null)
			mOwnedResources.Add(resource);
	}

	/// A sheet owned colour drawable, answered BORROWED.
	public ColorDrawable OwnColor(Color color)
	{
		let drawable = new ColorDrawable(color);
		mOwnedDrawables.Add(drawable);
		return drawable;
	}

	// ---- Internals -----------------------------------------------------------------------------

	/// A fresh rule, added and BORROWED back.
	private StyleRule AddNewRule()
	{
		let rule = new StyleRule();
		rule.BindOwnerVersion(&mVersion);
		mRules.Add(rule);
		mVersion++;
		return rule;
	}
}
