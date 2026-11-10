using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// ScrollView: a Panel that scrolls (`overflow: auto` on both axes) and takes focus, so the keys
// scroll it. Scrolling itself is the base node's, for any node a sheet gives `overflow: scroll`
// or `auto`: the wheel, the keys while focused, its bars, a focused descendant brought into view.
// Its children are its content.

[GuiReflect(true)]
class ScrollView : UIWidget
{
	public this()
	{
		Tag = "scrollview";
		AccessRoleName = "scrollview"; // what a screen reader takes it for
		TabFocusable = true;
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			EditLayoutStyle(scope (s) =>
				{
					s.OverflowX = .Auto;
					s.OverflowY = .Auto;
				});
		}
	}
}
