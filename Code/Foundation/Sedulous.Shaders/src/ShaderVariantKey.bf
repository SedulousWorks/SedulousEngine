using System;

namespace Sedulous.Shaders;

/// Identifies one compiled permutation of a named shader.
///
/// The name is held as a HASH rather than a string so the key is small, copyable and
/// hashable without owning anything, which is what lets it sit in a map alongside a
/// module pointer.
struct ShaderVariantKey : IHashable, IEquatable<ShaderVariantKey>
{
	public uint64 NameHash = 0;
	public ShaderStage Stage = .Vertex;
	public ShaderFlags Flags = .None;

	public this() {}

	public this(uint64 nameHash, ShaderStage stage, ShaderFlags flags)
	{
		NameHash = nameHash;
		Stage = stage;
		Flags = flags;
	}

	public int GetHashCode()
	{
		var hash = (int)(NameHash ^ (NameHash >> 32));
		hash = hash &* 31 &+ (int)Stage;
		hash = hash &* 31 &+ (int)Flags;
		return hash;
	}

	public bool Equals(ShaderVariantKey other)
		=> (NameHash == other.NameHash) && (Stage == other.Stage) && (Flags == other.Flags);

	[Commutable]
	public static bool operator==(ShaderVariantKey a, ShaderVariantKey b) => a.Equals(b);
}
