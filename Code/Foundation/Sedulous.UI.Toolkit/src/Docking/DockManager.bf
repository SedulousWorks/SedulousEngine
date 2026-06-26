namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Multi-window docking system. Manages a tree of DockSplits, DockTabGroups,
/// and DockablePanels with support for dragging, floating, and zone-based docking.
public class DockManager : ViewGroup, IDropTarget, IPopupOwner, IDockHost
{
	private View mRootNode;
	private List<DockablePanel> mPanels = new .() ~ delete _; // Non-owning tracking
	private List<DockableWindow> mDockableWindows = new .() ~ delete _; // Non-owning tracking
	private DockZoneIndicator mZoneIndicator ~ delete _;
	private bool mIsCleaningUp;

	/// Optional host for OS-level dockable windows.
	/// When set and SupportsOSWindows is true, dockable panels use real OS windows.
	/// When null or unsupported, falls back to PopupLayer virtual floating.
	public IDockableWindowHost DockableWindowHost;

	/// Fired when a dock tab is selected (user click or programmatic).
	/// The panel is the newly selected panel.
	public Event<delegate void(DockablePanel)> OnPanelActivated ~ _.Dispose();

	public View RootNode => mRootNode;

	public this()
	{
		mZoneIndicator = new DockZoneIndicator();
		mZoneIndicator.Visibility = .Gone;
	}

	public ~this()
	{
		// Don't call CloseAllDockableWindows() here - during destruction,
		// UIContext services are already gone and DetachView -> UnregisterElement
		// would access freed memory. Dockable windows live in PopupLayer and are
		// cleaned up by UIContext's tree destruction; panels inside them are owned
		// by DockableWindow (via AddView) and deleted by its ViewGroup destructor.
	}

	// === IDockHost ===

	UIContext IDockHost.Context => Context;

	void IDockHost.FloatPanel(DockablePanel panel, float x, float y)
	{
		FloatPanel(panel, x, y);
	}

	void IDockHost.DestroyDockableWindow(DockableWindow dw)
	{
		DestroyDockableWindow(dw);
	}

	// === Public API ===

	/// Create and add a new dockable panel with content.
	public DockablePanel AddPanel(StringView title, View content)
	{
		let panel = new DockablePanel(title, content);
		panel.OnCloseRequested.Add(new (p) => { ClosePanel(p); });
		panel.DockHost = this;
		mPanels.Add(panel);
		return panel;
	}

	/// Dock a panel at the specified position relative to the root.
	public void DockPanel(DockablePanel panel, DockPosition position)
	{
		DockPanelRelativeTo(panel, position, mRootNode);
	}

	/// Dock a panel at the specified position relative to another node.
	public void DockPanelRelativeTo(DockablePanel panel, DockPosition position, View relativeTo)
	{
		// Remove panel from its current location first.
		RemoveFromTree(panel);

		// Save dock position for re-dock after floating.
		panel.SaveDockPosition(position, relativeTo);

		if (position == .Float)
		{
			FloatPanel(panel, 100, 100);
			return;
		}

		// Clean up empty nodes left behind.
		// Grab a safe reference via ViewId in case cleanup invalidates relativeTo.
		ViewId relativeToId = (relativeTo != null) ? relativeTo.Id : .Invalid;
		CleanupEmptyNodes();

		// Re-resolve relativeTo - it may have been collapsed by cleanup.
		var target = relativeTo;
		if (relativeToId.IsValid && Context != null)
		{
			let resolved = Context.GetViewById(relativeToId);
			if (resolved != null && !resolved.IsPendingDeletion)
				target = resolved;
			else
				target = mRootNode;
		}
		else if (target != null && target.IsPendingDeletion)
		{
			target = mRootNode;
		}

		if (position == .Center)
		{
			// Add as tab to existing group or create new group.
			if (let tabGroup = target as DockTabGroup)
			{
				tabGroup.AddPanel(panel);
			}
			else if (let existingPanel = target as DockablePanel)
			{
				// If the panel is already in a tab group, just add to it.
				if (let parentGroup = existingPanel.Parent as DockTabGroup)
				{
					parentGroup.AddPanel(panel);
				}
				else
				{
					// Wrap standalone panel in a new tab group.
					let group = new DockTabGroup();
					ReplaceNode(existingPanel, group);
					group.AddPanel(existingPanel);
					group.AddPanel(panel);
				}
			}
			else
			{
				// Target is a DockSplit or null - find first tab group in subtree.
				DockTabGroup targetGroup = null;
				if (target != null)
					targetGroup = FindFirstTabGroup(target);
				if (targetGroup == null && mRootNode != null)
					targetGroup = FindFirstTabGroup(mRootNode);

				if (targetGroup != null)
				{
					targetGroup.AddPanel(panel);
				}
				else
				{
					// Empty tree - create new root.
					let group = new DockTabGroup();
					group.AddPanel(panel);
					mRootNode = group;
					AddView(group);
				}
			}
			Invalidate();
			return;
		}

		// Create split.
		InsertSplit(target, panel, position);
	}

	/// Undock a panel from its current position.
	public void UndockPanel(DockablePanel panel)
	{
		RemoveFromTree(panel);
		CleanupEmptyNodes();
		Invalidate();
	}

	/// Float a panel at the given position.
	/// Uses OS windows if DockableWindowHost supports it, otherwise PopupLayer.
	public void FloatPanel(DockablePanel panel, float x, float y)
	{
		RemoveFromTree(panel);

		let dockable = new DockableWindow(panel);
		mDockableWindows.Add(dockable);

		dockable.OnDockRequested.Add(new (fw) => { RedockDockableWindow(fw); });
		dockable.OnCloseRequested.Add(new (fw) => { CloseDockableWindow(fw); });

		bool useOSWindow = (DockableWindowHost != null && DockableWindowHost.SupportsOSWindows);

		if (useOSWindow)
		{
			dockable.IsOSWindow = true;
			DockableWindowHost.CreateDockableWindow(dockable, 300, 250, x, y,
				new (view) => {
					if (let fw = view as DockableWindow)
						CloseDockableWindow(fw);
				});
		}
		else if (Context != null)
		{
			// Virtual mode via PopupLayer.
			Root?.PopupLayer?.ShowPopup(dockable, this, x, y, false, false, true);
		}

		CleanupEmptyNodes();
		Invalidate();
	}

	/// Close a panel (undock and delete).
	public void ClosePanel(DockablePanel panel)
	{
		UndockPanel(panel);
		mPanels.Remove(panel);
		QueueDeleteNode(panel);
	}

	/// Activates (selects) a panel's tab in its parent tab group.
	/// No-op if the panel is not in a tab group.
	public void ActivatePanel(DockablePanel panel)
	{
		if (let tabGroup = panel.Parent as DockTabGroup)
		{
			for (int32 i = 0; i < tabGroup.PanelCount; i++)
			{
				if (tabGroup.GetPanel(i) === panel)
				{
					tabGroup.SelectedIndex = i;
					return;
				}
			}
		}
	}

	/// Re-dock a dockable window back into the dock tree.
	public void RedockDockableWindow(DockableWindow dockable)
	{
		let panel = dockable.DetachPanel();
		if (panel == null) return;

		DestroyDockableWindow(dockable);

		// Try to dock at last known position.
		View relativeTo = null;
		if (panel.mLastRelativeToId.IsValid && Context != null)
			relativeTo = Context.GetViewById(panel.mLastRelativeToId);

		if (relativeTo != null)
			DockPanelRelativeTo(panel, panel.mLastDockPosition, relativeTo);
		else
			DockPanel(panel, .Center);
	}

	/// Close a dockable window.
	public void CloseDockableWindow(DockableWindow dockable)
	{
		let panel = dockable.DetachPanel();
		DestroyDockableWindow(dockable);

		if (panel != null)
		{
			mPanels.Remove(panel);
			QueueDeleteNode(panel);
		}
	}

	/// Destroy a dockable window (OS or virtual).
	public void DestroyDockableWindow(DockableWindow dockable)
	{
		mDockableWindows.Remove(dockable);

		if (dockable.IsOSWindow && DockableWindowHost != null)
		{
			DockableWindowHost.DestroyDockableWindow(dockable);
			QueueDeleteNode(dockable);
		}
		else
		{
			// ClosePopup handles deletion (ownsView=true).
			Root?.PopupLayer?.ClosePopup(dockable);
		}
	}

	private void CloseAllDockableWindows()
	{
		for (int i = mDockableWindows.Count - 1; i >= 0; i--)
		{
			let dockable = mDockableWindows[i];
			let panel = dockable.DetachPanel();
			Root?.PopupLayer?.ClosePopup(dockable);
			mDockableWindows.RemoveAt(i);

			if (panel != null)
			{
				mPanels.Remove(panel);
				delete panel;
			}
		}
	}

	// === Layout Persistence ===

	/// Exports the current dock tree as a serializable data structure.
	/// Returns null if the tree is empty.
	/// The caller owns the returned DockLayoutNode and is responsible for
	/// serializing it and deleting it.
	public DockLayoutNode ExportLayout()
	{
		if (mRootNode == null) return null;
		return ExportNode(mRootNode);
	}

	/// Rebuilds the dock tree from a previously exported layout.
	/// Panels are matched by PersistenceId. Panels not found in the layout
	/// remain undocked. Layout nodes referencing unknown panel IDs are skipped.
	/// Existing tree structure is cleared before applying.
	public void ApplyLayout(DockLayoutNode layout)
	{
		if (layout == null) return;

		// Collect all registered panels by PersistenceId.
		let panelMap = scope Dictionary<StringView, DockablePanel>();
		for (let panel in mPanels)
		{
			if (panel.PersistenceId.Length > 0)
				panelMap[panel.PersistenceId] = panel;
		}

		// Detach all panels from the current tree (don't delete them).
		for (let panel in mPanels)
		{
			if (panel.Parent != null)
			{
				if (let tabGroup = panel.Parent as DockTabGroup)
					tabGroup.RemovePanel(panel);
				else if (panel.Parent === this)
					RemoveView(panel);
			}
		}

		// Clear old tree structure.
		if (mRootNode != null)
		{
			ClearTreeStructure(mRootNode);
			mRootNode = null;
		}

		// Rebuild from layout.
		mRootNode = BuildNode(layout, panelMap);
		if (mRootNode != null)
			AddView(mRootNode);

		// Float any panels that weren't placed by the layout.
		// This prevents panels from being invisible and unreachable.
		float floatX = 100, floatY = 100;
		for (let panel in mPanels)
		{
			if (panel.Parent == null)
			{
				FloatPanel(panel, floatX, floatY);
				floatX += 30;
				floatY += 30;
			}
		}

		Invalidate();
	}

	/// Finds a registered panel by its PersistenceId.
	public DockablePanel FindPanelById(StringView persistenceId)
	{
		for (let panel in mPanels)
		{
			if (panel.PersistenceId == persistenceId)
				return panel;
		}
		return null;
	}

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
		else if (let tabGroup = node as DockTabGroup)
		{
			let layoutNode = new DockLayoutNode();
			layoutNode.Type = .TabGroup;
			layoutNode.ActiveTabIndex = tabGroup.SelectedIndex;

			for (int i = 0; i < tabGroup.PanelCount; i++)
			{
				let panel = tabGroup.GetPanel(i);
				if (panel.PersistenceId.Length > 0)
					layoutNode.PanelIds.Add(new String(panel.PersistenceId));
			}

			return layoutNode;
		}
		else if (let panel = node as DockablePanel)
		{
			// Standalone panel not in a tab group - wrap in a TabGroup node.
			let layoutNode = new DockLayoutNode();
			layoutNode.Type = .TabGroup;
			layoutNode.ActiveTabIndex = 0;
			if (panel.PersistenceId.Length > 0)
				layoutNode.PanelIds.Add(new String(panel.PersistenceId));
			return layoutNode;
		}

		return null;
	}

	private View BuildNode(DockLayoutNode layoutNode, Dictionary<StringView, DockablePanel> panelMap)
	{
		if (layoutNode.Type == .Split)
		{
			let split = new DockSplit(layoutNode.Direction);
			split.SplitRatio = layoutNode.SplitRatio;

			View first = (layoutNode.First != null) ? BuildNode(layoutNode.First, panelMap) : null;
			View second = (layoutNode.Second != null) ? BuildNode(layoutNode.Second, panelMap) : null;

			if (first != null && second != null)
			{
				split.SetChildren(first, second);
				return split;
			}
			else if (first != null)
			{
				delete split;
				return first;
			}
			else if (second != null)
			{
				delete split;
				return second;
			}
			else
			{
				delete split;
				return null;
			}
		}
		else // TabGroup
		{
			let tabGroup = new DockTabGroup();

			for (let id in layoutNode.PanelIds)
			{
				if (panelMap.TryGetValue(id, let panel))
					tabGroup.AddPanel(panel);
			}

			if (tabGroup.PanelCount == 0)
			{
				delete tabGroup;
				return null;
			}

			if (layoutNode.ActiveTabIndex >= 0 && layoutNode.ActiveTabIndex < tabGroup.PanelCount)
				tabGroup.SelectedIndex = layoutNode.ActiveTabIndex;

			return tabGroup;
		}
	}

	/// Deletes tree structure nodes (DockSplit, DockTabGroup) without deleting panels.
	private void ClearTreeStructure(View node)
	{
		if (let split = node as DockSplit)
		{
			let first = split.First;
			let second = split.Second;

			if (second != null) split.RemoveView(second);
			if (first != null) split.RemoveView(first);

			if (first != null) ClearTreeStructure(first);
			if (second != null) ClearTreeStructure(second);

			if (node.Parent === this)
				RemoveView(node);
			QueueDeleteNode(split);
		}
		else if (let tabGroup = node as DockTabGroup)
		{
			// Remove panels without deleting them.
			while (tabGroup.PanelCount > 0)
				tabGroup.RemovePanel(tabGroup.GetPanel(tabGroup.PanelCount - 1));

			if (node.Parent === this)
				RemoveView(node);
			QueueDeleteNode(tabGroup);
		}
	}

	// === Internal tree operations ===

	private void InsertSplit(View existingNode, DockablePanel panel, DockPosition position)
	{
		// If the target is a panel inside a DockTabGroup, split relative to the
		// tab group instead (the panel stays in its group).
		var target = existingNode;
		if (target != null && target.Parent is DockTabGroup)
			target = target.Parent;

		Orientation orientation = (position == .Left || position == .Right) ? .Horizontal : .Vertical;
		let split = new DockSplit(orientation);

		let group = new DockTabGroup();
		group.AddPanel(panel);

		if (target == null)
		{
			if (mRootNode != null)
			{
				// Detach root BEFORE SetChildren.
				RemoveView(mRootNode);

				bool panelFirst = (position == .Left || position == .Top);
				if (panelFirst)
					split.SetChildren(group, mRootNode);
				else
					split.SetChildren(mRootNode, group);
			}
			else
			{
				split.SetChildren(group, null);
			}
			mRootNode = split;
			AddView(split);
		}
		else
		{
			bool panelFirst = (position == .Left || position == .Top);

			let parent = target.Parent;
			if (parent === this)
			{
				RemoveView(target);
				if (panelFirst)
					split.SetChildren(group, target);
				else
					split.SetChildren(target, group);
				mRootNode = split;
				AddView(split);
			}
			else if (let parentSplit = parent as DockSplit)
			{
				// Capture both children BEFORE detaching - DockSplit.First/Second
				// are index-based, so detaching shifts the array.
				bool isFirst = (parentSplit.First === target);
				let otherChild = isFirst ? parentSplit.Second : parentSplit.First;

				parentSplit.RemoveView(target);
				if (otherChild != null) parentSplit.RemoveView(otherChild);

				if (panelFirst)
					split.SetChildren(group, target);
				else
					split.SetChildren(target, group);

				if (isFirst)
					parentSplit.SetChildren(split, otherChild);
				else
					parentSplit.SetChildren(otherChild, split);
			}
		}

		Invalidate();
	}

	private void RemoveFromTree(DockablePanel panel)
	{
		// Check if in a tab group.
		if (let tabGroup = panel.Parent as DockTabGroup)
		{
			tabGroup.RemovePanel(panel);
			return;
		}

		// Direct child of DockManager (root).
		if (panel.Parent === this && mRootNode === panel)
		{
			RemoveView(panel);
			mRootNode = null;
			return;
		}

		// In a dockable window.
		for (int i = 0; i < mDockableWindows.Count; i++)
		{
			if (mDockableWindows[i].Panel === panel)
			{
				let dockable = mDockableWindows[i];
				dockable.DetachPanel();
				DestroyDockableWindow(dockable);
				return;
			}
		}
	}

	private void ReplaceNode(View oldNode, View newNode)
	{
		if (oldNode === mRootNode)
		{
			RemoveView(oldNode);
			mRootNode = newNode;
			AddView(newNode);
		}
		else if (let parentSplit = oldNode.Parent as DockSplit)
		{
			// Capture other child and detach both BEFORE SetChildren.
			bool isFirst = (parentSplit.First === oldNode);
			let other = isFirst ? parentSplit.Second : parentSplit.First;

			parentSplit.RemoveView(oldNode);
			if (other != null) parentSplit.RemoveView(other);

			if (isFirst)
				parentSplit.SetChildren(newNode, other);
			else
				parentSplit.SetChildren(other, newNode);
		}
	}

	private void CleanupEmptyNodes()
	{
		if (mIsCleaningUp) return; // Prevent re-entrancy (OnElementDeleted -> FloatPanel -> CleanupEmptyNodes)
		mIsCleaningUp = true;
		if (mRootNode != null)
			mRootNode = CleanupNode(mRootNode);
		mIsCleaningUp = false;
	}

	private View CleanupNode(View node)
	{
		if (let split = node as DockSplit)
		{
			// Detach both children upfront to avoid index-shifting bugs.
			let first = split.First;
			let second = split.Second;

			if (second != null) split.RemoveView(second);
			if (first != null) split.RemoveView(first);

			// Recursively clean the detached children.
			let cleanFirst = (first != null) ? CleanupNode(first) : null;
			let cleanSecond = (second != null) ? CleanupNode(second) : null;

			// Queue originals for deletion if they were replaced.
			if (first != null && cleanFirst !== first) QueueDeleteNode(first);
			if (second != null && cleanSecond !== second) QueueDeleteNode(second);

			// Rebuild based on results.
			if (cleanFirst != null && cleanSecond != null)
			{
				split.AddView(cleanFirst);
				split.AddView(cleanSecond);
				return node;
			}
			else if (cleanFirst != null)
			{
				if (split === mRootNode)
				{
					RemoveView(split);
					QueueDeleteNode(split);
					AddView(cleanFirst);
				}
				// Non-root: caller handles deletion via QueueDeleteNode(first/second).
				return cleanFirst;
			}
			else if (cleanSecond != null)
			{
				if (split === mRootNode)
				{
					RemoveView(split);
					QueueDeleteNode(split);
					AddView(cleanSecond);
				}
				return cleanSecond;
			}
			else
			{
				if (split === mRootNode)
				{
					RemoveView(split);
					QueueDeleteNode(split);
				}
				return null;
			}
		}
		else if (let tabGroup = node as DockTabGroup)
		{
			if (tabGroup.PanelCount == 0)
			{
				if (tabGroup === mRootNode)
				{
					RemoveView(tabGroup);
					QueueDeleteNode(tabGroup);
				}
				return null;
			}
		}

		return node;
	}

	private void QueueDeleteNode(View node)
	{
		if (Context != null)
			Context.MutationQueue.QueueDelete(node);
		else
			delete node;
	}

	// === Layout / Drawing ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = constraints.ConstrainWidth(0);
		let h = constraints.ConstrainHeight(0);

		if (mRootNode != null)
			mRootNode.Measure(BoxConstraints.Tight(w, h));

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mRootNode != null)
			mRootNode.Layout(0, 0, width, height);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, Height));
		else
			ctx.VG.FillRect(.(0, 0, Width, Height), .(30, 30, 35, 255));

		DrawChildren(ctx);

		// Draw zone indicator overlay.
		if (mZoneIndicator.Visibility != .Gone)
		{
			ctx.VG.PushState();
			mZoneIndicator.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	// === IDropTarget ===

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		return (data.Format == "dock/panel") ? .Move : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		if (data.Format == "dock/panel")
			ShowZoneIndicators(localX, localY);
	}

	public void OnDragOver(DragData data, float localX, float localY)
	{
		// Move virtual dockable window to follow cursor (PopupLayer mode).
		// OS dockable windows are moved by the application in OnInput using global coords.
		if (let panelData = data as DockPanelDragData)
		{
			if (panelData.SourceWindow != null && !panelData.SourceWindow.IsOSWindow)
			{
				if (Root?.PopupLayer != null)
				{
					// UI2 InputManager already normalizes to logical coords - no DPI division needed.
					let screenX = Context.DragDropManager.LastScreenX;
					let screenY = Context.DragDropManager.LastScreenY;
					Root.PopupLayer.UpdatePopupPosition(
						panelData.SourceWindow,
						screenX - panelData.DragOffsetX,
						screenY - panelData.DragOffsetY);
				}
			}
		}

		if (mZoneIndicator.Visibility != .Gone)
		{
			ShowZoneIndicators(localX, localY);
			mZoneIndicator.UpdateHover(localX, localY);
		}
	}

	public void OnDragLeave(DragData data)
	{
		HideZoneIndicators();
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (let panelData = data as DockPanelDragData)
		{
			let target = mZoneIndicator.HoveredTarget;
			HideZoneIndicators();

			// Use screen-relative coords for floating (localX/Y are DockManager-local).
			let floatX = Context.DragDropManager.LastScreenX;
			let floatY = Context.DragDropManager.LastScreenY;

			if (target.HasValue)
			{
				let t = target.Value;
				if (t.Position == .Float)
					FloatPanel(panelData.Panel, floatX, floatY);
				else
					DockPanelRelativeTo(panelData.Panel, t.Position, t.RelativeTo);
				return .Move;
			}
			else
			{
				// Dropped inside DockManager but not on a zone - float.
				if (panelData.SourceWindow != null)
				{
					// Already floating - just restore and keep at current position.
					panelData.SourceWindow.Opacity = 1.0f;
					panelData.SourceWindow.IsInteractionEnabled = true;
				}
				else
				{
					FloatPanel(panelData.Panel, floatX, floatY);
				}
				return .Move;
			}
		}

		HideZoneIndicators();
		return .None;
	}

	// === IPopupOwner ===

	public void OnPopupClosed(View popup)
	{
		for (int i = mDockableWindows.Count - 1; i >= 0; i--)
		{
			if (mDockableWindows[i] === popup)
			{
				mDockableWindows.RemoveAt(i);
				break;
			}
		}
	}

	public View OwnerView => this;

	// === Zone indicators ===

	private void ShowZoneIndicators(float cursorX, float cursorY)
	{
		mZoneIndicator.ClearTargets();
		float zoneSize = 40;

		if (mRootNode == null)
		{
			let cx = Width * 0.5f;
			let cy = Height * 0.5f;
			mZoneIndicator.AddTarget(.Center, .(cx - zoneSize * 0.5f, cy - zoneSize * 0.5f, zoneSize, zoneSize), null);
		}
		else
		{
			let cx = Width * 0.5f;
			let cy = Height * 0.5f;

			// Root-level edge zones.
			mZoneIndicator.AddTarget(.Top, .(cx - zoneSize * 0.5f, 8, zoneSize, zoneSize), mRootNode);
			mZoneIndicator.AddTarget(.Bottom, .(cx - zoneSize * 0.5f, Height - zoneSize - 8, zoneSize, zoneSize), mRootNode);
			mZoneIndicator.AddTarget(.Left, .(8, cy - zoneSize * 0.5f, zoneSize, zoneSize), mRootNode);
			mZoneIndicator.AddTarget(.Right, .(Width - zoneSize - 8, cy - zoneSize * 0.5f, zoneSize, zoneSize), mRootNode);

			// Walk tree to find hovered leaf node and add its zones.
			let hoveredNode = FindHoveredDockNode(mRootNode, cursorX, cursorY);
			if (hoveredNode != null)
			{
				let bounds = GetNodeBounds(hoveredNode);
				if (bounds.Width > 0 && bounds.Height > 0)
				{
					let ncx = bounds.X + bounds.Width * 0.5f;
					let ncy = bounds.Y + bounds.Height * 0.5f;
					float smallZone = 32;

					mZoneIndicator.AddTarget(.Center, .(ncx - smallZone * 0.5f, ncy - smallZone * 0.5f, smallZone, smallZone), hoveredNode);

					let edgeOffset = smallZone + 4;
					mZoneIndicator.AddTarget(.Top, .(ncx - smallZone * 0.5f, ncy - edgeOffset - smallZone * 0.5f, smallZone, smallZone), hoveredNode);
					mZoneIndicator.AddTarget(.Bottom, .(ncx - smallZone * 0.5f, ncy + edgeOffset - smallZone * 0.5f, smallZone, smallZone), hoveredNode);
					mZoneIndicator.AddTarget(.Left, .(ncx - edgeOffset - smallZone * 0.5f, ncy - smallZone * 0.5f, smallZone, smallZone), hoveredNode);
					mZoneIndicator.AddTarget(.Right, .(ncx + edgeOffset - smallZone * 0.5f, ncy - smallZone * 0.5f, smallZone, smallZone), hoveredNode);
				}
			}
		}

		mZoneIndicator.Visibility = .Visible;
		mZoneIndicator.Layout(0, 0, Width, Height);
	}

	private void HideZoneIndicators()
	{
		mZoneIndicator.ClearTargets();
		mZoneIndicator.Visibility = .Gone;
	}

	/// Find the leaf DockTabGroup or DockablePanel that the cursor is over.
	private View FindHoveredDockNode(View node, float localX, float localY)
	{
		if (let split = node as DockSplit)
		{
			if (split.First != null)
			{
				let bounds = GetNodeBounds(split.First);
				if (localX >= bounds.X && localX < bounds.X + bounds.Width &&
					localY >= bounds.Y && localY < bounds.Y + bounds.Height)
					return FindHoveredDockNode(split.First, localX, localY);
			}
			if (split.Second != null)
			{
				let bounds = GetNodeBounds(split.Second);
				if (localX >= bounds.X && localX < bounds.X + bounds.Width &&
					localY >= bounds.Y && localY < bounds.Y + bounds.Height)
					return FindHoveredDockNode(split.Second, localX, localY);
			}
			return node;
		}
		return node;
	}

	/// Find the first DockTabGroup in a subtree (depth-first).
	private DockTabGroup FindFirstTabGroup(View node)
	{
		if (let tabGroup = node as DockTabGroup)
			return tabGroup;

		if (let split = node as DockSplit)
		{
			if (split.First != null)
			{
				let result = FindFirstTabGroup(split.First);
				if (result != null) return result;
			}
			if (split.Second != null)
				return FindFirstTabGroup(split.Second);
		}

		return null;
	}

	/// Get bounds of a dock tree node in DockManager local coordinates.
	private RectangleF GetNodeBounds(View node)
	{
		float x = 0, y = 0;
		var current = node;
		while (current != null && current !== this)
		{
			x += current.Bounds.X;
			y += current.Bounds.Y;
			current = current.Parent;
		}
		return .(x, y, node.Width, node.Height);
	}
}
