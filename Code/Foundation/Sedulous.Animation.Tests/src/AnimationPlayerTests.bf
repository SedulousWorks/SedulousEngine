using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// Single clip playback: the clock, the looping, the events, and the matrices.
class AnimationPlayerTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A skeleton whose bones are all roots at the identity, which is enough for anything
	/// that is about the clock rather than the hierarchy.
	private static void SetupBones(Skeleton skeleton)
	{
		for (let bone in skeleton.Bones)
			bone.ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	[Test]
	public static void AnEventFiresWhenTheClockCrossesIt()
	{
		let skeleton = scope Skeleton(2);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		var fireCount = 0;
		player.SetEventHandler(new [&](name, time) => { fireCount++; });

		let clip = scope AnimationClip("Test", 1.0f);
		clip.AddEvent(0.5f, "Hit");
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void TheEventsFireInOrderAcrossUpdates()
	{
		let skeleton = scope Skeleton(2);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		let fired = scope List<String>();
		defer { ClearAndDeleteItems!(fired); }
		player.SetEventHandler(new [&](name, time) => { fired.Add(new String(name)); });

		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(0.3f, "A");
		clip.AddEvent(0.8f, "B");
		clip.AddEvent(1.5f, "C");
		clip.SortEvents();
		player.Play(clip);

		player.Update(0.5f);
		Test.Assert(fired.Count == 1);
		Test.Assert(fired[0] == "A");
		player.Update(0.5f);
		Test.Assert(fired.Count == 2);
		Test.Assert(fired[1] == "B");
		player.Update(0.5f);
		Test.Assert(fired.Count == 3);
		Test.Assert(fired[2] == "C");
	}

	/// A loop fires its events EVERY time round, and never stops.
	[Test]
	public static void ALoopingClipFiresEachTimeRoundAndWrapsTheClock()
	{
		let skeleton = scope Skeleton(2);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		var fireCount = 0;
		player.SetEventHandler(new [&](name, time) => { fireCount++; });

		let clip = scope AnimationClip("Test", 1.0f, true);
		clip.AddEvent(0.5f, "Hit");
		player.Play(clip);

		player.Update(0.8f);
		Test.Assert(fireCount == 1);
		player.Update(0.8f);
		Test.Assert(fireCount == 2);
		Test.Assert(player.CurrentTime < 1.0f, "wrapped");
		Test.Assert(player.State == .Playing, "a loop never ends");
	}

	[Test]
	public static void ANonLoopingClipClampsAndStops()
	{
		let skeleton = scope Skeleton(2);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		let clip = scope AnimationClip("Test", 1.0f, false);
		player.Play(clip);
		player.Update(2.0f);

		Test.Assert(Near(player.CurrentTime, 1.0f));
		Test.Assert(player.State == .Stopped);
	}

	/// Setting a handler REPLACES the one before it: a player drives one thing.
	[Test]
	public static void SettingAHandlerReplacesTheOneBeforeIt()
	{
		let skeleton = scope Skeleton(2);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		var first = 0;
		var second = 0;

		let clip = scope AnimationClip("Test", 1.0f);
		clip.AddEvent(0.5f, "Hit");

		player.SetEventHandler(new [&](name, time) => { first++; });
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(first == 1);
		Test.Assert(second == 0);

		player.SetEventHandler(new [&](name, time) => { second++; });
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(first == 1, "the old handler is gone, not merely quiet");
		Test.Assert(second == 1);
	}

	/// The whole point: a clip's keyframes become the matrices that get uploaded.
	[Test]
	public static void EvaluatingDrivesTheSkinningMatricesFromTheClip()
	{
		let skeleton = scope Skeleton(1);
		SetupBones(skeleton);

		let clip = scope AnimationClip("move", 1.0f);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(1.0f, .(0, 10, 0));

		let player = scope AnimationPlayer(skeleton);
		player.Play(clip);
		player.SetCurrentTime(1.0f);

		let skin = player.GetSkinningMatrices();
		Test.Assert(skin.Length == 1);
		// Ten up from a bind pose that was the identity.
		Test.Assert(Near(skin[0].M[3][1], 10.0f));
	}

	/// Stopping puts the poses back to the bind pose and forgets the clip; pausing holds
	/// the clock exactly where it was.
	[Test]
	public static void StoppingResetsAndPausingHolds()
	{
		let skeleton = scope Skeleton(1);
		SetupBones(skeleton);

		let clip = scope AnimationClip("move", 2.0f, true);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(2.0f, .(0, 20, 0));

		let player = scope AnimationPlayer(skeleton);
		player.Play(clip);
		player.Update(0.5f);

		player.Pause();
		Test.Assert(player.State == .Paused);
		let held = player.CurrentTime;
		player.Update(0.5f);
		Test.Assert(Near(player.CurrentTime, held), "a paused clock does not move");

		player.Resume();
		player.Update(0.5f);
		Test.Assert(player.CurrentTime > held);

		player.Stop();
		Test.Assert(player.State == .Stopped);
		Test.Assert(player.CurrentTime == 0.0f);
		Test.Assert(player.CurrentClip == null);
		Test.Assert(player.GetLocalPoses()[0].Position == Float3(0, 0, 0), "back at the bind pose");
	}

	/// A bone written directly survives evaluation, which is what procedural animation
	/// needs; and a blend lays another clip over the poses already there.
	[Test]
	public static void ABoneCanBeSetDirectlyAndAnotherClipBlendedOver()
	{
		let skeleton = scope Skeleton(1);
		SetupBones(skeleton);
		let player = scope AnimationPlayer(skeleton);

		player.SetBonePose(0, .(.(0, 4, 0), Quaternion.Identity, .(1, 1, 1)));
		Test.Assert(player.GetLocalPoses()[0].Position == Float3(0, 4, 0));

		let clip = scope AnimationClip("move", 1.0f);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 8, 0));
		track.AddKeyframe(1.0f, .(0, 8, 0));

		// Halfway between what was there and what the clip says.
		player.BlendAnimation(clip, 0.0f, 0.5f);
		Test.Assert(Near(player.GetLocalPoses()[0].Position.Y, 6.0f));

		// No weight at all changes nothing.
		player.BlendAnimation(clip, 0.0f, 0.0f);
		Test.Assert(Near(player.GetLocalPoses()[0].Position.Y, 6.0f));
	}
}
