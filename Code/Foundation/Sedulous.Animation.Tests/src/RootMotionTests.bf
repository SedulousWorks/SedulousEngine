using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// Root motion deltas from the players (root-motion.md P1): a looping clip's frames sum to its
/// travel with nothing lost at the wrap, whole loops in one step and backward steps included; a
/// turn accumulates and the travel after it goes the new way; a blend tree blends motion by the
/// pose's weights; a crossfade changes speed without a step; only the base layer moves.
class RootMotionTests
{
	private static bool Near(float a, float b, float relative)
		=> Math.Abs(a - b) <= Math.Max(relative * Math.Max(Math.Abs(a), Math.Abs(b)), 1e-5f);

	/// A clip whose root walks `metres` along +Z over `seconds` (and turns `turn` radians), as
	/// the cook bakes it, with a track so a graph state has a pose to sample.
	private static void Walker(AnimationClip clip, float metres, float seconds = 1.0f, float turn = 0.0f, bool loop = true)
	{
		clip.Duration = seconds;
		clip.IsLooping = loop;
		clip.RootMotion.Horizontal = true;
		clip.RootMotion.Yaw = turn != 0.0f;
		for (int i <= 30)
		{
			let t = (float)i / 30.0f;
			clip.RootMotion.Times.Add(t * seconds);
			clip.RootMotion.Positions.Add(.(0, 0, metres * t));
			clip.RootMotion.Yaws.Add(turn * t);
		}
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 1, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(seconds, .(0, 1, 0));
	}

	private static void OneBone(Skeleton skeleton)
	{
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
	}

	[Test]
	public static void ALoopsFramesSumToItsTravelNothingLostAtTheWrap()
	{
		let walk = scope AnimationClip("walk");
		Walker(walk, 2.0f);
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let player = scope AnimationPlayer(skeleton);
		player.Play(walk);
		var total = RootMotionDelta();
		for (int frame < 75) // 3 s at 25 Hz: three loops, wrapping mid frame
		{
			player.Update(0.04f);
			total = RootMotion.Compose(total, player.ConsumeRootMotion());
		}
		Test.Assert(Near(total.Translation.Z, 6.0f, 1e-4f));
		Test.Assert(Math.Abs(total.Translation.X) < 1e-5f);
		Test.Assert(player.ConsumeRootMotion().IsZero, "read: reset");

		// One step of two and a half loops counts every loop.
		let far = scope AnimationPlayer(skeleton);
		far.Play(walk);
		far.Update(0.3f);
		far.ConsumeRootMotion();
		far.Update(2.5f);
		Test.Assert(Near(far.ConsumeRootMotion().Translation.Z, 5.0f, 1e-4f));

		// Played backwards it walks back.
		let back = scope AnimationPlayer(skeleton);
		back.Play(walk);
		back.Speed = -1.0f;
		back.Update(1.5f);
		Test.Assert(Near(back.ConsumeRootMotion().Translation.Z, -3.0f, 1e-4f));

		// A clip that does not loop stops at its end.
		let once = scope AnimationClip("once");
		Walker(once, 2.0f, 1.0f, 0.0f, false);
		let stop = scope AnimationPlayer(skeleton);
		stop.Play(once);
		stop.Update(0.75f);
		stop.Update(0.75f);
		Test.Assert(Near(stop.ConsumeRootMotion().Translation.Z, 2.0f, 1e-4f));
	}

	/// A quarter turn while walking 2 m, per loop: four loops come round, the walk drawing a
	/// closed path back near its start rather than a straight 8 m line.
	[Test]
	public static void ATurnAccumulatesAndTheTravelAfterItGoesTheNewWay()
	{
		let arc = scope AnimationClip("arc");
		Walker(arc, 2.0f, 1.0f, HalfPi);
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let player = scope AnimationPlayer(skeleton);
		player.Play(arc);
		var total = RootMotionDelta();
		for (int frame < 120)
		{
			player.Update(1.0f / 30.0f);
			total = RootMotion.Compose(total, player.ConsumeRootMotion());
		}
		Test.Assert(Near(total.Yaw, 4.0f * HalfPi, 1e-3f));
		Test.Assert(Length(total.Translation) < 0.1f, "round the square, back where it began");
		// One loop on its own: a quarter turn, and its travel in the frame it started facing.
		let one = RootMotion.ClipRootMotion(arc, 0.0f, 1.0f, true);
		Test.Assert(Near(one.Yaw, HalfPi, 1e-4f));
		Test.Assert(Near(one.Translation.Z, 2.0f, 1e-3f));
	}

	/// Walk (2 m/s) and Run (4 m/s) in a 1D tree on Speed (0..1), or the same clips as two states
	/// with a half second fade on Running.
	private class Gaits
	{
		public AnimationClip Walk = new .("walk") ~ delete _;
		public AnimationClip Run = new .("run") ~ delete _;
		public AnimationGraph Graph = new .() ~ delete _;
		public int32 Speed = -1;
		public int32 Running = -1;

		public this(bool tree)
		{
			Walker(Walk, 2.0f);
			Walker(Run, 4.0f);
			Speed = Graph.AddParameter("Speed", .Float);
			Running = Graph.AddParameter("Running", .Bool);
			let layer = new AnimationLayer("Base");
			if (tree)
			{
				let blend = new BlendTree1D();
				blend.ParameterIndex = Speed;
				blend.AddEntry(0.0f, Walk);
				blend.AddEntry(1.0f, Run);
				layer.AddState(new AnimationGraphState("Move", blend, true));
			}
			else
			{
				layer.AddState(new AnimationGraphState("Walk", new ClipStateNode(Walk), true));
				layer.AddState(new AnimationGraphState("Run", new ClipStateNode(Run), true));
				let toRun = new AnimationGraphTransition();
				toRun.SourceStateIndex = 0;
				toRun.DestStateIndex = 1;
				toRun.Duration = 0.5f;
				toRun.AddBoolCondition(Running, true);
				layer.AddTransition(toRun);
			}
			Graph.AddLayer(layer);
		}
	}

	[Test]
	public static void AHalfAndHalfBlendOfTwoWalksMovesAtTheMeanSpeed()
	{
		let gaits = scope Gaits(true);
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let player = scope AnimationGraphPlayer(gaits.Graph, skeleton);
		player.SetFloat(gaits.Speed, 0.5f);
		var total = RootMotionDelta();
		for (int frame < 60) // 2 s
		{
			player.Update(1.0f / 30.0f);
			total = RootMotion.Compose(total, player.ConsumeRootMotion());
		}
		Test.Assert(Near(total.Translation.Z, 6.0f, 1e-3f), "3 m/s");
		player.SetFloat(gaits.Speed, 1.0f);
		player.Update(0.5f);
		Test.Assert(Near(player.ConsumeRootMotion().Translation.Z, 2.0f, 1e-3f), "all run");
	}

	[Test]
	public static void ACrossfadeChangesSpeedWithoutAStepAtEitherEnd()
	{
		let gaits = scope Gaits(false);
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let player = scope AnimationGraphPlayer(gaits.Graph, skeleton);
		let dt = 1.0f / 60.0f;
		var previous = -1.0f;
		var largestJump = 0.0f;
		for (int frame < 120)
		{
			if (frame == 30)
				player.SetBool(gaits.Running, true); // a half second fade from 2 to 4 m/s
			player.Update(dt);
			let step = player.ConsumeRootMotion().Translation.Z;
			if (previous >= 0.0f)
				largestJump = Math.Max(largestJump, Math.Abs(step - previous));
			previous = step;
		}
		Test.Assert(Near(previous, 4.0f * dt, 1e-3f), "running, after the fade");
		// The fade spreads the change over 30 frames: no frame differs from the one before by
		// more than a few times the even share (2 m/s * dt / 30 frames).
		Test.Assert(largestJump < 3.0f * (2.0f * dt / 30.0f));
	}

	[Test]
	public static void OnlyTheBaseLayerMovesTheCharacter()
	{
		let still = scope AnimationClip("still");
		Walker(still, 0.0f);
		let walk = scope AnimationClip("walk");
		Walker(walk, 2.0f);
		let graph = scope AnimationGraph();
		let baseLayer = new AnimationLayer("Base");
		baseLayer.AddState(new AnimationGraphState("Stand", new ClipStateNode(still), true));
		graph.AddLayer(baseLayer);
		let upper = new AnimationLayer("Upper");
		upper.AddState(new AnimationGraphState("Walk", new ClipStateNode(walk), true));
		graph.AddLayer(upper);
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let player = scope AnimationGraphPlayer(graph, skeleton);
		player.Update(0.5f);
		Test.Assert(player.ConsumeRootMotion().IsZero);
	}
}
