using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Resource;

/// The cooked record for a clip: its probed shape and its import intent.
///
/// The container BYTES are not here. They live in the instance's own "data" stream beside
/// this, still in whatever container they were imported as, because a decoded sidecar would
/// be an order of magnitude larger for no gain: the backend sniffs the container and picks
/// the decoder itself.
[Serializable]
class AudioClipSource
{
	public uint32 Channels = 0;
	public uint32 SampleRate = 0;
	public uint64 FrameCount = 0;
	public float DurationSeconds = 0.0f;

	/// The authored gain, multiplied with whatever a play asks for.
	public float Gain = 1.0f;

	public bool Loop = false;
	public uint64 LoopStartFrame = 0;
	/// Nought is the clip's own end.
	public uint64 LoopEndFrame = 0;

	/// Whether it pages off the mount rather than being held in memory.
	public bool Stream = false;
	/// Whether an in memory clip stays compressed and decodes as it plays.
	public bool KeepCompressed = false;

	/// The container it was imported as, recorded as a hint rather than as a decision:
	/// "wav", "ogg", "mp3", "flac".
	public String ContainerExtension = new .() ~ delete _;
}
