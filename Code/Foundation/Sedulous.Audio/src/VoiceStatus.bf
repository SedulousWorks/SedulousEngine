using System;
using Sedulous.Core;

namespace Sedulous.Audio;

/// A snapshot of one voice, for the tools and the tests: the state machine is observable
/// rather than inferred from what can be heard.
struct VoiceStatus
{
	/// Whether the slot is owned by the generation that was asked about.
	public bool Active = false;
	/// Audible and advancing: not paused, and not fading out.
	public bool Playing = false;
	public bool Paused = false;
	/// A fade to stop is in flight.
	public bool Stopping = false;
	public bool Spatial = false;

	public float Volume = 1.0f;
	public float Pitch = 1.0f;
	public AudioBus Bus = .Effects;

	/// The custom bus this routes through, empty for the fixed one. BORROWED from the voice,
	/// so it is valid until the next call that changes its routing.
	public StringView BusName = default;

	public uint8 Priority = 0;
	public Float3 Position = .(0, 0, 0);

	/// The cutoff currently applied by the distance filter. Nought means no filter at all.
	public float LowpassCutoffHz = 0.0f;

	/// The TRUE cursor, in seconds into the clip's own data, read from the voice rather than
	/// counted up from elapsed time: it honours the pitch, the pauses and the loop wraps,
	/// none of which a stopwatch would.
	public float CursorSeconds = 0.0f;

	/// The send level. Nought means no splitter in the chain.
	public float ReverbSend = 0.0f;

	public this() {}
}
