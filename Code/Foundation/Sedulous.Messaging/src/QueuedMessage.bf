namespace Sedulous.Messaging;

using System;

/// Wraps a message value of type T for deferred dispatch.
/// Created by MessageBus.Queue<T>(), consumed by MessageBus.Drain().
class QueuedMessage<T> : IQueuedMessage where T : struct, IMessage
{
	private T mMessage;

	public Type MessageType => typeof(T);

	public this(T message)
	{
		mMessage = message;
	}

	/// Dispatches the stored message to the subscription list.
	public void DispatchTo(ISubscriptionList list)
	{
		list.Dispatch(&mMessage);
	}

	/// Disposes the stored message value, cleaning up any owned resources.
	public void DisposeMessage()
	{
		mMessage.Dispose();
	}
}
