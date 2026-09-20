using System;
using System.Collections;
using Sedulous.Core;
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
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

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

		if (mGameInstance != null)
		{
			EnableDebugging();
			StartGameScriptFromProject();
		}

		if (instance != null)
		{
			let startScene = SceneGroup.CreateScene(instance.Name);
			if ((startScene == null) || !(SceneStorage.LoadScene(instance, startScene) case .Ok))
			{
				mContext.Notify(.Error, "Game: default scene failed to load.");
				if (startScene != null)
					SceneGroup.DestroyScene(startScene);
				if (mGameInstance != null)
					mGameInstance.StopScript(); // the script launched first; do not leave it running
				return;
			}
			if (mContext.Resources != null)
				SceneResolve.ResolveSceneResources(startScene, mContext.Resources);
			if (startScene.PendingPrefabInstanceCount > 0)
			{
				let resolver = ProjectPrefabResolver(mContext);
				defer delete resolver;
				ScenePrefabs.ResolveScenePrefabs(startScene, resolver);
				if (mContext.Resources != null)
					SceneResolve.ResolveSceneResources(startScene, mContext.Resources);
			}
			EnsureCamera(startScene);
			startScene.Start();
			startScene.SetSimulationEnabled(true);
			if (mGameInstance != null)
				mGameInstance.SetScene(startScene);
			else
				mScene = startScene; // no instance to track a current scene
		}

		mRunning = true;
		if (mPauseToggle != null)
			mPauseToggle.IsChecked = false;
		if (mGameInstance != null)
			mScene = mGameInstance.GetScene();
		mSceneTitle.Set((mScene != null) ? mScene.Name : "(no scene)");
		BindInput();
		BindBusLayout();
		GlobalLog(.Information, "Editor: Game: running scene '{}'", mSceneTitle);
		RefreshToolbar();
	}

	public void Stop()
	{
		mPendingPlay = false; // a Stop while waiting for the cook cancels the deferred start
		if (!mRunning && (mScene == null))
			return;
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
		if (mGameInstance != null)
			mGameInstance.StopScript();
		{
			let active = scope List<Sedulous.Scene.Scene>();
			active.AddRange(SceneGroup.ActiveScenes);
			for (let s in active)
				s.Stop();
			if (mGameInstance != null)
				mGameInstance.ClearScenes();
			else
				mFallbackScenes.Clear();
			mScene = null;
		}
		mRunning = false;
		RefreshToolbar();
	}

	/// The script may have switched scenes; follow it, and drop the ones it left.
	private void FollowInstanceScene()
	{
		if (!mRunning || (mGameInstance == null))
			return;
		let current = mGameInstance.GetScene();
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
			mGameInstance.DestroyScene(s); // drops any matching tracked load too
		}

		if (mInput != null)
			mInput.SetSourceProvider(mViewportSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mScene != null)
		{
			EnsureCamera(mScene);
			let paused = mSimPausedByDebugger || ((mPauseToggle != null) && mPauseToggle.IsChecked);
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
		mInput.SetSourceProvider(mViewportSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mGameInstance != null)
			mGameInstance.SetInputSource(mViewportSource);
		let mapId = mContext.Project.Settings.DefaultInputMapId;
		if (mapId.IsNil || (mContext.Resources == null))
			return;
		let map = mContext.Resources.Bind<InputMapResource>(mapId).Get;
		if (map != null)
		{
			if (mGameInstance != null)
				mGameInstance.SetInputMap(map.Map);
			GlobalLog(.Information, "Editor: Game: input map bound");
		}
		else
		{
			mContext.Notify(.Warning, "Game: default input map is not cooked yet.");
		}
	}

	private void BindBusLayout()
	{
		let audio = mHost.Context.GetSubsystem<AudioSubsystem>();
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
		let scriptClass = mContext.Resources.Bind<ScriptClass>(scriptId).Get;
		if ((scriptClass == null) || scriptClass.Source.IsEmpty)
		{
			mContext.Notify(.Warning, "Game: startup script asset not found.");
			return;
		}
		if ((mGameInstance == null) || !mGameInstance.StartScript(scriptClass))
			mContext.Notify(.Error, "Game: startup script failed to start (see Console).");
	}

	/// A prefab payload resolver over the project's source database. The caller owns it.
	public static ScenePrefabs.PayloadResolver ProjectPrefabResolver(EditorContext context)
	{
		return new [=context](prefabId) =>
		{
			if (context.Project == null)
				return null;
			let prefab = context.Project.SourceDb.GetInstance(prefabId);
			return (prefab != null) ? prefab.ReadData("scene") : null;
		};
	}
}
