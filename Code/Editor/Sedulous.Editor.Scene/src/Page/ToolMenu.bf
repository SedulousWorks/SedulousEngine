using System;
using System.Collections;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// One category's dropdown on the viewport toolbar, over the tools registered under it.
class ToolMenu
{
	/// Borrowed; the toolbar owns the button.
	public ToolbarMenuButton Button = null;
	public String Category = new .() ~ delete _;
	public List<String> Ids = new .() ~ DeleteContainerAndItems!(_);
	/// What the button shows now: the category, or "Terrain: Sculpt Terrain" while one of
	/// its tools is active.
	public String Label = new .() ~ delete _;

	public this() {}
}
