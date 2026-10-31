using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[DockManager]]: the tree surgery.
///
/// Every operation here PINS what it touches with an extra reference across the detach. A node
/// removed from its parent would otherwise be freed on the spot, and each of these takes a node
/// out before putting it somewhere else.
extension DockManager
{
	/// Splits a node in two, the new panel taking one half.
	private void InsertSplit(View existingNode, DockablePanel panel, DockPosition position)
	{
		// A panel inside a group splits relative to the GROUP, not to itself: splitting off one
		// tab would leave its siblings behind in a group that is no longer where it was.
		var target = existingNode;
		if ((target != null) && (target.Parent is DockTabGroup))
			target = target.Parent;

		let orientation = ((position == .Left) || (position == .Right))
			? Sedulous.UI.Orientation.Horizontal : Sedulous.UI.Orientation.Vertical;
		let split = new DockSplit(orientation);

		let group = new DockTabGroup();
		AdoptIntoGroup(group, panel);

		let panelFirst = (position == .Left) || (position == .Top);

		if (target == null)
			SplitAgainstRoot(split, group, panelFirst);
		else if (target.Parent == this)
			SplitTargetAtRoot(split, group, target, panelFirst);
		else if (let parentSplit = target.Parent as DockSplit)
			SplitInsideParent(split, group, target, parentSplit, panelFirst);

		Invalidate();
	}

	private void SplitAgainstRoot(DockSplit split, DockTabGroup group, bool panelFirst)
	{
		if (mRootNode != null)
		{
			let oldRoot = mRootNode;
			oldRoot.AddRef();
			RemoveView(oldRoot);
			split.SetChildren(panelFirst ? (View)group : oldRoot, panelFirst ? oldRoot : group);
		}
		else
		{
			split.SetChildren(group, null);
		}

		mRootNode = split;
		AddView(split);
	}

	private void SplitTargetAtRoot(DockSplit split, DockTabGroup group, View target,
		bool panelFirst)
	{
		target.AddRef();
		RemoveView(target);
		split.SetChildren(panelFirst ? (View)group : target, panelFirst ? target : group);
		mRootNode = split;
		AddView(split);
	}

	private void SplitInsideParent(DockSplit split, DockTabGroup group, View target,
		DockSplit parentSplit, bool panelFirst)
	{
		// BOTH children are captured before either is detached, because a split addresses its
		// children by index and removing one shifts the other.
		let isFirst = parentSplit.First == target;
		let otherChild = isFirst ? parentSplit.Second : parentSplit.First;

		target.AddRef();
		if (otherChild != null)
			otherChild.AddRef();

		parentSplit.RemoveView(target);
		if (otherChild != null)
			parentSplit.RemoveView(otherChild);

		split.SetChildren(panelFirst ? (View)group : target, panelFirst ? target : group);
		parentSplit.SetChildren(isFirst ? (View)split : otherChild,
			isFirst ? otherChild : (View)split);
	}

	/// Takes a panel out of wherever it currently is.
	private void RemoveFromTree(DockablePanel panel)
	{
		if (let tabGroup = panel.Parent as DockTabGroup)
		{
			// RemovePanel hands back a reference; the registry already holds one.
			let removed = tabGroup.RemovePanel(panel);
			if (removed != null)
				removed.ReleaseRef();
			return;
		}

		if ((panel.Parent == this) && (mRootNode == panel))
		{
			RemoveView(panel);
			mRootNode = null;
			return;
		}

		for (let window in mDockableWindows)
		{
			if (window.Panel != panel)
				continue;

			let detached = window.DetachPanel();
			if (detached != null)
				detached.ReleaseRef();

			DestroyDockableWindow(window);
			return;
		}
	}

	/// Puts one node where another was. CONSUMES the new node's reference; the old one is
	/// handed back to the caller by way of the reference it already holds.
	private void ReplaceNode(View oldNode, View newNode)
	{
		if (oldNode == mRootNode)
		{
			RemoveView(oldNode);
			mRootNode = newNode;
			AddView(newNode);
			return;
		}

		let parentSplit = oldNode.Parent as DockSplit;
		if (parentSplit == null)
			return;

		let isFirst = parentSplit.First == oldNode;
		let other = isFirst ? parentSplit.Second : parentSplit.First;
		if (other != null)
			other.AddRef();

		parentSplit.RemoveView(oldNode);
		if (other != null)
			parentSplit.RemoveView(other);

		parentSplit.SetChildren(isFirst ? newNode : other, isFirst ? other : newNode);
	}

	/// Collapses splits that have lost a child and groups that have lost every panel.
	///
	/// GUARDED against re-entry, because the cleanup queues deletions and a queued deletion can
	/// run another cleanup.
	private void CleanupEmptyNodes()
	{
		if (mIsCleaningUp)
			return;

		mIsCleaningUp = true;
		if (mRootNode != null)
		{
			let newRoot = CleanupNode(mRootNode);
			// The surviving node's reference belongs to whatever now holds it; the manager only
			// tracks which one is the root.
			if (newRoot != null)
				newRoot.ReleaseRef();
			mRootNode = newRoot;
		}
		mIsCleaningUp = false;
	}

	/// Returns what this node COLLAPSES TO, which may be itself, one of its children, or
	/// nothing. The result carries a reference the caller must release.
	private View CleanupNode(View node)
	{
		node.AddRef();

		if (let split = node as DockSplit)
			return CleanupSplit(split);

		if (let tabGroup = node as DockTabGroup)
		{
			if (tabGroup.PanelCount == 0)
			{
				DetachRootAndQueue(tabGroup);
				node.ReleaseRef();
				return null;
			}
		}

		return node;
	}

	private View CleanupSplit(DockSplit split)
	{
		let first = split.First;
		let second = split.Second;

		if (first != null)
			first.AddRef();
		if (second != null)
			second.AddRef();

		// Detached in REVERSE, so the first child's index does not shift under the second's
		// removal.
		if (second != null)
			split.RemoveView(second);
		if (first != null)
			split.RemoveView(first);

		let cleanFirst = (first != null) ? CleanupNode(first) : null;
		let cleanSecond = (second != null) ? CleanupNode(second) : null;

		// A child that collapsed to something else is no longer wanted.
		if ((first != null) && (cleanFirst != first))
			QueueDeleteNode(first);
		if ((second != null) && (cleanSecond != second))
			QueueDeleteNode(second);

		if (first != null)
			first.ReleaseRef();
		if (second != null)
			second.ReleaseRef();

		if ((cleanFirst != null) && (cleanSecond != null))
		{
			split.SetChildren(cleanFirst, cleanSecond);
			return split;
		}

		// One child left, or none: the split itself is redundant and collapses away.
		let survivor = (cleanFirst != null) ? cleanFirst : cleanSecond;
		if (split == mRootNode)
		{
			split.AddRef();
			RemoveView(split);
			QueueDeleteNode(split);
			split.ReleaseRef();

			if (survivor != null)
			{
				survivor.AddRef();
				AddView(survivor);
			}
		}

		split.ReleaseRef();
		return survivor;
	}

	private void DetachRootAndQueue(View node)
	{
		if (node != mRootNode)
			return;

		node.AddRef();
		RemoveView(node);
		QueueDeleteNode(node);
		node.ReleaseRef();
	}

	/// Tears down the structural nodes of a subtree WITHOUT destroying the panels in it, which
	/// is what restoring a layout needs: the panels are about to be placed again.
	private void ClearTreeStructure(View node)
	{
		node.AddRef();
		defer node.ReleaseRef();

		if (let split = node as DockSplit)
		{
			let first = split.First;
			let second = split.Second;

			if (first != null)
				first.AddRef();
			if (second != null)
				second.AddRef();

			if (second != null)
				split.RemoveView(second);
			if (first != null)
				split.RemoveView(first);

			if (first != null)
			{
				ClearTreeStructure(first);
				first.ReleaseRef();
			}
			if (second != null)
			{
				ClearTreeStructure(second);
				second.ReleaseRef();
			}

			if (node.Parent == this)
				RemoveView(node);

			QueueDeleteNode(split);
			return;
		}

		if (let tabGroup = node as DockTabGroup)
		{
			while (tabGroup.PanelCount > 0)
			{
				let panel = tabGroup.RemovePanel(tabGroup.GetPanel(tabGroup.PanelCount - 1));
				if (panel != null)
					panel.ReleaseRef();
			}

			if (node.Parent == this)
				RemoveView(node);

			QueueDeleteNode(tabGroup);
		}
	}

	/// Deferred destruction of a structural node, or of an orphaned panel.
	///
	/// The node is MARKED and held alive across the queue boundary, because the tree is
	/// rearranged during a drop, which is mid dispatch, and freeing a node whose own event is
	/// still unwinding is exactly the use after free this defers around.
	///
	/// With no context there is no queue, and dropping the last reference frees it directly.
	private void QueueDeleteNode(View node)
	{
		if ((node == null) || node.IsPendingDeletion)
			return;

		if (Context == null)
			return;

		node.IsPendingDeletion = true;
		node.AddRef();

		Context.MutationQueue.QueueAction(new [=]() =>
			{
				if (let parent = node.Parent as ViewGroup)
					parent.RemoveView(node);

				node.ReleaseRef();
			});
	}

	/// The first group in a subtree, depth first.
	private DockTabGroup FindFirstTabGroup(View node)
	{
		if (let tabGroup = node as DockTabGroup)
			return tabGroup;

		let split = node as DockSplit;
		if (split == null)
			return null;

		if (split.First != null)
		{
			if (let found = FindFirstTabGroup(split.First))
				return found;
		}

		return (split.Second != null) ? FindFirstTabGroup(split.Second) : null;
	}

	/// A node's rectangle in the manager's own coordinates, accumulated up the chain, because a
	/// node's bounds are relative to its parent and the zones are drawn in manager space.
	private Rectangle GetNodeBounds(View node)
	{
		var x = 0.0f;
		var y = 0.0f;
		var current = node;

		while ((current != null) && (current != this))
		{
			x += current.Bounds.X;
			y += current.Bounds.Y;
			current = current.Parent;
		}

		return .(x, y, node.Width, node.Height);
	}
}
