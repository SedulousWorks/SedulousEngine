namespace Sedulous.GUI;

using System;
using System.Collections;

/// Deferred mutation queue. Structural tree changes (add/remove/reparent/destroy)
/// and focus changes are enqueued here and drained at safe sync points. Prevents
/// use-after-free during event routing and render walks.
public class MutationQueue
{
	private List<delegate void()> mQueue = new .();

	/// Enqueue an action to run at the next drain point.
	public void QueueAction(delegate void() action)
	{
		mQueue.Add(action);
	}

	/// Queue a view for deferred deletion at the next drain point.
	/// Removes the view from its parent before deleting.
	public void QueueDelete(View view)
	{
		if (view == null || view.IsPendingDeletion)
			return;
		view.IsPendingDeletion = true;
		QueueAction(new () =>
		{
			if (view.Parent != null)
				if (let parentGroup = view.Parent as ViewGroup)
					parentGroup.RemoveView(view, false);
			delete view;
		});
	}

	/// True if there are pending mutations.
	public bool HasPending => mQueue.Count > 0;

	/// Execute all pending mutations (called at safe sync points).
	/// Actions executed may enqueue more actions - drain loops until empty.
	public void Drain()
	{
		while (mQueue.Count > 0)
		{
			// Snapshot current count; process those, then check for newly added.
			let count = mQueue.Count;
			for (int i = 0; i < count; i++)
			{
				let action = mQueue[i];
				action();
				delete action;
			}
			mQueue.RemoveRange(0, count);
		}
	}

	public ~this()
	{
		// Delete any undrained actions
		for (let d in mQueue)
			delete d;
		delete mQueue;
	}
}
