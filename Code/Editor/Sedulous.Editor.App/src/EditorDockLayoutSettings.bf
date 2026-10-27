using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// The dock's layout section of the per-project editor settings: the GUI dock's
/// DockLayoutDocument, captured from its DockController and applied through Adopt; panels by
/// their ids, a panel the layout names that is not registered keeping its place until it is.
/// Hand-written for its legacy reader: version 1 held Sedulous.UI's dock tree, which is read
/// once into the new layout (its splits, shares, tab groups and chosen tabs) and saved as
/// version 2 after.
class EditorDockLayoutSettings : ISerializable
{
	/// The identity version 1 was stored under, kept so its records are known as this type.
	public const uint64 TypeId = 0x2D4D3B1B4A3D2B7EUL;
	public const uint32 DataVersion = 2;
	/// Version 1 still reads, into the new layout: a legacy reader one version back, removed once
	/// projects have saved past it.
	public const uint32 MinReadDataVersion = 1;

	/// Whether a layout was captured; false, the caller keeps its default layout.
	public bool Captured = false;
	public DockLayoutDocument Document = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion, MinReadDataVersion);
		if (!ar.IsPayloadOk)
		{
			EndVersionedPayload(ar);
			return;
		}
		ar.BeginObject();
		if ((ar.Mode == .Read) && (ar.Version == 1))
		{
			// The old dock's tree, taken into the GUI dock's layout (saved as version 2 after).
			var hasRoot = false;
			ar.Key("hasRoot");
			Sedulous.Core.Serialization.Serialize(ar, ref hasRoot);
			Captured = false;
			if (hasRoot)
			{
				let root = scope LegacyDockNode();
				ar.Key("root");
				ReadLegacyNode(ar, root);
				LayoutFromLegacy(root, Document.Layout);
				// A tree that names no panel places none: the caller keeps its default.
				Captured = ar.IsPayloadOk && (root.FirstPanel() != null);
			}
		}
		else
		{
			ar.Key("captured");
			Sedulous.Core.Serialization.Serialize(ar, ref Captured);
			if (Captured)
			{
				ar.Key("layout");
				ar.BeginObject();
				Document.Serialize(ar);
				ar.EndObject();
			}
		}
		ar.EndObject();
		EndVersionedPayload(ar);
	}

	/// The old dock's tree as the GUI dock's layout, into `outLayout` (what it held before goes):
	/// its first panel's group in the central stack, each split's halves beside one another with
	/// the same shares, each group's tabs in order with its chosen one. A panel named twice (a
	/// file edited by hand) is placed once, where the walk first puts it.
	public static void LayoutFromLegacy(LegacyDockNode root, DockLayout outLayout)
	{
		outLayout.Set(scope DockLayout());
		PlaceLegacyNode(outLayout, root, outLayout.CentralStack);
	}

	/// One node of version 1's tree into `node`, its children behind their presence flags. Read
	/// whole so a positional backend lands where the next value starts.
	private static void ReadLegacyNode(ISerializer ar, LegacyDockNode node)
	{
		ar.BeginObject();
		uint8 type = 0; // the node is told by its children, not this
		ar.Key("type");
		Sedulous.Core.Serialization.Serialize(ar, ref type);
		ar.Key("direction");
		Sedulous.Core.Serialization.Serialize(ar, ref node.Direction);
		ar.Key("ratio");
		Sedulous.Core.Serialization.Serialize(ar, ref node.Ratio);
		ar.Key("activeTab");
		Sedulous.Core.Serialization.Serialize(ar, ref node.ActiveTab);
		ar.Key("panels");
		SerializeList(ar, node.Panels);
		var hasFirst = false;
		var hasSecond = false;
		ar.Key("hasFirst");
		Sedulous.Core.Serialization.Serialize(ar, ref hasFirst);
		ar.Key("hasSecond");
		Sedulous.Core.Serialization.Serialize(ar, ref hasSecond);
		if (hasFirst)
		{
			delete node.First;
			node.First = new LegacyDockNode();
			ar.Key("first");
			ReadLegacyNode(ar, node.First);
		}
		if (hasSecond)
		{
			delete node.Second;
			node.Second = new LegacyDockNode();
			ar.Key("second");
			ReadLegacyNode(ar, node.Second);
		}
		ar.EndObject();
	}

	/// Places `node`'s panels into `stack` and the stacks split from it. `stack` holds nothing
	/// yet, or the node's first panel: a split puts its second half's first panel beside it
	/// (taking the second half's share), so each half then splits only its own stack.
	private static void PlaceLegacyNode(DockLayout layout, LegacyDockNode node, DockNodeId stack)
	{
		if (!node.IsSplit)
		{
			for (let panel in node.Panels)
			{
				if (layout.StackOf(panel) == cNoDock)
					layout.InsertTab(panel, stack);
			}
			// The chosen tab, when it is this group's (a panel named twice is chosen where it
			// first was, not here).
			if ((node.ActiveTab >= 0) && (node.ActiveTab < node.Panels.Count))
			{
				let chosen = node.Panels[node.ActiveTab];
				if (layout.StackOf(chosen) == stack)
					layout.Activate(chosen);
			}
			return;
		}
		let firstPanel = node.First.FirstPanel();
		let secondPanel = node.Second.FirstPanel();
		if ((firstPanel == null) || (secondPanel == null))
		{
			PlaceLegacyNode(layout, (firstPanel != null) ? node.First : node.Second, stack);
			return;
		}
		if (layout.StackOf(firstPanel) == cNoDock)
			layout.InsertTab(firstPanel, stack);
		// Sedulous.UI's Orientation: Horizontal (0) put the second child right of the first,
		// Vertical (1) below it.
		let side = (node.Direction == 0) ? DockSide.End : DockSide.Bottom;
		let share = Math.Clamp(1.0f - node.Ratio, 0.05f, 0.95f);
		if (!layout.InsertBeside(secondPanel, stack, side, share).Ok)
		{
			PlaceLegacyNode(layout, node.First, stack); // a panel named twice: the first half alone
			return;
		}
		let beside = layout.StackOf(secondPanel);
		PlaceLegacyNode(layout, node.First, stack);
		PlaceLegacyNode(layout, node.Second, beside);
	}
}

/// One node of version 1's tree, as Sedulous.UI's DockLayoutNode wrote it: a split of two
/// children, the first's share `Ratio` (left or top), side by side (`Direction` 0, the old
/// Orientation.Horizontal) or one over the other (1, Vertical); or a tab group of panels in tab
/// order, `ActiveTab` the chosen one. Its written `type` is not kept: a node with both children
/// is a split, else a group.
class LegacyDockNode
{
	public uint8 Direction = 0;
	public float Ratio = 0.5f;
	public int32 ActiveTab = 0;
	public List<String> Panels = new .() ~ DeleteContainerAndItems!(_);
	/// OWNED.
	public LegacyDockNode First = null ~ delete _;
	/// OWNED.
	public LegacyDockNode Second = null ~ delete _;

	public bool IsSplit => (First != null) && (Second != null);

	/// The first panel of the subtree, in order (left or top first); null when it holds none.
	public String FirstPanel()
	{
		if (IsSplit)
		{
			if (let found = First.FirstPanel())
				return found;
			return Second.FirstPanel();
		}
		return Panels.IsEmpty ? null : Panels[0];
	}
}
