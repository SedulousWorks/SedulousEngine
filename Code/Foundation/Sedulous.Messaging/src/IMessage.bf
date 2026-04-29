namespace Sedulous.Messaging;

using System;

/// Interface that all message types must implement.
/// Messages are value types (structs) for zero-allocation dispatch.
/// Implement Dispose to clean up any heap-allocated fields (e.g., owned Strings).
/// For plain data messages, Dispose() is a no-op.
interface IMessage : IDisposable
{
}
