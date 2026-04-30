namespace Sedulous.Audio;

using System;

/// Interface for audio effects that process float32 stereo interleaved buffers in-place.
/// Each effect object is a self-contained instance with its own state.
interface IAudioEffect : IDisposable
{
	/// Human-readable name for debugging/UI.
	StringView Name { get; }

	/// Whether the effect is currently active. Disabled effects are bypassed.
	bool Enabled { get; set; }

	/// Processes audio samples in-place.
	/// buffer: interleaved float32 stereo samples (L,R,L,R,...).
	/// frameCount: number of stereo frames.
	/// sampleRate: current mix sample rate.
	void Process(float* buffer, int32 frameCount, int32 sampleRate);

	/// Resets internal state (delay lines, filter history, etc.).
	void Reset();
}
