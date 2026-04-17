namespace Sedulous.UI;

using System;
using System.Collections;

/// Deferred mutation queue. Structural tree changes (add/remove/reparent/destroy)
/// and focus changes are enqueued here and drained at safe sync points. Prevents
/// use-after-free during event routing and render walks.
public class MutationQueue
{
	private List<delegate void()> mQueue = new .() ~ {
		for (let d in _) delete d;
		delete _;
	};

	/// Enqueue an action to run at the next drain point.
	public void QueueAction(delegate void() action)
	{
		mQueue.Add(action);
	}

	/// True if there are pending mutations.
	public bool HasPending => mQueue.Count > 0;

	/// Execute all pending mutations (called at safe sync points).
	/// Actions executed may enqueue more actions — drain loops until empty.
	public void Drain()
	{
		// Process in FIFO order. New items appended by callbacks are
		// picked up in subsequent iterations of the outer while loop.
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
}
