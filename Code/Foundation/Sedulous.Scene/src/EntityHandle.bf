using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A light, copyable reference to an entity: a pool index and a generation counter.
///
/// The GENERATION is what makes a stale handle, one whose slot was destroyed and reused,
/// detectable in O(1) with no lookup table at all. Never keep a raw pointer to entity or
/// component data: the pools move, handles do not. Hold a handle and resolve it through
/// the scene.
[Scriptable]
struct EntityHandle : IHashable
{
	public const uint32 cInvalidIndex = 0xFFFFFFFF;

	public uint32 Index = cInvalidIndex;
	public uint32 Generation = 0;

	public this() {}

	public this(uint32 index, uint32 generation)
	{
		Index = index;
		Generation = generation;
	}

	[Scriptable]
	public static EntityHandle Invalid => .();

	/// Whether this handle was ever assigned. NOT whether it is still valid in a scene,
	/// which is Scene.IsValid's question.
	[Scriptable]
	public bool IsAssigned => Index != cInvalidIndex;

	[Commutable]
	public static bool operator==(EntityHandle a, EntityHandle b)
		=> (a.Index == b.Index) && (a.Generation == b.Generation);

	public int GetHashCode() => (int)(((uint64)Index << 32) | Generation);
}
