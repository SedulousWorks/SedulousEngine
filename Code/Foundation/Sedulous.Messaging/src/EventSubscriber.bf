using System;
using Sedulous.Core;

namespace Sedulous.Messaging;

/// One live subscription: which event, its handle, and what to call.
struct EventSubscriber
{
	public StringHash Name;
	public uint32 Handle;
	/// BORROWED. The subscriber owns the delegate and keeps it alive until it
	/// unsubscribes, the same rule the shell's handlers follow.
	public delegate void(Variant) Callback;
	/// Unsubscribed during a drain: it hears nothing more and leaves the list between events.
	public bool Dead;
	/// Handed to the bus by its unsubscribe: the bus deletes the callback when the entry leaves.
	public bool DeleteCallback;

	public this(StringHash name, uint32 handle, delegate void(Variant) callback)
	{
		Name = name;
		Handle = handle;
		Callback = callback;
		Dead = false;
		DeleteCallback = false;
	}
}
