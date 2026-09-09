using System;

namespace Sedulous.Physics;

/// A handle to a character controller, which is its slot in the world's own table.
struct CharacterId
{
	public const uint32 Invalid = 0xFFFFFFFF;

	public uint32 Value = Invalid;

	public this() {}
	public this(uint32 value) { Value = value; }

	public bool IsValid => Value != Invalid;

	[Commutable]
	public static bool operator==(CharacterId a, CharacterId b) => a.Value == b.Value;
}
