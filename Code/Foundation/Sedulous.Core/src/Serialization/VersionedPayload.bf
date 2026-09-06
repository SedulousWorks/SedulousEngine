using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Brackets a payload whose layout may evolve.
static
{
	/// A chain longer than this is not a chain, it is a corrupt length being trusted.
	/// Raptor reads the first sixteen and leaves the rest in the stream, which desyncs
	/// everything after it; failing outright says so instead.
	private const uint32 cMaxChainLength = 64;

	/// Writes the version chain the payload carries and pushes it as the active scope, so
	/// the body between here and EndVersionedPayload sees the version its DATA was written
	/// with rather than the version this build declares.
	///
	/// Writing emits what the type declares. Reading takes whatever the stream stored, so
	/// a body can branch: if (ar.Version >= 2) read the field that version two added.
	public static void BeginVersionedPayload(ISerializer ar, Span<SerializedDataVersion> declared)
	{
		let chain = scope List<SerializedDataVersion>();
		uint32 count = 0;

		if (ar.Mode == .Write)
		{
			count = (uint32)declared.Length;
			for (let entry in declared)
				chain.Add(entry);
		}

		ar.Key("dataVersions");
		ar.BeginArray(ref count);

		if (ar.Mode == .Read)
		{
			if (count > cMaxChainLength)
			{
				// The stream is desynced from here on whatever we do, so say so and stop
				// rather than allocating whatever the count happened to be.
				ar.FailPayload(.OutOfRange);
				ar.EndArray();
				ar.PushVersionScope(.());
				return;
			}
			chain.Resize((int)count);
		}

		for (int i < (int)count)
		{
			ar.Key("type");
			ar.Scalar(&chain[i].TypeId, .UInt64);
			ar.Key("version");
			ar.Scalar(&chain[i].Version, .UInt32);
		}

		ar.EndArray();
		// Copied into the serializer's own stack, so the local chain can go.
		ar.PushVersionScope(chain);
	}

	/// One type's own version, which is the common case: no versioned bases.
	public static void BeginVersionedPayload(ISerializer ar, uint64 typeId, uint32 version)
	{
		SerializedDataVersion[1] one = .(.(typeId, version));
		BeginVersionedPayload(ar, .(&one[0], 1));
	}

	public static void EndVersionedPayload(ISerializer ar) => ar.PopVersionScope();
}
