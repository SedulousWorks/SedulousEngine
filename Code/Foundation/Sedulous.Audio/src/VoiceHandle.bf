using System;

namespace Sedulous.Audio;

/// A handle into the fixed voice pool, checked by GENERATION.
///
/// A slot is reused the moment its voice ends, so a bare index would silently address
/// whatever took its place. The generation is what makes a stale handle answer "no" instead.
struct VoiceHandle
{
	public const uint32 InvalidSlot = 0xFFFFFFFF;

	public uint32 Slot = InvalidSlot;
	public uint32 Generation = 0;

	public this() {}

	public this(uint32 slot, uint32 generation)
	{
		Slot = slot;
		Generation = generation;
	}

	public bool IsValid => Slot != InvalidSlot;

	/// [Commutable] so Beef derives the inequality from this one declaration; without it
	/// every use of it warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(VoiceHandle a, VoiceHandle b) =>
		(a.Slot == b.Slot) && (a.Generation == b.Generation);
}
