using System;

namespace Sedulous.Physics;

/// A handle to a joint, which is its slot in the world's own table.
struct JointId
{
	public const uint32 Invalid = 0xFFFFFFFF;

	public uint32 Value = Invalid;

	public this() {}
	public this(uint32 value) { Value = value; }

	public bool IsValid => Value != Invalid;

	[Commutable]
	public static bool operator==(JointId a, JointId b) => a.Value == b.Value;
}
