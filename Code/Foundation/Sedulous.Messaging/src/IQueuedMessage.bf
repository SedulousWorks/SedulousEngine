namespace Sedulous.Messaging;

using System;

/// Type-erased interface for queued messages.
/// Allows the message queue to store messages of different types
/// and dispatch them without generics.
interface IQueuedMessage
{
	/// Gets the runtime Type of the message.
	Type MessageType { get; }

	/// Dispatches this message to the given subscription list.
	void DispatchTo(ISubscriptionList list);

	/// Disposes the stored message value, cleaning up any owned resources.
	void DisposeMessage();
}
