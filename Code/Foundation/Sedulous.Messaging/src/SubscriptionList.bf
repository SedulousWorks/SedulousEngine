namespace Sedulous.Messaging;

using System;
using System.Collections;

/// Typed subscription list for a specific message type T.
/// Stores delegate entries and handles safe enumeration during add/remove.
class SubscriptionList<T> : ISubscriptionList where T : struct, IMessage
{
	struct Entry
	{
		public uint64 Id;
		public delegate void(ref T) Handler;
	}

	private List<Entry> mEntries = new .() ~ delete _;
	private int32 mDispatchDepth = 0;
	private bool mNeedsCompaction = false;

	/// Adds a handler with the given ID.
	public void Add(uint64 id, delegate void(ref T) handler)
	{
		Entry entry;
		entry.Id = id;
		entry.Handler = handler;
		mEntries.Add(entry);
	}

	/// Dispatches the message to all subscribers.
	/// Safe to call re-entrantly. Safe during concurrent Remove (nulled entries skipped).
	public void Dispatch(void* messagePtr)
	{
		mDispatchDepth++;

		// Snapshot count: entries added during dispatch are not called for this message.
		let count = mEntries.Count;
		for (int i = 0; i < count; i++)
		{
			let handler = mEntries[i].Handler;
			if (handler != null)
				handler(ref *(T*)messagePtr);
		}

		mDispatchDepth--;

		if (mDispatchDepth == 0 && mNeedsCompaction)
			Compact();
	}

	/// Removes a subscription by ID.
	/// During dispatch: nulls entry for deferred compaction.
	/// Outside dispatch: removes immediately.
	/// Deletes the delegate in both cases.
	public bool Remove(uint64 id)
	{
		for (int i = 0; i < mEntries.Count; i++)
		{
			if (mEntries[i].Id == id)
			{
				let handler = mEntries[i].Handler;

				if (mDispatchDepth > 0)
				{
					var entry = Entry();
					entry.Id = 0;
					entry.Handler = null;
					mEntries[i] = entry;
					mNeedsCompaction = true;
				}
				else
				{
					mEntries.RemoveAt(i);
				}

				delete handler;
				return true;
			}
		}
		return false;
	}

	/// Removes nulled-out entries after dispatch completes.
	private void Compact()
	{
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			if (mEntries[i].Handler == null)
				mEntries.RemoveAt(i);
		}
		mNeedsCompaction = false;
	}

	/// Disposes all remaining delegates.
	public void Dispose()
	{
		for (let entry in mEntries)
		{
			if (entry.Handler != null)
				delete entry.Handler;
		}
		mEntries.Clear();
	}
}
