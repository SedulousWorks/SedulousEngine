using System;
using System.Collections;

namespace Sedulous.UI;

/// Matches views by type, style class, id, control state, structural position and an optional
/// pseudo element name, as a CHAIN of compounds joined by the descendant and child
/// combinators.
///
class StyleSelector
{
	// The SUBJECT compound, meaning the rightmost one, which is the view the rule applies to.
	// Kept as flat fields rather than a SelectorCompound so the sheet builders and every
	// existing reader keep their shape.

	/// Null matches any type.
	public Type ViewType = null;
	/// All must be present on the view. Empty matches any.
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);
	/// The view's Name, from `#id`. Null when not constrained.
	public String Id ~ delete _;
	/// All flags must be present on the view. Null matches any state.
	public ControlState? State = null;
	public StructuralMatch Structural = .None;
	/// A type name no registry knows; see SelectorCompound.UnknownType.
	public bool UnknownType = false;
	/// Null targets the element itself.
	public String PseudoElement ~ delete _;
	/// NEAREST FIRST: the first is matched against the subject's parent, or an ancestor
	/// depending on its DirectParent, the second against that view's parent, and so on.
	public List<SelectorAncestor> Ancestors = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	/// Higher wins the cascade.
	public int32 Specificity
	{
		get
		{
			var score = SelectorCompound.Weigh(ViewType, UnknownType, StyleClasses.Count,
				Id != null, State, Structural);

			if (PseudoElement != null)
				score += 1;
			for (let ancestor in Ancestors)
				score += ancestor.Compound.Specificity;

			return score;
		}
	}

	public void AddClass(StringView name) => StyleClasses.Add(new String(name));

	public void SetId(StringView id)
	{
		if (Id == null)
			Id = new .();
		Id.Set(id);
	}

	public void SetPseudoElement(StringView name)
	{
		if (PseudoElement == null)
			PseudoElement = new .();
		PseudoElement.Set(name);
	}

	/// Prepends an ancestor step, so the sheet can add them in the order it lists them,
	/// outermost first, while the list stays nearest first. OWNERSHIP of the compound
	/// transfers.
	public void AddAncestor(SelectorCompound compound, bool directParent)
	{
		Ancestors.Insert(0, new SelectorAncestor(compound, directParent));
	}

	/// No constraints at all: matches every view in every state.
	public bool IsEmpty =>
		(ViewType == null) && !UnknownType && StyleClasses.IsEmpty && (Id == null)
		&& (State == null) && (Structural == .None) && (PseudoElement == null)
		&& Ancestors.IsEmpty;

	/// Whether this selector matches a view in a given state, and an optional pseudo element
	/// name.
	///
	/// A selector naming a pseudo element matches ONLY when one is asked for, and one naming
	/// none matches only when none is: `Slider::thumb` must not apply to the slider itself.
	public bool Matches(View view, ControlState state, StringView pseudoElement = default)
	{
		if (PseudoElement != null)
		{
			if (pseudoElement.IsEmpty || (PseudoElement != pseudoElement))
				return false;
		}
		else if (!pseudoElement.IsEmpty)
		{
			return false;
		}

		if (UnknownType)
			return false;
		if ((ViewType != null) && !view.GetType().IsSubtypeOf(ViewType))
			return false;

		for (let styleClass in StyleClasses)
		{
			if (!view.HasClass(styleClass))
				return false;
		}

		if ((Id != null) && (view.Name != Id))
			return false;

		if (State != null)
		{
			let required = State.Value;
			// The normal state constrains nothing, having no flags to require.
			if ((required != .Normal) && !HasAllStateFlags(state, required))
				return false;
		}

		if (Structural != .None)
		{
			let structuralOnly = scope SelectorCompound();
			structuralOnly.Structural = Structural;
			if (!CompoundMatches(structuralOnly, view, state))
				return false;
		}

		return Ancestors.IsEmpty || AncestorsMatch(0, view);
	}

	/// Whether EVERY required flag is present.
	///
	/// A compound state selector is a conjunction: `:hover:checked` describes a view that is
	/// both, so a hovered but unchecked one must not match it.
	private static bool HasAllStateFlags(ControlState state, ControlState required) =>
		((uint32)state & (uint32)required) == (uint32)required;

	/// One compound against one view.
	private static bool CompoundMatches(SelectorCompound compound, View view, ControlState state)
	{
		if (compound.UnknownType)
			return false;
		if ((compound.ViewType != null) && !view.GetType().IsSubtypeOf(compound.ViewType))
			return false;

		for (let styleClass in compound.StyleClasses)
		{
			if (!view.HasClass(styleClass))
				return false;
		}

		if ((compound.Id != null) && (view.Name != compound.Id))
			return false;

		if (compound.State != null)
		{
			let required = compound.State.Value;
			if ((required != .Normal) && !HasAllStateFlags(state, required))
				return false;
		}

		if (compound.Structural == .None)
			return true;

		let parent = view.Parent as ViewGroup;

		if (compound.Structural.HasFlag(.FirstChild)
			&& ((parent == null) || (parent.ChildCount == 0)
				|| (parent.GetChildAt(0) != view)))
			return false;

		if (compound.Structural.HasFlag(.LastChild)
			&& ((parent == null) || (parent.ChildCount == 0)
				|| (parent.GetChildAt(parent.ChildCount - 1) != view)))
			return false;

		if (compound.Structural.HasFlag(.Empty))
		{
			let self = view as ViewGroup;
			if ((self != null) && (self.ChildCount != 0))
				return false;
		}

		return true;
	}

	/// The ancestor steps from `index` on, right to left with BACKTRACKING: a descendant step
	/// may match ANY ancestor, and the steps beyond it must still match from there.
	private bool AncestorsMatch(int index, View from)
	{
		if (index >= Ancestors.Count)
			return true;

		let step = Ancestors[index];

		if (step.DirectParent)
		{
			let parent = from.Parent;
			return (parent != null)
				&& CompoundMatches(step.Compound, parent, parent.GetControlState())
				&& AncestorsMatch(index + 1, parent);
		}

		var ancestor = from.Parent;
		while (ancestor != null)
		{
			if (CompoundMatches(step.Compound, ancestor, ancestor.GetControlState())
				&& AncestorsMatch(index + 1, ancestor))
				return true;
			ancestor = ancestor.Parent;
		}
		return false;
	}

	/// Targets ONLY the named pseudo element, with nothing else constrained.
	public bool IsPseudoElementOnly(StringView part) =>
		(ViewType == null) && !UnknownType && StyleClasses.IsEmpty && (Id == null)
		&& (State == null) && (Structural == .None) && Ancestors.IsEmpty
		&& (PseudoElement != null) && (PseudoElement == part);
}
