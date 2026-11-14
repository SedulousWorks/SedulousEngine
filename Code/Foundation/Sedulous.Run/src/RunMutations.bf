using System;
using System.Collections;

namespace Sedulous.Run;

/// What a run defers while its scripts run. A script may destroy an entity, destroy or replace a
/// scene, or stop its networking from anywhere it runs: an update, the fixed step, an event
/// handler, a network message, a destroy hook. Done at once, that frees what the code that called
/// the script is still walking. So whoever runs a run's scripts calls Enter first and Leave after,
/// and what is asked for meanwhile waits here until Flush, which the same caller runs once it has
/// left, between the frame's phases.
///
/// Each piece of work names its owner (the scene, the manager it acts on); an owner that goes
/// away first cancels its work (Cancel), so the queue never reaches a freed owner.
class RunMutations
{
	private struct Item
	{
		/// Compared by reference; null once done or cancelled.
		public Object Owner;
		/// OWNED: deleted once it has run, or when cancelled.
		public delegate void() Work;
	}

	private List<Item> mItems = new .() ~ { for (let item in _) delete item.Work; delete _; };
	private int32 mDepth = 0;
	private bool mFlushing = false;

	/// Work asked for from here until the matching Leave waits for Flush. Pairs nest.
	public void Enter() => mDepth++;
	public void Leave()
	{
		Runtime.Assert(mDepth > 0);
		mDepth--;
	}

	/// Whether work asked for now must wait for Flush.
	public bool IsDeferring => mDepth > 0;

	/// Queues `work` for `owner` until the next Flush, taking OWNERSHIP of the delegate.
	public void Enqueue(Object owner, delegate void() work)
	{
		Item item;
		item.Owner = owner;
		item.Work = work;
		mItems.Add(item);
	}

	/// Drops (and deletes) what `owner` queued: it is going away. Safe during Flush.
	public void Cancel(Object owner)
	{
		if (owner == null)
			return;
		for (int i < mItems.Count)
		{
			if (mItems[i].Owner === owner)
			{
				mItems[i].Owner = null;
				delete mItems[i].Work;
				mItems[i].Work = null;
			}
		}
	}

	/// Runs what was queued, in order, once no Enter is open; work queued by work runs in the
	/// same flush. Nothing while one is open, or from inside a flush.
	public void Flush()
	{
		if ((mDepth > 0) || mFlushing)
			return;
		mFlushing = true;
		// By index: the list may grow while an item runs.
		for (int i = 0; i < mItems.Count; i++)
		{
			if (mItems[i].Owner == null)
				continue;
			let work = mItems[i].Work;
			mItems[i].Owner = null;
			mItems[i].Work = null;
			work();
			delete work;
		}
		mItems.Clear();
		mFlushing = false;
	}

	/// The work still waiting.
	public int PendingCount
	{
		get
		{
			int count = 0;
			for (let item in mItems)
			{
				if (item.Owner != null)
					count++;
			}
			return count;
		}
	}
}
