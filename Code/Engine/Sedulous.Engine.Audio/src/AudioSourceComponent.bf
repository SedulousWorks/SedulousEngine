using System;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// A sound at an entity.
///
/// It plays either a single CLIP or a CUE, which resolves one weighted variant with its own
/// jitter per trigger. Everything below the authored block is runtime state the scene system
/// owns and nothing serializes.
[SerializableComponent("audio.Source", 3)]
struct AudioSourceComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	/// Which of the two references below plays.
	public AudioSourceType SourceType = .Clip;
	public Ref<AudioClip> Clip = .(Guid());
	public Ref<SoundCue> Cue = .(Guid());

	public AudioBus Bus = .Effects;
	/// A NAMED custom bus. When the applied layout carries one of this name the voice routes
	/// there; an unknown or empty name falls back to the fixed bus above.
	public String BusName = null;

	public float Volume = 1.0f;
	/// Real resampling at runtime.
	public float Pitch = 1.0f;
	/// ORed with the clip's own authored intent.
	public bool Loop = false;
	public bool Spatial = true;
	/// Starts when the scene's simulation starts.
	public bool AutoPlay = false;

	/// The distance low pass FLOOR in hertz for a spatial source: the cutoff glides from open
	/// at the near distance to this at the far one. Nought muffles nothing.
	public float DistanceLowpassHz = 4000.0f;

	/// This source's feed into the scene's reverb, from nought to one. The zones drive the
	/// room's character; this scales how much of this voice reaches it. Nought is dry.
	public float ReverbSend = 0.0f;

	/// Pool contention: the higher survives.
	public uint8 Priority = 128;
	public float MinDistance = 1.0f;
	public float MaxDistance = 100.0f;
	public AudioAttenuationModel AttenuationModel = .Inverse;
	public float Rolloff = 1.0f;
	/// Velocities feed the spatialiser every frame.
	public float DopplerFactor = 1.0f;
	public float ConeInnerAngleDegrees = 360.0f;
	public float ConeOuterAngleDegrees = 360.0f;
	public float ConeOuterGain = 0.0f;

	// ---- runtime ----

	public VoiceHandle Voice = .();

	/// The entity active LATCH: true while the voice is stopped BECAUSE its entity is
	/// effectively inactive. Reactivation restarts an automatic source from it.
	public bool ActiveSuspended = false;

	/// The cue's no repeat state, one per component so two things triggering the same cue do
	/// not share a sequence.
	public int32 LastCueVariant = -1;
	public uint32 CueSequentialCursor = 0;

	public Float3 PreviousPosition = .(0.0f, 0.0f, 0.0f);
	public bool HasPreviousPosition = false;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Clip.Bind(manager);
		Cue.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "clip", ref Clip.Id);
		ar.Key("bus");
		SerializeEnum(ar, ref Bus);
		SerializeValue(ar, "volume", ref Volume);
		SerializeValue(ar, "pitch", ref Pitch);
		SerializeValue(ar, "loop", ref Loop);
		SerializeValue(ar, "spatial", ref Spatial);
		SerializeValue(ar, "autoPlay", ref AutoPlay);
		SerializeValue(ar, "distanceLowpassHz", ref DistanceLowpassHz);
		SerializeValue(ar, "cue", ref Cue.Id);
		SerializeValue(ar, "priority", ref Priority);
		SerializeValue(ar, "minDistance", ref MinDistance);
		SerializeValue(ar, "maxDistance", ref MaxDistance);
		ar.Key("attenuationModel");
		SerializeEnum(ar, ref AttenuationModel);
		SerializeValue(ar, "rolloff", ref Rolloff);
		SerializeValue(ar, "dopplerFactor", ref DopplerFactor);
		SerializeValue(ar, "coneInnerAngleDegrees", ref ConeInnerAngleDegrees);
		SerializeValue(ar, "coneOuterAngleDegrees", ref ConeOuterAngleDegrees);
		SerializeValue(ar, "coneOuterGain", ref ConeOuterGain);
		Sedulous.Core.Serialization.Serialize(ar, "busName", BusName);
		SerializeValue(ar, "reverbSend", ref ReverbSend);
		ar.Key("sourceType");
		SerializeEnum(ar, ref SourceType);
	}
}
