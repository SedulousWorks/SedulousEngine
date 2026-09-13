using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// An audio file and how it should cook.
[Serializable]
class AudioClipAsset : Asset
{
	/// Decoded on the fly at runtime, which is what music and ambience want.
	public bool Stream = false;
	/// An in memory clip decoded on play rather than on load.
	public bool KeepCompressed = false;
	/// Downmixed at cook, which is what a positioned sound wants.
	public bool ForceMono = false;

	public bool Loop = false;
	public uint64 LoopStartFrame = 0;
	/// Nought means the clip's end.
	public uint64 LoopEndFrame = 0;

	/// Drops the silent tail at cook.
	public bool TrimTrailingSilence = false;
	/// Peak normalises, leaving a decibel of headroom.
	public bool Normalize = false;

	/// Authored gain, folded at runtime rather than baked into the samples.
	public float Gain = 1.0f;
}
