using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The application level audio broker.
///
/// It owns the ONE engine, hands it to every scene's audio system, pushes the winning
/// listeners, and carries the engine global one shot surface that needs no entity at all.
class AudioSubsystem : Subsystem, ISceneObserver, IRunListener
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

	/// One live run's group, by its run's id.
	private struct RunEntry
	{
		public RunId Run;
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
	/// The heard run; nought hears every run.
	private RunId mFocusedRun = 0;
	/// BORROWED: the runs subscribed to, from OnReady to OnShutdown.
	private IRunManager mRunManager = null;
	/// The editor's preference, every Game tab heard rather than the focused one.
	private bool mHearAllRuns = false;
	/// The scene systems' way back to the run registry. OWNED.
	private delegate uint64(IRun run) mRunGroupResolver ~ delete _;
	/// `Audio` to scripts outside every run, on the application's services; OWNED.
	private AudioFacade mScriptFacade = null ~ delete _;
	/// `Audio` to each run's scripts, among its services, carrying the run; OWNED, by the run's id,
	/// until the run goes (or this subsystem shuts down).
	private List<(RunId run, AudioFacade facade)> mRunFacades = new .() ~ { for (let entry in _) delete entry.facade; delete _; };

	/// Where a script's asset ids resolve: the application's resource manager, read per call, since
	/// it may be handed over after this is made. Null resolves none. OWNED.
	public delegate ResourceManager() ScriptResources = null ~ delete _;

	public this(AudioEngineSettings engineSettings = null)
	{
		mEngineSettings = engineSettings;
		mScriptFacade = new AudioFacade(this, new [=this] () => ResolveScriptResources());
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

	// ---- runs: what one running game plays, keyed by its run's id (Scene.Run) ----
	//
	// A run's group follows its lifecycle (Raptor's run-context spec): its session's stop (or its
	// destruction) fades the group out, the host's pause pauses it, the run manager's focus decides
	// who is heard. No host relays any of it.

	private const float cRunFadeSeconds = 0.1f;

	/// The run's group, made on first use; nought for no run or no engine. A new run starts
	/// muted when another run holds the focus and only the focused run is heard, and paused when
	/// its run is.
	public uint64 RunGroupFor(IRun run)
	{
		if ((run == null) || (mEngine == null))
			return 0;
		let found = FindRunGroup(run.Id);
		if (found != 0)
			return found;
		let group = mEngine.CreateRunGroup();
		mRuns.Add(.() { Run = run.Id, Group = group });
		mEngine.SetRunGroupMuted(group, !IsRunAudible(run.Id));
		mEngine.SetRunGroupPaused(group, run.State == .Paused);
		return group;
	}

	/// The run's group if it has one, without making it; nought otherwise.
	public uint64 FindRunGroup(IRun run) => (run != null) ? FindRunGroup(run.Id) : 0;

	private uint64 FindRunGroup(RunId run)
	{
		for (let entry in mRuns)
		{
			if (entry.Run == run)
				return entry.Group;
		}
		return 0;
	}

	/// The run's session is over (stopped, or the run gone without a stop): what it plays fades
	/// out over `fadeSeconds`, then its group is freed. Other runs and the editor are untouched.
	private void EndRunGroup(RunId run, float fadeSeconds)
	{
		for (int i < mRuns.Count)
		{
			if (mRuns[i].Run != run)
				continue;
			if (mEngine != null)
			{
				mEngine.StopRunGroup(mRuns[i].Group, fadeSeconds);
				mEndingRuns.Add(.() { Group = mRuns[i].Group, SecondsLeft = fadeSeconds + 0.05f });
			}
			mRuns.RemoveAt(i);
			return;
		}
	}

	// IRunListener: the run manager's announcements.
	public void OnRunCreated(IRun run) => OfferRunFacade(run);
	public void OnRunStopping(IRun run) => EndRunGroup(run.Id, cRunFadeSeconds);
	public void OnRunDestroyed(IRun run)
	{
		EndRunGroup(run.Id, cRunFadeSeconds);
		// Its services are gone with it (the run disposed them first): its Audio goes too.
		for (int i < mRunFacades.Count)
		{
			if (mRunFacades[i].run != run.Id)
				continue;
			delete mRunFacades[i].facade;
			mRunFacades.RemoveAt(i);
			break;
		}
	}

	// ==================== scripts ====================

	/// The facades offered: the shared one on the application's services, each run's among the
	/// run's.
	public AudioFacade ScriptFacade => mScriptFacade;
	public int RunScriptFacadeCount => mRunFacades.Count;

	public override void OnRegister(SubsystemManager manager)
	{
		base.OnRegister(manager);
		manager.RegisterService(mScriptFacade);
	}

	public override void OnUnregister()
	{
		if (Manager != null)
			Manager.UnregisterService<AudioFacade>();
		base.OnUnregister();
	}

	private ResourceManager ResolveScriptResources() => (ScriptResources != null) ? ScriptResources() : null;

	// `run`'s own `Audio` among its services, carrying the run, so what its scripts play goes into
	// it and its bus volumes are its own. Once per run.
	private void OfferRunFacade(IRun run)
	{
		let held = run as RunBase;
		if (held == null)
			return;
		for (let entry in mRunFacades)
		{
			if (entry.run == run.Id)
				return;
		}
		let facade = new AudioFacade(this, new [=this] () => ResolveScriptResources(), run);
		mRunFacades.Add((run.Id, facade));
		held.Register<AudioFacade>(facade);
	}

	// The runs still alive let go of their `Audio`, which goes with this subsystem.
	private void WithdrawRunFacades()
	{
		if (mRunManager != null)
		{
			mRunManager.ForEachRun(scope (run) =>
				{
					let held = run as RunBase;
					if (held == null)
						return;
					let offered = held.FindService(typeof(AudioFacade));
					for (let entry in mRunFacades)
					{
						if (entry.facade === offered)
						{
							held.Remove<AudioFacade>();
							break;
						}
					}
				});
		}
		for (let entry in mRunFacades)
			delete entry.facade;
		mRunFacades.Clear();
	}

	public void OnRunPaused(IRun run, bool paused)
	{
		let group = FindRunGroup(run.Id);
		if ((group != 0) && (mEngine != null))
			mEngine.SetRunGroupPaused(group, paused);
	}

	public void OnFocusChanged(IRun focused)
	{
		mFocusedRun = (focused != null) ? focused.Id : 0;
		ApplyRunAudibility();
	}

	/// The editor's preference, every Game tab heard (default off: the focused one only).
	public void SetHearAllRuns(bool all)
	{
		mHearAllRuns = all;
		ApplyRunAudibility();
	}

	public bool HearAllRuns => mHearAllRuns;

	/// Whether `run` is heard; scenes outside every run always are.
	public bool IsRunAudible(IRun run) => (run == null) || IsRunAudible(run.Id);

	private bool IsRunAudible(RunId run) => mHearAllRuns || (mFocusedRun == 0) || (mFocusedRun == run);

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
		if (Manager == null)
			return;

		if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
		// The runs' lifecycle; caught up on what holds already (the focus; paused groups are made
		// paused when their run first plays).
		mRunManager = Manager.RunManager;
		if (mRunManager != null)
		{
			mRunManager.Subscribe(this);
			OnFocusChanged(mRunManager.Focused);
			// The runs made before this was ready get their `Audio` too.
			mRunManager.ForEachRun(scope (run) => { OfferRunFacade(run); });
		}
	}

	protected override void OnShutdown()
	{
		WithdrawRunFacades();
		if (mRunManager != null)
		{
			mRunManager.Unsubscribe(this);
			mRunManager = null;
		}
		if (Manager != null)
		{
			if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
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
