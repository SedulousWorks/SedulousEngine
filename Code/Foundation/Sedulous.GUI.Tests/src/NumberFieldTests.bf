using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A number field 120 by 24 at the root's top left beside a focusable panel, counting what it
/// reports. The root and the tree go with it.
class NumberBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public NumberField Field = new .() ~ _.ReleaseRef();
	public Panel Other = new .() ~ _.ReleaseRef();
	public int Inputs = 0;
	public int Changes = 0;
	public int ChangeEvents = 0;

	public this()
	{
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Field.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(120.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(Field);
		Other.TabFocusable = true;
		Other.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(20.0f);
				s.Width = LayoutLength.Px(20.0f);
			});
		Root.AddChild(Other);
		Root.UpdateLayout();
		Field.SetOnValueChanging(new (value) => { ++Inputs; });
		Field.SetOnValueChanged(new (value) => { ++Changes; });
		Field.AddEventListener(.Changed, new (e) => { ++ChangeEvents; });
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static uint32 K(KeyCode k) => (uint32)k;

	/// A press let go on the field: editing, all of it selected.
	public void ClickToEdit()
	{
		D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		D.InjectMouseUp(.(30.0f, 12.0f), .Left);
	}
}

/// NumberField: expressions, its form, typed values committed, stepped by its arrows, keys and the
/// wheel, scrubbed, a scrub cancelled, and its mixed state; its arrows hidden when too narrow.
class NumberFieldTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1.2e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	[Test]
	public static void ExpressionsAreReadAsArithmeticOrNotAtAll()
	{
		Test.Assert(Near(EvaluateExpression("2*3").Value, 6.0));
		Test.Assert(Near(EvaluateExpression(" 1 + 2 * (3 - 1) / 4 ").Value, 2.0));
		Test.Assert(Near(EvaluateExpression("-1.5").Value, -1.5));
		Test.Assert(Near(EvaluateExpression("10/4").Value, 2.5));
		Test.Assert(!EvaluateExpression("abc").HasValue);
		Test.Assert(!EvaluateExpression("1/0").HasValue);
		Test.Assert(!EvaluateExpression("(1+2").HasValue);
		Test.Assert(!EvaluateExpression("").HasValue);
	}

	[Test]
	public static void WrittenWithTheStepsDecimalsBetweenItsPrefixAndSuffix()
	{
		let b = scope NumberBed();
		b.Field.Step = 0.25;
		b.Field.Value = 1.5;
		Test.Assert(b.Field.Text == "1.5");
		b.Field.Prefix = "$";
		b.Field.Suffix = " ea";
		Test.Assert(b.Field.Text == "$1.5 ea");
		b.Field.IsInteger = true;
		Test.Assert(Near(b.Field.Value, 2.0)); // whole numbers
		Test.Assert(b.Field.Text == "$2 ea");
		Test.Assert(b.Changes == 0); // code reports nothing
	}

	[Test]
	public static void TypedTextCommitsOnReturnAsItsExpressionSnappedAndKeptInRange()
	{
		let b = scope NumberBed();
		b.Field.Step = 0.5;
		b.ClickToEdit();
		Test.Assert(b.Field.IsEditing);
		b.D.InjectText("2*3.6");
		b.D.InjectKeyDown(NumberBed.K(.Return));
		Test.Assert(Near(b.Field.Value, 7.0)); // 7.2 to the step
		Test.Assert(b.Field.Text == "7");
		Test.Assert(b.Changes == 1);
		Test.Assert(b.ChangeEvents == 1);

		b.ClickToEdit();
		b.D.InjectText("500");
		b.Other.RequestFocus(); // leaving commits too
		Test.Assert(Near(b.Field.Value, 100.0)); // the maximum
		Test.Assert(b.Changes == 2);

		b.Field.RequestFocus();
		b.ClickToEdit();
		b.D.InjectText("nonsense");
		b.D.InjectKeyDown(NumberBed.K(.Return));
		Test.Assert(Near(b.Field.Value, 100.0)); // back as it was
		Test.Assert(b.Field.Text == "100");
		Test.Assert(b.Changes == 2);

		// Its prefix and suffix may be typed or left out.
		b.Field.Suffix = " px";
		b.ClickToEdit();
		b.D.InjectText("12 px");
		b.D.InjectKeyDown(NumberBed.K(.Return));
		Test.Assert(Near(b.Field.Value, 12.0));
	}

	[Test]
	public static void TheArrowsTheKeysAndTheWheelStepItEachACommittedChange()
	{
		let b = scope NumberBed();
		b.Field.Step = 2.0;
		b.Field.Page = 10.0;
		b.Field.RequestFocus();
		b.D.InjectKeyDown(NumberBed.K(.Up));
		Test.Assert(Near(b.Field.Value, 2.0));
		b.D.InjectKeyDown(NumberBed.K(.PageUp));
		Test.Assert(Near(b.Field.Value, 12.0));
		b.D.InjectKeyDown(NumberBed.K(.Down));
		Test.Assert(Near(b.Field.Value, 10.0));
		Test.Assert(b.Changes == 3);

		b.D.InjectMouseWheel(.(30.0f, 12.0f), .(0.0f, 1.0f));
		Test.Assert(Near(b.Field.Value, 12.0));

		// The up arrow, held: once on the press, then repeating.
		let up = b.Field.UpButton.ScreenBounds;
		let at = Float2(up.X + up.Width * 0.5f, up.Y + up.Height * 0.5f);
		b.D.InjectMouseMove(at);
		b.D.InjectMouseDown(at, .Left);
		Test.Assert(Near(b.Field.Value, 14.0));
		b.Root.Context.Update(SceneFixtures.Seconds(0.5)); // past the delay
		b.Root.Context.Update(SceneFixtures.Seconds(0.13)); // two intervals
		b.D.InjectMouseUp(at, .Left);
		Test.Assert(b.Field.Value > 14.0);
		Test.Assert(b.Field.IsFocused); // the field keeps the focus
	}

	[Test]
	public static void APressAndADragScrubsItShiftFineCtrlCoarse()
	{
		let b = scope NumberBed();
		b.D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		b.D.InjectMouseMove(.(32.0f, 12.0f)); // within the threshold
		Test.Assert(Near(b.Field.Value, 0.0));
		b.D.InjectMouseMove(.(50.0f, 12.0f)); // 20 px: five steps
		Test.Assert(Near(b.Field.Value, 5.0));
		Test.Assert(b.Inputs == 1);
		Test.Assert(b.Changes == 0);
		b.D.InjectMouseUp(.(50.0f, 12.0f), .Left);
		Test.Assert(b.Changes == 1);
		Test.Assert(!b.Field.IsEditing); // a scrub, not a click

		b.Field.Step = 0.0; // continuous: a two-hundredth of the range per four pixels
		b.D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		b.D.InjectMouseMove(.(70.0f, 12.0f), KeyModShift); // a tenth: 40 px is 0.5
		Test.Assert(Near(b.Field.Value, 5.5));
		b.D.InjectMouseUp(.(70.0f, 12.0f), .Left);
	}

	[Test]
	public static void EscapeMidScrubPutsTheValueBackAndReportsTheCancel()
	{
		let b = scope NumberBed();
		b.Field.Value = 3.0;
		int cancels = 0;
		b.Field.SetOnValueCancelled(new [&] () => { ++cancels; });
		b.D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		b.D.InjectMouseMove(.(50.0f, 12.0f));
		Test.Assert(Near(b.Field.Value, 8.0));
		b.D.InjectKeyDown(NumberBed.K(.Escape));
		Test.Assert(Near(b.Field.Value, 3.0));
		Test.Assert(b.Field.Text == "3");
		Test.Assert(cancels == 1);
		b.D.InjectMouseMove(.(90.0f, 12.0f)); // the press no longer scrubs
		b.D.InjectMouseUp(.(90.0f, 12.0f), .Left);
		Test.Assert(Near(b.Field.Value, 3.0));
		Test.Assert(b.Changes == 0);
		Test.Assert(!b.Field.IsEditing);

		// Escape on a press not yet a scrub cancels nothing that changed.
		b.D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		b.D.InjectKeyDown(NumberBed.K(.Escape));
		b.D.InjectMouseUp(.(30.0f, 12.0f), .Left);
		Test.Assert(cancels == 1);
	}

	[Test]
	public static void MixedNoNumberShowsAndTheUsersNextChangeCommitsEvenTheValueItHeld()
	{
		let b = scope NumberBed();
		b.Field.Placeholder = "Mixed";
		b.Field.Value = 4.0;
		b.Field.IsMixed = true;
		Test.Assert(b.Field.IsMixed);
		Test.Assert(b.Field.Text.Length == 0);

		// A press let go and Return with nothing typed: still mixed, nothing committed.
		b.ClickToEdit();
		b.D.InjectKeyDown(NumberBed.K(.Return));
		Test.Assert(b.Field.IsMixed);
		Test.Assert(b.Changes == 0);

		// Typed: the value it already held is committed all the same.
		b.D.InjectText("4");
		b.D.InjectKeyDown(NumberBed.K(.Return));
		Test.Assert(!b.Field.IsMixed);
		Test.Assert(Near(b.Field.Value, 4.0));
		Test.Assert(b.Changes == 1);

		// A scrub from mixed, given up: mixed again.
		b.Field.Value = 4.0;
		b.Field.IsMixed = true;
		b.Other.RequestFocus();
		b.D.InjectMouseDown(.(30.0f, 12.0f), .Left);
		b.D.InjectMouseMove(.(50.0f, 12.0f));
		Test.Assert(!b.Field.IsMixed);
		b.D.InjectKeyDown(NumberBed.K(.Escape));
		Test.Assert(b.Field.IsMixed);
		Test.Assert(b.Field.Text.Length == 0);
		b.D.InjectMouseUp(.(50.0f, 12.0f), .Left);

		// Setting the value clears it.
		b.Field.Value = 2.0;
		Test.Assert(!b.Field.IsMixed);
		Test.Assert(b.Field.Text == "2");
	}

	[Test]
	public static void WithWheelStepsOffTheWheelGoesOnToWhatScrolls()
	{
		let b = scope NumberBed();
		b.Field.StepsOnWheel = false;
		b.Field.RequestFocus();
		b.D.InjectMouseWheel(.(30.0f, 12.0f), .(0.0f, 1.0f));
		Test.Assert(Near(b.Field.Value, 0.0));
		Test.Assert(b.Changes == 0);
	}

	[Test]
	public static void MarkupSetsItsRangeItsFormAndItsValue()
	{
		let tree = MarkupFixtures.Load("<NumberField min=\"-10\" max=\"10\" step=\"0.1\" value=\"2.25\" suffix=\" m\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let f = tree as NumberField;
		Test.Assert(f != null);
		Test.Assert(Math.Abs(f.Min - -10.0) < 1e-9);
		Test.Assert(Math.Abs(f.Value - 2.3) < 1e-9); // to the step
		Test.Assert(f.Text == "2.3 m");
	}

	[Test]
	public static void AFieldTooNarrowForItsNumberAndItsArrowsGivesTheArrowsRoomToTheNumber()
	{
		let b = scope NumberBed();
		Test.Assert(b.Field.ShowsArrows); // 120 wide: both fit
		Test.Assert(b.Field.UpButton.Visible);
		b.Field.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(40.0f); });
		b.Root.UpdateLayout();
		Test.Assert(!b.Field.ShowsArrows);
		Test.Assert(!b.Field.UpButton.Visible);
		Test.Assert(!b.Field.DownButton.Visible);
		// Its keys still step it.
		b.Field.Step = 1.0;
		b.Field.Value = 5.0;
		b.Field.RequestFocus();
		b.D.InjectKeyDown(NumberBed.K(.Up));
		Test.Assert(Near(b.Field.Value, 6.0));
	}
}
