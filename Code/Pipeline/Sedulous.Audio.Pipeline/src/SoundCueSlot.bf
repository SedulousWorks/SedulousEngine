using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Pipeline;

/// One weighted variant of a cue.
[Serializable]
class SoundCueSlot
{
	/// Empty means the slot is unused.
	public Guid ClipId = .Empty;
	public float Weight = 1.0f;
}
