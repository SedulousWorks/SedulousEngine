using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Messaging;

/// A name keyed event bus, and nothing else.
///
/// A RUN SCOPE facility: a scene's, or a whole run's. It knows nothing of scenes and
/// nothing of scripting. Native systems publish and subscribe directly, so a game written
/// entirely in native code is a first class participant; a script layer reaches it through
/// a bridge, never the other way round.
///
/// Delivery is DEFERRED. Publish enqueues, and Drain, called at the top level of a scope's
/// tick with no script call in flight, delivers everything queued to its subscribers in
/// SUBSCRIPTION ORDER. A handler may publish again and those cascade in the same drain,
/// bounded so a runaway emit cannot spin forever. A handler may also subscribe and unsubscribe
/// (itself included): the list changes only between events, so no running handler is skipped,
/// and one whose unsubscribe hands its callback over (Unsubscribe's deleteCallback) is deleted
/// only once it has returned.
class EventBus
{
	/// The cascade bound: a handler that keeps emitting cannot spin the drain.
	public const uint32 cMaxDrainPasses = 8;

	private List<EventSubscriber> mSubscribers = new .() ~ { DeleteHandedOver(_); delete _; };
	/// Subscribed during a drain, joining the list at the next Settle.
	private List<EventSubscriber> mAdded = new .() ~ { DeleteHandedOver(_); delete _; };
	private bool mDraining = false;
	private bool mHasDead = false;
	private List<PendingEvent> mQueue = new .() ~ { DisposeQueue(_); delete _; };
	private uint32 mNextHandle = 1;

	/// Queues `payload` under `name`, for the next drain. The bus OWNS the payload from
	/// here on and disposes it once delivered.
	public void Publish(StringHash name, Variant payload)
	{
		mQueue.Add(.(name, payload));
	}

	/// Subscribes a callback to `name`, returning the handle that unsubscribes it. The
	/// CALLER owns the delegate and must keep it alive while it is subscribed. Made from a
	/// handler during a drain, it joins after the event being delivered, so it hears the ones
	/// after.
	public uint32 Subscribe(StringHash name, delegate void(Variant) callback)
	{
		let handle = mNextHandle++;
		// The list may not change under a running handler.
		if (mDraining)
			mAdded.Add(.(name, handle, callback));
		else
			mSubscribers.Add(.(name, handle, callback));
		return handle;
	}

	/// Removes a subscription. Safe when it is already gone, and from a handler during a drain
	/// (its own included): it stops hearing at once and leaves the list between events. With
	/// `deleteCallback`, the bus TAKES the callback and deletes it as the entry leaves, after
	/// it returned if it is the one running; an owner that frees its handlers mid drain (a
	/// script bridge whose scene stops from a handler) hands them over this way.
	public void Unsubscribe(uint32 handle, bool deleteCallback = false)
	{
		for (int i < mAdded.Count)
		{
			if (mAdded[i].Handle == handle)
			{
				if (deleteCallback)
					delete mAdded[i].Callback;
				mAdded.RemoveAt(i);
				return;
			}
		}
		for (int i < mSubscribers.Count)
		{
			if (mSubscribers[i].Handle == handle)
			{
				if (mDraining)
				{
					mSubscribers[i].Dead = true;
					mSubscribers[i].DeleteCallback = deleteCallback;
					mHasDead = true;
				}
				else
				{
					if (deleteCallback)
						delete mSubscribers[i].Callback;
					mSubscribers.RemoveAt(i);
				}
				return;
			}
		}
	}

	/// Delivers everything queued.
	///
	/// A handler's own publish is delivered in this SAME call, up to the pass cap; within
	/// one event subscribers fire in subscription order. A drain asked for from a handler does
	/// nothing: the one running delivers what was published.
	public void Drain()
	{
		if (mDraining)
			return;
		mDraining = true;
		uint32 pass = 0;
		let batch = scope List<PendingEvent>();

		while (!mQueue.IsEmpty)
		{
			if (++pass > cMaxDrainPasses)
			{
				GlobalLog(.Warning,
					"EventBus: the drain hit its {} pass cap, dropping the rest. A runaway emit?",
					cMaxDrainPasses);
				DisposeQueue(mQueue);
				break;
			}

			// Take the current batch; a handler's publish appends to the now empty queue
			// and is delivered on the next pass rather than inside this loop.
			batch.Clear();
			batch.AddRange(mQueue);
			mQueue.Clear();

			for (var event in ref batch)
			{
				// The list does not change size while handlers run (Subscribe and Unsubscribe
				// wait for Settle), so no handler is moved, skipped or freed under it.
				for (int i < mSubscribers.Count)
				{
					if (!mSubscribers[i].Dead && (mSubscribers[i].Name == event.Name))
						mSubscribers[i].Callback(event.Payload);
				}
				event.Dispose();
				Settle();
			}
		}
		mDraining = false;
		Settle();
	}

	/// Drops every subscriber and everything queued, for a scope's teardown. From a handler
	/// during a drain, every subscription stops hearing at once and leaves when no handler runs.
	public void Clear()
	{
		DisposeQueue(mQueue);
		DeleteHandedOver(mAdded);
		mAdded.Clear();
		if (!mDraining)
		{
			DeleteHandedOver(mSubscribers);
			mSubscribers.Clear();
			return;
		}
		for (int i < mSubscribers.Count)
			mSubscribers[i].Dead = true;
		mHasDead = !mSubscribers.IsEmpty;
	}

	/// The live subscriptions: those joining after the drain count, the unsubscribed do not.
	public int SubscriberCount
	{
		get
		{
			var live = mAdded.Count;
			for (let subscriber in mSubscribers)
			{
				if (!subscriber.Dead)
					live++;
			}
			return live;
		}
	}
	public int PendingCount => mQueue.Count;

	/// Between events, with no handler running: the unsubscribed leave (their handed over
	/// callbacks deleted), the subscribed join.
	private void Settle()
	{
		if (mHasDead)
		{
			for (int i = mSubscribers.Count - 1; i >= 0; i--)
			{
				if (mSubscribers[i].Dead)
				{
					if (mSubscribers[i].DeleteCallback)
						delete mSubscribers[i].Callback;
					mSubscribers.RemoveAt(i);
				}
			}
			mHasDead = false;
		}
		mSubscribers.AddRange(mAdded);
		mAdded.Clear();
	}

	/// The callbacks the list holds that their unsubscribe handed over, deleted.
	private static void DeleteHandedOver(List<EventSubscriber> subscribers)
	{
		for (let subscriber in subscribers)
		{
			if (subscriber.DeleteCallback)
				delete subscriber.Callback;
		}
	}

	/// An undelivered payload is still the bus's to free.
	private static void DisposeQueue(List<PendingEvent> queue)
	{
		for (var event in ref queue)
			event.Dispose();
		queue.Clear();
	}
}
