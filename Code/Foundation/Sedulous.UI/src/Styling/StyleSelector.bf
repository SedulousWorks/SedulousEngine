namespace Sedulous.UI;

using System;
using System.Collections;

/// Matches views by type, style class(es), control state, and optional
/// pseudo-element name. Pseudo-elements target sub-parts of composite
/// controls (e.g., Slider::thumb, TabView::strip).
///
/// Specificity: each class=10, type=1, state=1, pseudo-element=1.
public class StyleSelector
{
	/// View type to match (null = any type).
	public Type ViewType;

	/// Style classes to match. All must be present on the view.
	/// Empty = any class.
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	/// Control state to match (null = any state).
	/// All selector state flags must be present in the view's state.
	public ControlState? State;

	/// Pseudo-element name to match (null = targets the element itself).
	/// e.g., "thumb", "track", "checkmark", "tab", "strip"
	public String PseudoElement ~ delete _;

	/// Computed specificity: each class=10, type=1, state=1, pseudo-element=1.
	/// Higher specificity wins in the cascade.
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
	/// optional pseudo-element name.
	public bool Matches(View view, ControlState state, StringView pseudoElement = default)
	{
		if (ViewType != null && !view.GetType().IsSubtypeOf(ViewType))
			return false;

		// All selector classes must be present on the view.
		if (StyleClasses.Count > 0)
		{
			for (let cls in StyleClasses)
			{
				if (!view.HasClass(StringView(cls)))
					return false;
			}
		}

		// All selector state flags must be present in the view's state.
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
	public void AddClass(StringView name)
	{
		StyleClasses.Add(new String(name));
	}

	/// Convenience: set pseudo-element.
	public void SetPseudoElement(StringView name)
	{
		delete PseudoElement;
		PseudoElement = new String(name);
	}
}
