using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// One-shots and crossfades on the animated entities: a one-shot asked for on an animator
/// starts over its clip, plays and ends, and its end reaches the animation subsystem's
/// listeners with the entity and the clip; the manager says it plays and stops it; a clip
/// changed with a fade time eases in; a graph's entity takes a one-shot too.
static class OneShotTests
{
	private static bool Near(float a, float b, float epsilon = 1e-3f) => Math.Abs(a - b) <= epsilon;

	/// A clip that holds the one bone at height `y` for its whole duration.
	private static void Hold(AnimationClip clip, float y)
	{
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, y, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(clip.Duration, .(0, y, 0));
	}

	private class Listener : IAnimationListener
	{
		public List<AnimationOneShotEnded> Ended = new .() ~ delete _;

		public void OnOneShotEnded(AnimationOneShotEnded ended)
		{
			Ended.Add(ended);
		}
	}

	private class Stage
	{
		public Scene Level = new .("oneshots") ~ delete _;
		public Skeleton Skeleton = new .(1) ~ delete _;
		public EntityHandle Hero;

		public this()
		{
			Skeleton.Bones[0].Index = 0;
			Skeleton.Bones[0].ParentIndex = -1;
			Skeleton.FindRootBones();
			Skeleton.BuildChildIndices();
			Skeleton.ComputeInverseBindPoses();
			Level.AddSystem<MeshComponentManager>();
			AnimationScene.AddAnimationSceneManagers(Level);
			Hero = Level.CreateEntity("Hero");
		}

		public SkeletalAnimationComponentManager Animators => Level.GetSystem<SkeletalAnimationComponentManager>();
		public AnimationGraphComponentManager Graphs => Level.GetSystem<AnimationGraphComponentManager>();

		public SkeletalAnimationComponent* Animator(AnimationClip clip)
		{
			let animator = Animators.Add(Hero);
			animator.Skeleton.SetDirect(Skeleton);
			animator.Clip.SetDirect(clip);
			return animator;
		}

		public void Run(float seconds)
		{
			for (float t = 0.0f; t < seconds - 1.0e-4f; t += 0.01f)
				Level.Update(0.01f);
		}
	}

	private static float Height(SkeletalAnimationComponent* animator)
	{
		animator.Player.GetSkinningMatrices(); // evaluates
		return animator.Player.GetFinalPoses()[0].Position.Y;
	}

	[Test]
	public static void AOneShotAskedOfAnAnimatorPlaysOverItsClipEndsAndItsListenersHearIt()
	{
		let stage = scope Stage();
		let stand = scope AnimationClip("Stand", 1.0f, true);
		Hold(stand, 0.0f);
		let hop = scope AnimationClip("Hop", 0.5f, true);
		Hold(hop, 1.0f);
		let animator = stage.Animator(stand);
		stage.Run(0.05f); // the player is built and the clip plays

		let hopId = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7);
		// What the facade's PlayOneShot asks for, with a clip made in code.
		animator.OneShot.Clip.SetDirect(hop);
		animator.OneShot.Clip.SetId(hopId);
		animator.OneShot.Settings = .(1.0f, 0.1f, 0.1f, 0);
		animator.OneShot.Pending = true;
		Test.Assert(stage.Animators.IsPlayingOneShot(stage.Hero), "asked for counts as playing");

		let subsystem = scope AnimationSubsystem();
		let listener = scope Listener();
		subsystem.RegisterListener(listener);
		subsystem.RegisterListener(listener); // twice is once
		subsystem.OnSystemsReady(stage.Level);

		stage.Run(0.25f);
		Test.Assert(Near(Height(animator), 1.0f), "in full over the clip");
		Test.Assert(stage.Animators.IsPlayingOneShot(stage.Hero));
		subsystem.Update(0.0f);
		Test.Assert(listener.Ended.IsEmpty);

		stage.Run(0.35f);
		Test.Assert(!stage.Animators.IsPlayingOneShot(stage.Hero));
		Test.Assert(Near(Height(animator), 0.0f), "the clip's own pose again");
		subsystem.Update(0.0f);
		Test.Assert(listener.Ended.Count == 1);
		Test.Assert(listener.Ended[0].Scene === stage.Level);
		Test.Assert(listener.Ended[0].Entity == stage.Hero);
		Test.Assert(listener.Ended[0].Clip == hopId);
		subsystem.Update(0.0f);
		Test.Assert(listener.Ended.Count == 1, "told once");

		// Stopped, it blends out and is reported too.
		animator.OneShot.Settings = .(1.0f, 0.0f, 0.0f, -1);
		animator.OneShot.Pending = true;
		stage.Run(0.1f);
		Test.Assert(stage.Animators.IsPlayingOneShot(stage.Hero));
		stage.Animators.StopOneShot(stage.Hero, 0.05f);
		stage.Run(0.1f);
		Test.Assert(!stage.Animators.IsPlayingOneShot(stage.Hero));
		subsystem.Update(0.0f);
		Test.Assert(listener.Ended.Count == 2);
		subsystem.UnregisterListener(listener);
		subsystem.OnDestroying(stage.Level);
	}

	[Test]
	public static void AClipChangedWithAFadeTimeEasesIntoTheNewClip()
	{
		let stage = scope Stage();
		let high = scope AnimationClip("High", 1.0f, true);
		Hold(high, 1.0f);
		let low = scope AnimationClip("Low", 1.0f, true);
		Hold(low, 0.0f);
		let highAgain = scope AnimationClip("High again", 1.0f, true);
		Hold(highAgain, 1.0f);
		let animator = stage.Animator(high);
		stage.Run(0.1f);
		Test.Assert(Near(Height(animator), 1.0f));

		// What SetClip(entity, clip, 0.5) asks for, with a clip made in code.
		animator.ClipFade = 0.5f;
		animator.Clip.SetDirect(low);
		stage.Run(0.25f);
		Test.Assert(Near(Height(animator), 0.5f, 0.06f), "halfway through the fade");
		stage.Run(0.35f);
		Test.Assert(Near(Height(animator), 0.0f));
		Test.Assert(animator.ClipFade == 0.0f, "spent on that change");

		// No fade asked: at once.
		animator.Clip.SetDirect(highAgain);
		stage.Run(0.02f);
		Test.Assert(Near(Height(animator), 1.0f));
	}

	[Test]
	public static void AGraphsEntityTakesAOneShotOverItsGraph()
	{
		let stage = scope Stage();
		// No layers: its pose is the bind pose.
		let graph = scope AnimationGraph();
		let wave = scope AnimationClip("Wave", 0.3f, false);
		Hold(wave, 1.0f);
		let animator = stage.Graphs.Add(stage.Hero);
		animator.Skeleton.SetDirect(stage.Skeleton);
		animator.Graph.SetDirect(graph);
		stage.Run(0.02f);
		Test.Assert(animator.Player != null);

		animator.OneShot.Clip.SetDirect(wave);
		animator.OneShot.Settings = .(1.0f, 0.0f, 0.0f, 0);
		animator.OneShot.Pending = true;
		stage.Run(0.1f);
		Test.Assert(stage.Graphs.IsPlayingOneShot(stage.Hero));
		Test.Assert(Near(animator.Player.GetLocalPoses()[0].Position.Y, 1.0f));
		stage.Run(0.3f);
		Test.Assert(!stage.Graphs.IsPlayingOneShot(stage.Hero));
		Test.Assert(Near(animator.Player.GetLocalPoses()[0].Position.Y, 0.0f));
		let ended = scope List<OneShotEnded>();
		stage.Graphs.DrainEnded(ended);
		Test.Assert(ended.Count == 1);
		Test.Assert(ended[0].Entity == stage.Hero);
	}

	/// A request with no clip id, or before the scene was resolved against a resource manager,
	/// asks for nothing.
	[Test]
	public static void ARequestWithNothingToBindAsksForNothing()
	{
		let stage = scope Stage();
		let stand = scope AnimationClip("Stand", 1.0f, true);
		stage.Animator(stand);
		stage.Animators.PlayOneShot(stage.Hero, Guid(), .());
		Test.Assert(!stage.Animators.IsPlayingOneShot(stage.Hero));
		stage.Animators.PlayOneShot(stage.Hero, Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), .());
		Test.Assert(!stage.Animators.IsPlayingOneShot(stage.Hero), "no resource manager yet");
		// Stopping what never played, and asking of an entity with no animator, are quiet.
		stage.Animators.StopOneShot(stage.Hero, 0.2f);
		Test.Assert(!stage.Animators.IsPlayingOneShot(stage.Level.CreateEntity("Bare")));
	}
}
