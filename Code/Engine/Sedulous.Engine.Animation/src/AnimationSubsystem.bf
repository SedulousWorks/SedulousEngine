using System;
using System.Collections;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// The application level animation subsystem.
///
/// The managers are scene systems, and the scene's own tick drives them. What this does per
/// frame is tell its listeners of the one-shots that ended in each running scene, and draw the
/// IK components that ask for it (DebugDraw) into each running scene's debug list, which
/// follows the navigation and physics precedent.
class AnimationSubsystem : Subsystem, ISceneObserver
{
	/// The watched scenes, BORROWED.
	private List<Scene> mScenes = new .() ~ delete _;
	/// BORROWED: a listener unregisters before it goes.
	private List<IAnimationListener> mListeners = new .() ~ delete _;
	/// Scratch: one scene's ended one-shots, drained from its managers.
	private List<OneShotEnded> mEnded = new .() ~ delete _;

	/// Registering twice is once.
	public void RegisterListener(IAnimationListener listener)
	{
		if ((listener == null) || mListeners.Contains(listener))
			return;
		mListeners.Add(listener);
	}

	public void UnregisterListener(IAnimationListener listener)
	{
		mListeners.Remove(listener);
	}

	public void OnSystemsReady(Scene scene)
	{
		mScenes.Add(scene);
	}

	public void OnDestroying(Scene scene)
	{
		for (int i = mScenes.Count - 1; i >= 0; i--)
		{
			if (mScenes[i] === scene)
			{
				mScenes.RemoveAt(i);
				return;
			}
		}
	}

	public override void Update(float deltaTime)
	{
		// Headless too: before the debug drawing, which needs a renderer.
		TellOneShotsEnded();
		if (Manager == null)
			return;
		let render = Manager.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		for (let scene in mScenes)
		{
			let twoBone = scene.GetSystem<TwoBoneIkComponentManager>();
			let aim = scene.GetSystem<AimIkComponentManager>();
			let feet = scene.GetSystem<FootIkComponentManager>();
			if (((twoBone == null) || (twoBone.Count == 0)) && ((aim == null) || (aim.Count == 0))
				&& ((feet == null) || (feet.Count == 0)))
				continue;

			using (ProfileScope("Animation.IkDebugDraw"))
			{
				let draw = render.DebugScene(scene);
				twoBone?.DrawDebug(draw);
				aim?.DrawDebug(draw);
				feet?.DrawDebug(draw);
			}
		}
	}

	private void TellOneShotsEnded()
	{
		for (let scene in mScenes)
		{
			mEnded.Clear();
			scene.GetSystem<AnimationGraphComponentManager>()?.DrainEnded(mEnded);
			scene.GetSystem<SkeletalAnimationComponentManager>()?.DrainEnded(mEnded);
			for (let ended in mEnded)
			{
				let event = AnimationOneShotEnded(scene, ended.Entity, ended.Clip);
				for (let listener in mListeners)
					listener.OnOneShotEnded(event);
			}
		}
		mEnded.Clear();
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
	}

	protected override void OnShutdown()
	{
		if (Manager == null)
			return;
		if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
			scenes.UnregisterObserver(this);
	}
}
