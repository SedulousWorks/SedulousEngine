using Sedulous.Core.Mathematics;

namespace Sedulous.Audio;

/// Interface for an audio playback source with volume, pitch, and 3D positioning controls.
interface IAudioSource
{
	/// Gets the current playback state.
	AudioSourceState State { get; }

	/// Gets or sets the volume level (0.0 to 1.0).
	float Volume { get; set; }

	/// Gets or sets the playback pitch multiplier (1.0 = normal speed).
	float Pitch { get; set; }

	/// Gets or sets whether the source should loop when playback completes.
	bool Loop { get; set; }

	/// Gets or sets the world position for 3D audio spatialization.
	Vector3 Position { get; set; }

	/// Gets or sets the minimum distance where attenuation begins.
	/// Below this distance, the sound plays at full volume.
	float MinDistance { get; set; }

	/// Gets or sets the maximum distance for sound attenuation.
	/// Beyond this distance, the sound is inaudible.
	float MaxDistance { get; set; }

	/// Plays the specified audio clip from the beginning.
	void Play(AudioClip clip);

	/// Pauses the currently playing audio.
	void Pause();

	/// Resumes playback from the paused position.
	void Resume();

	/// Stops playback and resets to the beginning.
	void Stop();
}
