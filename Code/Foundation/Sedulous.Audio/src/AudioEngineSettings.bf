using Sedulous.VFS;

namespace Sedulous.Audio;

/// How an engine is brought up.
class AudioEngineSettings
{
	/// HEADLESS never touches a device: the mixer is pumped by hand from the update. That is
	/// what lets the tests, the cooker and a machine with no sound card run the whole state
	/// machine deterministically.
	///
	/// With a device asked for and none available, the engine says so and falls back to this
	/// rather than failing: the handles stay valid and the game plays on in silence.
	public bool Headless = false;

	public uint32 VoiceCount = 64;
	public uint32 StreamVoiceCount = 8;
	/// The headless mixing rate. A real device uses its own.
	public uint32 SampleRate = 48000;
	/// One to four. A spatial voice attaches to the CLOSEST of them.
	public uint32 ListenerCount = 1;

	/// Stopping and pausing ALWAYS fade, over this. An instant cut is a click, and a click is
	/// the most audible thing an engine can do.
	public float StopFadeSeconds = 0.010f;

	/// A stolen voice's sound moves to a bounded dying list and fades out over this while the
	/// newcomer starts at once, so a steal is inaudible rather than a click.
	public float StealFadeSeconds = 0.030f;
	/// Nought cuts a stolen voice immediately; a full list hard cuts its oldest.
	public uint32 DyingVoiceCapacity = 8;

	/// The window within which a repeated play of one clip merges into the voice already
	/// going, rather than stacking.
	public float DedupeWindowSeconds = 1.0f / 30.0f;

	/// Optional, for streaming a clip addressed by path. A clip carrying its own source needs
	/// none. BORROWED.
	public IFileSystem FileSystem = null;

	/// Copies the settings wholesale, which is how the engine takes its OWN copy: the caller
	/// may keep, change or free what it passed without the running engine noticing.
	public void CopyFrom(AudioEngineSettings other)
	{
		Headless = other.Headless;
		VoiceCount = other.VoiceCount;
		StreamVoiceCount = other.StreamVoiceCount;
		SampleRate = other.SampleRate;
		ListenerCount = other.ListenerCount;
		StopFadeSeconds = other.StopFadeSeconds;
		StealFadeSeconds = other.StealFadeSeconds;
		DyingVoiceCapacity = other.DyingVoiceCapacity;
		DedupeWindowSeconds = other.DedupeWindowSeconds;
		FileSystem = other.FileSystem;
	}
}
