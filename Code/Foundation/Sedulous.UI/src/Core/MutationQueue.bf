using System;
using System.Collections;

namespace Sedulous.UI;

/// Tree changes deferred to a safe point.
///
/// A handler that removes the view it is running inside would pull the ground from under the
/// dispatch walking the tree, so the change is queued and drained between frames instead.
///
/// PARTIAL PORT: QueueDelete needs ViewGroup and lands with it.
class MutationQueue
{
	private List<delegate void()> mQueue = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	/// OWNERSHIP of the action transfers.
	public void QueueAction(delegate void() action) => mQueue.Add(action);

	public bool HasPending => !mQueue.IsEmpty;

	/// Runs everything pending.
	///
	/// An action may queue MORE, so this loops until the queue stays empty: the batch is taken
	/// away before running, so anything added lands in a fresh one rather than being appended
	/// to the list being walked.
	public void Drain()
	{
		while (!mQueue.IsEmpty)
		{
			let batch = scope List<delegate void()>();
			for (let action in mQueue)
				batch.Add(action);
			mQueue.Clear();

			for (let action in batch)
			{
				action();
				delete action;
			}
		}
	}
}
