using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// An audio file and how it should cook.
[Category("Audio")]
[Serializable]
class AudioClipAsset : Asset
{
	/// Decoded on the fly at runtime, which is what music and ambience want.
	[Description("Decode on the fly at runtime (music/ambience)")]
	public bool Stream = false;
	/// An in memory clip decoded on play rather than on load.
	public bool KeepCompressed = false;
	/// Downmixed at cook, which is what a positioned sound wants.
	public bool ForceMono = false;

	public bool Loop = false;
	[VisibleWhen("Loop")]
	public uint64 LoopStartFrame = 0;
	/// Nought means the clip's end.
	[Description("0 = clip end")]
	[VisibleWhen("Loop")]
	public uint64 LoopEndFrame = 0;

	/// Drops the silent tail at cook.
	public bool TrimTrailingSilence = false;
	/// Peak normalises, leaving a decibel of headroom.
	public bool Normalize = false;

	/// Authored gain, folded at runtime rather than baked into the samples.
	[Range(0.0f, 4.0f, 0.01f)]
	public float Gain = 1.0f;
}
