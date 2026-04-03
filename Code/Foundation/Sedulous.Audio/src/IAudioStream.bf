using System;

namespace Sedulous.Audio;

/// Interface for streaming audio playback (music, long audio files).
/// Unlike IAudioClip which loads entire audio into memory, streams read data on-demand.
interface IAudioStream : IDisposable
{
	/// Gets the total duration of the audio stream in seconds.
	float Duration { get; }

	/// Gets the current playback position in seconds.
	float Position { get; }

	/// Gets the sample rate of the audio stream (e.g., 44100).
	int32 SampleRate { get; }

	/// Gets the number of channels (1 = mono, 2 = stereo).
	int32 Channels { get; }

	/// Gets whether the stream is ready for playback.
	bool IsReady { get; }

	/// Gets the current playback state.
	AudioSourceState State { get; }

	/// Gets or sets the volume level (0.0 to 1.0).
	float Volume { get; set; }

	/// Gets or sets whether the stream should loop when playback completes.
	bool Loop { get; set; }

	/// Starts or restarts playback from the beginning.
	void Play();

	/// Pauses playback at the current position.
	void Pause();

	/// Resumes playback from the paused position.
	void Resume();

	/// Stops playback and resets to the beginning.
	void Stop();

	/// Seeks to a specific position in seconds.
	void Seek(float position);
}
