using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The small types of the first slice whose Raptor tests need later slices: what each one sets
/// out to do, checked here until those land.
class PrimitivesTests
{
	/// An op enqueued while the queue drains waits for the next drain, so a drain always ends.
	[Test]
	public static void AMutationQueuedDuringADrainRunsOnTheNext()
	{
		let queue = scope MutationQueue();
		let ran = scope List<int>();
		queue.Enqueue(new [&]() =>
			{
				ran.Add(1);
				queue.Enqueue(new [&]() => ran.Add(2));
			});
		Test.Assert(!queue.IsEmpty);
		queue.Drain();
		Test.Assert(ran.Count == 1);
		Test.Assert(!queue.IsEmpty, "the one queued inside waits");
		queue.Drain();
		Test.Assert(ran.Count == 2);
		Test.Assert(ran[1] == 2);
		Test.Assert(queue.IsEmpty);
	}

	[Test]
	public static void ARangeSnapsAndKeepsWithinUnlessAllowed()
	{
		var range = RangeValue();
		range.Min = 0.0;
		range.Max = 10.0;
		range.Step = 0.5;
		Test.Assert(range.Constrain(3.3) == 3.5);
		Test.Assert(range.Constrain(-2.0) == 0.0);
		Test.Assert(range.Constrain(12.0) == 10.0);
		range.AllowGreater = true;
		Test.Assert(range.Constrain(12.0) == 12.0);
		Test.Assert(range.Decimals == 1);
		Test.Assert(range.KeyStep == 0.5);
		Test.Assert(range.PageStep == 1.0, "a tenth of the range");

		// A scroll bar: the page is shown, so the value goes no further than the maximum less it.
		var bar = RangeValue();
		bar.Max = 100.0;
		bar.Page = 20.0;
		bar.PageShown = true;
		Test.Assert(bar.Upper == 80.0);
		bar.Value = 40.0;
		Test.Assert(bar.Ratio == 0.5);
		Test.Assert(bar.FromRatio(0.25) == 20.0);
	}

	[Test]
	public static void AnExponentialRangePlacesByLogarithm()
	{
		var range = RangeValue();
		range.Min = 1.0;
		range.Max = 100.0;
		range.Exponential = true;
		Test.Assert(Math.Abs(range.RatioOf(10.0) - 0.5) < 1e-5);
		Test.Assert(Math.Abs(range.FromRatio(0.5) - 10.0) < 1e-4);
		var continuous = RangeValue();
		Test.Assert(continuous.Decimals == 3);
	}

	[Test]
	public static void FrameStatsDescribeTheirPhasesAndReasons()
	{
		let stats = scope FrameStats();
		let text = scope String();
		stats.Describe(text);
		Test.Assert(text.EndsWith("; asked by: nothing"), text);

		stats.StyleMs = 0.25;
		stats.Restyled = 3;
		stats.Reasons.Layout = true;
		stats.Reasons.Animation = true;
		stats.AnimatedNode.Set("spinner");
		text.Clear();
		stats.Describe(text);
		Test.Assert(text.StartsWith("style 250 us (3 restyled)"), text);
		Test.Assert(text.EndsWith("; asked by: layout animation (spinner)"), text);
	}

	[Test]
	public static void AnIdentifierReadsLettersDigitsDashesAndUnderscores()
	{
		int i = 0;
		Test.Assert(ParseUtil.ReadIdent("font-size_2: 3px", ref i) == "font-size_2");
		Test.Assert(i == 11);
		int at = 0;
		Test.Assert(ParseUtil.ReadIdent(":hover", ref at).IsEmpty);
		Test.Assert(at == 0);
	}

	[Test]
	public static void TheOverlayPresetsTurnOnTheirHalf()
	{
		Test.Assert(!DebugOverlay().Any);
		Test.Assert(DebugOverlay.Layout.AnyLayout && !DebugOverlay.Layout.AnyInput);
		Test.Assert(DebugOverlay.Input.AnyInput && !DebugOverlay.Input.AnyLayout);
		Test.Assert(DebugOverlay.Layout == DebugOverlay.Layout);
		Test.Assert(DebugOverlay.Layout != DebugOverlay.Input);
	}

	[Test]
	public static void TheDefaultThemeIsWrittenInTokens()
	{
		let css = StringView(Theme.DefaultThemeCSS);
		Test.Assert(css.Contains(":root {"));
		Test.Assert(css.Contains("--accent: #33507a;"));
		Test.Assert(css.Contains("@media (prefers-color-scheme: light)"));
		Test.Assert(css.Contains("@media (prefers-reduced-motion: reduce)"));
	}
}
