namespace Sedulous.Audio;

/// Represents the playback state of an audio source.
enum AudioSourceState
{
	/// The source is stopped and not playing.
	Stopped,
	/// The source is currently playing audio.
	Playing,
	/// The source is paused.
	Paused
}
