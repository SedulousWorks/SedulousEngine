using System;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// PoseOverlay on the players: a one-shot blends in over the clip's pose, plays once whatever its
/// own looping, blends out and says it ended; it plays its loops, or until stopped; a stop blends
/// it out; a crossfade eases from the old clip's pose into the new; a graph's pose takes one too.
class PoseOverlayTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static void OneBone(Skeleton skeleton)
	{
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	/// A clip that holds the bone at height `y` for its whole duration.
	private static void Holding(AnimationClip clip, float y)
	{
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, y, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(clip.Duration, .(0, y, 0));
	}

	/// The bone's height as the player last showed it.
	private static float Height(AnimationPlayer player)
	{
		player.GetSkinningMatrices(); // evaluates
		return player.GetFinalPoses()[0].Position.Y;
	}

	/// Runs the player `seconds` in 1/100 s steps; how many one-shots ended meanwhile.
	private static int Run(AnimationPlayer player, float seconds)
	{
		var ended = 0;
		for (float t = 0.0f; t < seconds - 1.0e-4f; t += 0.01f)
		{
			player.Update(0.01f);
			if (player.ConsumeOneShotEnded())
				ended++;
		}
		return ended;
	}

	[Test]
	public static void AOneShotBlendsInPlaysOnceThoughItLoopsBlendsOutAndEnds()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let stand = scope AnimationClip("Stand", 1.0f, true);
		Holding(stand, 0.0f);
		// A looping clip: the one-shot still plays it once.
		let hop = scope AnimationClip("Hop", 1.0f, true);
		Holding(hop, 1.0f);
		let player = scope AnimationPlayer(skeleton);
		player.Play(stand);
		player.Overlay.PlayOneShot(hop, .(1.0f, 0.2f, 0.2f, 0));
		Test.Assert(player.Overlay.IsPlayingOneShot);

		Test.Assert(Run(player, 0.1f) == 0);
		Test.Assert(Near(Height(player), 0.5f, 0.06f), "halfway in");
		Test.Assert(Run(player, 0.4f) == 0);
		Test.Assert(Near(Height(player), 1.0f), "in full");
		Test.Assert(Run(player, 0.4f) == 0);
		Test.Assert(Height(player) < 0.6f, "on its way out");
		Test.Assert(Run(player, 0.2f) == 1, "ended once");
		Test.Assert(!player.Overlay.IsPlayingOneShot);
		Test.Assert(Near(Height(player), 0.0f), "the clip's own pose again");
		Test.Assert(player.State == .Playing, "the clip played on underneath");
		Test.Assert(Run(player, 1.0f) == 0);
	}

	[Test]
	public static void AOneShotPlaysItsLoopsOrUntilStoppedAndAStopBlendsItOut()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let stand = scope AnimationClip("Stand", 1.0f, true);
		Holding(stand, 0.0f);
		let wave = scope AnimationClip("Wave", 0.5f, false);
		Holding(wave, 1.0f);
		let player = scope AnimationPlayer(skeleton);
		player.Play(stand);

		// Once more after the first: two plays, a second in all.
		player.Overlay.PlayOneShot(wave, .(1.0f, 0.0f, 0.0f, 1));
		Test.Assert(Run(player, 0.9f) == 0);
		Test.Assert(Near(Height(player), 1.0f));
		Test.Assert(Run(player, 0.2f) == 1);

		// Until stopped: still playing long after its length; a stop takes it out over 0.2 s.
		player.Overlay.PlayOneShot(wave, .(1.0f, 0.0f, 0.0f, -1));
		Test.Assert(Run(player, 3.0f) == 0);
		Test.Assert(player.Overlay.IsPlayingOneShot);
		player.Overlay.StopOneShot(0.2f);
		Test.Assert(Run(player, 0.1f) == 0);
		Test.Assert(Near(Height(player), 0.5f, 0.06f));
		Test.Assert(Run(player, 0.15f) == 1);
		Test.Assert(Near(Height(player), 0.0f));

		// A stop with no blend ends it at once.
		player.Overlay.PlayOneShot(wave, .(1.0f, 0.0f, 0.0f, -1));
		Test.Assert(Run(player, 0.1f) == 0);
		player.Overlay.StopOneShot(0.0f);
		Test.Assert(Run(player, 0.01f) == 1);
	}

	[Test]
	public static void ACrossfadeEasesFromTheOldClipsPoseIntoTheNewOne()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let high = scope AnimationClip("High", 1.0f, true);
		Holding(high, 1.0f);
		let low = scope AnimationClip("Low", 1.0f, true);
		Holding(low, 0.0f);
		let player = scope AnimationPlayer(skeleton);
		player.Play(high);
		Run(player, 0.1f);
		Test.Assert(Near(Height(player), 1.0f));

		player.CrossFadeTo(low, 0.5f);
		Test.Assert(Run(player, 0.25f) == 0, "a fade is no one-shot: nothing ends");
		Test.Assert(Near(Height(player), 0.5f, 0.06f));
		Run(player, 0.3f);
		Test.Assert(Near(Height(player), 0.0f));
		Test.Assert(player.CurrentClip == low);

		// No fade time: a plain switch.
		player.CrossFadeTo(high, 0.0f);
		Run(player, 0.01f);
		Test.Assert(Near(Height(player), 1.0f));
	}

	[Test]
	public static void AGraphsPoseTakesAOneShotTheSameWay()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let hop = scope AnimationClip("Hop", 1.0f, false);
		Holding(hop, 1.0f);
		// No layers: its pose is the bind pose.
		let graph = scope AnimationGraph();
		let player = scope AnimationGraphPlayer(graph, skeleton);
		player.Overlay.PlayOneShot(hop, .(1.0f, 0.0f, 0.0f, 0));
		player.Update(0.5f);
		Test.Assert(Near(player.GetLocalPoses()[0].Position.Y, 1.0f));
		Test.Assert(!player.ConsumeOneShotEnded());
		player.Update(0.6f);
		Test.Assert(player.ConsumeOneShotEnded());
		Test.Assert(Near(player.GetLocalPoses()[0].Position.Y, 0.0f));
	}
}
