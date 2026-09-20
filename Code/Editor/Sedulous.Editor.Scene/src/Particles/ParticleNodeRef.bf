using System;

namespace Sedulous.Editor.Scene;

/// A tree row by what it stands for rather than its id, so a selection survives a rebuild.
struct ParticleNodeRef : IEquatable<ParticleNodeRef>, IHashable
{
	public ParticleNodeKind Kind = .Effect;
	/// The owning system; -1 for the effect root.
	public int32 SystemIndex = -1;
	/// The initializer or behavior index within the system; -1 for anything else.
	public int32 ModuleIndex = -1;

	public this() {}

	public this(ParticleNodeKind kind, int32 systemIndex, int32 moduleIndex)
	{
		Kind = kind;
		SystemIndex = systemIndex;
		ModuleIndex = moduleIndex;
	}

	public static ParticleNodeRef Root => .(.Effect, -1, -1);

	public bool Equals(ParticleNodeRef other) => (Kind == other.Kind) && (SystemIndex == other.SystemIndex) && (ModuleIndex == other.ModuleIndex);
	public int GetHashCode() => ((int)Kind * 7919) ^ (SystemIndex * 31) ^ ModuleIndex;

	[Commutable]
	public static bool operator==(ParticleNodeRef a, ParticleNodeRef b) => a.Equals(b);
}
