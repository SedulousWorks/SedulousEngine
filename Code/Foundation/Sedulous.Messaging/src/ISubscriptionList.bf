namespace Sedulous.Messaging;

using System;

/// Type-erased interface for subscription lists.
/// Allows MessageBus to store heterogeneous lists in a Dictionary<Type, ISubscriptionList>
/// and dispatch/remove without knowing the concrete message type.
interface ISubscriptionList : IDisposable
{
	/// Dispatches a message to all subscribers.
	/// messagePtr points to a T value on the stack or in a QueuedMessage.
	void Dispatch(void* messagePtr);

	/// Removes a subscription by ID.
	/// Returns true if found and removed.
	bool Remove(uint64 id);
}
