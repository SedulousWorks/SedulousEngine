namespace Sedulous.Scenes;

using System;

/// Lightweight handle to an entity in a scene.
/// Contains an index into the entity pool and a generation counter for validation.
/// Never store direct pointers to entities - always use handles and resolve through Scene.
public struct EntityHandle : IHashable, IEquatable<EntityHandle>
{
	public uint32 Index;
	public uint32 Generation;

	/// An invalid handle (default).
	public static readonly EntityHandle Invalid = .() { Index = uint32.MaxValue, Generation = 0 };

	/// Whether this handle has been assigned (not necessarily still valid in the scene).
	public bool IsAssigned => Index != uint32.MaxValue;

	public int GetHashCode()
	{
		return (int)(Index * 2654435761u) ^ (int)(Generation * 2246822519u);
	}

	public bool Equals(EntityHandle other)
	{
		return Index == other.Index && Generation == other.Generation;
	}

	public static bool operator ==(EntityHandle a, EntityHandle b)
	{
		return a.Index == b.Index && a.Generation == b.Generation;
	}

	public static bool operator !=(EntityHandle a, EntityHandle b)
	{
		return !(a == b);
	}
}
