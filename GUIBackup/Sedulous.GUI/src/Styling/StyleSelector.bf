namespace Sedulous.GUI;

using System;
using System.Collections;

/// Matches views by Beef type, style classes, control state flags,
/// and optional pseudo-element name.
///
/// Specificity: each class=10, type=1, state=1, pseudo-element=1.
///
/// Pseudo-elements (e.g., ::thumb, ::track, ::checkmark) target sub-parts
/// of composite controls. The control queries its pseudo-element styles
/// via View.ResolvePartStyle().
public class StyleSelector
{
	/// View type to match (null = any type). Subtypes match via IsSubtypeOf.
	public Type ViewType;

	/// Style classes to match. All must be present on the view.
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	/// Control state flags to match (null = any state).
	public ControlState? State;

	/// Pseudo-element name to match (null = targets the element itself).
	/// e.g., "thumb", "track", "checkmark", "tab", "strip"
	public String PseudoElement ~ delete _;

	/// Reserved for future combinator support (descendant/child selectors).
	/// When set, this selector only matches if ParentSelector also matches
	/// an ancestor. Not implemented in v1.
	public StyleSelector ParentSelector;

	/// Computed specificity.
	public int32 Specificity
	{
		get
		{
			int32 s = 0;
			s += (int32)StyleClasses.Count * 10;
			if (ViewType != null) s += 1;
			if (State.HasValue) s += 1;
			if (PseudoElement != null) s += 1;
			return s;
		}
	}

	/// Check if this selector matches the given view, state, and
	/// pseudo-element name.
	public bool Matches(View view, ControlState state, StringView pseudoElement = default)
	{
		// Type check
		if (ViewType != null && !view.GetType().IsSubtypeOf(ViewType))
			return false;

		// Class check: ALL selector classes must be on the view
		if (StyleClasses.Count > 0)
		{
			for (let cls in StyleClasses)
			{
				if (!view.HasClass(StringView(cls)))
					return false;
			}
		}

		// State check: ALL selector state flags must be present
		if (State.HasValue)
		{
			let required = State.Value;
			if (required != .Normal && !state.HasFlag(required))
				return false;
		}

		// Pseudo-element check
		if (PseudoElement != null)
		{
			if (pseudoElement.IsEmpty || StringView(PseudoElement) != pseudoElement)
				return false;
		}
		else if (!pseudoElement.IsEmpty)
		{
			// Selector has no pseudo-element but query is for one — no match
			return false;
		}

		return true;
	}

	/// Convenience: add a class to this selector.
	public StyleSelector AddClass(StringView name)
	{
		StyleClasses.Add(new String(name));
		return this;
	}

	/// Convenience: set pseudo-element.
	public StyleSelector SetPseudoElement(StringView name)
	{
		delete PseudoElement;
		PseudoElement = new String(name);
		return this;
	}
}
