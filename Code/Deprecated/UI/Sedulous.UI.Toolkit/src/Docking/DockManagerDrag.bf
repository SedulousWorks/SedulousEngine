using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[DockManager]]: accepting a dragged panel, and the drop zones that say where it would land.
extension DockManager
{
	private const float RootZoneSize = 40.0f;
	private const float NodeZoneSize = 32.0f;

	public override IDropTarget AsDropTarget() => this;

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY) =>
		(data.Format == "dock/panel") ? .Move : .None;

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		if (data.Format == "dock/panel")
			ShowZoneIndicators(localX, localY);
	}

	public void OnDragOver(DragData data, float localX, float localY)
	{
		CarryOverlayWindow(data);

		if (mZoneIndicator.Visibility == .Gone)
			return;

		// Rebuilt every frame, because which node is hovered decides which zones exist at all.
		ShowZoneIndicators(localX, localY);
		mZoneIndicator.UpdateHover(localX, localY);
	}

	/// An OVERLAY floating window follows the cursor during the drag, since nothing else moves
	/// it. A real window is moved by the application's own drag handling, and one under system
	/// chrome deliberately stays put.
	private void CarryOverlayWindow(DragData data)
	{
		let panelData = data as DockPanelDragData;
		if ((panelData == null) || (panelData.SourceWindow == null)
			|| panelData.SourceWindow.IsOSWindow || (Context == null))
			return;

		if (let root = Root())
		{
			let dragDrop = Context.DragDrop;
			root.GetPopupLayer().UpdatePopupPosition(panelData.SourceWindow,
				dragDrop.LastScreenX - panelData.DragOffsetX,
				dragDrop.LastScreenY - panelData.DragOffsetY);
		}
	}

	public void OnDragLeave(DragData data) => HideZoneIndicators();

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		let panelData = data as DockPanelDragData;
		if (panelData == null)
		{
			HideZoneIndicators();
			return .None;
		}

		let target = mZoneIndicator.HoveredTarget;
		HideZoneIndicators();

		var floatX = 0.0f;
		var floatY = 0.0f;
		if (Context != null)
		{
			floatX = Context.DragDrop.LastScreenX;
			floatY = Context.DragDrop.LastScreenY;
		}

		if (target != null)
		{
			if (target.Value.Position == .Float)
				FloatPanel(panelData.Panel, floatX, floatY);
			else
				DockPanelRelativeTo(panelData.Panel, target.Value.Position, target.Value.RelativeTo);

			return .Move;
		}

		// Dropped inside the manager but on no zone. A panel that CAME from a floating window
		// simply stays in it, already moved to where it was released; one dragged out of the
		// tree becomes a new window there.
		if (panelData.SourceWindow != null)
		{
			panelData.SourceWindow.Opacity = 1.0f;
			panelData.SourceWindow.IsInteractionEnabled = true;
		}
		else
		{
			FloatPanel(panelData.Panel, floatX, floatY);
		}

		return .Move;
	}

	// ---- Zones ----------------------------------------------------------------------------------

	/// Where the panel would END UP for a given zone, which is what the hover wash draws. A
	/// split inserts at the default half, and joining the tabs takes the whole region.
	private static Rectangle DropPreviewRect(DockPosition position, Rectangle bounds)
	{
		switch (position)
		{
		case .Top: return .(bounds.X, bounds.Y, bounds.Width, bounds.Height * 0.5f);
		case .Bottom: return .(bounds.X, bounds.Y + (bounds.Height * 0.5f), bounds.Width,
			bounds.Height * 0.5f);
		case .Left: return .(bounds.X, bounds.Y, bounds.Width * 0.5f, bounds.Height);
		case .Right: return .(bounds.X + (bounds.Width * 0.5f), bounds.Y, bounds.Width * 0.5f,
			bounds.Height);
		case .Center, .Float: return bounds;
		}
	}

	/// Two rings of zones: four against the WINDOW's own edges, which dock against the whole
	/// tree, and five around the node under the cursor, which dock against just that node. Both
	/// are needed, because "put this down the left of everything" and "put this left of that
	/// panel" are different intentions that would otherwise share a chip.
	private void ShowZoneIndicators(float cursorX, float cursorY)
	{
		mZoneIndicator.ClearTargets();

		if (mRootNode == null)
		{
			AddCenterZoneForEmptyTree();
		}
		else
		{
			AddRootEdgeZones();
			AddHoveredNodeZones(cursorX, cursorY);
		}

		// The indicator is outside the styled tree, so the resolved accent is handed to it.
		mZoneIndicator.Accent = ResolveStyleColor(.AccentColor, Color.Rgb(80, 150, 240));
		mZoneIndicator.Visibility = .Visible;
		mZoneIndicator.Layout(0, 0, Width, Height);
	}

	private void AddCenterZoneForEmptyTree()
	{
		let center = Float2(Width * 0.5f, Height * 0.5f);
		mZoneIndicator.AddTarget(.Center,
			.(center.X - (RootZoneSize * 0.5f), center.Y - (RootZoneSize * 0.5f), RootZoneSize,
				RootZoneSize), null, .(0, 0, Width, Height));
	}

	private void AddRootEdgeZones()
	{
		let center = Float2(Width * 0.5f, Height * 0.5f);
		let rootRect = Rectangle(0, 0, Width, Height);
		let half = RootZoneSize * 0.5f;

		mZoneIndicator.AddTarget(.Top, .(center.X - half, 8, RootZoneSize, RootZoneSize),
			mRootNode, DropPreviewRect(.Top, rootRect));
		mZoneIndicator.AddTarget(.Bottom,
			.(center.X - half, Height - RootZoneSize - 8, RootZoneSize, RootZoneSize), mRootNode,
			DropPreviewRect(.Bottom, rootRect));
		mZoneIndicator.AddTarget(.Left, .(8, center.Y - half, RootZoneSize, RootZoneSize),
			mRootNode, DropPreviewRect(.Left, rootRect));
		mZoneIndicator.AddTarget(.Right,
			.(Width - RootZoneSize - 8, center.Y - half, RootZoneSize, RootZoneSize), mRootNode,
			DropPreviewRect(.Right, rootRect));
	}

	/// A cross of five chips over whichever leaf the cursor is on.
	private void AddHoveredNodeZones(float cursorX, float cursorY)
	{
		let hoveredNode = FindHoveredDockNode(mRootNode, cursorX, cursorY);
		if (hoveredNode == null)
			return;

		let bounds = GetNodeBounds(hoveredNode);
		if ((bounds.Width <= 0) || (bounds.Height <= 0))
			return;

		let center = bounds.Center();
		let half = NodeZoneSize * 0.5f;
		let edgeOffset = NodeZoneSize + 4.0f;

		mZoneIndicator.AddTarget(.Center,
			.(center.X - half, center.Y - half, NodeZoneSize, NodeZoneSize), hoveredNode,
			DropPreviewRect(.Center, bounds));
		mZoneIndicator.AddTarget(.Top,
			.(center.X - half, center.Y - edgeOffset - half, NodeZoneSize, NodeZoneSize),
			hoveredNode, DropPreviewRect(.Top, bounds));
		mZoneIndicator.AddTarget(.Bottom,
			.(center.X - half, center.Y + edgeOffset - half, NodeZoneSize, NodeZoneSize),
			hoveredNode, DropPreviewRect(.Bottom, bounds));
		mZoneIndicator.AddTarget(.Left,
			.(center.X - edgeOffset - half, center.Y - half, NodeZoneSize, NodeZoneSize),
			hoveredNode, DropPreviewRect(.Left, bounds));
		mZoneIndicator.AddTarget(.Right,
			.(center.X + edgeOffset - half, center.Y - half, NodeZoneSize, NodeZoneSize),
			hoveredNode, DropPreviewRect(.Right, bounds));
	}

	private void HideZoneIndicators()
	{
		mZoneIndicator.ClearTargets();
		mZoneIndicator.Visibility = .Gone;
	}

	/// The leaf under a point: a group or a standalone panel, descending through splits.
	private View FindHoveredDockNode(View node, float localX, float localY)
	{
		let split = node as DockSplit;
		if (split == null)
			return node;

		if (split.First != null)
		{
			if (GetNodeBounds(split.First).Contains(.(localX, localY)))
				return FindHoveredDockNode(split.First, localX, localY);
		}

		if (split.Second != null)
		{
			if (GetNodeBounds(split.Second).Contains(.(localX, localY)))
				return FindHoveredDockNode(split.Second, localX, localY);
		}

		// Between the two, which is the divider: the split itself is the answer.
		return node;
	}

	// ---- Persistence ----------------------------------------------------------------------------

	/// A snapshot of the current tree. OWNERSHIP transfers; null when nothing is docked.
	public DockLayoutNode ExportLayout() => (mRootNode != null) ? ExportNode(mRootNode) : null;

	private DockLayoutNode ExportNode(View node)
	{
		if (let split = node as DockSplit)
		{
			let layoutNode = new DockLayoutNode();
			layoutNode.Type = .Split;
			layoutNode.Direction = split.Orientation;
			layoutNode.SplitRatio = split.SplitRatio;

			if (split.First != null)
				layoutNode.First = ExportNode(split.First);
			if (split.Second != null)
				layoutNode.Second = ExportNode(split.Second);

			return layoutNode;
		}

		if (let tabGroup = node as DockTabGroup)
		{
			let layoutNode = new DockLayoutNode();
			layoutNode.Type = .TabGroup;
			layoutNode.ActiveTabIndex = tabGroup.SelectedIndex;

			for (int32 i = 0; i < tabGroup.PanelCount; i++)
			{
				let panel = tabGroup.GetPanel(i);
				// A panel with no persistence id CANNOT be restored, so recording it would
				// produce a layout that silently loses a tab on load.
				if (!panel.PersistenceId.IsEmpty)
					layoutNode.PanelIds.Add(new String(panel.PersistenceId));
			}

			return layoutNode;
		}

		if (let panel = node as DockablePanel)
		{
			// A standalone panel is written as a one tab group, so loading always produces the
			// same shape whatever it was saved from.
			let layoutNode = new DockLayoutNode();
			layoutNode.Type = .TabGroup;
			layoutNode.ActiveTabIndex = 0;
			if (!panel.PersistenceId.IsEmpty)
				layoutNode.PanelIds.Add(new String(panel.PersistenceId));

			return layoutNode;
		}

		return null;
	}

	/// Rebuilds the tree from a snapshot, matching panels by their persistence id. BORROWS the
	/// layout.
	///
	/// Panels the layout does not mention are FLOATED rather than dropped, cascading so several
	/// do not land on top of each other. A panel the user has open is never silently discarded
	/// because a saved layout predates it.
	public void ApplyLayout(DockLayoutNode layout)
	{
		if (layout == null)
			return;

		let panelMap = scope Dictionary<String, DockablePanel>();
		for (let panel in mPanels)
		{
			if (!panel.PersistenceId.IsEmpty)
				panelMap[scope:: String(panel.PersistenceId)] = panel;
		}

		DetachAllPanels();

		if (mRootNode != null)
		{
			ClearTreeStructure(mRootNode);
			mRootNode = null;
		}

		let newRoot = BuildNode(layout, panelMap);
		mRootNode = newRoot;
		if (mRootNode != null)
			AddView(mRootNode);

		FloatUnplacedPanels();
		Invalidate();
	}

	/// Takes every panel out of the tree WITHOUT destroying any: they are about to be placed
	/// again, or floated.
	private void DetachAllPanels()
	{
		for (let panel in mPanels)
		{
			if (panel.Parent == null)
				continue;

			if (let tabGroup = panel.Parent as DockTabGroup)
			{
				let removed = tabGroup.RemovePanel(panel);
				if (removed != null)
					removed.ReleaseRef();
			}
			else if (panel.Parent == this)
			{
				RemoveView(panel);
			}
		}
	}

	private void FloatUnplacedPanels()
	{
		var x = 100.0f;
		var y = 100.0f;

		for (let panel in mPanels)
		{
			if (panel.Parent != null)
				continue;

			FloatPanel(panel, x, y);
			x += 30.0f;
			y += 30.0f;
		}
	}

	/// OWNERSHIP of the result transfers.
	private View BuildNode(DockLayoutNode layoutNode, Dictionary<String, DockablePanel> panelMap)
	{
		if (layoutNode.Type == .Split)
			return BuildSplit(layoutNode, panelMap);

		return BuildTabGroup(layoutNode, panelMap);
	}

	/// A split with only one surviving child COLLAPSES to that child, which is what keeps a
	/// layout usable when some of the panels it names no longer exist.
	private View BuildSplit(DockLayoutNode layoutNode, Dictionary<String, DockablePanel> panelMap)
	{
		let split = new DockSplit(layoutNode.Direction);
		split.SplitRatio = layoutNode.SplitRatio;

		let first = (layoutNode.First != null) ? BuildNode(layoutNode.First, panelMap) : null;
		let second = (layoutNode.Second != null) ? BuildNode(layoutNode.Second, panelMap) : null;

		if ((first != null) && (second != null))
		{
			split.SetChildren(first, second);
			return split;
		}

		split.ReleaseRef();
		return (first != null) ? first : second;
	}

	private View BuildTabGroup(DockLayoutNode layoutNode, Dictionary<String, DockablePanel> panelMap)
	{
		let tabGroup = new DockTabGroup();

		for (let id in layoutNode.PanelIds)
		{
			if (panelMap.TryGetValue(id, let panel))
				AdoptIntoGroup(tabGroup, panel);
		}

		if (tabGroup.PanelCount == 0)
		{
			tabGroup.ReleaseRef();
			return null;
		}

		if ((layoutNode.ActiveTabIndex >= 0) && (layoutNode.ActiveTabIndex < tabGroup.PanelCount))
			tabGroup.SetSelectedIndex(layoutNode.ActiveTabIndex);

		return tabGroup;
	}
}
