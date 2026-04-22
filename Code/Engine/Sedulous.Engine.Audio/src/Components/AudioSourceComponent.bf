namespace Sedulous.Engine.Audio;

using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Audio;

/// Volume category for an audio source.
public enum AudioVolumeCategory : uint8
{
	/// Sound effects (short clips, spatialized).
	SFX,
	/// Music (long-form, typically non-spatialized).
	Music
}

/// Component for an audio source attached to an entity.
/// The AudioSourceComponentManager resolves the clip resource, creates the
/// IAudioSource, syncs 3D position from the entity transform, and manages
/// playback lifecycle.
class AudioSourceComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("ClipRef", ref mClipRef);
		s.Float("Volume", ref Volume);
		s.Float("Pitch", ref Pitch);
		s.Bool("Loop", ref Loop);
		s.Bool("Spatial", ref Spatial);
		s.Bool("AutoPlay", ref AutoPlay);
		s.Float("MinDistance", ref MinDistance);
		s.Float("MaxDistance", ref MaxDistance);
		var category = (uint8)Category;
		s.UInt8("Category", ref category);
		if (s.IsReading) Category = (AudioVolumeCategory)category;
	}

	// --- Resource ref (serializable) ---

	/// Audio clip resource reference.
	private ResourceRef mClipRef ~ _.Dispose();

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

	/// Volume category (affects which category volume multiplier applies).
	public AudioVolumeCategory Category = .SFX;

	// --- Runtime state (managed by AudioSourceComponentManager) ---

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

	public void SetClipRef(ResourceRef @ref)
	{
		mClipRef.Dispose();
		mClipRef = ResourceRef(@ref.Id, @ref.Path ?? "");
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
