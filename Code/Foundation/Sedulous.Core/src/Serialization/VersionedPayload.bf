using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Brackets a payload stamped with its type's data version.
///
/// ONE supported layout per type by default: the current one. A payload written under any
/// other version is refused, not migrated. The one allowance is a type that keeps a LEGACY
/// READER, which names the oldest concrete version it still understands; the scope then
/// reports the STORED version so its body can branch on it.
static
{
	/// A chain longer than this is not a chain, it is a corrupt length being trusted.
	/// Reading the first sixteen and leaving the rest in the stream would desync
	/// everything after it; failing outright says so instead.
	private const uint32 cMaxChainLength = 64;

	/// Writes the version chain the payload carries and pushes it as the active scope, so
	/// the body between here and EndVersionedPayload sees the version its DATA was written
	/// with rather than the version this build declares.
	///
	/// Writing emits what the type declares. Reading takes whatever the stream stored and
	/// REFUSES anything but the declared chain, so a body reads one layout: the scope is
	/// what the data said rather than what this build assumed, and a mismatch has already
	/// failed the payload by the time the body runs.
	/// `minReadVersion` is the oldest CONCRETE version a legacy reader still accepts, nought
	/// meaning the current one alone. Only the first entry, the concrete type's, is relaxed:
	/// a base in the chain stays exact, since nothing branches on a base's version.
	public static void BeginVersionedPayload(ISerializer ar, Span<SerializedDataVersion> declared,
		uint32 minReadVersion = 0)
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

		// ONE supported layout per type, unless a legacy reader says otherwise.
		//
		// A stored chain that differs in any way, its length, a type id or a version, is
		// REFUSED rather than guessed at: a reader that assumed an older layout would decode
		// the wrong fields and hand back a value that looks plausible, which is worse than
		// saying no. The exception is a version at or above `minReadVersion` in the concrete
		// slot, which a type with a legacy reader has declared it can still decode.
		if (ar.Mode == .Read)
		{
			var matches = (int)count == declared.Length;
			for (int i = 0; matches && (i < (int)count); i++)
			{
				let legacy = (i == 0) && (minReadVersion != 0)
					&& (chain[i].Version >= minReadVersion)
					&& (chain[i].Version < declared[i].Version);
				matches = (chain[i].TypeId == declared[i].TypeId)
					&& ((chain[i].Version == declared[i].Version) || legacy);
			}
			if (!matches)
				ar.FailPayload(.NotSupported);
		}

		// Copied into the serializer's own stack, so the local chain can go.
		ar.PushVersionScope(chain);
	}

	/// One type's own version, which is the common case: no versioned bases.
	public static void BeginVersionedPayload(ISerializer ar, uint64 typeId, uint32 version,
		uint32 minReadVersion = 0)
	{
		SerializedDataVersion[1] one = .(.(typeId, version));
		BeginVersionedPayload(ar, .(&one[0], 1), minReadVersion);
	}

	public static void EndVersionedPayload(ISerializer ar) => ar.PopVersionScope();
}
