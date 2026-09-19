using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Audio;

/// The runtime clip: its shape, and the ORIGINAL container bytes.
///
/// An in memory clip holds the encoded bytes rather than decoded samples, which is what
/// keeps a bank of sounds to a sensible size; it decodes once at first play unless it is
/// flagged to stay compressed, which suits a large sound that can afford the decode as it
/// goes. A streamed clip holds a re-openable source instead, so the engine pages it straight
/// out of the mount without ever holding the whole thing.
/// On the script surface as an opaque handle: a script holds one and hands it back.
[Scriptable]
class AudioClip
{
	public uint32 Channels = 0;
	public uint32 SampleRate = 0;
	public uint64 FrameCount = 0;
	public float DurationSeconds = 0.0f;

	/// The authored gain, folded into every voice's volume.
	public float Gain = 1.0f;

	/// The default intent; a play request may override it.
	public bool Loop = false;
	public uint64 LoopStartFrame = 0;
	/// Nought is the clip's end.
	public uint64 LoopEndFrame = 0;

	/// Decode as it plays, from the source below, rather than being held in memory.
	public bool Stream = false;
	/// Stay compressed in memory and decode on the fly, rather than decoding once up front.
	public bool KeepCompressed = false;

	/// The original container bytes, for a clip that is not streamed.
	public List<uint8> EncodedData = new .() ~ delete _;

	/// The re-openable source, for a clip that is. OWNED.
	public IAudioStreamSource StreamSource = null ~ if (_ != null) delete _;

	public Span<uint8> EncodedBytes => EncodedData;
}
