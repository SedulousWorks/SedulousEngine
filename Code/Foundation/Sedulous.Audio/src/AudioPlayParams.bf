using System;
using Sedulous.Core;

namespace Sedulous.Audio;

/// What one play asks for.
struct AudioPlayParams
{
	public AudioBus Bus = .Effects;

	/// BY NAME, when the applied layout has a custom bus so called: the voice routes there
	/// instead of the fixed bus above. An unknown name falls back to it, warned once, rather
	/// than refusing to play: content must never silence itself.
	///
	/// BORROWED for the call; the engine copies what it keeps.
	public StringView BusName = default;

	/// Multiplied with the clip's own authored gain.
	public float Volume = 1.0f;
	/// Real resampling, not a number that is stored and ignored.
	public float Pitch = 1.0f;
	/// Minus one left to plus one right, for a voice that is not spatial.
	public float Pan = 0.0f;
	/// Combined with the clip's own intent rather than replacing it.
	public bool Loop = false;

	/// Higher wins when the pool is full.
	public uint8 Priority = 128;
	/// The scene this belongs to, for pausing and teardown. Nought is global.
	public uint64 SceneGroup = 0;
	public bool StartPaused = false;

	/// Whether a play of the same clip within the merge window folds into the one already
	/// going, which is what keeps a shotgun's pellets from stacking into one loud crack.
	///
	/// A PERSISTENT SOURCE must opt out: several authored emitters playing one clip in the
	/// same instant are distinct voices at distinct places, and merging them silences all but
	/// one of them.
	public bool AllowDedupe = true;

	/// Nought to one. A splitter after the voice's chain feeds the scene's send reverb in
	/// parallel with the dry path, scaled by this. Nought splices no splitter at all.
	/// It needs a scene group, the send reverb being per scene.
	public float ReverbSend = 0.0f;

	// ---- spatial ----

	public bool Spatial = false;

	/// The cutoff glides from fully open at the near distance down to this by the far one,
	/// which is what makes a distant sound muffled rather than merely quiet. Nought puts no
	/// filter in the chain at all.
	public float DistanceLowpassHz = 4000.0f;

	public Float3 Position = .(0, 0, 0);
	/// Feeds the pitch shift of movement, from the frame's own transform delta.
	public Float3 Velocity = .(0, 0, 0);

	public float MinDistance = 1.0f;
	public float MaxDistance = 100.0f;
	public AudioAttenuationModel AttenuationModel = .Inverse;
	public float Rolloff = 1.0f;
	public float DopplerFactor = 1.0f;

	public float ConeInnerAngleDegrees = 360.0f;
	public float ConeOuterAngleDegrees = 360.0f;
	public float ConeOuterGain = 0.0f;

	public this() {}
}
