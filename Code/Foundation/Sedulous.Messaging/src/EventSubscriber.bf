using System;
using Sedulous.Core;

namespace Sedulous.Messaging;

/// One live subscription: which event, its handle, and what to call.
struct EventSubscriber
{
	public StringHash Name;
	public uint32 Handle;
	/// BORROWED unless Owned: the subscriber owns the delegate and keeps it alive until it
	/// unsubscribes, the same rule the shell's handlers follow. Null once unsubscribed during
	/// a delivery, until the delivery ends and the slot is swept.
	public delegate void(Variant) Callback;
	/// The bus deletes the callback as it unsubscribes (EventBus.SubscribeOwned).
	public bool Owned;

	public this(StringHash name, uint32 handle, delegate void(Variant) callback, bool owned = false)
	{
		Name = name;
		Handle = handle;
		Callback = callback;
		Owned = owned;
	}
}
