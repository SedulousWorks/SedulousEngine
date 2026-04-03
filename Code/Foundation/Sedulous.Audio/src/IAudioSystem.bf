using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Audio;

/// Main audio system interface providing clip loading, source management, and 3D audio.
interface IAudioSystem : IDisposable
{
	/// Returns true if the audio system initialized successfully.
	bool IsInitialized { get; }

	/// Gets the 3D audio listener.
	IAudioListener Listener { get; }

	/// Gets or sets the master volume affecting all audio (0.0 to 1.0).
	float MasterVolume { get; set; }

	/// Creates a new audio source for controlled playback.
	IAudioSource CreateSource();

	/// Destroys an audio source, stopping any playing audio and freeing resources.
	void DestroySource(IAudioSource source);

	/// Plays an audio clip with fire-and-forget semantics (no source management needed).
	void PlayOneShot(AudioClip clip, float volume = 1.0f);

	/// Plays an audio clip at a 3D position with fire-and-forget semantics.
	void PlayOneShot3D(AudioClip clip, Vector3 position, float volume = 1.0f);

	/// Loads an audio clip from raw audio file data (WAV format).
	Result<AudioClip> LoadClip(Span<uint8> data);

	/// Opens an audio stream from a file path for streaming playback.
	/// Use this for music and long audio files that shouldn't be loaded entirely into memory.
	Result<IAudioStream> OpenStream(StringView filePath);

	/// Pauses all audio playback.
	void PauseAll();

	/// Resumes all audio playback.
	void ResumeAll();

	/// Updates the audio system, processing 3D spatialization and cleaning up finished one-shots.
	/// Should be called once per frame.
	void Update();
}
