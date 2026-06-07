namespace Sedulous.GUI;

using System;

/// Matches views by type, style class, and/or control state.
/// Specificity determines cascade priority: higher specificity wins.
public class StyleSelector
{
	/// View type to match (null = any type).
	public Type ViewType;

	/// Style class to match (null = any class).
	public String StyleClass ~ delete _;

	/// Control state to match (null = any state).
	public ControlState? State;

	/// Computed specificity: class=10, type=1, state=1.
	/// Higher specificity wins in the cascade.
	public int32 Specificity
	{
		get
		{
			int32 s = 0;
			if (StyleClass != null) s += 10;
			if (ViewType != null) s += 1;
			if (State.HasValue) s += 1;
			return s;
		}
	}

	/// Check if this selector matches the given view and state.
	public bool Matches(View view, ControlState state)
	{
		if (ViewType != null && !view.GetType().IsSubtypeOf(ViewType))
			return false;
		if (StyleClass != null)
		{
			if (view.StyleId == null || view.StyleId != StyleClass)
				return false;
		}
		// State check: all selector state flags must be present in the view's state.
		if (State.HasValue)
		{
			let required = State.Value;
			if (required != .Normal && !state.HasFlag(required))
				return false;
		}
		return true;
	}
}
