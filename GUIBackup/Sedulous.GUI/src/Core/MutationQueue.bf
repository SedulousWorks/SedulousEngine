namespace Sedulous.GUI;

using System;
using System.Collections;

/// Deferred tree mutation queue. Actions queued during event handling or
/// layout are executed at frame end to prevent iterator invalidation and
/// parent/child state corruption.
public class MutationQueue
{
	private List<delegate void()> mQueue = new .() ~ DeleteContainerAndItems!(_);
	private List<delegate void()> mDraining = new .() ~ delete _;

	/// Queue an action for deferred execution.
	public void QueueAction(delegate void() action)
	{
		mQueue.Add(action);
	}

	/// Execute all pending mutations. Loops until empty in case
	/// mutations enqueue further mutations.
	public void Drain()
	{
		while (mQueue.Count > 0)
		{
			// Swap to a separate list so new mutations queued during
			// drain are collected in mQueue for the next iteration.
			let temp = mDraining;
			mDraining = mQueue;
			mQueue = temp;

			for (let action in mDraining)
			{
				action();
				delete action;
			}
			mDraining.Clear();
		}
	}

	/// Returns true if there are pending mutations.
	public bool HasPending => mQueue.Count > 0;
}
