using System;
using System.Collections;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A snapshot of one node of the dock tree, which is what makes a layout saveable.
///
/// Panels are named by their PERSISTENCE ID rather than held as views, so a layout survives the
/// panels themselves being destroyed and rebuilt, and can be written to disk. What format it is
/// written in is the consumer's business; this is only the shape.
class DockLayoutNode
{
	public DockLayoutNodeType Type = .TabGroup;

	// ---- Only meaningful on a Split -------------------------------------------------------------

	public Orientation Direction = .Horizontal;
	/// The fraction of the space the FIRST child takes.
	public float SplitRatio = 0.5f;
	/// OWNED. Left or top.
	public DockLayoutNode First = null ~ delete _;
	/// OWNED. Right or bottom.
	public DockLayoutNode Second = null ~ delete _;

	// ---- Only meaningful on a TabGroup ----------------------------------------------------------

	/// The panels in this group, in tab order.
	public List<String> PanelIds = new .() ~ DeleteContainerAndItems!(_);
	public int32 ActiveTabIndex = 0;

	public this() {}
}
