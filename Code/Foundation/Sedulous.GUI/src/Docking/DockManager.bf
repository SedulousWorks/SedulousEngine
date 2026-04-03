using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Manages a docking layout with panels that can be docked, tabbed, or floated.
/// Contains a tree of DockSplit and DockTabGroup nodes.
public class DockManager : Control, IDropTarget
{
	// Root of the layout tree (DockTabGroup or DockSplit)
	private Control mRootNode ~ delete _;

	// Floating panels (popup windows)
	private List<FloatingWindow> mFloatingWindows = new .() ~ DeleteContainerAndItems!(_);

	// Currently dragged panel (for drag-dock operations)
	private DockablePanel mDraggedPanel;
	private DockPosition mDropPosition;
	private Control mDropTarget;  // Where to dock

	// Drag-drop visual indicators
	private DockZoneIndicator mZoneIndicator ~ delete _;
	private DockTarget mDropTargetIndicator ~ delete _;
	private bool mShowingIndicators = false;

	// Drag event handlers for proactive zone indicator display
	private delegate void(DragEventArgs) mDragStartedHandler /*~ delete _*/;
	private delegate void(DragEventArgs) mDragCompletedHandler /*~ delete _*/;

	// Events
	private EventAccessor<delegate void(DockManager, DockablePanel)> mPanelDocked = new .() ~ delete _;
	private EventAccessor<delegate void(DockManager, DockablePanel)> mPanelClosed = new .() ~ delete _;

	/// Creates a new DockManager.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;

		// Don't create an initial empty group - it causes layout shifts when cleaned up.
		// The first DockPanel call will create the root group.
		mRootNode = null;

		// Create visual indicators for drag-drop
		mZoneIndicator = new DockZoneIndicator();
		mDropTargetIndicator = new DockTarget();
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "DockManager";

	/// The root layout node.
	public Control RootNode => mRootNode;

	/// Event fired when a panel is docked.
	public EventAccessor<delegate void(DockManager, DockablePanel)> PanelDocked => mPanelDocked;

	/// Event fired when a panel is closed.
	public EventAccessor<delegate void(DockManager, DockablePanel)> PanelClosed => mPanelClosed;

	// === Panel Management ===

	/// Adds a panel to the center (as a tab in the root group).
	public void AddPanel(DockablePanel panel)
	{
		DockPanel(panel, .Center);
	}

	/// Docks a panel at the specified position relative to the root.
	public void DockPanel(DockablePanel panel, DockPosition position)
	{
		DockPanelRelativeTo(panel, mRootNode, position);
	}

	/// Docks a panel relative to a target node.
	public void DockPanelRelativeTo(DockablePanel panel, Control target, DockPosition position)
	{
		if (panel == null)
			return;

		switch (position)
		{
		case .Center:
			DockToCenter(panel, target);

		case .Left:
			DockToEdge(panel, target, .Horizontal, true);

		case .Right:
			DockToEdge(panel, target, .Horizontal, false);

		case .Top:
			DockToEdge(panel, target, .Vertical, true);

		case .Bottom:
			DockToEdge(panel, target, .Vertical, false);

		case .Float:
			FloatPanel(panel);
		}

		if (Context != null)
			panel.OnAttachedToContext(Context);

		mPanelDocked.[Friend]Invoke(this, panel);
		InvalidateLayout();
	}

	/// Docks a panel to the center (as a tab).
	private void DockToCenter(DockablePanel panel, Control target)
	{
		// Find the tab group to add to
		DockTabGroup targetGroup = null;

		if (let group = target as DockTabGroup)
		{
			targetGroup = group;
		}
		else if (let split = target as DockSplit)
		{
			// Find first tab group in the split
			targetGroup = FindFirstTabGroup(split);
		}

		if (targetGroup == null)
		{
			// Create a new group as root
			targetGroup = new DockTabGroup();
			targetGroup.Manager = this;
			ReplaceRoot(targetGroup);
		}

		targetGroup.AddPanel(panel);
	}

	/// Docks a panel to an edge, creating a split.
	private void DockToEdge(DockablePanel panel, Control target, Orientation orientation, bool first)
	{
		// Create a new tab group for the panel
		let newGroup = new DockTabGroup();
		newGroup.Manager = this;
		newGroup.AddPanel(panel);

		// If no target (empty dock manager), just use the new group as root
		if (target == null)
		{
			ReplaceRoot(newGroup);
			return;
		}

		// Create a split
		let split = new DockSplit(orientation);
		split.Manager = this;

		if (first)
		{
			split.First = newGroup;
			split.Second = target;
			split.SplitRatio = 0.25f;  // New panel takes 25%
		}
		else
		{
			split.First = target;
			split.Second = newGroup;
			split.SplitRatio = 0.75f;  // New panel takes 25%
		}

		// Update parent references
		if (let oldGroup = target as DockTabGroup)
			oldGroup.Manager = this;
		else if (let oldSplit = target as DockSplit)
		{
			oldSplit.Manager = this;
			oldSplit.ParentSplit = split;
		}

		// Replace target with split in parent
		if (target == mRootNode)
		{
			ReplaceRoot(split);
		}
		else
		{
			// Find parent split and replace
			ReplaceInParent(target, split);
		}
	}

	/// Docks a panel relative to a specific tab group, creating a split around that group.
	/// This allows docking to an edge of a specific panel rather than the whole layout.
	public void DockPanelRelativeToGroup(DockablePanel panel, DockTabGroup targetGroup, DockPosition position)
	{
		if (panel == null || targetGroup == null)
			return;

		// Center means add as tab to the group
		if (position == .Center)
		{
			targetGroup.AddPanel(panel);
			if (Context != null)
				panel.OnAttachedToContext(Context);
			mPanelDocked.[Friend]Invoke(this, panel);
			InvalidateLayout();
			return;
		}

		// Float is not applicable here
		if (position == .Float)
		{
			FloatPanel(panel);
			return;
		}

		// Determine orientation and order based on position
		Orientation orientation;
		bool newPanelFirst;

		switch (position)
		{
		case .Left:
			orientation = .Horizontal;
			newPanelFirst = true;
		case .Right:
			orientation = .Horizontal;
			newPanelFirst = false;
		case .Top:
			orientation = .Vertical;
			newPanelFirst = true;
		case .Bottom:
			orientation = .Vertical;
			newPanelFirst = false;
		default:
			return;
		}

		// Create new tab group for the panel
		let newGroup = new DockTabGroup();
		newGroup.Manager = this;
		newGroup.AddPanel(panel);

		// Create a split containing both the target group and new group
		let split = new DockSplit(orientation);
		split.Manager = this;

		if (newPanelFirst)
		{
			split.First = newGroup;
			split.Second = targetGroup;
			split.SplitRatio = 0.25f;  // New panel takes 25%
		}
		else
		{
			split.First = targetGroup;
			split.Second = newGroup;
			split.SplitRatio = 0.75f;  // New panel takes 25%
		}

		// Ensure targetGroup's Manager is set (may be cleared during tree restructuring)
		targetGroup.Manager = this;

		// Replace targetGroup with split in its parent
		if (targetGroup == mRootNode)
		{
			// targetGroup was the root - replace with split
			mRootNode = split;
			split.SetParent(this);
			if (Context != null)
				split.OnAttachedToContext(Context);
		}
		else
		{
			// Find parent split and replace targetGroup with split
			ReplaceInParent(targetGroup, split);
		}

		if (Context != null)
			panel.OnAttachedToContext(Context);

		mPanelDocked.[Friend]Invoke(this, panel);
		InvalidateLayout();
	}

	/// Replaces the root node.
	private void ReplaceRoot(Control newRoot)
	{
		if (mRootNode != null)
		{
			mRootNode.SetParent(null);
			if (Context != null)
				mRootNode.OnDetachedFromContext();
		}

		// Don't delete old root - it's being reused in a split
		mRootNode = newRoot;

		if (mRootNode != null)
		{
			mRootNode.SetParent(this);
			if (Context != null)
				mRootNode.OnAttachedToContext(Context);
		}
	}

	/// Replaces a node in its parent split.
	private void ReplaceInParent(Control oldNode, Control newNode)
	{
		// Walk the tree to find parent
		ReplaceInSplit(mRootNode, oldNode, newNode);
	}

	private bool ReplaceInSplit(Control node, Control oldNode, Control newNode)
	{
		if (let split = node as DockSplit)
		{
			if (split.First == oldNode)
			{
				split.First = newNode;
				return true;
			}
			if (split.Second == oldNode)
			{
				split.Second = newNode;
				return true;
			}

			// Recurse
			if (ReplaceInSplit(split.First, oldNode, newNode))
				return true;
			if (ReplaceInSplit(split.Second, oldNode, newNode))
				return true;
		}
		return false;
	}

	/// Finds the first tab group in a node.
	private DockTabGroup FindFirstTabGroup(Control node)
	{
		if (let group = node as DockTabGroup)
			return group;

		if (let split = node as DockSplit)
		{
			let first = FindFirstTabGroup(split.First);
			if (first != null)
				return first;
			return FindFirstTabGroup(split.Second);
		}

		return null;
	}

	/// Floats a panel (shows as floating window).
	public void FloatPanel(DockablePanel panel)
	{
		FloatPanelAt(panel, .(100, 100), .(300, 200));
	}

	/// Floats a panel at the specified position and size.
	public void FloatPanelAt(DockablePanel panel, Vector2 position, Vector2 size)
	{
		// Remove from current group if docked
		if (panel.ParentGroup != null)
		{
			panel.ParentGroup.RemovePanel(panel);
			CleanupEmptyNodes();
		}

		// Create floating window
		let floatWindow = new FloatingWindow(this, panel);
		floatWindow.Position = position;
		floatWindow.Size = size;
		mFloatingWindows.Add(floatWindow);

		if (Context != null)
			floatWindow.OnAttachedToContext(Context);

		InvalidateLayout();
	}

	/// Re-docks a floating panel.
	public void RedockPanel(DockablePanel panel, DockPosition position)
	{
		// Find and remove from floating windows
		for (int i = 0; i < mFloatingWindows.Count; i++)
		{
			if (mFloatingWindows[i].Panel == panel)
			{
				let floatWindow = mFloatingWindows[i];
				mFloatingWindows.RemoveAt(i);
				floatWindow.Panel = null;  // Prevent panel deletion
				delete floatWindow;
				break;
			}
		}

		// Dock the panel
		DockPanel(panel, position);
	}

	/// Gets the number of floating windows.
	public int FloatingWindowCount => mFloatingWindows.Count;

	/// Gets a floating window by index.
	public FloatingWindow GetFloatingWindow(int index)
	{
		if (index >= 0 && index < mFloatingWindows.Count)
			return mFloatingWindows[index];
		return null;
	}

	/// Removes a panel from the dock layout.
	public void RemovePanel(DockablePanel panel)
	{
		if (panel.ParentGroup != null)
		{
			panel.ParentGroup.RemovePanel(panel);
			CleanupEmptyNodes();
		}
		else
		{
			// Check floating windows
			RemovePanelFromFloatingWindow(panel);
		}
	}

	/// Removes a panel from its floating window (if any) without deleting the panel.
	/// Returns true if the panel was found and removed from a floating window.
	public bool RemovePanelFromFloatingWindow(DockablePanel panel)
	{
		for (int i = 0; i < mFloatingWindows.Count; i++)
		{
			if (mFloatingWindows[i].Panel == panel)
			{
				let floatWindow = mFloatingWindows[i];
				floatWindow.Panel = null;  // Detach panel without deleting it
				mFloatingWindows.RemoveAt(i);
				delete floatWindow;
				return true;
			}
		}
		return false;
	}

	/// Removes a floating window from the list and schedules it for deletion.
	/// Safe to call from within the window's event handlers.
	public void RemoveFloatingWindow(FloatingWindow window)
	{
		for (int i = 0; i < mFloatingWindows.Count; i++)
		{
			if (mFloatingWindows[i] == window)
			{
				mFloatingWindows.RemoveAt(i);

				// Use context's deferred deletion so ElementHandles properly see it as deleted
				if (Context != null)
					Context.MutationQueue.QueueDelete(window);
				else
					delete window;  // Fallback if no context

				return;
			}
		}
	}

	// === Floating Window Drag Support ===

	/// Finds the DockTabGroup under a point and updates its drag feedback.
	/// Returns the group and drop zone if found, null otherwise.
	public (DockTabGroup group, DockPosition zone)? UpdateFloatingDragTarget(Vector2 point)
	{
		// Clear feedback from all groups first
		ClearAllFloatingDragFeedback(mRootNode);

		// Find and update the group under the cursor
		let group = FindTabGroupAt(mRootNode, point);
		if (group != null)
		{
			let zone = group.UpdateFloatingDragFeedback(point);
			if (zone != null)
				return (group, zone.Value);
		}
		return null;
	}

	/// Clears floating drag feedback from all DockTabGroups.
	public void ClearAllFloatingDragFeedback()
	{
		ClearAllFloatingDragFeedback(mRootNode);
	}

	private void ClearAllFloatingDragFeedback(Control node)
	{
		if (node == null)
			return;

		if (let group = node as DockTabGroup)
		{
			group.ClearFloatingDragFeedback();
		}
		else if (let split = node as DockSplit)
		{
			ClearAllFloatingDragFeedback(split.First);
			ClearAllFloatingDragFeedback(split.Second);
		}
	}

	private DockTabGroup FindTabGroupAt(Control node, Vector2 point)
	{
		if (node == null)
			return null;

		if (let group = node as DockTabGroup)
		{
			if (group.ArrangedBounds.Contains(point.X, point.Y))
				return group;
		}
		else if (let split = node as DockSplit)
		{
			// Check both children
			let first = FindTabGroupAt(split.First, point);
			if (first != null)
				return first;
			let second = FindTabGroupAt(split.Second, point);
			if (second != null)
				return second;
		}
		return null;
	}

	/// Cleans up empty tab groups and collapses unnecessary splits.
	/// Called after panels are moved between groups.
	public void CleanupEmptyNodes()
	{
		// Collect nodes to delete after tree restructuring completes.
		// This avoids use-after-free: SetChild tries to detach old children,
		// so they must remain valid until after the assignment.
		List<Control> toDelete = scope .();

		let oldRoot = mRootNode;
		let newRoot = CleanupNode(mRootNode, toDelete);

		// If the root changed, the new root was detached during cleanup
		// (when the parent split set its child to null). Re-attach it.
		if (newRoot != oldRoot)
		{
			if (oldRoot != null)
				oldRoot.SetParent(null);
			if (newRoot != null)
			{
				newRoot.SetParent(this);
				if (Context != null)
					newRoot.OnAttachedToContext(Context);
			}
		}

		mRootNode = newRoot;

		// Restore Manager references on surviving nodes (may have been cleared during restructuring)
		RestoreManagerReferences(mRootNode);

		// Now safe to delete - all SetChild calls have completed
		for (let node in toDelete)
			delete node;

		InvalidateLayout();
	}

	/// Recursively restores Manager references on all nodes in the tree.
	private void RestoreManagerReferences(Control node)
	{
		if (node == null)
			return;

		if (let group = node as DockTabGroup)
		{
			group.Manager = this;
		}
		else if (let split = node as DockSplit)
		{
			split.Manager = this;
			RestoreManagerReferences(split.First);
			RestoreManagerReferences(split.Second);
		}
	}

	private Control CleanupNode(Control node, List<Control> toDelete)
	{
		if (let group = node as DockTabGroup)
		{
			// Keep empty groups at root, otherwise remove
			if (group.PanelCount == 0 && node != mRootNode)
			{
				toDelete.Add(group);
				return null;
			}
			return group;
		}

		if (let split = node as DockSplit)
		{
			split.First = CleanupNode(split.First, toDelete);
			split.Second = CleanupNode(split.Second, toDelete);

			// If one child is null, collapse to the other
			if (split.First == null && split.Second == null)
			{
				toDelete.Add(split);
				return null;
			}
			if (split.First == null)
			{
				let second = split.Second;
				split.Second = null;  // Prevent destructor from deleting
				toDelete.Add(split);
				return second;
			}
			if (split.Second == null)
			{
				let first = split.First;
				split.First = null;  // Prevent destructor from deleting
				toDelete.Add(split);
				return first;
			}

			return split;
		}

		return node;
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		if (mRootNode != null)
			mRootNode.OnAttachedToContext(context);

		// Subscribe to drag events to show zone indicators proactively
		if (context.DragDropManager != null)
		{
			mDragStartedHandler = new => OnGlobalDragStarted;
			mDragCompletedHandler = new => OnGlobalDragCompleted;
			context.DragDropManager.DragStarted.Subscribe(mDragStartedHandler);
			context.DragDropManager.DragCompleted.Subscribe(mDragCompletedHandler);
		}
	}

	public override void OnDetachedFromContext()
	{
		// Unsubscribe from drag events
		if (Context?.DragDropManager != null)
		{
			if (mDragStartedHandler != null)
				Context.DragDropManager.DragStarted.Unsubscribe(mDragStartedHandler, true);
			if (mDragCompletedHandler != null)
				Context.DragDropManager.DragCompleted.Unsubscribe(mDragCompletedHandler, true);
		}

		if (mRootNode != null)
			mRootNode.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	/// Called when any drag operation starts in the context.
	private void OnGlobalDragStarted(DragEventArgs args)
	{
		// Only show indicators for dock panel drags
		if (args.Data?.Format != DockPanelDragDataFormat.DockPanel)
			return;

		mShowingIndicators = true;

		// Show zone indicator at center of manager
		let center = Vector2(
			ArrangedBounds.X + ArrangedBounds.Width / 2,
			ArrangedBounds.Y + ArrangedBounds.Height / 2
		);
		mZoneIndicator.Show(center);
	}

	/// Called when any drag operation completes in the context.
	private void OnGlobalDragCompleted(DragEventArgs args)
	{
		mShowingIndicators = false;
		mZoneIndicator.Hide();
		mDropTargetIndicator.Hide();

		// If drop wasn't handled and it's a dock panel, check if we should float it
		if (!args.Handled && args.Data?.Format == DockPanelDragDataFormat.DockPanel)
		{
			let panelData = args.Data as DockPanelDragData;
			if (panelData != null && panelData.Panel != null)
			{
				// Drop outside any valid target - float the panel
				let panel = panelData.Panel;
				let dropPos = args.Position;

				// Remove from source group
				if (panelData.SourceGroup != null)
				{
					panelData.SourceGroup.RemovePanel(panel);
					CleanupEmptyNodes();
				}

				// Float at drop position with reasonable default size
				FloatPanelAt(panel, dropPos, .(300, 200));
			}
		}
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mRootNode != null)
		{
			mRootNode.Measure(constraints);
			return mRootNode.DesiredSize;
		}
		return .(0, 0);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (mRootNode != null)
		{
			mRootNode.Arrange(contentBounds);
		}

		// Arrange floating windows (they position themselves but need Arrange called for layout)
		for (let floatWindow in mFloatingWindows)
		{
			floatWindow.Arrange(floatWindow.WindowBounds);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Background
		let bgColor = Background.A > 0 ? Background : Color(30, 30, 30, 255);
		ctx.FillRect(ArrangedBounds, bgColor);

		// Render layout tree
		if (mRootNode != null)
		{
			mRootNode.Render(ctx);
		}

		// Render floating windows
		for (let floatWindow in mFloatingWindows)
		{
			floatWindow.Render(ctx);
		}

		// Render drag-drop indicators on top
		if (mShowingIndicators)
		{
			mDropTargetIndicator.Render(ctx);
			mZoneIndicator.Render(ctx);
		}
	}

	// === IDropTarget Implementation ===

	/// Returns whether this manager can accept the given drag data.
	public bool CanAcceptDrop(DragData data)
	{
		return data != null && data.Format == DockPanelDragDataFormat.DockPanel;
	}

	/// Called when a drag enters this manager.
	public void OnDragEnter(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		// Zone indicator is managed by global drag events (OnGlobalDragStarted/Completed).
		// Just accept the drop effect here.
		args.Effect = .Move;
	}

	/// Called while dragging over this manager.
	public void OnDragOver(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		let pos = args.Position;

		// Update zone indicator hover state
		let hoveredZone = mZoneIndicator.UpdateHover(pos);

		if (hoveredZone != null)
		{
			args.Effect = .Move;

			// Calculate target bounds based on zone
			let targetBounds = CalculateDropBounds(hoveredZone.Value);
			mDropTargetIndicator.Show(targetBounds, hoveredZone.Value);
			mDropPosition = hoveredZone.Value;
		}
		else
		{
			mDropTargetIndicator.Hide();
			args.Effect = .None;
		}
	}

	/// Called when a drag leaves this manager.
	public void OnDragLeave(DragEventArgs args)
	{
		// Don't hide zone indicators here - they're managed by global drag events.
		// Only hide the drop target preview since we're no longer hovering a zone.
		mDropTargetIndicator.Hide();
	}

	/// Called when a drop occurs on this manager.
	public void OnDrop(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		let panelData = args.Data as DockPanelDragData;
		if (panelData == null || panelData.Panel == null)
			return;

		let panel = panelData.Panel;

		// Remove from source (either tab group or floating window)
		if (panelData.SourceGroup != null)
		{
			panelData.SourceGroup.RemovePanel(panel);
			CleanupEmptyNodes();
		}
		else
		{
			// May be from a floating window
			RemovePanelFromFloatingWindow(panel);
		}

		// Dock at the target position
		DockPanel(panel, mDropPosition);

		// Clean up indicators
		mShowingIndicators = false;
		mZoneIndicator.Hide();
		mDropTargetIndicator.Hide();

		args.Handled = true;
	}

	/// Calculates the drop bounds for a dock position.
	private RectangleF CalculateDropBounds(DockPosition position)
	{
		let bounds = ArrangedBounds;
		let quarterWidth = bounds.Width * 0.25f;
		let quarterHeight = bounds.Height * 0.25f;

		switch (position)
		{
		case .Left:
			return .(bounds.X, bounds.Y, quarterWidth, bounds.Height);
		case .Right:
			return .(bounds.Right - quarterWidth, bounds.Y, quarterWidth, bounds.Height);
		case .Top:
			return .(bounds.X, bounds.Y, bounds.Width, quarterHeight);
		case .Bottom:
			return .(bounds.X, bounds.Bottom - quarterHeight, bounds.Width, quarterHeight);
		case .Center:
			return bounds;
		case .Float:
			return .(bounds.X + 50, bounds.Y + 50, 300, 200);
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		// Check floating windows first (they're rendered on top)
		// Note: check in reverse order so topmost windows are hit first
		for (int i = mFloatingWindows.Count - 1; i >= 0; i--)
		{
			let floatWindow = mFloatingWindows[i];
			let hit = floatWindow.HitTest(point);
			if (hit != null)
				return hit;
		}

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// When showing indicators, check zone indicator first.
		// This allows DockManager to intercept drops on zone buttons
		// even when cursor is technically over a child DockTabGroup.
		if (mShowingIndicators)
		{
			let zoneHit = mZoneIndicator.HitTest(point);
			if (zoneHit != null)
				return this;  // Return DockManager so we become drop target
		}

		// Check root node
		if (mRootNode != null)
		{
			let hit = mRootNode.HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// === Visual Children ===

	public override int VisualChildCount => mRootNode != null ? 1 : 0;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mRootNode != null)
			return mRootNode;
		return null;
	}
}
