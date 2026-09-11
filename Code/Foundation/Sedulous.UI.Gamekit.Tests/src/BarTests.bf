using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// A bar is a progress bar with an optional drain. These cover the instant fill with the
/// inherited clamp, the drain arriving exactly on its target across frames, retargeting rather
/// than stacking, and the zero duration snap.
class BarTests
{
	private static Bar Attach(WidgetBed bed)
	{
		let bar = new Bar();
		bed.Root.AddView(bar); // attaches it, so it can reach the animation manager
		return bar;
	}

	[Test]
	public static void SetFillSnapsAndClamps()
	{
		let bed = scope WidgetBed();
		let bar = Attach(bed);

		bar.SetFill(0.5f);
		Test.Assert(bar.Value.Value == 0.5f);
		bar.SetFill(2.0f);
		Test.Assert(bar.Value.Value == 1.0f, "over range clamps");
		bar.SetFill(-1.0f);
		Test.Assert(bar.Value.Value == 0.0f);
	}

	[Test]
	public static void AnimateToDrainsTowardTheTargetArrivingExactly()
	{
		let bed = scope WidgetBed();
		let bar = Attach(bed);

		bar.SetFill(1.0f);
		bar.AnimateTo(0.0f, 1.0f);

		bed.Context.BeginFrame(0.5f);
		let mid = bar.Value.Value;
		Test.Assert(mid > 0.0f);
		Test.Assert(mid < 1.0f);

		bed.Context.BeginFrame(0.6f); // 1.1s elapsed, past the duration
		Test.Assert(bar.Value.Value == 0.0f);
	}

	[Test]
	public static void ANewAnimateToReplacesTheInFlightDrain()
	{
		let bed = scope WidgetBed();
		let bar = Attach(bed);

		bar.SetFill(1.0f);
		bar.AnimateTo(0.0f, 1.0f);
		bed.Context.BeginFrame(0.5f);
		bar.AnimateTo(1.0f, 1.0f); // reverse, from halfway back up
		bed.Context.BeginFrame(1.1f);
		Test.Assert(bar.Value.Value == 1.0f);
	}

	[Test]
	public static void AnimateToWithNoDurationSnaps()
	{
		let bed = scope WidgetBed();
		let bar = Attach(bed);

		bar.SetFill(1.0f);
		bar.AnimateTo(0.25f, 0.0f);
		Test.Assert(bar.Value.Value == 0.25f);
	}
}
