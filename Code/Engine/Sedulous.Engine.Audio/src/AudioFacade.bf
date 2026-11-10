using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.Resource;
using Sedulous.Run;

namespace Sedulous.Engine.Audio;

/// `Audio`: the run's music and one shots, by asset id, and the buses. The subsystem's own
/// (AudioSubsystem makes and offers them): one to scripts outside every run, on the application's
/// services, and one per run, among the run's services, which its scripts find first.
///
/// One per run: a run's own carries the run, so
/// what its scripts play goes into the run (the run's stop, pause and mute reach it) and its
/// bus volumes are the run's own (a game's options sliders never move the editor's buses or
/// another run's). A facade with no run plays outside every run, on the engine's buses.
class AudioFacade
{
	/// BORROWED: the subsystem. The resources come through a getter, read per call, since
	/// an application's manager may be handed over after the facade is made.
	private AudioSubsystem mAudio;
	private delegate ResourceManager() mResources ~ delete _;
	/// BORROWED: the run this facade plays into (a GameInstance); null is outside every run.
	private IRun mRun;

	public this(AudioSubsystem audio, delegate ResourceManager() resources, IRun run = null)
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
	public VoiceHandle PlayOneShot(Guid clip, AudioBus bus = .Effects, float volume = 1.0f, float pitch = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot(resolved, bus, volume, pitch, RunGroup) : .();
	}
	public VoiceHandle PlayOneShot3D(Guid clip, Float3 position)
	{
		let resolved = Clip(clip);
		var parameters = AudioPlayParams();
		parameters.RunGroup = RunGroup;
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayOneShot3D(resolved, position, parameters) : .();
	}
	public VoiceHandle PlayCue(Guid cue, AudioBus bus = .Effects)
	{
		let resolved = Cue(cue);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot(resolved, bus, RunGroup) : .();
	}
	public VoiceHandle PlayCue3D(Guid cue, Float3 position)
	{
		let resolved = Cue(cue);
		var parameters = AudioPlayParams();
		parameters.RunGroup = RunGroup;
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayCueOneShot3D(resolved, position, parameters) : .();
	}
	/// The music track, cross faded from the run's last.
	public VoiceHandle PlayMusic(Guid clip, float crossFadeSeconds = 1.0f, float volume = 1.0f)
	{
		let resolved = Clip(clip);
		return ((resolved != null) && (mAudio != null)) ? mAudio.PlayMusic(resolved, crossFadeSeconds, volume, RunGroup) : .();
	}
	/// The run's music, faded out.
	public void StopMusic(float fadeSeconds = 1.0f) => mAudio?.StopMusic(fadeSeconds, RunGroup);

	// ---- by content path: the asset as the project names it ("Audio/Jump") ----
	// A path resolves by type: a clip plays, a cue resolves one weighted variant. One that
	// names nothing playable gives an invalid voice; a script never faults over content.

	public VoiceHandle PlayOneShotPath(StringView path, AudioBus bus = .Effects) =>
		((mAudio != null) && (Resources != null)) ? mAudio.PlayOneShotByPath(Resources, path, bus, RunGroup) : .();
	public VoiceHandle PlayOneShot3DPath(StringView path, Float3 position) =>
		((mAudio != null) && (Resources != null)) ? mAudio.PlayOneShot3DByPath(Resources, path, position, RunGroup) : .();
	public VoiceHandle PlayCuePath(StringView path, AudioBus bus = .Effects) =>
		((mAudio != null) && (Resources != null)) ? mAudio.PlayCueByPath(Resources, path, bus, RunGroup) : .();
	/// The music track by path, cross faded from the run's last.
	public VoiceHandle PlayMusicPath(StringView path, float crossFadeSeconds = 1.0f) =>
		((mAudio != null) && (Resources != null)) ? mAudio.PlayMusicByPath(Resources, path, Math.Max(crossFadeSeconds, 0.0f), RunGroup) : .();

	// ---- a playing voice: what a game changes while it plays (its music's speed) ----

	/// The run's music voice, invalid when none is playing.
	public VoiceHandle MusicVoice() => (Engine != null) ? Engine.MusicVoice(RunGroup) : .();
	public bool IsVoicePlaying(VoiceHandle voice) => (Engine != null) && Engine.IsPlaying(voice);
	/// Stops a voice, fading out over `fadeSeconds` (at least the click free window).
	public void StopVoice(VoiceHandle voice, float fadeSeconds = 0.0f) => Engine?.Stop(voice, fadeSeconds);
	public void SetVoicePaused(VoiceHandle voice, bool paused) => Engine?.SetPaused(voice, paused);
	/// The volume at once, or eased there over `seconds`.
	public void SetVoiceVolume(VoiceHandle voice, float volume, float seconds = 0.0f) => Engine?.SetVoiceVolume(voice, volume, seconds);
	/// The pitch, the playback rate (tempo and pitch together: 1.2 plays twenty percent faster
	/// and higher), at once or eased there over `seconds`.
	public void SetVoicePitch(VoiceHandle voice, float pitch, float seconds = 0.0f) => Engine?.SetVoicePitch(voice, pitch, seconds);

	/// A fixed bus's volume: the run's own in a run, the engine's outside one.
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
	public float BusVolume(AudioBus bus)
	{
		let engine = Engine;
		if (engine == null)
			return 1.0f;
		let run = RunGroup;
		return (run != 0) ? engine.RunBusVolume(run, bus) : engine.BusVolume(bus);
	}
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
	public bool BusMuted(AudioBus bus)
	{
		let engine = Engine;
		if (engine == null)
			return false;
		let run = RunGroup;
		return (run != 0) ? engine.RunBusMuted(run, bus) : engine.BusMuted(bus);
	}

	/// A bus's volume by name: the four fixed names (master, effects, music, ui, any case)
	/// first, then the applied layout's named buses; the run's own in a run, the bus's
	/// outside one. An unknown name changes nothing.
	public void SetNamedBusVolume(StringView name, float volume)
	{
		let engine = Engine;
		if (engine == null)
			return;
		let clamped = Math.Clamp(volume, 0.0f, 4.0f);
		if (AudioBusNames.TryParse(name, let fixedBus))
		{
			SetBusVolume(fixedBus, clamped);
			return;
		}
		let run = RunGroup;
		if (run != 0)
			engine.SetRunNamedBusVolume(run, name, clamped);
		else
			engine.SetNamedBusVolume(name, clamped);
	}
	public float NamedBusVolume(StringView name)
	{
		let engine = Engine;
		if (engine == null)
			return 1.0f;
		if (AudioBusNames.TryParse(name, let fixedBus))
			return BusVolume(fixedBus);
		let run = RunGroup;
		if (run != 0)
			return engine.RunNamedBusVolume(run, name);
		// An unknown bus reads as untouched, full volume, not silent.
		return engine.HasNamedBus(name) ? engine.NamedBusVolume(name) : 1.0f;
	}
	public void SetNamedBusMuted(StringView name, bool muted)
	{
		let engine = Engine;
		if (engine == null)
			return;
		if (AudioBusNames.TryParse(name, let fixedBus))
		{
			SetBusMuted(fixedBus, muted);
			return;
		}
		let run = RunGroup;
		if (run != 0)
			engine.SetRunNamedBusMuted(run, name, muted);
		else
			engine.SetNamedBusMuted(name, muted);
	}
	public bool NamedBusMuted(StringView name)
	{
		let engine = Engine;
		if (engine == null)
			return false;
		if (AudioBusNames.TryParse(name, let fixedBus))
			return BusMuted(fixedBus);
		let run = RunGroup;
		return (run != 0) ? engine.RunNamedBusMuted(run, name) : engine.NamedBusMuted(name);
	}
}
