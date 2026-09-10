using System;

namespace Sedulous.UI;

/// One row of a ContextMenu: a label, what it does, and possibly a submenu.
///
/// Owns its action and its submenu. Raptor holds the submenu as a RefPtr<View> to sidestep a
/// gcc modules bug with the mutually recursive types; Beef has no such trouble, so it is held
/// as what it is.
class MenuItem
{
	public String Label = new .() ~ delete _;
	/// OWNED; null for a separator or a pure submenu row.
	public delegate void() Action ~ delete _;
	public bool Enabled = true;
	public bool IsSeparator = false;
	/// OWNED; null unless this row opens a submenu.
	public ContextMenu Submenu ~ _?.ReleaseRef();

	public this() {}

	/// CONSUMES the action delegate.
	public this(StringView label, delegate void() action, bool enabled = true)
	{
		Label.Set(label);
		Action = action;
		Enabled = enabled;
	}

	public static MenuItem CreateSeparator()
	{
		let item = new MenuItem();
		item.IsSeparator = true;
		return item;
	}
}
