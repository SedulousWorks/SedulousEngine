using System;
using System.Collections;

namespace Sedulous.GUI;

/// Type of tree mutation.
public enum MutationType
{
	/// Add a child to a container.
	AddChild,
	/// Remove a child from a container (optionally delete).
	RemoveChild,
	/// Delete an element.
	DeleteElement
}

/// Represents a pending tree mutation.
public struct Mutation
{
	public MutationType Type;
	public UIElement Target;
	public UIElementId TargetId;
	public UIElement Child;
	public UIElementId ChildId;
	public bool DeleteAfterRemove;
}

/// Queue for deferred tree mutations.
/// All tree modifications (add/remove/delete) are queued during event processing
/// and applied at the end of the frame to prevent crashes from modifications
/// during iteration or event handling.
public class MutationQueue
{
	private List<Mutation> mPending = new .() ~ delete _;
	private List<delegate void()> mQueuedActions = new .() ~ DeleteContainerAndItems!(_);
	private HashSet<UIElementId> mDeletedThisFrame = new .() ~ delete _;
	private bool mProcessing = false;

	/// Whether mutations are currently being processed.
	public bool IsProcessing => mProcessing;

	/// Number of pending mutations.
	public int Count => mPending.Count;

	/// Queue adding a child to a container.
	/// The child will be added when Process() is called.
	public void QueueAddChild(UIElement parent, UIElement child)
	{
		mPending.Add(.()
		{
			Type = .AddChild,
			Target = parent,
			TargetId = parent.Id,
			Child = child,
			ChildId = child.Id,
			DeleteAfterRemove = false
		});
	}

	/// Queue removing a child from a container.
	/// If deleteAfterRemove is true, the child will be deleted after removal.
	public void QueueRemoveChild(UIElement parent, UIElement child, bool deleteAfterRemove = true)
	{
		mPending.Add(.()
		{
			Type = .RemoveChild,
			Target = parent,
			TargetId = parent.Id,
			Child = child,
			ChildId = child.Id,
			DeleteAfterRemove = deleteAfterRemove
		});
	}

	/// Queue deleting an element.
	/// The element will be removed from its parent and deleted when Process() is called.
	public void QueueDelete(UIElement element)
	{
		if (element == null)
			return;

		// Mark as pending deletion immediately
		element.[Friend]mIsPendingDeletion = true;

		mPending.Add(.()
		{
			Type = .DeleteElement,
			Target = element,
			TargetId = element.Id,
			Child = null,
			DeleteAfterRemove = true
		});
	}

	/// Queue an action to be executed at the end of the frame.
	/// Useful for deferring operations that would cause use-after-free if executed immediately.
	public void QueueAction(delegate void() action)
	{
		if (action != null)
			mQueuedActions.Add(action);
	}

	/// Process all pending mutations.
	/// Called at the end of each frame by GUIContext.
	public void Process(GUIContext context)
	{
		if (mPending.Count == 0 && mQueuedActions.Count == 0)
			return;

		mProcessing = true;

		for (let mutation in mPending)
		{
			switch (mutation.Type)
			{
			case .AddChild:
				// Look up elements by ID to verify they still exist
				let addParent = context.GetElementById(mutation.TargetId);
				let addChild = context.GetElementById(mutation.ChildId);
				// Skip if child is already pending deletion
				if (addParent != null && addChild != null && !addChild.IsPendingDeletion)
				{
					addParent.TryAddChild(addChild);
				}

			case .RemoveChild:
				// Look up elements by ID to verify they still exist
				let parent = context.GetElementById(mutation.TargetId);
				let child = context.GetElementById(mutation.ChildId);
				if (parent != null && child != null)
				{
					// Detach the child from its parent (this unregisters via OnDetachedFromContext)
					let detached = parent.TryDetachChild(child);

					// If deletion requested and detachment succeeded
					if (mutation.DeleteAfterRemove && detached != null)
					{
						context.OnElementDeleted(mutation.ChildId);
						// Note: UnregisterElementTree not needed here because DetachChild
						// already called OnDetachedFromContext which unregisters recursively
						delete detached;
					}
				}

			case .DeleteElement:
				// Skip if already deleted this frame
				if (mDeletedThisFrame.Contains(mutation.TargetId))
					continue;

				// Look up element by ID to verify it still exists in registry
				var target = context.GetElementById(mutation.TargetId);

				// If not found in registry but we have a valid reference marked for deletion,
				// use the direct reference. This handles the case where the element was removed
				// from the tree (e.g., popup closed) but deletion was deferred.
				// Safe because we track deleted IDs to avoid dangling pointer access.
				if (target == null && mutation.Target != null)
				{
					target = mutation.Target;
				}

				if (target != null)
				{
					// Track this ID as deleted to prevent double-deletion
					mDeletedThisFrame.Add(mutation.TargetId);

					// Notify context so input/focus managers can clear references
					context.OnElementDeleted(mutation.TargetId);

					// Clear root element reference if this is the root
					if (context.[Friend]mRootElement == target)
					{
						context.[Friend]mRootElement = null;
					}

					// Remove from parent if any
					if (target.Parent != null)
					{
						target.DetachFromParent();
					}

					// Unregister the element and all its descendants before deletion
					context.UnregisterElementTree(target);
					delete target;
				}
			}
		}

		mPending.Clear();
		mDeletedThisFrame.Clear();

		// Execute queued actions after mutations are processed
		for (let action in mQueuedActions)
		{
			action();
			delete action;
		}
		mQueuedActions.Clear();

		mProcessing = false;
	}

	/// Clear all pending mutations without processing them.
	public void Clear()
	{
		mPending.Clear();
		mDeletedThisFrame.Clear();
		DeleteContainerAndItems!(mQueuedActions);
		mQueuedActions = new .();
	}
}
