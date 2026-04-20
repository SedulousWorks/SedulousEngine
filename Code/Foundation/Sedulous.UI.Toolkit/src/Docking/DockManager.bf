namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Multi-window docking system. Manages a tree of DockSplits, DockTabGroups,
/// and DockablePanels with support for dragging, floating, and zone-based docking.
/// Faithfully ported from legacy Sedulous.UI.Toolkit.
public class DockManager : ViewGroup, IDropTarget, IPopupOwner, IDockHost
{
	private View mRootNode;
	private List<DockablePanel> mPanels = new .() ~ delete _; // Non-owning tracking
	private List<FloatingWindow> mFloatingWindows = new .() ~ delete _; // Non-owning tracking
	private DockZoneIndicator mZoneIndicator ~ delete _;
	private bool mIsCleaningUp;

	/// Optional host for OS-level floating windows.
	/// When set and SupportsOSWindows is true, floating panels use real OS windows.
	/// When null or unsupported, falls back to PopupLayer virtual floating.
	public IFloatingWindowHost FloatingWindowHost;

	public View RootNode => mRootNode;

	public this()
	{
		mZoneIndicator = new DockZoneIndicator();
		mZoneIndicator.Visibility = .Gone;
	}

	public ~this()
	{
		// Don't call CloseAllFloatingWindows() here — during destruction,
		// UIContext services are already gone and DetachSubtree -> UnregisterElement
		// would access freed memory. Floating windows live in PopupLayer and are
		// cleaned up by UIContext's tree destruction; panels inside them are owned
		// by FloatingWindow (via AddView) and deleted by its ViewGroup destructor.
	}

	// === IDockHost ===

	UIContext IDockHost.Context => Context;

	void IDockHost.FloatPanel(DockablePanel panel, float x, float y)
	{
		FloatPanel(panel, x, y);
	}

	void IDockHost.DestroyFloatingWindow(FloatingWindow fw)
	{
		DestroyFloatingWindow(fw);
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

		// Re-resolve relativeTo — it may have been collapsed by cleanup.
		var target = relativeTo;
		if (relativeToId.IsValid && Context != null)
		{
			let resolved = Context.GetElementById(relativeToId);
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
				// Target is a DockSplit or null — find first tab group in subtree.
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
					// Empty tree — create new root.
					let group = new DockTabGroup();
					group.AddPanel(panel);
					mRootNode = group;
					AddView(group);
				}
			}
			InvalidateLayout();
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
		InvalidateLayout();
	}

	/// Float a panel at the given position.
	/// Uses OS windows if FloatingWindowHost supports it, otherwise PopupLayer.
	public void FloatPanel(DockablePanel panel, float x, float y)
	{
		RemoveFromTree(panel);

		let floating = new FloatingWindow(panel);
		mFloatingWindows.Add(floating);

		floating.OnDockRequested.Add(new (fw) => { RedockFloatingWindow(fw); });
		floating.OnCloseRequested.Add(new (fw) => { CloseFloatingWindow(fw); });

		bool useOSWindow = (FloatingWindowHost != null && FloatingWindowHost.SupportsOSWindows);

		if (useOSWindow)
		{
			floating.IsOSWindow = true;
			FloatingWindowHost.CreateFloatingWindow(floating, 300, 250, x, y,
				new (view) => {
					if (let fw = view as FloatingWindow)
						CloseFloatingWindow(fw);
				});
		}
		else if (Context != null)
		{
			// Virtual mode via PopupLayer.
			Root?.PopupLayer?.ShowPopup(floating, this, x, y, false, false, true);
		}

		CleanupEmptyNodes();
		InvalidateLayout();
	}

	/// Close a panel (undock and delete).
	public void ClosePanel(DockablePanel panel)
	{
		UndockPanel(panel);
		mPanels.Remove(panel);
		QueueDeleteNode(panel);
	}

	/// Re-dock a floating window back into the dock tree.
	public void RedockFloatingWindow(FloatingWindow floating)
	{
		let panel = floating.DetachPanel();
		if (panel == null) return;

		DestroyFloatingWindow(floating);

		// Try to dock at last known position.
		View relativeTo = null;
		if (panel.mLastRelativeToId.IsValid && Context != null)
			relativeTo = Context.GetElementById(panel.mLastRelativeToId);

		if (relativeTo != null)
			DockPanelRelativeTo(panel, panel.mLastDockPosition, relativeTo);
		else
			DockPanel(panel, .Center);
	}

	/// Close a floating window.
	public void CloseFloatingWindow(FloatingWindow floating)
	{
		let panel = floating.DetachPanel();
		DestroyFloatingWindow(floating);

		if (panel != null)
		{
			mPanels.Remove(panel);
			QueueDeleteNode(panel);
		}
	}

	/// Destroy a floating window (OS or virtual).
	public void DestroyFloatingWindow(FloatingWindow floating)
	{
		mFloatingWindows.Remove(floating);

		if (floating.IsOSWindow && FloatingWindowHost != null)
		{
			FloatingWindowHost.DestroyFloatingWindow(floating);
			QueueDeleteNode(floating);
		}
		else
		{
			// ClosePopup handles deletion (ownsView=true).
			Root?.PopupLayer?.ClosePopup(floating);
		}
	}

	private void CloseAllFloatingWindows()
	{
		for (int i = mFloatingWindows.Count - 1; i >= 0; i--)
		{
			let floating = mFloatingWindows[i];
			let panel = floating.DetachPanel();
			Root?.PopupLayer?.ClosePopup(floating);
			mFloatingWindows.RemoveAt(i);

			if (panel != null)
			{
				mPanels.Remove(panel);
				delete panel;
			}
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
				DetachView(mRootNode);

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
				DetachView(target);
				if (panelFirst)
					split.SetChildren(group, target);
				else
					split.SetChildren(target, group);
				mRootNode = split;
				AddView(split);
			}
			else if (let parentSplit = parent as DockSplit)
			{
				// Capture both children BEFORE detaching — DockSplit.First/Second
				// are index-based, so detaching shifts the array.
				bool isFirst = (parentSplit.First === target);
				let otherChild = isFirst ? parentSplit.Second : parentSplit.First;

				parentSplit.DetachView(target);
				if (otherChild != null) parentSplit.DetachView(otherChild);

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

		InvalidateLayout();
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
			DetachView(panel);
			mRootNode = null;
			return;
		}

		// In a floating window.
		for (int i = 0; i < mFloatingWindows.Count; i++)
		{
			if (mFloatingWindows[i].Panel === panel)
			{
				let floating = mFloatingWindows[i];
				floating.DetachPanel();
				DestroyFloatingWindow(floating);
				return;
			}
		}
	}

	private void ReplaceNode(View oldNode, View newNode)
	{
		if (oldNode === mRootNode)
		{
			DetachView(oldNode);
			mRootNode = newNode;
			AddView(newNode);
		}
		else if (let parentSplit = oldNode.Parent as DockSplit)
		{
			// Capture other child and detach both BEFORE SetChildren.
			bool isFirst = (parentSplit.First === oldNode);
			let other = isFirst ? parentSplit.Second : parentSplit.First;

			parentSplit.DetachView(oldNode);
			if (other != null) parentSplit.DetachView(other);

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

			if (second != null) split.DetachView(second);
			if (first != null) split.DetachView(first);

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
					DetachView(split);
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
					DetachView(split);
					QueueDeleteNode(split);
					AddView(cleanSecond);
				}
				return cleanSecond;
			}
			else
			{
				if (split === mRootNode)
				{
					DetachView(split);
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
					DetachView(tabGroup);
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

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let w = wSpec.Resolve(0);
		let h = hSpec.Resolve(0);

		if (mRootNode != null)
			mRootNode.Measure(.Exactly(w), .Exactly(h));

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (mRootNode != null)
			mRootNode.Layout(0, 0, right - left, bottom - top);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		if (!ctx.TryDrawDrawable("DockManager.Background", bounds, .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("DockManager.Background") ?? ctx.Theme?.Palette.Background ?? .(30, 30, 35, 255);
			ctx.VG.FillRect(bounds, bgColor);
		}

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
		// Move virtual floating window to follow cursor (PopupLayer mode).
		// OS floating windows are moved by the application in OnInput using global coords.
		if (let panelData = data as DockPanelDragData)
		{
			if (panelData.SourceWindow != null && !panelData.SourceWindow.IsOSWindow)
			{
				if (Root?.PopupLayer != null)
				{
					let screenX = Context.DragDropManager.LastScreenX;
					let screenY = Context.DragDropManager.LastScreenY;
					let dpi = Context.DpiScale;
					Root.PopupLayer.UpdatePopupPosition(
						panelData.SourceWindow,
						(screenX - panelData.DragOffsetX) / dpi,
						(screenY - panelData.DragOffsetY) / dpi);
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
				// Dropped inside DockManager but not on a zone — float.
				if (panelData.SourceWindow != null)
				{
					// Already floating — just restore and keep at current position.
					panelData.SourceWindow.Alpha = 1.0f;
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
		for (int i = mFloatingWindows.Count - 1; i >= 0; i--)
		{
			if (mFloatingWindows[i] === popup)
			{
				mFloatingWindows.RemoveAt(i);
				break;
			}
		}
	}

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
