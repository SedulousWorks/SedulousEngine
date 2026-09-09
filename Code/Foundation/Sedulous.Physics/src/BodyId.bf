using System;

namespace Sedulous.Physics;

/// A handle to a body.
///
/// It is the backend's own index and sequence number, so a stale handle does not address
/// whatever took the slot: the sequence half moves on.
struct BodyId
{
	public const uint32 Invalid = 0xFFFFFFFF;

	public uint32 Value = Invalid;

	public this() {}
	public this(uint32 value) { Value = value; }

	public bool IsValid => Value != Invalid;

	[Commutable]
	public static bool operator==(BodyId a, BodyId b) => a.Value == b.Value;
}
