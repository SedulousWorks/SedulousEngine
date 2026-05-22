namespace Sedulous.Audio;

using System;

/// Opaque handle returned by `IAudioSystem.PlayOneShot` / `PlayCue` (and
/// their 3D variants). Lets a caller stop the specific playback it
/// started without affecting other audio.
///
/// Internally a (slot, generation) pair: the audio backend keeps a pool
/// of one-shot source slots, and bumps each slot's generation when it's
/// reused. `Stop(handle)` validates that the slot still belongs to this
/// handle's generation before acting, so a handle to a one-shot that
/// has since finished (and had its slot recycled by a later PlayCue)
/// is silently a no-op rather than stopping someone else's audio.
///
/// `Invalid` is the default-constructed value (slot=0, generation=0).
/// A handle whose generation is 0 is always treated as invalid - real
/// generations start at 1.
[CRepr]
public struct AudioPlaybackHandle : IHashable
{
	/// Index into the backend's one-shot source pool. Meaningful only
	/// in combination with `Generation`.
	public uint32 Slot;

	/// Monotonic counter bumped each time the backend reuses this slot.
	/// Zero means "never assigned" - i.e. the handle is invalid.
	public uint32 Generation;

	public static readonly AudioPlaybackHandle Invalid = .() { Slot = 0, Generation = 0 };

	public bool IsValid => Generation != 0;

	public int GetHashCode()
	{
		return (int)((Slot * 397) ^ Generation);
	}

	public static bool operator ==(Self a, Self b) =>
		a.Slot == b.Slot && a.Generation == b.Generation;
}
