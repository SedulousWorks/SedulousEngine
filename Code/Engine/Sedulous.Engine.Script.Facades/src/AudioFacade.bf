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
///
/// One per run: a GameInstance's own, on its run host, carries the instance as its run, so
/// what its scripts play goes into the run (the run's stop, pause and mute reach it) and its
/// bus volumes are the run's own (a game's options sliders never move the editor's buses or
/// another run's). A facade with no run plays outside every run, on the engine's buses.
[Scriptable, ServiceFacade("Audio")]
class AudioFacade
{
	/// BORROWED: the subsystem. The resources come through a getter, read per call, since
	/// an application's manager may be handed over after the facade is made.
	private AudioSubsystem mAudio;
	private delegate ResourceManager() mResources ~ delete _;
	/// BORROWED: the run this facade plays into (a GameInstance); null is outside every run.
	private Object mRun;

	public this(AudioSubsystem audio, delegate ResourceManager() resources, Object run = null)
	{
		mAudio = audio;
		mResources = resources;
		mRun = run;
	}

	private ResourceManager Resources => (mResources != null) ? mResources() : null;
	private AudioClip Clip(Guid id) => ((Resources != null) && (id != Guid())) ? Resources.Bind<AudioClip>(id).Get : null;
	private SoundCue Cue(Guid id) => ((Resources != null) && (id != Guid())) ? Resources.Bind<SoundCue>(id).Get : null;
	private AudioEngine Engine => mAudio?.Engine;
	/// The run's group, made on first use; nought outside a run.
	private uint64 RunGroup => ((mAudio != null) && (mRun != null)) ? mAudio.RunGroupFor(mRun) : 0;

	/// A clip once, on a bus; an invalid voice when the clip did not resolve.
	[Scriptable]
	public VoiceHandle PlayOneShot(Guid clip, AudioBus bus = .Effects, float volume = 1.0f, float pitch = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot(resolved, bus, volume, pitch, RunGroup) : .();
	}
	[Scriptable]
	public VoiceHandle PlayOneShot3D(Guid clip, Float3 position)
	{
		let resolved = Clip(clip);
		var parameters = AudioPlayParams();
		parameters.RunGroup = RunGroup;
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot3D(resolved, position, parameters) : .();
	}
	[Scriptable]
	public VoiceHandle PlayCue(Guid cue, AudioBus bus = .Effects)
	{
		let resolved = Cue(cue);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot(resolved, bus, RunGroup) : .();
	}
	[Scriptable]
	public VoiceHandle PlayCue3D(Guid cue, Float3 position)
	{
		let resolved = Cue(cue);
		var parameters = AudioPlayParams();
		parameters.RunGroup = RunGroup;
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot3D(resolved, position, parameters) : .();
	}
	/// The music track, cross faded from the run's last.
	[Scriptable]
	public VoiceHandle PlayMusic(Guid clip, float crossFadeSeconds = 1.0f, float volume = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayMusic(resolved, crossFadeSeconds, volume, RunGroup) : .();
	}
	/// The run's music, faded out.
	[Scriptable]
	public void StopMusic(float fadeSeconds = 1.0f) => mAudio?.StopMusic(fadeSeconds, RunGroup);

	// ---- a playing voice: what a game changes while it plays (its music's speed) ----

	/// The run's music voice, invalid when none is playing.
	[Scriptable]
	public VoiceHandle MusicVoice() => (Engine != null) ? Engine.MusicVoice(RunGroup) : .();
	[Scriptable]
	public bool IsVoicePlaying(VoiceHandle voice) => (Engine != null) && Engine.IsPlaying(voice);
	/// Stops a voice, fading out over `fadeSeconds` (at least the click free window).
	[Scriptable]
	public void StopVoice(VoiceHandle voice, float fadeSeconds = 0.0f) => Engine?.Stop(voice, fadeSeconds);
	[Scriptable]
	public void SetVoicePaused(VoiceHandle voice, bool paused) => Engine?.SetPaused(voice, paused);
	/// The volume at once, or eased there over `seconds`.
	[Scriptable]
	public void SetVoiceVolume(VoiceHandle voice, float volume, float seconds = 0.0f) => Engine?.SetVoiceVolume(voice, volume, seconds);
	/// The pitch, the playback rate (tempo and pitch together: 1.2 plays twenty percent faster
	/// and higher), at once or eased there over `seconds`.
	[Scriptable]
	public void SetVoicePitch(VoiceHandle voice, float pitch, float seconds = 0.0f) => Engine?.SetVoicePitch(voice, pitch, seconds);

	/// A fixed bus's volume: the run's own in a run, the engine's outside one.
	[Scriptable]
	public void SetBusVolume(AudioBus bus, float volume)
	{
		let engine = Engine;
		if (engine == null)
			return;
		let clamped = Math.Clamp(volume, 0.0f, 4.0f);
		let run = RunGroup;
		if (run != 0)
			engine.SetRunBusVolume(run, bus, clamped);
		else
			engine.SetBusVolume(bus, clamped);
	}
	[Scriptable]
	public float BusVolume(AudioBus bus)
	{
		let engine = Engine;
		if (engine == null)
			return 1.0f;
		let run = RunGroup;
		return (run != 0) ? engine.RunBusVolume(run, bus) : engine.BusVolume(bus);
	}
	[Scriptable]
	public void SetBusMuted(AudioBus bus, bool muted)
	{
		let engine = Engine;
		if (engine == null)
			return;
		let run = RunGroup;
		if (run != 0)
			engine.SetRunBusMuted(run, bus, muted);
		else
			engine.SetBusMuted(bus, muted);
	}
	[Scriptable]
	public bool BusMuted(AudioBus bus)
	{
		let engine = Engine;
		if (engine == null)
			return false;
		let run = RunGroup;
		return (run != 0) ? engine.RunBusMuted(run, bus) : engine.BusMuted(bus);
	}

	/// A layout's named bus volume, by name: the run's own in a run, the bus's outside one.
	[Scriptable]
	public void SetNamedBusVolume(StringView name, float volume)
	{
		let engine = Engine;
		if (engine == null)
			return;
		let clamped = Math.Clamp(volume, 0.0f, 4.0f);
		let run = RunGroup;
		if (run != 0)
			engine.SetRunNamedBusVolume(run, name, clamped);
		else
			engine.SetNamedBusVolume(name, clamped);
	}
	[Scriptable]
	public float NamedBusVolume(StringView name)
	{
		let engine = Engine;
		if (engine == null)
			return 1.0f;
		let run = RunGroup;
		return (run != 0) ? engine.RunNamedBusVolume(run, name) : engine.NamedBusVolume(name);
	}
	[Scriptable]
	public void SetNamedBusMuted(StringView name, bool muted)
	{
		let engine = Engine;
		if (engine == null)
			return;
		let run = RunGroup;
		if (run != 0)
			engine.SetRunNamedBusMuted(run, name, muted);
		else
			engine.SetNamedBusMuted(name, muted);
	}
	[Scriptable]
	public bool NamedBusMuted(StringView name)
	{
		let engine = Engine;
		if (engine == null)
			return false;
		let run = RunGroup;
		return (run != 0) ? engine.RunNamedBusMuted(run, name) : engine.NamedBusMuted(name);
	}
}
