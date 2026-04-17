namespace Sedulous.UI;

using System;

/// A single item in a ContextMenu. Owns its action delegate and optional submenu.
public class MenuItem
{
	public String Label ~ delete _;
	public delegate void() Action ~ delete _;
	public bool Enabled = true;
	public bool IsSeparator;
	public ContextMenu Submenu ~ delete _;

	public this() { }

	public this(StringView label, delegate void() action, bool enabled = true)
	{
		Label = new String(label);
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
