namespace Sedulous.Engine.Core;

using System;

/// Lightweight handle to a component in a ComponentManager pool.
/// Contains an index into the pool and a generation counter for validation.
public struct ComponentHandle<T> : IHashable, IEquatable<ComponentHandle<T>> where T : Component
{
	public uint32 Index;
	public uint32 Generation;

	/// An invalid handle (default).
	public static readonly ComponentHandle<T> Invalid = .() { Index = uint32.MaxValue, Generation = 0 };

	/// Whether this handle has been assigned (not necessarily still valid).
	public bool IsAssigned => Index != uint32.MaxValue;

	public int GetHashCode()
	{
		return (int)(Index * 2654435761) ^ (int)(Generation * 2246822519);
	}

	public bool Equals(ComponentHandle<T> other)
	{
		return Index == other.Index && Generation == other.Generation;
	}

	public static bool operator ==(ComponentHandle<T> a, ComponentHandle<T> b)
	{
		return a.Index == b.Index && a.Generation == b.Generation;
	}

	public static bool operator !=(ComponentHandle<T> a, ComponentHandle<T> b)
	{
		return !(a == b);
	}
}
