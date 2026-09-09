namespace Sedulous.Audio;

/// What probing an encoded container found in it.
struct AudioClipMetadata
{
	public uint32 Channels = 0;
	public uint32 SampleRate = 0;
	public uint64 FrameCount = 0;
	public float DurationSeconds = 0.0f;

	public this() {}

	/// Whether the probe found audio at all, rather than bytes it could not read.
	public bool IsValid => (Channels > 0) && (SampleRate > 0);
}
