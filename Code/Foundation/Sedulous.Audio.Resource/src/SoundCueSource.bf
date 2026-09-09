using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Resource;

/// The cooked WIRE for a cue: the variants as PARALLEL ARRAYS of clip id and weight.
///
/// A variant points at its clip by ID rather than carrying it, so one clip backs as many
/// cues as reference it and the edge is what a reload of that clip travels along.
[Serializable]
class SoundCueSource
{
	public List<Guid> ClipId = new .() ~ delete _;
	public List<float> Weight = new .() ~ delete _;

	/// The pick mode, as its ordinal.
	public uint8 Mode = 0;

	public float PitchMin = 1.0f;
	public float PitchMax = 1.0f;
	public float VolumeMin = 1.0f;
	public float VolumeMax = 1.0f;
}
