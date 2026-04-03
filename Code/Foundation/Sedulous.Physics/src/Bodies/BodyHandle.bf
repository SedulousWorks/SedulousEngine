namespace Sedulous.Physics;

using System;

/// Handle to a physics body using Index + Generation for safe references.
/// Generation counter prevents stale reference bugs when slots are reused.
struct BodyHandle : IEquatable<BodyHandle>, IHashable
{
	public uint32 Index;
	public uint32 Generation;

	public static readonly Self Invalid = .((uint32)-1, 0);

	public this(uint32 index, uint32 generation)
	{
		Index = index;
		Generation = generation;
	}

	public bool IsValid => Index != (uint32)-1;

	public bool Equals(BodyHandle other) => Index == other.Index && Generation == other.Generation;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public static bool operator ==(BodyHandle lhs, BodyHandle rhs) => lhs.Equals(rhs);
	public static bool operator !=(BodyHandle lhs, BodyHandle rhs) => !lhs.Equals(rhs);
}
