using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// The serialization contract: mode aware, format agnostic.
///
/// One Serialize body runs either direction, and the interface speaks in intent, meaning
/// typed scalars, named fields and structured scopes, rather than in bytes. That is what
/// lets a positional binary backend and a keyed text backend implement the same thing.
///
/// Backends extend Serializer rather than implementing this directly, since Serializer
/// supplies the no-op defaults for the naming and scope operations an unkeyed format
/// ignores.
interface ISerializer
{
	SerializeMode Mode { get; }

	/// The version the CURRENT payload's data carries, for its concrete type.
	uint32 Version { get; }
	/// The version the current payload's data carries for one type in its chain, or zero
	/// when that type is absent. Unversioned data reads as zero.
	uint32 VersionOf(uint64 typeId);
	void PushVersionScope(Span<SerializedDataVersion> chain);
	void PopVersionScope();

	/// Names the next value within the current object. Unkeyed formats ignore it.
	void Key(StringView name);

	void BeginObject();
	void EndObject();
	/// Moves the element count: written on write, read on read.
	void BeginArray(ref uint32 count);
	void EndArray();

	/// Moves one typed scalar between memory and the backing store.
	void Scalar(void* value, ScalarKind kind);
	/// Moves a string. First class, so a text format can store it natively.
	void Text(String value);
	/// Moves an opaque blob: raw in binary, encoded in text.
	void Blob(void* data, int size);

	/// Fails the whole payload. A Serialize body that reads structurally invalid data, a
	/// cross-field invariant a positional format cannot express, calls this so corrupt
	/// data loads loudly rather than silently.
	void FailPayload(ErrorCode code);
	bool IsPayloadOk { get; }

	/// Captures on read, or re-injects on write, the current framed region's remaining
	/// content verbatim, so a payload whose type this build cannot instantiate survives a
	/// round trip. False where an unknown region cannot be preserved.
	bool RawRemainder(List<uint8> blob);
}
