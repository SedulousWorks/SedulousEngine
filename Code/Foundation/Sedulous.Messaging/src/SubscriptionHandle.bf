namespace Sedulous.Messaging;

using System;

/// Handle returned by MessageBus.Subscribe, used to unsubscribe.
/// Implements IDisposable for RAII-style auto-unsubscribe.
///
/// Usage:
///   let handle = bus.Subscribe<MyMessage>(new => OnMyMessage);
///   // Later:
///   handle.Dispose();       // explicit unsubscribe
///   bus.Unsubscribe(handle); // equivalent
struct SubscriptionHandle : IDisposable
{
	private MessageBus mBus;
	private Type mMessageType;
	private uint64 mId;

	/// The message type this subscription is for.
	public Type MessageType => mMessageType;

	/// The unique subscription ID.
	public uint64 Id => mId;

	public this(MessageBus bus, Type messageType, uint64 id)
	{
		mBus = bus;
		mMessageType = messageType;
		mId = id;
	}

	/// Unsubscribes from the message bus. Safe to call multiple times.
	public void Dispose() mut
	{
		if (mBus != null)
		{
			mBus.Unsubscribe(this);
			mBus = null;
		}
	}
}
