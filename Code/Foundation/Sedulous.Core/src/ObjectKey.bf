namespace Sedulous.Core;

using System;

/// Hashable + equatable identity key for a reference-typed object.
///
/// Wraps a class reference so it can be used as a Dictionary key without the
/// wrapped class itself having to implement IHashable / IEquatable. Keys are
/// equal iff they refer to the same object instance (pointer identity).
///
/// Usage:
///   Dictionary&lt;ObjectKey&lt;ITextureView&gt;, MaterialInstance&gt; cache = ...;
///   cache[.(textureView)] = instance;
public struct ObjectKey<T> : IHashable, IEquatable<ObjectKey<T>> where T : class
{
	private readonly int mPtr;

	public this(T obj)
	{
		mPtr = (int)(void*)Internal.UnsafeCastToPtr(obj);
	}

	public int GetHashCode() => mPtr;

	public bool Equals(ObjectKey<T> other) => mPtr == other.mPtr;

	public static bool operator ==(ObjectKey<T> a, ObjectKey<T> b) => a.mPtr == b.mPtr;
	public static bool operator !=(ObjectKey<T> a, ObjectKey<T> b) => a.mPtr != b.mPtr;
}
