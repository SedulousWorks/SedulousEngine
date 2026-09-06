using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Serialization;

/// Owns a serializer and whatever intermediate state has to outlive it.
///
/// A binary backend writes straight to the stream and needs none. A text backend builds a
/// document first, so something has to hold that document for as long as the serializer
/// refers to it, and flush it when the writing is done.
abstract class SerializerContext
{
	/// The serializer to use. Owned by this context and destroyed with it.
	public abstract Serializer Serializer { get; }

	/// Called after a write is complete, to push whatever was built to the stream. A
	/// backend that wrote as it went does nothing here.
	public virtual void Flush(IStream output)
	{
	}
}
