using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Replication;

/// The small shared wire helpers: the component type tag, the prefab Guid, the entity record
/// flags, and the baseline key hash.
static class ReplicationWire
{
	/// Entity record flags, shared by the snapshot and delta payloads.
	public const uint8 cFlagRemoved = 1 << 0;
	/// First delivery to this peer: a prefab Guid follows.
	public const uint8 cFlagSpawn = 1 << 1;

	/// Length prefixed UTF-8, for the component's SerializationTypeId.
	public static void WriteString(BitWriter writer, StringView text)
	{
		writer.WriteVarU32((uint32)text.Length);
		writer.WriteBytes(.((uint8*)text.Ptr, text.Length));
	}

	public static void ReadString(BitReader reader, String outText)
	{
		outText.Clear();
		let count = reader.ReadVarU32();
		if ((count == 0) || !reader.Ok)
			return;

		let bytes = scope uint8[(int)count];
		reader.ReadBytes(bytes);
		outText.Append(StringView((char8*)&bytes[0], (int)count));
	}

	/// The 16 raw bytes. DIVERGES from Raptor, which writes two u64 halves, because Beef's
	/// Guid does not expose them; the byte count and the round trip are the same.
	public static void WriteGuid(BitWriter writer, Guid value)
	{
		var value;
		writer.WriteBytes(.((uint8*)&value, sizeof(Guid)));
	}

	public static Guid ReadGuid(BitReader reader)
	{
		Guid value = default;
		reader.ReadBytes(.((uint8*)&value, sizeof(Guid)));
		return value;
	}

	/// FNV-1a over the component's on disk type id: the delta baseline key.
	public static uint32 HashTypeId(StringView text)
	{
		// Cast, not a `u` suffix: `2166136261u` is pointer sized `uint` in Beef, not uint32.
		var hash = (uint32)2166136261;
		for (int i < text.Length)
		{
			// Wrapping, because FNV overflows by design and Beef's plain operators trap.
			hash ^= (uint32)(uint8)text[i];
			hash &*= (uint32)16777619;
		}
		return hash;
	}

	/// A stable NetworkId derived from an entity's authored Guid. Both peers load the SAME
	/// scene, so they compute the SAME id for the same entity with no hand authored ids.
	/// Never nought, which stays "unassigned".
	public static NetworkId DeterministicNetworkId(Guid id)
	{
		var id;
		let halves = (uint64*)&id;
		var hash = halves[0] ^ (halves[1] &* (uint64)0x9E3779B97F4A7C15);
		hash ^= hash >> 32;
		let value = (uint32)hash;
		return .((value == 0) ? 1 : value);
	}
}
