using System;
using System.Collections;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// The Context level animation subsystem.
///
/// The managers are scene systems, and the scene's own tick drives them. What this does per
/// frame is draw the IK components that ask for it (DebugDraw) into each running scene's debug
/// list, which follows the navigation and physics precedent.
class AnimationSubsystem : Subsystem, ISceneObserver
{
	/// The watched scenes, BORROWED.
	private List<Scene> mScenes = new .() ~ delete _;

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
		if (Context == null)
			return;
		let render = Context.GetSubsystem<RenderSubsystem>();
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
		if (Context == null)
			return;
		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.UnregisterObserver(this);
	}
}
