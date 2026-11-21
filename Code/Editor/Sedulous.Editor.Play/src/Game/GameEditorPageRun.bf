using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Input;
using Sedulous.Input.Resource;
using Sedulous.Audio.Resource;
using Sedulous.Script.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Project;
using Sedulous.Engine.DefaultApp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Play;

/// Starting and stopping a run: the default scene into the instance, the startup script,
/// the input map and bus layout, and following the scene the script switches to.
extension GameEditorPage
{
	private void StartRunNow()
	{
		if (mRunning || (mScenes == null) || (mContext.Project == null))
			return;

		let project = mContext.Project;
		Instance instance = null;
		if (!project.Settings.DefaultSceneId.IsNil)
			instance = project.SourceDb.GetInstance(project.Settings.DefaultSceneId);
		if ((instance == null) && !project.Settings.DefaultScene.IsEmpty)
			instance = project.SourceDb.GetInstanceByPath(project.Settings.DefaultScene);
		if (instance == null)
			GlobalLog(.Information, "Editor: Game: no default scene - the game script owns boot.");

		mFrameCount = 0;
		mStoppedRunTime = 0;
		if (mApplicationRun != null)
		{
			mApplicationRun.ResetRunClock(); // run time counts from this start
			// A Game tab keeps its own save in the project's ignored Editor/ folder, so testing
			// never touches a player's save.
			let saveName = ProjectLayout.SaveFileName(project.Settings.Name, .. scope String());
			mApplicationRun.SetSaveFile(PathJoin(project.EditorStateRoot(.. scope String()), saveName, .. scope String()));
			// The project's levels as they are at this start, for the run's scripts.
			QualityLevels.Offer(mApplicationRun.Quality, project.Settings, mContext.Resources, .());
			SyncQualityChoice();
			EnableDebugging();
			StartGameScriptFromProject();
		}

		if (instance != null)
		{
			// Through the INSTANCE when there is one: its scenes belong to its run, so their
			// behaviours run on the run's script host, where Input and Run live. The bare group's
			// scenes have no run and use the subsystem's default host, where a behaviour reading
			// Input faults.
			let startScene = (mApplicationRun != null) ? mApplicationRun.CreateScene(instance.Name) : mFallbackScenes.CreateScene(instance.Name);
			if ((startScene == null) || !(SceneStorage.LoadScene(instance, startScene) case .Ok))
			{
				mContext.Notify(.Error, "Game: default scene failed to load.");
				// Undone as a Stop undoes a run: the script launched above, the debugger wired to
				// this tab, the scenes. Left wired, the editor would call into this tab once closed.
				TearDownRun();
				return;
			}
			if (mContext.Resources != null)
				SceneResolve.ResolveSceneResources(startScene, mContext.Resources);
			// The prefabs it places come from the run's resources, as a level the game loads
			// later does, so the run places a prefab as it spawns one.
			if ((startScene.PendingPrefabInstanceCount > 0) && (mContext.Resources != null))
			{
				ScenePrefabs.ResolveScenePrefabs(startScene, mContext.Resources);
				SceneResolve.ResolveSceneResources(startScene, mContext.Resources);
			}
			EnsureCamera(startScene);
			startScene.Start();
			startScene.SetSimulationEnabled(true);
			if (mApplicationRun != null)
				mApplicationRun.SetScene(startScene);
			else
				mScene = startScene; // no instance to track a current scene
		}

		mRunning = true;
		if (mApplicationRun != null)
			mApplicationRun.Start(); // the run's session: whatever follows the run's lifecycle hears it
		if (mPauseToggle != null)
			mPauseToggle.Checked = false;
		if (mApplicationRun != null)
			mScene = mApplicationRun.GetScene();
		mSceneTitle.Set((mScene != null) ? mScene.Name : "(no scene)");
		BindInput();
		BindBusLayout();
		// The tab Play was pressed in is the one played (and heard).
		if ((mApp != null) && (mApp.Runs != null) && (mApplicationRun != null))
			mApp.Runs.SetFocused(mApplicationRun);
		GlobalLog(.Information, "Editor: Game: running scene '{}'", mSceneTitle);
		RefreshToolbar();
	}

	public void Stop()
	{
		mPendingPlay = false; // a Stop while waiting for the cook cancels the deferred start
		if (!mRunning && (mScene == null))
			return;
		TearDownRun();
	}

	/// Undoes whatever a run set up, however far its start got: the debugger wired to this tab,
	/// the script, the scenes, the input. Stop and every failed start end through it.
	private void TearDownRun()
	{
		DropScriptedInput(); // a stopped run scripts nothing
		if (mInput != null)
		{
			mInput.SetMap(scope InputMap()); // an empty map: the run's actions die with it
			mInput.SetSourceProvider(mViewportSource, null);
		}
		if (let debugger = mDebuggerPanel.Debugger)
			debugger.SetListener(null);
		mDebuggerPanel.SetIdle();
		mSimPausedByDebugger = false;
		mContext.ClearScriptExecutionPoint(); // no run, no paused location
		delete mContext.ScriptValueProbe; // hover values die with the run
		mContext.ScriptValueProbe = null;
		delete mContext.OnBreakpointsChanged; // the live sync dies with the run
		mContext.OnBreakpointsChanged = null;
		ClearAndDeleteItems(mAppliedBreakpoints);
		if (mRunning && (mApplicationRun != null))
			mStoppedRunTime = mApplicationRun.RunTime;
		if (mApplicationRun != null)
			mApplicationRun.StopRunBehavior();
		// The run's session ends: its sound fades out and its screens go with it, as everything
		// following the run's lifecycle hears (another tab's run and the editor's own play on).
		if (mApplicationRun != null)
			mApplicationRun.Stop();
		{
			let active = scope List<Sedulous.Scene.Scene>();
			active.AddRange(SceneGroup.ActiveScenes);
			for (let s in active)
				s.Stop();
			if (mApplicationRun != null)
				mApplicationRun.ClearScenes();
			else
				mFallbackScenes.Clear();
			mScene = null;
		}
		mRunning = false;
		mViewport.ClearPicture(); // the run's last frame does not linger
		RefreshToolbar();
	}

	/// The script may have switched scenes; follow it, and drop the ones it left.
	private void FollowInstanceScene()
	{
		if (!mRunning || (mApplicationRun == null))
			return;
		let current = mApplicationRun.GetScene();
		if (current == mScene)
			return;
		mScene = current; // may be null: a script that unloaded without loading

		let outgoing = scope List<Sedulous.Scene.Scene>();
		for (let s in SceneGroup.ActiveScenes)
		{
			if (s != mScene)
				outgoing.Add(s);
		}
		for (let s in outgoing)
		{
			s.Stop();
			mApplicationRun.DestroyScene(s); // drops any matching tracked load too
		}

		if (mInput != null)
			mInput.SetSourceProvider(ActiveSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mScene != null)
		{
			EnsureCamera(mScene);
			let paused = mSimPausedByDebugger || ((mPauseToggle != null) && mPauseToggle.Checked);
			if (paused)
				mScene.SetSimulationEnabled(false);
			mSceneTitle.Set(mScene.Name);
		}
		else
		{
			mSceneTitle.Set("(no scene)");
		}
		GlobalLog(.Information, "Editor: Game: running scene '{}'", mSceneTitle);
		RefreshToolbar();
	}

	/// A scene with no camera gets a default one, so a run is never a black screen.
	private static void EnsureCamera(Sedulous.Scene.Scene scene)
	{
		let cameras = scene.GetSystem<CameraComponentManager>();
		if ((cameras == null) || (cameras.ComponentCount > 0))
			return;
		GlobalLog(.Warning, "Editor: Game: scene has no camera - adding a default one");
		let e = scene.CreateEntity("PlayerCamera");
		var t = Transform();
		t.Position = .(8.0f, 6.0f, 10.0f);
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.675f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.42f);
		scene.SetLocalTransform(e, t);
		cameras.Add(e);
	}

	private void BindInput()
	{
		if (mInput == null)
			return;
		mViewportSource.Viewport = mViewport;
		mViewportSource.ShellInput = mShellInput;
		mInput.SetSourceProvider(ActiveSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mApplicationRun != null)
			mApplicationRun.SetInputSource(ActiveSource);
		let mapId = mContext.Project.Settings.DefaultInputMapId;
		if (mapId.IsNil || (mContext.Resources == null))
			return;
		let map = mContext.Resources.Bind<InputMapResource>(mapId).Get;
		if (map != null)
		{
			if (mApplicationRun != null)
				mApplicationRun.SetInputMap(map.Map);
			GlobalLog(.Information, "Editor: Game: input map bound");
		}
		else
		{
			mContext.Notify(.Warning, "Game: default input map is not cooked yet.");
		}
	}

	/// The sound, BORROWED: the hear-all preference (the run's stop, pause and focus reach it through
	/// the run). Null with no audio.
	private AudioSubsystem Audio => mHost?.Subsystems?.GetSubsystem<AudioSubsystem>();

	/// The run follows the tab: the host's pause and the focus, and the sound the hear-all preference.
	private void SyncRunAudio()
	{
		let audio = Audio;
		if ((audio == null) || (mApplicationRun == null))
			return;
		let hearAll = GameAudioEditorSettings.HearAllRunsPreference(mContext);
		if (audio.HearAllRuns != hearAll)
			audio.SetHearAllRuns(hearAll);
		if (!mRunning)
			return;
		// The toolbar's pause and a debugger break freeze the run's sound with the game (a
		// game's own pause menu is time scale nought, the game's business: its music plays on).
		let paused = mSimPausedByDebugger || ((mPauseToggle != null) && mPauseToggle.Checked);
		mApplicationRun.SetPaused(paused); // the host's pause: the run (its sound with it) hears it once per change
		// Clicking into this tab's viewport makes its run the one played, and the one heard.
		let runs = (mApp != null) ? mApp.Runs : null;
		if (mViewport.IsFocused && (runs != null) && ((Object)runs.Focused !== mApplicationRun))
			runs.SetFocused(mApplicationRun);
	}

	private void BindBusLayout()
	{
		let audio = mHost.Subsystems.GetSubsystem<AudioSubsystem>();
		if ((audio == null) || (audio.Engine == null))
			return;
		let layoutId = mContext.Project.Settings.DefaultBusLayoutId;
		if (layoutId.IsNil || (mContext.Resources == null))
			return;
		let layout = mContext.Resources.Bind<AudioBusLayoutResource>(layoutId).Get;
		if (layout != null)
		{
			audio.Engine.ApplyBusLayout(layout.Layout);
			GlobalLog(.Information, "Editor: Game: audio bus layout applied");
		}
		else
		{
			mContext.Notify(.Warning, "Game: default bus layout is not cooked yet.");
		}
	}

	private void StartGameScriptFromProject()
	{
		let scriptId = mContext.Project.Settings.StartupScriptId;
		if (scriptId.IsNil || (mContext.Resources == null))
			return;
		let scriptClass = mContext.Resources.Bind<BehaviorClass>(scriptId).Get;
		if ((scriptClass == null) || scriptClass.Source.IsEmpty)
		{
			mContext.Notify(.Warning, "Game: startup script asset not found.");
			return;
		}
		if ((mApplicationRun == null) || !mApplicationRun.StartRunBehavior(scriptClass))
			mContext.Notify(.Error, "Game: startup script failed to start (see Console).");
	}
}
