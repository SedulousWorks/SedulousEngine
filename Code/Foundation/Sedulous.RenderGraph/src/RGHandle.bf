using System;

namespace Sedulous.RenderGraph;

/// A handle to a graph resource, either a texture or a buffer.
///
/// GENERATION CHECKED: the index alone would go stale the moment a slot is reused between
/// frames, and a stale handle then names whatever took its place.
struct RGHandle
{
	public const uint32 InvalidIndex = 0xFFFFFFFF;

	public uint32 Index = InvalidIndex;
	public uint32 Generation = 0;

	public this() {}

	public this(uint32 index, uint32 generation)
	{
		Index = index;
		Generation = generation;
	}

	public static RGHandle Invalid => .();

	public bool IsValid => Index != InvalidIndex;

	/// [Commutable] so Beef derives the inequality from this one declaration. Without it
	/// every use of it warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(RGHandle a, RGHandle b) =>
		(a.Index == b.Index) && (a.Generation == b.Generation);
}
