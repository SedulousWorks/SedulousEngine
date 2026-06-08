namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;

/// Describes the type of a dock layout node.
enum DockLayoutNodeType
{
	/// A split node with two children and a divider.
	Split,
	/// A tab group containing one or more panels.
	TabGroup
}

/// Serializable snapshot of a dock tree node.
/// Used by DockManager.ExportLayout/ApplyLayout for layout persistence.
/// The consumer (e.g., editor) is responsible for serializing this structure
/// to disk in whatever format it chooses.
class DockLayoutNode
{
	/// Node type: Split or TabGroup.
	public DockLayoutNodeType Type;

	// === Split properties (only valid when Type == .Split) ===

	/// Split orientation.
	public Orientation Direction;

	/// Split ratio (0..1), where the value is the fraction of the first child.
	public float SplitRatio;

	/// First child (left or top). Owned by this node.
	public DockLayoutNode First ~ delete _;

	/// Second child (right or bottom). Owned by this node.
	public DockLayoutNode Second ~ delete _;

	// === TabGroup properties (only valid when Type == .TabGroup) ===

	/// Persistence IDs of panels in this tab group, in tab order.
	public List<String> PanelIds = new .() ~ DeleteContainerAndItems!(_);

	/// Index of the active (visible) tab.
	public int ActiveTabIndex;
}
