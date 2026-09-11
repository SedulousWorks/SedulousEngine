using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The clip: its tracks, its events, and when they fire.
class AnimationClipTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void AnEventCarriesItsTimeAndName()
	{
		let event = scope AnimationEvent(0.5f, "Footstep");
		Test.Assert(event.Time == 0.5f);
		Test.Assert(event.Name == "Footstep");
	}

	[Test]
	public static void AddingEventsCountsThem()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		Test.Assert(clip.Events.IsEmpty);
		clip.AddEvent(0.5f, "Hit");
		Test.Assert(clip.Events.Count == 1);
		clip.AddEvent(1.0f, "Sound");
		Test.Assert(clip.Events.Count == 2);
	}

	[Test]
	public static void TheEventsSortByTime()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(1.5f, "C");
		clip.AddEvent(0.2f, "A");
		clip.AddEvent(0.8f, "B");
		clip.SortEvents();

		Test.Assert(clip.Events[0].Time == 0.2f);
		Test.Assert(clip.Events[1].Time == 0.8f);
		Test.Assert(clip.Events[2].Time == 1.5f);
		Test.Assert(clip.Events[0].Name == "A");
		Test.Assert(clip.Events[2].Name == "C");
	}

	/// The span is HALF OPEN on the left and closed on the right, so an event exactly on the
	/// previous time does not fire twice across two updates.
	[Test]
	public static void AnEventFiresOnlyWhenTheSpanCrossesIt()
	{
		{
			let clip = scope AnimationClip("Test", 2.0f);
			clip.AddEvent(0.5f, "Hit");
			var count = 0;
			clip.FireEvents(0.0f, 1.0f, scope [&count](name, time) => { count++; });
			Test.Assert(count == 1);
		}
		{
			let clip = scope AnimationClip("Test", 2.0f);
			clip.AddEvent(1.5f, "Hit");
			var count = 0;
			clip.FireEvents(0.0f, 1.0f, scope [&count](name, time) => { count++; });
			Test.Assert(count == 0);
		}
		{
			// Exactly on the right hand end, which is inside the span.
			let clip = scope AnimationClip("Test", 1.0f);
			clip.AddEvent(0.5f, "Exact");
			var count = 0;
			clip.FireEvents(0.3f, 0.5f, scope [&count](name, time) => { count++; });
			Test.Assert(count == 1);
		}
	}

	[Test]
	public static void TheEventsFireInOrderAndAcrossALoop()
	{
		{
			let clip = scope AnimationClip("Test", 2.0f);
			clip.AddEvent(0.3f, "A");
			clip.AddEvent(0.7f, "B");
			clip.AddEvent(1.2f, "C");
			clip.SortEvents();

			let fired = scope List<String>();
			clip.FireEvents(0.0f, 1.5f, scope (name, time) =>
				{
					fired.Add(new String(name));
				});
			defer { ClearAndDeleteItems!(fired); }

			Test.Assert(fired.Count == 3);
			Test.Assert(fired[0] == "A");
			Test.Assert(fired[1] == "B");
			Test.Assert(fired[2] == "C");
		}
		{
			// A wrap on a one second loop: the tail past the previous time fires, then the
			// head that was wrapped into. Nothing sits in the tail here, so only the early
			// one fires.
			let clip = scope AnimationClip("Test", 1.0f, true);
			clip.AddEvent(0.2f, "Early");
			clip.AddEvent(0.8f, "Late");
			clip.SortEvents();

			let fired = scope List<String>();
			clip.FireEvents(0.9f, 1.3f, scope (name, time) =>
				{
					fired.Add(new String(name));
				});
			defer { ClearAndDeleteItems!(fired); }

			Test.Assert(fired.Count == 1);
			Test.Assert(fired[0] == "Early");
		}
		{
			// Not looping, and run past the end: everything up to the duration fires and
			// nothing wraps.
			let clip = scope AnimationClip("Test", 1.0f, false);
			clip.AddEvent(0.8f, "NearEnd");
			clip.AddEvent(1.0f, "AtEnd");
			clip.SortEvents();

			var count = 0;
			clip.FireEvents(0.5f, 1.5f, scope [&count](name, time) => { count++; });
			Test.Assert(count == 2);
		}
	}

	/// The duration is the LAST keyframe, and a track for a bone is made once and then
	/// answered again.
	[Test]
	public static void TheDurationComesFromTheLastKeyframe()
	{
		let clip = scope AnimationClip("Test");
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(1.25f, .(1, 0, 0));

		clip.ComputeDuration();
		Test.Assert(Near(clip.Duration, 1.25f));

		Test.Assert(clip.GetOrCreatePositionTrack(0) == track);
		Test.Assert(clip.PositionTracks.Count == 1);
	}

	/// A binary search over the keyframes, CLAMPED at both ends.
	[Test]
	public static void TheKeyframeLookupClampsAtBothEnds()
	{
		let track = scope AnimationTrack<Float3>();
		Test.Assert(!track.FindKeyframes(0.0f).IsValid, "an empty track has no interval");

		track.AddKeyframe(0.0f, .(0, 0, 0));
		let single = track.FindKeyframes(5.0f);
		Test.Assert(single.Prev == 0);
		Test.Assert(single.Next == 0);

		track.AddKeyframe(1.0f, .(1, 0, 0));
		track.AddKeyframe(2.0f, .(2, 0, 0));
		track.AddKeyframe(3.0f, .(3, 0, 0));

		let before = track.FindKeyframes(-1.0f);
		Test.Assert((before.Prev == 0) && (before.Next == 0));

		let after = track.FindKeyframes(99.0f);
		Test.Assert((after.Prev == 3) && (after.Next == 3));

		let middle = track.FindKeyframes(1.5f);
		Test.Assert((middle.Prev == 1) && (middle.Next == 2));
		Test.Assert(Near(middle.T, 0.5f));
	}

	/// The sort is STABLE, so two keys at one time keep the order they were authored in.
	[Test]
	public static void TheKeyframeSortIsStable()
	{
		let track = scope AnimationTrack<Float3>();
		track.AddKeyframe(1.0f, .(1, 0, 0));
		track.AddKeyframe(0.5f, .(2, 0, 0));
		track.AddKeyframe(1.0f, .(3, 0, 0));
		track.SortKeyframes();

		Test.Assert(track.Keyframes[0].Value.X == 2.0f);
		// Both of these were keyed at one second, in this order.
		Test.Assert(track.Keyframes[1].Value.X == 1.0f);
		Test.Assert(track.Keyframes[2].Value.X == 3.0f);
	}
}
