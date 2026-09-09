using System;

namespace Sedulous.UI;

/// A control state paired with the atlas region name that draws it.
struct StateImageEntry
{
	public ControlState State = .Normal;
	public StringView Name = default;

	public this() {}

	public this(ControlState state, StringView name)
	{
		State = state;
		Name = name;
	}
}
