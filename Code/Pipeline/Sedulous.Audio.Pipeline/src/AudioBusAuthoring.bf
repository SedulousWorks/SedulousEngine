using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Pipeline;

/// One bus as the inspector edits it: FLAT fields rather than an effect list.
///
/// Flat so the generic property page can edit it without an array editor. The builder folds
/// these into the wire's generic effect chain, in the order lowpass, highpass, delay, reverb,
/// skipping whichever are off.
[Serializable]
class AudioBusAuthoring
{
	public float Volume = 1.0f;
	public bool Muted = false;

	/// Nought turns each of these off.
	public float LowpassHz = 0.0f;
	public float HighpassHz = 0.0f;
	public float DelaySeconds = 0.0f;
	public float DelayDecay = 0.3f;
	public float ReverbWet = 0.0f;

	public float ReverbRoomSize = 0.6f;
	public float ReverbDamping = 0.4f;
}
