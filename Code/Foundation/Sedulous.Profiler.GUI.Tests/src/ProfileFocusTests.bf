using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Tests; // KnownSource

namespace Sedulous.Profiler.GUI.Tests;

/// The focus every view on a page reads: the frames, the name and
/// the span chosen, each change told to the views; a new source letting the choices go; a name's time
/// in a frame (a recursive scope counted once), the longest and the median frame.
class ProfileFocusTests
{
	private class Counting : IProfileFocusClient
	{
		public int Sources = 0;
		public int Frames = 0;
		public int Choices = 0;
		public void OnProfileSourceChanged() { Sources++; }
		public void OnProfileFramesChanged() { Frames++; }
		public void OnProfileChoiceChanged() { Choices++; }
	}

	[Test]
	public static void TheFramesTheNameAndTheSpanChosenEachChangeToldOnce()
	{
		let source = scope KnownSource();
		source.AddFrame(10);
		source.AddFrame(20);
		let focus = new ProfileFocus();
		defer focus.ReleaseLastRef();
		let views = scope Counting();
		focus.Join(views);
		focus.SetSource(source);
		Test.Assert(views.Sources == 1);
		Test.Assert(focus.Frames.Empty);

		focus.SetFrame(1);
		Test.Assert(views.Frames == 2, "the source's, then the choice");
		Test.Assert(focus.Frames.First == 1);
		focus.SetFrame(1); // the same: nothing told
		Test.Assert(views.Frames == 2);

		focus.ChooseName(4, false);
		Test.Assert(focus.Name.Is(4, false));
		Test.Assert(!focus.Name.Is(4, true));
		focus.SetSpan(1030, 1010);
		Test.Assert(focus.Span.BeginTick == 1010);
		Test.Assert(focus.Span.EndTick == 1030);
		Test.Assert(views.Choices == 3, "the source's, the name, the span");

		// Other frames: the span went with them, the name stays.
		focus.SetFrame(0);
		Test.Assert(!focus.Span.Any);
		Test.Assert(focus.Name.Any);
		Test.Assert(views.Choices == 4);

		// Another source: every choice goes.
		let other = scope KnownSource();
		focus.SetSource(other);
		Test.Assert(focus.Frames.Empty);
		Test.Assert(!focus.Name.Any);
		focus.Leave(views);
		Test.Assert(focus.ClientCount == 0);
	}

	[Test]
	public static void ANamesTimeInAFrameItsPassesApartARecursiveScopeCountedOnce()
	{
		let source = scope KnownSource();
		let walk = source.Name("Walk");
		let other = source.Name("Other");
		let frame = source.AddFrame(20);
		// Walk inside Walk (ended first, so listed first), then the outer Walk, then a second one.
		KnownSource.AddScope(frame, walk, 1, 2, 4);
		KnownSource.AddScope(frame, walk, 0, 1, 6);
		KnownSource.AddScope(frame, other, 0, 6, 8);
		KnownSource.AddScope(frame, walk, 0, 8, 11);
		KnownSource.AddPass(frame, walk, 0, 7);
		Test.Assert(ProfileFrames.NameTicksInFrame(frame, .(walk, false)) == 8, "5 + 3, the inner one inside");
		Test.Assert(ProfileFrames.NameTicksInFrame(frame, .(walk, true)) == 7);
		Test.Assert(ProfileFrames.NameTicksInFrame(frame, .()) == 0);
	}

	[Test]
	public static void TheLongestAndTheMedianFrameOfARange()
	{
		let source = scope KnownSource();
		for (let ms in int64[5](10, 40, 20, 30, 15))
			source.AddFrame(ms);
		let all = ProfileFrames.AllFrames(source);
		Test.Assert((all.First == 0) && (all.Last == 4));
		Test.Assert(ProfileFrames.LongestFrame(source, all).First == 1);
		Test.Assert(ProfileFrames.MedianFrame(source, all).First == 2, "10 15 [20] 30 40");
		var some = FrameRange();
		some.First = 2;
		some.Last = 3;
		some.Empty = false;
		Test.Assert(ProfileFrames.MedianFrame(source, some).First == 2, "of two, the shorter");
		Test.Assert(ProfileFrames.LongestFrame(source, FrameRange()).Empty);
		Test.Assert(ProfileFrames.AllFrames(null).Empty);
	}
}
