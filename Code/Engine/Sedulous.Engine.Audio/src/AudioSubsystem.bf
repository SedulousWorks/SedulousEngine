using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The Context level audio broker.
///
/// It owns the ONE engine, hands it to every scene's audio system, pushes the winning
/// listeners, and carries the engine global one shot surface that needs no entity at all.
class AudioSubsystem : Subsystem, ISceneObserver
{
	/// One watched scene and its audio system, both BORROWED.
	private struct SceneEntry
	{
		public Scene Scene;
		public AudioSceneSystem System;

		public this(Scene scene, AudioSceneSystem system)
		{
			Scene = scene;
			System = system;
		}
	}

	/// One live run's group: the run is an opaque key (a GameInstance), BORROWED.
	private struct RunEntry
	{
		public Object Run;
		public uint64 Group;
	}

	/// An ended run fading out before its group is freed.
	private struct EndingRun
	{
		public uint64 Group;
		/// Freed once its voices' fades have landed.
		public float SecondsLeft;
	}

	/// A cue's no repeat state, kept per cue PRODUCT so two call sites triggering one cue
	/// share its sequence rather than each starting over.
	private class CueOneShotState
	{
		public int32 LastVariant = -1;
		public uint32 SequentialCursor = 0;
	}

	private AudioEngineSettings mEngineSettings ~ delete _;
	private AudioEngine mEngine = null ~ delete _;
	private List<SceneEntry> mSystems = new .() ~ delete _;

	private Sedulous.Core.Random mCueRandom = .();
	private Dictionary<SoundCue, CueOneShotState> mCueOneShotState
		= new .() ~ DeleteDictionaryAndValues!(_);
	/// Warned once per content path, so a mistyped path in a script does not flood the log.
	private HashSet<String> mWarnedPaths = new .() ~ DeleteContainerAndItems!(_);

	private List<RunEntry> mRuns = new .() ~ delete _;
	private List<EndingRun> mEndingRuns = new .() ~ delete _;
	/// BORROWED: the heard run; null hears every run.
	private Object mFocusedRun = null;
	/// The editor's preference, every Game tab heard rather than the focused one.
	private bool mHearAllRuns = false;
	/// The scene systems' way back to the run registry. OWNED.
	private delegate uint64(Object run) mRunGroupResolver ~ delete _;

	public this(AudioEngineSettings engineSettings = null)
	{
		mEngineSettings = engineSettings;
		mRunGroupResolver = new (run) => RunGroupFor(run);
	}

	public AudioEngine Engine => mEngine;

	/// AFTER the scene subsystem: the voices and listeners synced during each scene's own
	/// phase, and here the engine reaps, pumps and takes the listener.
	public override int32 UpdateOrder => -100;

	public void OnSystemsReady(Scene scene)
	{
		let system = scene.GetSystem<AudioSceneSystem>();
		if (system == null)
			return;

		system.SetEngine(mEngine);
		system.SetRunGroupResolver(mRunGroupResolver);
		mSystems.Add(SceneEntry(scene, system));
	}

	public void OnDestroying(Scene scene)
	{
		for (int i = mSystems.Count - 1; i >= 0; i--)
		{
			if (mSystems[i].Scene === scene)
			{
				mSystems.RemoveAt(i);
				return;
			}
		}
	}

	/// The listeners and the engine's own tick.
	///
	/// EVERY active listener component across the started scenes fills a slot, in scene
	/// order, up to what the engine was configured for: a spatial voice attenuates against
	/// the CLOSEST enabled one, which is what a split screen's ears are. With no component
	/// anywhere, the first started scene's camera stands in on slot nought, and the unused
	/// slots switch off.
	public override void Update(float deltaTime)
	{
		if (mEngine == null)
			return;

		using (ProfileScope("Audio.Engine"))
		{
			ReapEndedRuns(deltaTime);

			let capacity = mEngine.ListenerCount;
			uint32 used = 0;

			// Only heard runs' scenes feed the listeners: two Game tabs' cameras must not both
			// be the ears.
			for (let entry in mSystems)
			{
				if (!entry.System.Started || (used >= capacity) || !IsRunAudible(entry.Scene.Run))
					continue;

				for (let pose in entry.System.ListenerPoses)
				{
					if (used >= capacity)
						break;

					mEngine.SetListenerTransformIndexed(used, pose.Position, pose.Forward, pose.Up,
						pose.Velocity);
					mEngine.SetListenerEnabled(used, true);
					used++;
				}
			}

			if (used == 0)
			{
				for (let entry in mSystems)
				{
					if (!entry.System.Started || !IsRunAudible(entry.Scene.Run))
						continue;

					if (CameraListenerPose(entry.Scene, var position, var forward, var up))
					{
						mEngine.SetListenerTransformIndexed(0, position, forward, up, .(0, 0, 0));
						mEngine.SetListenerEnabled(0, true);
						used = 1;
						break;
					}
				}
			}

			// Slot nought always stays enabled, so a scene with no listener at all is still
			// heard from the origin rather than falling silent.
			for (uint32 i = Math.Max(used, 1); i < capacity; i++)
				mEngine.SetListenerEnabled(i, false);

			// Reaping, the merge clock, and the headless pump.
			mEngine.Update(deltaTime);
		}
	}

	// ---- the engine global one shots ----

	/// `runGroup` (RunGroupFor) puts the voice in a run: the run's stop, pause and mute reach
	/// it.
	public VoiceHandle PlayOneShot(AudioClip clip, AudioBus bus = .Effects, float volume = 1.0f,
		float pitch = 1.0f, uint64 runGroup = 0)
	{
		if (mEngine == null)
			return .();

		var parameters = AudioPlayParams();
		parameters.Bus = bus;
		parameters.Volume = volume;
		parameters.Pitch = pitch;
		parameters.RunGroup = runGroup;
		return mEngine.Play(clip, parameters);
	}

	public VoiceHandle PlayOneShot3D(AudioClip clip, Float3 position,
		AudioPlayParams baseParams = .())
	{
		if (mEngine == null)
			return .();

		var parameters = baseParams;
		parameters.Spatial = true;
		parameters.Position = position;
		return mEngine.Play(clip, parameters);
	}

	/// One cue TRIGGER as a one shot: a weighted variant and its jitter, through the same
	/// resolution the components use.
	public VoiceHandle PlayCueOneShot(SoundCue cue, AudioBus bus = .Effects, uint64 runGroup = 0)
	{
		var parameters = AudioPlayParams();
		parameters.Bus = bus;
		parameters.RunGroup = runGroup;
		return PlayCueResolved(cue, parameters);
	}

	public VoiceHandle PlayCueOneShot3D(SoundCue cue, Float3 position,
		AudioPlayParams baseParams = .())
	{
		var parameters = baseParams;
		parameters.Spatial = true;
		parameters.Position = position;
		return PlayCueResolved(cue, parameters);
	}

	// ---- music, which is scene free and survives a scene swap; one slot per run ----

	public VoiceHandle PlayMusic(AudioClip clip, float crossFadeSeconds = 1.0f,
		float volume = 1.0f, uint64 runGroup = 0)
		=> (mEngine != null) ? mEngine.PlayMusic(clip, crossFadeSeconds, volume, runGroup) : .();

	public void StopMusic(float fadeSeconds = 1.0f, uint64 runGroup = 0)
	{
		if (mEngine != null)
			mEngine.StopMusic(fadeSeconds, runGroup);
	}

	// ---- runs: what one running game plays, keyed by its run (Scene.Run) ----

	/// The run's group, made on first use; nought for no run or no engine. A new run starts
	/// muted when another run holds the focus and only the focused run is heard.
	public uint64 RunGroupFor(Object run)
	{
		if ((run == null) || (mEngine == null))
			return 0;
		for (let entry in mRuns)
		{
			if (entry.Run === run)
				return entry.Group;
		}
		let group = mEngine.CreateRunGroup();
		mRuns.Add(.() { Run = run, Group = group });
		mEngine.SetRunGroupMuted(group, !IsRunAudible(run));
		return group;
	}

	/// The run's group if it has one, without making it; nought otherwise.
	public uint64 FindRunGroup(Object run)
	{
		for (let entry in mRuns)
		{
			if (entry.Run === run)
				return entry.Group;
		}
		return 0;
	}

	/// The run is over (its Stop, its instance released): everything it plays fades out over
	/// `fadeSeconds`, then its group is freed. Other runs and the editor are untouched.
	public void EndRun(Object run, float fadeSeconds = 0.1f)
	{
		for (int i < mRuns.Count)
		{
			if (mRuns[i].Run !== run)
				continue;
			if (mEngine != null)
			{
				mEngine.StopRunGroup(mRuns[i].Group, fadeSeconds);
				mEndingRuns.Add(.() { Group = mRuns[i].Group, SecondsLeft = fadeSeconds + 0.05f });
			}
			mRuns.RemoveAt(i);
			break;
		}
		if (mFocusedRun === run)
		{
			mFocusedRun = null;
			ApplyRunAudibility();
		}
	}

	/// The host's pause (the toolbar's, a debugger break): the run's music and one shots
	/// freeze with the game. A game's own pause menu (time scale nought) is the game's business.
	public void SetRunPaused(Object run, bool paused)
	{
		let group = FindRunGroup(run);
		if (group != 0)
			mEngine.SetRunGroupPaused(group, paused);
	}

	/// The run the user is playing (the focused Game tab): with HearAllRuns off, only it is
	/// heard, and the others keep running muted. Null is no preference: every run is heard.
	public void SetFocusedRun(Object run)
	{
		mFocusedRun = run;
		ApplyRunAudibility();
	}

	public Object FocusedRun => mFocusedRun;

	/// The editor's preference, every Game tab heard (default off: the focused one only).
	public void SetHearAllRuns(bool all)
	{
		mHearAllRuns = all;
		ApplyRunAudibility();
	}

	public bool HearAllRuns => mHearAllRuns;

	/// Whether `run` is heard; scenes outside every run always are.
	public bool IsRunAudible(Object run) => (run == null) || mHearAllRuns || (mFocusedRun == null) || (mFocusedRun === run);

	private void ApplyRunAudibility()
	{
		if (mEngine == null)
			return;
		for (let entry in mRuns)
			mEngine.SetRunGroupMuted(entry.Group, !IsRunAudible(entry.Run));
	}

	/// Frees the ended runs whose fade out has finished.
	private void ReapEndedRuns(float deltaTime)
	{
		for (int i = mEndingRuns.Count - 1; i >= 0; i--)
		{
			mEndingRuns[i].SecondsLeft -= deltaTime;
			if (mEndingRuns[i].SecondsLeft <= 0.0f)
			{
				if (mEngine != null)
					mEngine.DestroyRunGroup(mEndingRuns[i].Group);
				mEndingRuns.RemoveAt(i);
			}
		}
	}

	public void Stop(VoiceHandle handle)
	{
		if (mEngine != null)
			mEngine.Stop(handle);
	}

	public bool IsPlaying(VoiceHandle handle) => (mEngine != null) && mEngine.IsPlaying(handle);

	public void SetBusVolume(AudioBus bus, float volume)
	{
		if (mEngine != null)
			mEngine.SetBusVolume(bus, volume);
	}

	public float BusVolume(AudioBus bus) => (mEngine != null) ? mEngine.BusVolume(bus) : 0.0f;

	// ---- content path playback ----
	//
	// The path is the source database's, which is the string an editor shows. The cook
	// mirrors both group paths and ids into the cooked database, so one string resolves
	// against the runtime's. Missing, uncooked or mistyped content WARNS ONCE per path and
	// does nothing: a script never faults over a content problem.
	//
	// A path resolves BY TYPE: a clip plays, and a cue resolves one weighted trigger.

	public VoiceHandle PlayOneShotByPath(ResourceManager resources, StringView path,
		AudioBus bus = .Effects, uint64 runGroup = 0)
	{
		ResolveContentPath(resources, path, var clip, var cue);
		if (cue != null)
		{
			var parameters = AudioPlayParams();
			parameters.Bus = bus;
			parameters.RunGroup = runGroup;
			return PlayCueResolved(cue, parameters);
		}
		return (clip != null) ? PlayOneShot(clip, bus, 1.0f, 1.0f, runGroup) : .();
	}

	public VoiceHandle PlayOneShot3DByPath(ResourceManager resources, StringView path,
		Float3 position, uint64 runGroup = 0)
	{
		ResolveContentPath(resources, path, var clip, var cue);
		var parameters = AudioPlayParams();
		parameters.RunGroup = runGroup;
		if (cue != null)
		{
			parameters.Spatial = true;
			parameters.Position = position;
			return PlayCueResolved(cue, parameters);
		}
		return (clip != null) ? PlayOneShot3D(clip, position, parameters) : .();
	}

	public VoiceHandle PlayCueByPath(ResourceManager resources, StringView path,
		AudioBus bus = .Effects, uint64 runGroup = 0)
	{
		ResolveContentPath(resources, path, var clip, var cue);
		if (cue != null)
			return PlayCueOneShot(cue, bus, runGroup);
		return (clip != null) ? PlayOneShot(clip, bus, 1.0f, 1.0f, runGroup) : .();
	}

	public VoiceHandle PlayMusicByPath(ResourceManager resources, StringView path,
		float crossFadeSeconds = 1.0f, uint64 runGroup = 0)
	{
		ResolveContentPath(resources, path, var clip, var cue);

		if ((clip == null) && (cue != null))
		{
			// Music from a cue: resolve ONE variant and cross fade to it.
			let state = CueState(cue);
			let pick = SoundCue.Resolve(cue, ref mCueRandom, state.LastVariant,
				ref state.SequentialCursor);
			if (pick.IsValid)
			{
				state.LastVariant = pick.VariantIndex;
				clip = cue.Variants[pick.VariantIndex].Clip;
			}
		}

		return (clip != null) ? PlayMusic(clip, crossFadeSeconds, 1.0f, runGroup) : .();
	}

	protected override void OnInit()
	{
		mEngine = new AudioEngine(mEngineSettings);

		// Scenes created before this ran are still waiting for an engine.
		for (let entry in mSystems)
			entry.System.SetEngine(mEngine);
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
	}

	protected override void OnShutdown()
	{
		if (Context != null)
		{
			if (let scenes = Context.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}

		DeleteAndNullify!(mEngine);
	}

	/// No listener component anywhere means the active CAMERA is the listener, which is what
	/// a scene without an authored listener expects to hear. The first camera wins.
	private static bool CameraListenerPose(Scene scene, out Float3 outPosition,
		out Float3 outForward, out Float3 outUp)
	{
		outPosition = .(0, 0, 0);
		outForward = .(0, 0, -1);
		outUp = .(0, 1, 0);

		let cameras = scene.GetSystem<CameraComponentManager>();
		if (cameras == null)
			return false;

		var found = false;
		var position = Float3(0, 0, 0);
		var forward = Float3(0, 0, -1);
		var up = Float3(0, 1, 0);

		cameras.ForEach(scope [&] (camera, entity) =>
			{
				if (found)
					return;

				let world = scene.GetWorldMatrix(entity);
				position = TransformPoint(Float3(0.0f, 0.0f, 0.0f), world);
				forward = Normalized(Float3(-world.M[2][0], -world.M[2][1], -world.M[2][2]));
				up = Normalized(Float3(world.M[1][0], world.M[1][1], world.M[1][2]));
				found = true;
			});

		outPosition = position;
		outForward = forward;
		outUp = up;
		return found;
	}

	/// The path's product, sniffed by the instance's TYPE. Binding through the manager caches
	/// it exactly as a component's reference does.
	private void ResolveContentPath(ResourceManager resources, StringView path,
		out AudioClip outClip, out SoundCue outCue)
	{
		outClip = null;
		outCue = null;

		let instance = resources.Database.GetInstanceByPath(path);
		if (instance == null)
		{
			WarnPathOnce(path, "there is no content at this path");
			return;
		}

		if (instance.TypeName.EndsWith("SoundCueSource"))
		{
			outCue = resources.Bind<SoundCue>(instance.Id).Get;
			if (outCue == null)
				WarnPathOnce(path, "the sound cue would not load, so it may be uncooked");
			return;
		}

		if (instance.TypeName.EndsWith("AudioClipSource"))
		{
			outClip = resources.Bind<AudioClip>(instance.Id).Get;
			if (outClip == null)
				WarnPathOnce(path, "the audio clip would not load, so it may be uncooked");
			return;
		}

		WarnPathOnce(path, "it is neither an audio clip nor a sound cue");
	}

	private void WarnPathOnce(StringView path, StringView reason)
	{
		let key = scope String(path);
		if (mWarnedPaths.Contains(key))
			return;

		mWarnedPaths.Add(new String(path));
		GlobalLog(.Warning,
			"Audio: playing '{}' was ignored because {}. Warned once for this path.", path,
			reason);
	}

	private CueOneShotState CueState(SoundCue cue)
	{
		if (mCueOneShotState.TryGetValue(cue, let existing))
			return existing;

		let created = new CueOneShotState();
		mCueOneShotState[cue] = created;
		return created;
	}

	private VoiceHandle PlayCueResolved(SoundCue cue, AudioPlayParams baseParams)
	{
		if ((mEngine == null) || (cue == null))
			return .();

		let state = CueState(cue);
		let pick = SoundCue.Resolve(cue, ref mCueRandom, state.LastVariant,
			ref state.SequentialCursor);
		if (!pick.IsValid)
			return .();

		state.LastVariant = pick.VariantIndex;

		var parameters = baseParams;
		parameters.Pitch *= pick.Pitch;
		parameters.Volume *= pick.Volume;
		// Distinct triggers are never merged with one another.
		parameters.AllowDedupe = false;

		return mEngine.Play(cue.Variants[pick.VariantIndex].Clip, parameters);
	}
}
