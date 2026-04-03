namespace Sedulous.Physics;

using System;

/// Handle to a physics constraint.
/// Uses Index + Generation pattern for safe references.
struct ConstraintHandle : IEquatable<ConstraintHandle>, IHashable
{
	public uint32 Index;
	public uint32 Generation;

	/// Invalid constraint handle.
	public static readonly Self Invalid = .((uint32)-1, 0);

	/// Creates a new constraint handle.
	public this(uint32 index, uint32 generation)
	{
		Index = index;
		Generation = generation;
	}

	/// Returns true if this handle is potentially valid.
	public bool IsValid => Index != (uint32)-1;

	public bool Equals(ConstraintHandle other)
	{
		return Index == other.Index && Generation == other.Generation;
	}

	public int GetHashCode()
	{
		return (int)(Index ^ (Generation << 16));
	}

	public static bool operator==(ConstraintHandle a, ConstraintHandle b)
	{
		return a.Equals(b);
	}

	public static bool operator!=(ConstraintHandle a, ConstraintHandle b)
	{
		return !a.Equals(b);
	}
}
