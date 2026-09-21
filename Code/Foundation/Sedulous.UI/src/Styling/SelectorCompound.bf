using System;
using System.Collections;

namespace Sedulous.UI;

/// One compound of a selector: every constraint here must hold on ONE view.
///
/// A class, not a struct: it owns strings, and a Beef struct copy would alias them, so the
/// ancestor step that holds one owns it. StyleSelector.Subject's only caller wanted the
/// specificity, which is a shared static.
class SelectorCompound
{
	/// The view type to match. Null matches any type.
	public Type ViewType = null;
	/// A type name the sheet used that no registry knows.
	///
	/// Such a compound matches NOTHING. Matching everything instead would be silent and
	/// wrong; matching nothing is loud in a test and harmless at runtime.
	public bool UnknownType = false;
	/// All must be present on the view. Empty matches any.
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);
	/// The view's Name, from `#id`. Null when not constrained.
	public String Id ~ delete _;
	/// All flags must be present on the view. Null matches any state.
	public ControlState? State = null;
	public StructuralMatch Structural = .None;

	public this() {}

	public bool IsEmpty =>
		(ViewType == null) && !UnknownType && StyleClasses.IsEmpty && (Id == null)
		&& (State == null) && (Structural == .None);

	public void SetId(StringView id)
	{
		if (Id == null)
			Id = new .();
		Id.Set(id);
	}

	public void AddClass(StringView name) => StyleClasses.Add(new String(name));

	public int32 Specificity => Weigh(ViewType, UnknownType, StyleClasses.Count, Id != null,
		State, Structural);

	/// CSS's weighting, shared with StyleSelector's subject: an id is a hundred, a class or a
	/// pseudo class ten, and a type or pseudo element one.
	public static int32 Weigh(Type viewType, bool unknownType, int classCount, bool hasId,
		ControlState? state, StructuralMatch structural)
	{
		var score = (int32)classCount * 10;

		if (hasId)
			score += 100;
		if ((viewType != null) || unknownType)
			score += 1;

		if (state != null)
		{
			// Each state flag is one pseudo class, and `:normal`, having no flags at all,
			// still counts as one.
			var count = 0;
			var bits = (uint32)state.Value;
			while (bits != 0)
			{
				bits &= bits - 1;
				count++;
			}
			score += ((count == 0) ? 1 : (int32)count) * 10;
		}

		var structuralBits = (uint8)structural;
		while (structuralBits != 0)
		{
			structuralBits &= (uint8)(structuralBits - 1);
			score += 10;
		}

		return score;
	}
}
