using System;
using System.Collections;

namespace Sedulous.UI;

/// Matches views by type, style class, id, control state, structural position and an optional
/// pseudo element name, as a CHAIN of compounds joined by the descendant and child
/// combinators.
///
/// Matches itself is not here: it reads the view tree, so it lives with View.
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

	/// Targets ONLY the named pseudo element, with nothing else constrained.
	public bool IsPseudoElementOnly(StringView part) =>
		(ViewType == null) && !UnknownType && StyleClasses.IsEmpty && (Id == null)
		&& (State == null) && (Structural == .None) && Ancestors.IsEmpty
		&& (PseudoElement != null) && (PseudoElement == part);
}
