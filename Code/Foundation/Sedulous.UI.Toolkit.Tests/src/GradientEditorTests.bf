using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The colour ramp: its stops, its sampling, and the sorted invariant everything else rests on.
class GradientEditorTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	private static GradientEditor BlackToWhite()
	{
		let editor = new GradientEditor();
		GradientStop[2] stops = .(.(0.0f, .(0, 0, 0, 1)), .(1.0f, .(1, 1, 1, 1)));
		editor.SetStops(stops);
		return editor;
	}

	[Test]
	public static void SetStopsReplacesEverythingAndReportsNothing()
	{
		let editor = new GradientEditor();
		defer editor.ReleaseRef();

		Test.Assert(editor.StopCount == 0);
		Test.Assert(editor.SelectedIndex == -1);

		var added = 0;
		var changed = 0;
		editor.OnStopAdded.Add(new [&](index) => { added++; });
		editor.OnStopChanged.Add(new [&](index) => { changed++; });

		GradientStop[2] stops = .(.(0.0f, .(0, 0, 0, 1)), .(1.0f, .(1, 1, 1, 1)));
		editor.SetStops(stops);

		Test.Assert(editor.StopCount == 2);
		Test.Assert(editor.GetStop(0).Time == 0.0f);
		Test.Assert(editor.GetStop(1).Time == 1.0f);
		Test.Assert(added == 0, "loading a value is not the user adding stops");
		Test.Assert(changed == 0);
	}

	[Test]
	public static void UpdateStopColorReportsTheChange()
	{
		let editor = BlackToWhite();
		defer editor.ReleaseRef();

		var changedIndex = -99;
		editor.OnStopChanged.Add(new [&](index) => { changedIndex = index; });

		editor.UpdateStopColor(1, .(1, 0, 0, 1));
		Test.Assert(changedIndex == 1);
		Test.Assert(editor.GetStop(1).Color.X == 1.0f);
		Test.Assert(editor.GetStop(1).Color.Y == 0.0f);

		// Out of range is a no op rather than a crash, because the index came from a dialog
		// that may have outlived the stop it was opened for.
		changedIndex = -99;
		editor.UpdateStopColor(99, .(0, 1, 0, 1));
		Test.Assert(changedIndex == -99);
	}

	/// The ramp is flat outside its ends and linear between the stops.
	[Test]
	public static void SamplingInterpolatesAndClampsAtTheEnds()
	{
		let editor = BlackToWhite();
		defer editor.ReleaseRef();

		Test.Assert(Near(editor.Sample(-1.0f).X, 0.0f), "flat before the first stop");
		Test.Assert(Near(editor.Sample(0.5f).X, 0.5f));
		Test.Assert(Near(editor.Sample(2.0f).X, 1.0f), "flat after the last");
	}

	[Test]
	public static void AnEmptyRampSamplesToNothing()
	{
		let editor = new GradientEditor();
		defer editor.ReleaseRef();

		let sample = editor.Sample(0.5f);
		Test.Assert((sample.X == 0.0f) && (sample.W == 0.0f));
	}

	/// Two stops at the SAME time have no span to interpolate across; the earlier one wins
	/// rather than the maths dividing by nothing.
	[Test]
	public static void CoincidentStopsDoNotDivideByZero()
	{
		let editor = new GradientEditor();
		defer editor.ReleaseRef();

		GradientStop[2] stops = .(.(0.5f, .(1, 0, 0, 1)), .(0.5f, .(0, 1, 0, 1)));
		editor.SetStops(stops);

		let sample = editor.Sample(0.5f);
		Test.Assert(sample.X == 1.0f);
		Test.Assert(sample.Y == 0.0f);
	}
}
