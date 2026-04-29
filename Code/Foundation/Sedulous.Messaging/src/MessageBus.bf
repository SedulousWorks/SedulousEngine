namespace Sedulous.Messaging;

using System;
using System.Collections;

/// Abstract message bus providing typed publish/subscribe messaging.
///
/// Generic methods (Subscribe<T>, Publish<T>, Queue<T>) are concrete because
/// Beef does not support generic virtual methods. The class is abstract to
/// establish the extension pattern — use DefaultMessageBus or a custom subclass.
///
/// Subclasses can override Drain() and Dispose() for extension points
/// (e.g., logging, profiling, thread safety).
public abstract class MessageBus : IDisposable
{
	private Dictionary<Type, ISubscriptionList> mSubscriptions = new .() ~ delete _;
	private List<IQueuedMessage> mQueue = new .() ~ delete _;
	private uint64 mNextId = 1;
	private bool mDisposed = false;

	// ==================== Subscribe ====================

	/// Subscribes a handler for messages of type T.
	/// Returns a SubscriptionHandle that can be used to unsubscribe.
	/// The bus takes ownership of the delegate.
	public SubscriptionHandle Subscribe<T>(delegate void(ref T) handler)
		where T : struct, IMessage
	{
		let type = typeof(T);
		let list = GetOrCreateList<T>(type);
		let id = mNextId++;
		list.Add(id, handler);
		return SubscriptionHandle(this, type, id);
	}

	// ==================== Unsubscribe ====================

	/// Unsubscribes using a SubscriptionHandle.
	/// Safe to call during dispatch (deferred removal).
	/// Safe to call multiple times (no-op if already removed).
	public void Unsubscribe(SubscriptionHandle handle)
	{
		if (mSubscriptions.TryGetValue(handle.MessageType, let list))
			list.Remove(handle.Id);
	}

	// ==================== Publish ====================

	/// Publishes a message immediately to all current subscribers of type T.
	/// The message is passed by reference for efficiency.
	public void Publish<T>(ref T message) where T : struct, IMessage
	{
		if (mSubscriptions.TryGetValue(typeof(T), let list))
			list.Dispatch(&message);
	}

	// ==================== Queue / Drain ====================

	/// Queues a message for deferred dispatch during the next Drain().
	/// The message value is copied into a heap-allocated wrapper.
	/// Ownership of any heap data in the message transfers to the queue.
	public void Queue<T>(T message) where T : struct, IMessage
	{
		mQueue.Add(new QueuedMessage<T>(message));
	}

	/// Drains all queued messages, dispatching each to its subscribers.
	/// Re-entrancy safe: messages queued by handlers during Drain are
	/// processed in the next Drain call, not the current one.
	public virtual void Drain()
	{
		let count = mQueue.Count;
		if (count == 0)
			return;

		for (int i = 0; i < count; i++)
		{
			let queued = mQueue[i];

			if (mSubscriptions.TryGetValue(queued.MessageType, let list))
				queued.DispatchTo(list);

			queued.DisposeMessage();
			delete queued;
		}

		mQueue.RemoveRange(0, count);
	}

	// ==================== Dispose ====================

	/// Disposes the message bus, cleaning up all subscriptions and queued messages.
	public virtual void Dispose()
	{
		if (mDisposed)
			return;
		mDisposed = true;

		for (let kv in mSubscriptions)
		{
			kv.value.Dispose();
			delete kv.value;
		}
		mSubscriptions.Clear();

		for (let queued in mQueue)
		{
			queued.DisposeMessage();
			delete queued;
		}
		mQueue.Clear();
	}

	public ~this()
	{
		Dispose();
	}

	// ==================== Internal ====================

	private SubscriptionList<T> GetOrCreateList<T>(Type type)
		where T : struct, IMessage
	{
		if (mSubscriptions.TryGetValue(type, let existing))
			return (SubscriptionList<T>)existing;

		let list = new SubscriptionList<T>();
		mSubscriptions[type] = list;
		return list;
	}
}
