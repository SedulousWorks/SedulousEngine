using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Audio;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Audio`: the sound source on an entity.
[Scriptable, SceneFacade("Audio")]
class AudioSceneFacade : SceneFacade
{
	private AudioSceneSystem System => Scene.GetSystem<AudioSceneSystem>();

	/// Plays the entity's source; the voice, for a later stop or check.
	[Scriptable]
	public VoiceHandle Play(EntityHandle entity) => System?.Play(entity) ?? .();
	[Scriptable]
	public void Stop(EntityHandle entity) => System?.Stop(entity);
	[Scriptable]
	public void SetPaused(EntityHandle entity, bool paused) => System?.SetPaused(entity, paused);
	[Scriptable]
	public bool IsPlaying(EntityHandle entity) => System?.IsPlaying(entity) ?? false;
	/// The clip by asset id.
	[Scriptable]
	public void SetClip(EntityHandle entity, Guid clip) => System?.SetClip(entity, clip);
}

/// `Audio`: the run's music and one shots, by asset id, and the buses. Installed by the
/// application, which owns the resources the ids resolve through.
[Scriptable, ServiceFacade("Audio")]
class AudioFacade
{
	/// BORROWED: the subsystem. The resources come through a getter, read per call, since
	/// an application's manager may be handed over after the facade is made.
	private AudioSubsystem mAudio;
	private delegate ResourceManager() mResources ~ delete _;

	public this(AudioSubsystem audio, delegate ResourceManager() resources)
	{
		mAudio = audio;
		mResources = resources;
	}

	private ResourceManager Resources => (mResources != null) ? mResources() : null;
	private AudioClip Clip(Guid id) => ((Resources != null) && (id != Guid())) ? Resources.Bind<AudioClip>(id).Get : null;
	private SoundCue Cue(Guid id) => ((Resources != null) && (id != Guid())) ? Resources.Bind<SoundCue>(id).Get : null;

	/// A clip once, on a bus; an invalid voice when the clip did not resolve.
	[Scriptable]
	public VoiceHandle PlayOneShot(Guid clip, AudioBus bus = .Effects, float volume = 1.0f, float pitch = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot(resolved, bus, volume, pitch) : .();
	}
	[Scriptable]
	public VoiceHandle PlayOneShot3D(Guid clip, Float3 position)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot3D(resolved, position) : .();
	}
	[Scriptable]
	public VoiceHandle PlayCue(Guid cue, AudioBus bus = .Effects)
	{
		let resolved = Cue(cue);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot(resolved, bus) : .();
	}
	[Scriptable]
	public VoiceHandle PlayCue3D(Guid cue, Float3 position)
	{
		let resolved = Cue(cue);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot3D(resolved, position) : .();
	}
	/// The music track, cross faded from the last.
	[Scriptable]
	public VoiceHandle PlayMusic(Guid clip, float crossFadeSeconds = 1.0f, float volume = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayMusic(resolved, crossFadeSeconds, volume) : .();
	}
	[Scriptable]
	public void SetBusVolume(AudioBus bus, float volume) => mAudio?.SetBusVolume(bus, volume);
	[Scriptable]
	public float BusVolume(AudioBus bus) => mAudio?.BusVolume(bus) ?? 0.0f;
}
