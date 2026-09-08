using System;
using Sedulous.Core;

namespace Sedulous.Messaging;

/// A published event waiting for the next drain.
struct PendingEvent : IDisposable
{
	public StringHash Name;
	/// OWNED by the queue: a payload has to outlive the Publish call that made it, so the
	/// bus takes it and disposes it once delivered.
	public Variant Payload;

	public this(StringHash name, Variant payload)
	{
		Name = name;
		Payload = payload;
	}

	public void Dispose() mut => Payload.Dispose();
}
