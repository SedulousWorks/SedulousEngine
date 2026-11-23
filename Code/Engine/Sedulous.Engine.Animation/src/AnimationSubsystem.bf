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
/// frame is post each running scene's ended one-shots and passed clip events to their entities
/// (AnimationEntityEvents), and draw the IK components that ask for it (DebugDraw) into each
/// running scene's debug list, which follows the navigation and physics precedent.
class AnimationSubsystem : Subsystem, ISceneObserver
{
	/// The watched scenes, BORROWED.
	private List<Scene> mScenes = new .() ~ delete _;
	/// Scratch: one scene's ended one-shots, drained from its managers.
	private List<OneShotEnded> mEnded = new .() ~ delete _;
	/// Scratch: one scene's clip events, drained from its managers.
	private List<ClipEventFired> mEvents = new .() ~ DeleteContainerAndItems!(_);

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
		PostAnimationEvents();
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

	private void PostAnimationEvents()
	{
		for (let scene in mScenes)
		{
			// Drained whether or not anything listens, so the managers' lists never grow.
			mEnded.Clear();
			scene.GetSystem<AnimationGraphComponentManager>()?.DrainEnded(mEnded);
			scene.GetSystem<SkeletalAnimationComponentManager>()?.DrainEnded(mEnded);
			ClearAndDeleteItems!(mEvents);
			scene.GetSystem<AnimationGraphComponentManager>()?.DrainEvents(mEvents);
			scene.GetSystem<SkeletalAnimationComponentManager>()?.DrainEvents(mEvents);
			if (!scene.WantsEntityEvents)
				continue;
			for (let ended in mEnded)
			{
				var clip = EntityEventArg.FromGuid(ended.Clip);
				scene.PostEntityEvent(.(ended.Entity, AnimationEntityEvents.Finished, .(&clip, 1)));
			}
			for (let fired in mEvents)
			{
				var name = EntityEventArg.FromString(fired.Name);
				scene.PostEntityEvent(.(fired.Entity, AnimationEntityEvents.ClipEvent, .(&name, 1)));
			}
		}
		mEnded.Clear();
		ClearAndDeleteItems!(mEvents);
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
