using System;

namespace Sedulous.Resources;

/// Identifies a resource type by a hash of its name (e.g. "texture", "shader", "model").
struct ResourceType : IEquatable<ResourceType>, IHashable
{
	public uint64 Value;

	public this(uint64 value)
	{
		Value = value;
	}

	/// Create a ResourceType from a type name string.
	public this(StringView name)
	{
		Value = HashName(name);
	}

	public bool IsValid => Value != 0;

	public static readonly ResourceType Invalid = .(0);

	public bool Equals(ResourceType other) => Value == other.Value;
	public int GetHashCode() => (int)Value;

	public static bool operator ==(ResourceType lhs, ResourceType rhs) => lhs.Value == rhs.Value;
	public static bool operator !=(ResourceType lhs, ResourceType rhs) => lhs.Value != rhs.Value;

	/// Simple FNV-1a hash for type name strings.
	private static uint64 HashName(StringView name)
	{
		uint64 hash = 14695981039346656037UL;
		for (let c in name.RawChars)
		{
			hash ^= (uint64)c;
			hash *= 1099511628211UL;
		}
		return hash;
	}
}