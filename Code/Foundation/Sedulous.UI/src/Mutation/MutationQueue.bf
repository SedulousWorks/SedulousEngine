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

	// Diagnostic: track ViewIds of views deleted during the current drain.
	private List<ViewId> mDeletedThisFrame = new .() ~ delete _;

	/// ViewIds of views that were deleted during the most recent Drain().
	/// Cleared at the start of each Drain(). Useful for debugging.
	public int DeletedThisFrameCount => mDeletedThisFrame.Count;

	/// Get a ViewId that was deleted during the most recent drain.
	public ViewId GetDeletedThisFrame(int index) => mDeletedThisFrame[index];

	/// Record that a view was deleted during this frame's drain.
	public void NotifyDeleted(ViewId id)
	{
		mDeletedThisFrame.Add(id);
	}

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
		mDeletedThisFrame.Clear();

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
