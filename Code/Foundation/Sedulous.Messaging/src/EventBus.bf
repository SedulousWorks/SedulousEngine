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
/// bounded so a runaway emit cannot spin forever.
class EventBus
{
	/// The cascade bound: a handler that keeps emitting cannot spin the drain.
	public const uint32 cMaxDrainPasses = 8;

	private List<EventSubscriber> mSubscribers = new .() ~ delete _;
	private List<PendingEvent> mQueue = new .() ~ { DisposeQueue(_); delete _; };
	private uint32 mNextHandle = 1;

	/// Queues `payload` under `name`, for the next drain. The bus OWNS the payload from
	/// here on and disposes it once delivered.
	public void Publish(StringHash name, Variant payload)
	{
		mQueue.Add(.(name, payload));
	}

	/// Subscribes a callback to `name`, returning the handle that unsubscribes it. The
	/// CALLER owns the delegate and must keep it alive while it is subscribed.
	public uint32 Subscribe(StringHash name, delegate void(Variant) callback)
	{
		let handle = mNextHandle++;
		mSubscribers.Add(.(name, handle, callback));
		return handle;
	}

	/// Removes a subscription. Safe when it is already gone.
	///
	/// NOT for use from inside a handler mid drain: churn subscriptions outside delivery.
	public void Unsubscribe(uint32 handle)
	{
		for (int i < mSubscribers.Count)
		{
			if (mSubscribers[i].Handle == handle)
			{
				mSubscribers.RemoveAt(i);
				return;
			}
		}
	}

	/// Delivers everything queued.
	///
	/// A handler's own publish is delivered in this SAME call, up to the pass cap; within
	/// one event subscribers fire in subscription order.
	public void Drain()
	{
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
				// The count is SNAPSHOT, so a handler that subscribes does not receive the
				// very event it is handling.
				let count = mSubscribers.Count;
				for (int i = 0; (i < count) && (i < mSubscribers.Count); i++)
				{
					if (mSubscribers[i].Name == event.Name)
						mSubscribers[i].Callback(event.Payload);
				}
				event.Dispose();
			}
		}
	}

	/// Drops every subscriber and everything queued, for a scope's teardown.
	public void Clear()
	{
		mSubscribers.Clear();
		DisposeQueue(mQueue);
	}

	public int SubscriberCount => mSubscribers.Count;
	public int PendingCount => mQueue.Count;

	/// An undelivered payload is still the bus's to free.
	private static void DisposeQueue(List<PendingEvent> queue)
	{
		for (var event in ref queue)
			event.Dispose();
		queue.Clear();
	}
}
