using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// A ticker is a label showing an integer that rolls. These cover the instant set, the roll
/// landing exactly on its target, and the zero duration snap.
class TickerTests
{
	private static Ticker Attach(WidgetBed bed)
	{
		let ticker = new Ticker();
		bed.Root.AddView(ticker);
		return ticker;
	}

	[Test]
	public static void SetNumberUpdatesTheValueAndTheRenderedText()
	{
		let bed = scope WidgetBed();
		let ticker = Attach(bed);

		Test.Assert(ticker.Number == 0);
		Test.Assert(ticker.Text.Value == "0");

		ticker.SetNumber(1234);
		Test.Assert(ticker.Number == 1234);
		Test.Assert(ticker.Text.Value == "1234");

		ticker.SetNumber(-7);
		Test.Assert(ticker.Text.Value == "-7");
	}

	[Test]
	public static void AnimateToRollsToTheTargetLandingExactly()
	{
		let bed = scope WidgetBed();
		let ticker = Attach(bed);

		ticker.SetNumber(0);
		ticker.AnimateTo(100, 1.0f);

		bed.Context.BeginFrame(0.5f);
		let mid = ticker.Number;
		Test.Assert(mid > 0);
		Test.Assert(mid < 100);

		bed.Context.BeginFrame(0.6f);
		Test.Assert(ticker.Number == 100);
		Test.Assert(ticker.Text.Value == "100");
	}

	[Test]
	public static void AnimateToWithNoDurationSnaps()
	{
		let bed = scope WidgetBed();
		let ticker = Attach(bed);

		ticker.AnimateTo(42, 0.0f);
		Test.Assert(ticker.Number == 42);
		Test.Assert(ticker.Text.Value == "42");
	}
}
