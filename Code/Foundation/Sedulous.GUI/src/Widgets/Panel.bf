using System;

namespace Sedulous.GUI;

// Panel: the plain container element (`<Panel>` in markup, `add("Panel")` in a script). It lays
// out its children by its display kind (a flex column unless its sheet or markup says otherwise:
// `display`, `flex-direction`, `grid-template-columns`, ...); everything it does is the base
// node's.

[GuiReflect(true)]
class Panel : UIWidget
{
	public this()
	{
		Tag = "panel";
	}
}
