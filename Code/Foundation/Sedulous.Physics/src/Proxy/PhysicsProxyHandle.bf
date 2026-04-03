namespace Sedulous.Physics;

using System;

/// Handle to a physics body proxy using Index + Generation for safe references.
/// Used by the Engine integration layer to track entity-to-body mappings.
struct PhysicsProxyHandle : IEquatable<PhysicsProxyHandle>, IHashable
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

	public bool Equals(PhysicsProxyHandle other) => Index == other.Index && Generation == other.Generation;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public static bool operator ==(PhysicsProxyHandle lhs, PhysicsProxyHandle rhs) => lhs.Equals(rhs);
	public static bool operator !=(PhysicsProxyHandle lhs, PhysicsProxyHandle rhs) => !lhs.Equals(rhs);
}
