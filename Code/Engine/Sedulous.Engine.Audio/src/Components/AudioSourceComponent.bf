namespace Sedulous.Engine.Audio;

using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Audio;
using System;

/// Component for an audio source attached to an entity.
/// The AudioSourceComponentManager resolves the clip resource, creates the
/// IAudioSource, syncs 3D position from the entity transform, and manages
/// playback lifecycle.
class AudioSourceComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 2;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("ClipRef", ref mClipRef);
		s.ResourceRef("CueRef", ref mCueRef);
		s.Float("Volume", ref Volume);
		s.Float("Pitch", ref Pitch);
		s.Bool("Loop", ref Loop);
		s.Bool("Spatial", ref Spatial);
		s.Bool("AutoPlay", ref AutoPlay);
		s.Float("MinDistance", ref MinDistance);
		s.Float("MaxDistance", ref MaxDistance);
		s.String("BusName", BusName);
		s.Bool("UseAttenuator", ref UseAttenuator);
		if (UseAttenuator)
		{
			var curve = (uint8)AttenuatorConfig.Curve;
			s.UInt8("AttenuationCurve", ref curve);
			if (s.IsReading) AttenuatorConfig.Curve = (AttenuationCurve)curve;
			s.Float("AttMinDistance", ref AttenuatorConfig.MinDistance);
			s.Float("AttMaxDistance", ref AttenuatorConfig.MaxDistance);
			s.Float("AttMaxDistanceLowPassHz", ref AttenuatorConfig.MaxDistanceLowPassHz);
			s.Float("AttConeInnerAngle", ref AttenuatorConfig.ConeInnerAngle);
			s.Float("AttConeOuterAngle", ref AttenuatorConfig.ConeOuterAngle);
			s.Float("AttConeOuterGain", ref AttenuatorConfig.ConeOuterGain);
			s.Float("AttDopplerFactor", ref AttenuatorConfig.DopplerFactor);
		}
	}

	// --- Resource refs (serializable) ---

	/// Audio clip resource reference (used when CueRef is empty).
	private ResourceRef mClipRef ~ _.Dispose();

	/// Sound cue resource reference (overrides ClipRef when set).
	private ResourceRef mCueRef ~ _.Dispose();

	// --- Configuration ---

	/// Volume level (0.0 to 1.0).
	public float Volume = 1.0f;

	/// Pitch multiplier (1.0 = normal speed).
	public float Pitch = 1.0f;

	/// Whether the source loops.
	public bool Loop = false;

	/// Whether this source uses 3D spatialization.
	public bool Spatial = true;

	/// Whether to start playing automatically on initialization.
	public bool AutoPlay = false;

	/// Minimum distance where attenuation begins.
	public float MinDistance = 1.0f;

	/// Maximum distance for sound attenuation.
	public float MaxDistance = 50.0f;

	/// Name of the audio bus this source routes to (e.g., "SFX", "Music", "UI").
	public String BusName = new .("SFX") ~ delete _;

	/// Whether to use a custom attenuator (instead of default linear).
	public bool UseAttenuator = false;

	/// Custom attenuator configuration. Only used when UseAttenuator is true.
	public SoundAttenuator AttenuatorConfig = .();

	// --- Runtime state (managed by AudioSourceComponentManager) ---

	/// Resolved sound cue (not owned - owned by resource system).
	public SoundCue Cue;

	/// Resolved audio clip (not owned - owned by resource system).
	public AudioClip Clip;

	/// Audio source handle (owned by IAudioSystem, managed by manager).
	public IAudioSource Source;

	/// Whether the clip has been resolved and the source created.
	public bool IsReady => Source != null && Clip != null;

	/// Whether playback has been requested (set by AutoPlay or Play()).
	public bool PlayRequested = false;

	// --- Resource ref accessors ---

	public ResourceRef ClipRef => mClipRef;
	public ResourceRef CueRef => mCueRef;

	public void SetClipRef(ResourceRef @ref)
	{
		mClipRef.Dispose();
		mClipRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	public void SetCueRef(ResourceRef @ref)
	{
		mCueRef.Dispose();
		mCueRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Requests playback to start. Will begin once the clip is resolved.
	public void Play()
	{
		PlayRequested = true;
	}

	/// Stops playback.
	public void Stop()
	{
		PlayRequested = false;
		if (Source != null)
			Source.Stop();
	}

	/// Pauses playback.
	public void Pause()
	{
		if (Source != null)
			Source.Pause();
	}

	/// Resumes playback.
	public void Resume()
	{
		if (Source != null)
			Source.Resume();
	}
}
