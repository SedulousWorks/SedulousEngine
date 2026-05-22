using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Audio;

/// Main audio system interface providing clip loading, source management, and 3D audio.
interface IAudioSystem : IDisposable
{
	/// Returns true if the audio system initialized successfully.
	bool IsInitialized { get; }

	/// Gets the 3D audio listener.
	AudioListener Listener { get; }

	/// Gets or sets the master volume affecting all audio (0.0 to 1.0).
	float MasterVolume { get; set; }

	/// Gets the bus system for routing audio through named buses.
	/// Returns null if the backend doesn't support buses.
	IAudioBusSystem BusSystem { get; }

	/// Creates a new audio source for controlled playback.
	IAudioSource CreateSource();

	/// Destroys an audio source, stopping any playing audio and freeing resources.
	void DestroySource(IAudioSource source);

	/// Plays an audio clip with fire-and-forget semantics (no source management needed).
	/// Returns a handle that callers can pass to `Stop` if they later want to
	/// cancel this specific playback; fire-and-forget callers ignore it.
	AudioPlaybackHandle PlayOneShot(AudioClip clip, float volume = 1.0f);

	/// Plays an audio clip at a 3D position with fire-and-forget semantics.
	AudioPlaybackHandle PlayOneShot3D(AudioClip clip, Vector3 position, float volume = 1.0f);

	/// Loads an audio clip from raw audio file data (WAV format).
	Result<AudioClip> LoadClip(Span<uint8> data);

	/// Opens an audio stream from a file path for streaming playback.
	/// Use this for music and long audio files that shouldn't be loaded entirely into memory.
	Result<IAudioStream> OpenStream(StringView filePath);

	/// Plays a sound cue with fire-and-forget semantics.
	/// Selects an entry, applies randomization, routes to the cue's bus.
	/// Returns a handle that callers can pass to `Stop` to cancel this
	/// specific playback; fire-and-forget callers ignore it.
	AudioPlaybackHandle PlayCue(SoundCue cue, float volume = 1.0f);

	/// Plays a sound cue at a 3D position with fire-and-forget semantics.
	AudioPlaybackHandle PlayCue3D(SoundCue cue, Vector3 position, float volume = 1.0f);

	/// Pauses all audio playback.
	void PauseAll();

	/// Resumes all audio playback.
	void ResumeAll();

	/// Stops every active source - both long-lived sources created via
	/// CreateSource and fire-and-forget one-shots from PlayOneShot /
	/// PlayCue. After this returns, no graph nodes are reading clip
	/// samples and the audio thread emits silence. Useful before
	/// teardown sequences that free the AudioClips the graph was
	/// referencing.
	void StopAll();

	/// Stops the specific one-shot playback identified by `handle`.
	/// Silently no-ops when the handle has already expired (the slot
	/// has been recycled for another playback) or was never valid.
	void Stop(AudioPlaybackHandle handle);

	/// Returns true if the one-shot identified by `handle` is still
	/// playing. False after natural completion, after a Stop call, or
	/// for an expired/invalid handle.
	bool IsPlaying(AudioPlaybackHandle handle);

	/// Updates the audio system, processing 3D spatialization and cleaning up finished one-shots.
	/// Should be called once per frame.
	void Update();
}
