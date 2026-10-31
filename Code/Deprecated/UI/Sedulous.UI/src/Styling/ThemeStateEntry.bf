using System;

namespace Sedulous.UI;

/// A control state paired with the internal image key holding that state's image.
class ThemeStateEntry
{
	public ControlState State = .Normal;
	public String Key = new .() ~ delete _;

	public this() {}

	public this(ControlState state, StringView key)
	{
		State = state;
		Key.Set(key);
	}
}
