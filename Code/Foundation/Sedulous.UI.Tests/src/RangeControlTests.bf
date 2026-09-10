using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The two range controls: a Slider, which picks a value along a track, and a ScrollBar, whose
/// thumb also reports how much of the content is visible.
class RangeControlTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	// ---- Slider -------------------------------------------------------------------------------

	[Test]
	public static void ASliderClampsToItsRange()
	{
		let slider = new Slider(0, 100, 50);
		defer slider.ReleaseRef();

		Test.Assert(slider.Value.Value == 50);

		slider.Value.Value = -10;
		Test.Assert(slider.Value.Value == 0);

		slider.Value.Value = 200;
		Test.Assert(slider.Value.Value == 100);
	}

	/// A step snaps whatever is written to it, not only what a drag produces.
	[Test]
	public static void ASliderSnapsToItsStep()
	{
		let slider = new Slider(0, 100);
		defer slider.ReleaseRef();

		slider.Step.Value = 10;
		slider.Value.Value = 33;

		Test.Assert(slider.Value.Value == 30);
	}

	/// Snapping is relative to Min, not to zero, so a range that does not start at zero lands
	/// on values the caller asked for rather than on multiples of the step.
	[Test]
	public static void ASlidersStepIsMeasuredFromItsMinimum()
	{
		let slider = new Slider(3, 100);
		defer slider.ReleaseRef();

		slider.Step.Value = 5;
		slider.Value.Value = 9;

		Test.Assert(slider.Value.Value == 8, "3, 8, 13 - not 5, 10, 15");
	}

	/// The event reports the value the slider SETTLED on, which after snapping is not the one
	/// the caller wrote.
	[Test]
	public static void ASliderReportsTheValueItSettledOn()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let slider = new Slider(0, 100);
		root.AddView(slider);

		var lastValue = -1.0f;
		slider.OnValueChanged.Add(new [&lastValue](s, v) => { lastValue = v; });

		slider.Value.Value = 42;
		Test.Assert(lastValue == 42);

		slider.Step.Value = 10;
		slider.Value.Value = 33;
		Test.Assert(lastValue == 30, "the snapped value, not the 33 that was written");
	}

	/// The arrows step, Home and End go to the ends.
	[Test]
	public static void TheKeyboardDrivesASlider()
	{
		let slider = new Slider(0, 100, 50);
		defer slider.ReleaseRef();
		slider.Step.Value = 5;

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		slider.OnKeyDown(right);
		Test.Assert(slider.Value.Value == 55);

		let left = scope KeyEventArgs();
		left.Set(.Left, .None, false);
		slider.OnKeyDown(left);
		Test.Assert(slider.Value.Value == 50);

		let home = scope KeyEventArgs();
		home.Set(.Home, .None, false);
		slider.OnKeyDown(home);
		Test.Assert(slider.Value.Value == 0);

		let end = scope KeyEventArgs();
		end.Set(.End, .None, false);
		slider.OnKeyDown(end);
		Test.Assert(slider.Value.Value == 100);
	}

	/// With no step the arrows move a twentieth of the range, so the nudge is sensible whatever
	/// the scale rather than a fixed amount that is huge on one slider and invisible on another.
	[Test]
	public static void AStepLessSliderNudgesByAFractionOfItsRange()
	{
		let slider = new Slider(0, 200, 100);
		defer slider.ReleaseRef();

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		slider.OnKeyDown(right);

		Test.Assert(slider.Value.Value == 110, "a twentieth of 200");
	}

	/// Moving an end strands the value outside the range, so the ends re-clamp it.
	[Test]
	public static void NarrowingASlidersRangePullsItsValueIn()
	{
		let slider = new Slider(0, 100, 90);
		defer slider.ReleaseRef();

		slider.Max.Value = 50;

		Test.Assert(slider.Value.Value == 50);
	}

	/// A slider wants the arrow keys itself, so focus must not spend them on moving away.
	[Test]
	public static void ASliderClaimsTheArrowKeys()
	{
		let slider = new Slider(0, 100);
		defer slider.ReleaseRef();

		Test.Assert(slider.WantsArrowKeys);
		Test.Assert(slider.IsFocusable);
		Test.Assert(slider.IsTabStop);
	}

	// ---- ScrollBar ----------------------------------------------------------------------------

	[Test]
	public static void AScrollBarClampsToItsRange()
	{
		let bar = new ScrollBar();
		defer bar.ReleaseRef();

		bar.MaxValue = 100;

		bar.Value = -10;
		Test.Assert(bar.Value == 0);

		bar.Value = 200;
		Test.Assert(bar.Value == 100);
	}

	[Test]
	public static void AScrollBarReportsItsValue()
	{
		let bar = new ScrollBar();
		defer bar.ReleaseRef();
		bar.MaxValue = 100;

		var lastValue = -1.0f;
		bar.OnValueChanged.Add(new [&lastValue](b, v) => { lastValue = v; });

		bar.Value = 42;
		Test.Assert(lastValue == 42);

		// Writing the value it already holds reports nothing.
		lastValue = -1;
		bar.Value = 42;
		Test.Assert(lastValue == -1);
	}

	/// Shrinking the range pulls the value in with it, rather than leaving a scroll position
	/// past the end of what is now scrollable.
	[Test]
	public static void ShrinkingAScrollBarsRangePullsItsValueIn()
	{
		let bar = new ScrollBar();
		defer bar.ReleaseRef();

		bar.MaxValue = 100;
		bar.Value = 90;

		bar.MaxValue = 40;
		Test.Assert(bar.Value == 40);
	}

	/// The thumb's size is the visible fraction of the whole scrollable extent, and it never
	/// shrinks past a floor however long the content gets.
	[Test]
	public static void AScrollBarsThumbShowsHowMuchIsVisible()
	{
		let bar = new ScrollBar();
		defer bar.ReleaseRef();
		bar.Bounds = .(0, 0, 10, 200);

		// Viewport 50 of a 150 extent: a third of the bar.
		bar.MaxValue = 100;
		bar.ViewportSize = 50;
		Test.Assert(NearlyEqual(bar.GetThumbRect().Height, 200.0f / 3.0f, 0.001f));

		// At the top the thumb sits at the top; at the bottom it sits flush with the end.
		Test.Assert(bar.GetThumbRect().Y == 0);
		bar.Value = 100;
		Test.Assert(NearlyEqual(bar.GetThumbRect().Y, 200 - 200.0f / 3.0f, 0.001f));

		// A very long document floors the thumb rather than letting it vanish.
		bar.MaxValue = 100000;
		Test.Assert(bar.GetThumbRect().Height == 10);
	}

	/// A scrollbar always shows the arrow, even inside a text control whose own cursor is an
	/// I-beam: the effective cursor walks up to the parent, and a bar is never text.
	[Test]
	public static void AScrollBarKeepsTheArrowCursorInsideATextControl()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		group.Cursor = .IBeam;
		group.Bounds = .(0, 0, 200, 100);
		root.AddView(group);

		let bar = new ScrollBar();
		bar.Bounds = .(0, 0, 10, 100);
		group.AddView(bar);

		Test.Assert(bar.EffectiveCursor(.(5, 50)) == CursorType.Arrow);
		Test.Assert(group.EffectiveCursor(.(100, 50)) == CursorType.IBeam, "the parent still is");
	}
}
