using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Messaging;

/// A name keyed event bus, and nothing else.
///
/// A RUN SCOPE facility: a scene's, or a whole run's. It knows nothing of scenes. Systems and
/// game code publish and subscribe directly.
///
/// Delivery is DEFERRED by default. Publish enqueues, and Drain, called at the top level of a
/// scope's tick with no handler in flight, delivers everything queued to its subscribers
/// in SUBSCRIPTION ORDER. A handler may publish again and those cascade in the same drain,
/// bounded so a runaway emit cannot spin forever. Post queues without the cascade: what it
/// queues during a drain waits for the next one. Send delivers at once, inside the caller.
///
/// A subscription may end at any time, from inside a handler (its own included): one ended
/// during a delivery is skipped from then on, and its slot, with an owned callback, goes when
/// the delivery ends.
class EventBus
{
	/// The cascade bound: a handler that keeps emitting cannot spin the drain.
	public const uint32 cMaxDrainPasses = 8;

	private List<EventSubscriber> mSubscribers = new .() ~ { DeleteOwned(_); delete _; };
	private List<PendingEvent> mQueue = new .() ~ { DisposeQueue(_); delete _; };
	/// What Post queued while a drain delivered, held for the next drain.
	private List<PendingEvent> mHeld = new .() ~ { DisposeQueue(_); delete _; };
	/// OWNED: the owned callbacks of subscriptions ended during a delivery, deleted once no
	/// delivery is in flight, since one of them may be the very callback running.
	private List<delegate void(Variant)> mRetired = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mNextHandle = 1;
	/// The deliveries in flight (drains and sends, nested), and the drains among them.
	private int32 mDelivering = 0;
	private int32 mDraining = 0;
	/// The slots ended during a delivery, swept when it ends.
	private int32 mEnded = 0;

	/// Queues `payload` under `name`, for the next drain. The bus OWNS the payload from
	/// here on and disposes it once delivered.
	public void Publish(StringHash name, Variant payload)
	{
		mQueue.Add(.(name, payload));
	}

	/// As Publish, without the cascade: posted while a drain delivers, it waits for the next
	/// drain, so a handler that posts again cannot keep a drain going. The bus OWNS the
	/// payload.
	public void Post(StringHash name, Variant payload)
	{
		if (mDraining > 0)
			mHeld.Add(.(name, payload));
		else
			mQueue.Add(.(name, payload));
	}

	/// Delivers `payload` under `name` NOW, inside the caller, to its subscribers in
	/// subscription order. BORROWED: the caller still owns the payload, which need only live
	/// for the call, so a payload referencing the caller's own copy costs nothing.
	public void Send(StringHash name, Variant payload)
	{
		mDelivering++;
		Deliver(name, payload);
		EndDelivery();
	}

	/// Subscribes a callback to `name`, returning the handle that unsubscribes it. The
	/// CALLER owns the delegate and must keep it alive while it is subscribed.
	public uint32 Subscribe(StringHash name, delegate void(Variant) callback)
	{
		let handle = mNextHandle++;
		mSubscribers.Add(.(name, handle, callback));
		return handle;
	}

	/// As Subscribe, the bus taking OWNERSHIP of `callback`: deleted when the subscription
	/// ends (once no delivery is in flight), when the bus is cleared, or with the bus.
	public uint32 SubscribeOwned(StringHash name, delegate void(Variant) callback)
	{
		let handle = mNextHandle++;
		mSubscribers.Add(.(name, handle, callback, true));
		return handle;
	}

	/// Removes a subscription. Safe when it is already gone, and from inside a handler: during
	/// a delivery the slot stays, skipped, until the delivery ends, so the deliveries in
	/// flight neither skip a subscriber nor reach a callback already deleted.
	public void Unsubscribe(uint32 handle)
	{
		if (handle == 0)
			return;
		for (int i < mSubscribers.Count)
		{
			if (mSubscribers[i].Handle == handle)
			{
				End(i);
				return;
			}
		}
	}

	/// Delivers everything queued.
	///
	/// A handler's own publish is delivered in this SAME call, up to the pass cap; within
	/// one event subscribers fire in subscription order. A post waits for the next drain.
	public void Drain()
	{
		uint32 pass = 0;
		let batch = scope List<PendingEvent>();
		mDelivering++;
		mDraining++;

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
				Deliver(event.Name, event.Payload);
				event.Dispose();
			}
		}

		mDraining--;
		if ((mDraining == 0) && !mHeld.IsEmpty)
		{
			mQueue.AddRange(mHeld);
			mHeld.Clear();
		}
		EndDelivery();
	}

	/// Drops every subscriber and everything queued, for a scope's teardown.
	public void Clear()
	{
		if (mDelivering == 0)
		{
			DeleteOwned(mSubscribers);
			mSubscribers.Clear();
		}
		else
		{
			for (int i < mSubscribers.Count)
			{
				if (mSubscribers[i].Callback != null)
					End(i);
			}
		}
		DisposeQueue(mQueue);
		DisposeQueue(mHeld);
	}

	/// The live subscriptions: one ended during a delivery is not counted.
	public int SubscriberCount => mSubscribers.Count - mEnded;
	public int PendingCount => mQueue.Count + mHeld.Count;

	/// To every live subscriber of `name`. The count is SNAPSHOT, so a handler that subscribes
	/// does not receive the very event it is handling, and an ended slot stays in place until
	/// the delivery ends, so the indexes hold.
	private void Deliver(StringHash name, Variant payload)
	{
		let count = mSubscribers.Count;
		for (int i = 0; (i < count) && (i < mSubscribers.Count); i++)
		{
			let subscriber = mSubscribers[i];
			if ((subscriber.Callback != null) && (subscriber.Name == name))
				subscriber.Callback(payload);
		}
	}

	/// Ends subscription `index`: at once with no delivery in flight, else marked and swept
	/// when the delivery ends, an owned callback deleted then.
	private void End(int index)
	{
		var subscriber = ref mSubscribers[index];
		if (mDelivering == 0)
		{
			if (subscriber.Owned)
				delete subscriber.Callback;
			mSubscribers.RemoveAt(index);
			return;
		}
		if (subscriber.Owned)
			mRetired.Add(subscriber.Callback);
		subscriber.Callback = null;
		subscriber.Handle = 0;
		mEnded++;
	}

	/// The outermost delivery's end sweeps what ended during it.
	private void EndDelivery()
	{
		if (--mDelivering > 0)
			return;
		if (mEnded > 0)
		{
			int kept = 0;
			for (int i < mSubscribers.Count)
			{
				if (mSubscribers[i].Callback != null)
					mSubscribers[kept++] = mSubscribers[i];
			}
			mSubscribers.RemoveRange(kept, mSubscribers.Count - kept);
			mEnded = 0;
		}
		ClearAndDeleteItems!(mRetired);
	}

	/// An undelivered payload is still the bus's to free.
	private static void DisposeQueue(List<PendingEvent> queue)
	{
		for (var event in ref queue)
			event.Dispose();
		queue.Clear();
	}

	/// The owned callbacks still subscribed.
	private static void DeleteOwned(List<EventSubscriber> subscribers)
	{
		for (let subscriber in subscribers)
		{
			if (subscriber.Owned && (subscriber.Callback != null))
				delete subscriber.Callback;
		}
	}
}
