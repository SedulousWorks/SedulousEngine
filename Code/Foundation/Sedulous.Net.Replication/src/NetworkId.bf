using System;

namespace Sedulous.Net.Replication;

/// A stable, server assigned handle for a replicated entity. Wire carried; nought is
/// unassigned.
///
/// Distinct from EntityHandle, which is an index and generation and is process local, and
/// from the persisted Guid, which is disk identity. NetworkId is the compact id peers agree
/// on for the lifetime of a networked entity.
struct NetworkId : IHashable
{
	public uint32 Value = 0;

	public this() {}
	public this(uint32 value)
	{
		Value = value;
	}

	public static NetworkId Invalid => .(0);
	public bool IsValid => Value != 0;

	public int GetHashCode() => (int)Value;

	[Commutable]
	public static bool operator==(NetworkId a, NetworkId b) => a.Value == b.Value;
}
