namespace Sedulous.Physics;

using System;

/// Handle to a physics shape using Index + Generation for safe references.
/// Shapes can be shared between multiple bodies.
struct ShapeHandle : IEquatable<ShapeHandle>, IHashable
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

	public bool Equals(ShapeHandle other) => Index == other.Index && Generation == other.Generation;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public static bool operator ==(ShapeHandle lhs, ShapeHandle rhs) => lhs.Equals(rhs);
	public static bool operator !=(ShapeHandle lhs, ShapeHandle rhs) => !lhs.Equals(rhs);
}
