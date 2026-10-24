using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// CheckBox and ToggleSwitch: the button core as a toggle with an indicator part; a click toggles
/// and reports, code does not report; the mixed state settles on a click.
class CheckBoxTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A root 100 by 100 whose children each keep their own size, held by the caller.
	private static SceneRoot NewRoot()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; }); // each at its own size
		return root;
	}

	private static void Click(EventDispatcher d)
	{
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
	}

	/// How many vertices `root` draws, laid out first.
	private static int Vertices(SceneRoot root)
	{
		root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.Draw(dc);
		return canvas.GetBatch().Vertices.Count;
	}

	[Test]
	public static void Defaults()
	{
		let cb = new CheckBox();
		defer cb.ReleaseRef();
		Test.Assert(!cb.Checked);
		Test.Assert(cb.IsToggle);
		Test.Assert(cb.TabFocusable);
		Test.Assert(cb.Tag == "checkbox");
		Test.Assert(cb.IndicatorPart != null);
	}

	[Test]
	public static void AClickTogglesItAndReportsCodesChangesDoNotReport()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let cb = new CheckBox();
		defer cb.ReleaseRef();
		root.AddChild(cb);
		root.UpdateLayout();
		int32 changes = 0;
		bool last = false;
		cb.SetOnToggled(new [&] (on) =>
			{
				++changes;
				last = on;
			});
		let d = root.EventDispatcher;

		Click(d);
		Test.Assert(cb.Checked);
		Test.Assert(changes == 1);
		Test.Assert(last);
		Click(d);
		Test.Assert(!cb.Checked);
		Test.Assert(changes == 2);

		cb.Toggle();
		cb.Checked = false;
		Test.Assert(changes == 2);
	}

	[Test]
	public static void TheMixedStateShowsUntilSetAndAClickOnItChecksIt()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let cb = new CheckBox();
		defer cb.ReleaseRef();
		root.AddChild(cb);
		root.UpdateLayout();
		cb.Indeterminate = true;
		Test.Assert(cb.Indeterminate);
		Test.Assert((cb.WidgetStates & WidgetStateIndeterminate) != 0);

		Click(root.EventDispatcher);
		Test.Assert(cb.Checked);
		Test.Assert(!cb.Indeterminate);

		cb.Indeterminate = true;
		cb.Checked = true; // a choice settles it, though the state was already checked
		Test.Assert(!cb.Indeterminate);
	}

	[Test]
	public static void ItsIndicatorDrawsTheBoxATickWhenCheckedABarWhenMixed()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let cb = new CheckBox();
		defer cb.ReleaseRef();
		root.AddChild(cb);
		let plain = Vertices(root);
		Test.Assert(plain > 0); // the outline
		cb.Indeterminate = true;
		let mixed = Vertices(root);
		Test.Assert(mixed > plain); // the outline and the bar
		cb.Checked = true;
		let ticked = Vertices(root);
		Test.Assert(ticked > plain); // the outline and the tick
		Test.Assert(ticked != mixed); // a stroked tick, not the bar's rectangle
	}

	[Test]
	public static void ASwitchTogglesLikeACheckBoxItsKnobMovingAlongTheTrack()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let sw = new ToggleSwitch();
		defer sw.ReleaseRef();
		root.AddChild(sw);
		root.UpdateLayout();
		Test.Assert(sw.Tag == "switch");
		Test.Assert(Near(sw.Size.X, 36.0f));
		let off = Vertices(root);
		Test.Assert(off > 0);
		Click(root.EventDispatcher);
		Test.Assert(sw.Checked);
		Test.Assert(Vertices(root) == off); // the same track and knob, the knob at the other end
	}
}
