using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Tweens: a property a sheet names moves over the cascade on the GUI's clock, from the value
// underneath or a given start, through the same typed values a transition moves (a number, a
// length, a colour, box shadows, a transform), and holds its end until stopped, a sheet's later
// change leaving it be; a tween of the same property replaces the running one from where it shows;
// delays, repeats, ping-pong and the callback at the end; a paused GUI's tweens stand still, and a
// destroyed node takes its tweens with it.

/// A widget in a GUI styled by a sheet; a frame runs the clock, then the style pass, as a host does.
/// The root, the widget and the manager go with it.
class TweenBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public UIWidget Widget = new .() ~ _?.ReleaseRef();
	public StyleManager Styles = new .() ~ delete _;

	public this(StringView css)
	{
		Widget.Tag = "box";
		using (Node.StyleWriteScope(Widget))
		{
			Widget.Size = .(100.0f, 50.0f);
		}
		Root.AddChild(Widget);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.StyleSheet = sheet;
		Styles.ApplyTree(Root);
	}

	public void Frame(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
		Styles.ApplyTree(Root);
		Root.UpdateLayout();
	}

	public float Red => Widget.Box.BackgroundColor.R;
}

/// A GUI whose data holds `score` (0, a whole number), and a widget to run a group on. (Raptor's
/// bed binds a label to the score; the tests here read the data itself.) The root goes with it.
class TweenDataBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public UIWidget Holder = new .() ~ _.ReleaseRef();

	public this()
	{
		Root.AddChild(Holder);
		Data.Set("score", System.Variant.Create((int32)0));
		Frame(0.0);
	}

	public DataModel Data => Root.Context.Data;

	public void Frame(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
	}

	/// The score now, which must be a whole number.
	public int32 Score
	{
		get
		{
			let v = Data.Peek("score");
			Test.Assert(v.VariantType == typeof(int32)); // a whole number stays one
			return v.Get<int32>();
		}
	}
}

class TweenTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ASheetsPropertyMovesOverTheCascadeFromTheValueUnderneathAndHoldsItsEnd()
	{
		let bed = scope TweenBed("box { background-color: #000000; } box.lit { background-color: #00ff00; }");
		let tween = bed.Widget.Animate("background-color", "#ff0000", 1.0f, "linear");
		defer tween.ReleaseRef();
		Test.Assert(tween != null);
		bed.Frame(0.5);
		Test.Assert(tween.MovesStyle);
		Test.Assert(Near(bed.Red, 0.5f));
		bed.Frame(0.5);
		Test.Assert(Near(bed.Red, 1.0f));
		Test.Assert(tween.IsDone);
		bed.Frame(0.5);
		Test.Assert(Near(bed.Red, 1.0f)); // held

		// The sheet changes underneath: the tween's end still shows.
		bed.Widget.AddClass("lit");
		bed.Frame(0.1);
		Test.Assert(Near(bed.Red, 1.0f));
		Test.Assert(Near(bed.Widget.Box.BackgroundColor.G, 0.0f));
		// Stopped: the property is the sheet's again.
		Test.Assert(bed.Widget.StopAnimation("background-color"));
		bed.Frame(0.0);
		Test.Assert(Near(bed.Red, 0.0f));
		Test.Assert(Near(bed.Widget.Box.BackgroundColor.G, 1.0f));
		Test.Assert(!bed.Widget.StopAnimation("background-color")); // nothing moves it now
	}

	[Test]
	public static void EveryValueKindATransitionMovesANumberALengthBoxShadowsATransform()
	{
		let bed = scope TweenBed("box { opacity: 1; width: 100; box-shadow: 0 0 0 transparent; transform: rotate(0deg); }");
		let opacity = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
		defer opacity.ReleaseRef();
		let width = bed.Widget.Animate("width", "200", 1.0f, "linear");
		defer width.ReleaseRef();
		let shadow = bed.Widget.Animate("box-shadow", "0 4px 8px #000000", 1.0f, "linear");
		defer shadow.ReleaseRef();
		let transform = bed.Widget.Animate("transform", "rotate(90deg)", 1.0f, "linear");
		defer transform.ReleaseRef();
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		Test.Assert(Near(bed.Widget.Size.X, 150.0f));
		Test.Assert(bed.Widget.Box.Shadows.Count == 1);
		Test.Assert(Near(bed.Widget.Box.Shadows[0].Offset.Y, 2.0f));
		Test.Assert(bed.Widget.StyleTransforms.Count == 1);
		Test.Assert(Near(bed.Widget.StyleTransforms[0].Angle, 0.7853982f));
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.0f));
		Test.Assert(Near(bed.Widget.Size.X, 200.0f));
	}

	[Test]
	public static void AGivenStartTheEasingAndNothingToMoveFrom()
	{
		let bed = scope TweenBed("box { }");
		let fade = bed.Widget.Animate("opacity", "1", 1.0f, "ease-in-quad");
		defer fade.ReleaseRef();
		fade.From("0");
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.25f)); // eased in: a quarter at half time
		// A property no sheet sets and with no start moves from its initial value (transparent).
		let colour = bed.Widget.Animate("background-color", "#ff0000", 1.0f, "linear");
		defer colour.ReleaseRef();
		bed.Frame(0.5);
		Test.Assert(Near(bed.Red, 0.5f));
		Test.Assert(Near(bed.Widget.Box.BackgroundColor.A, 0.5f));
	}

	[Test]
	public static void ATweenOfTheSamePropertyReplacesTheRunningOneFromWhereItShows()
	{
		let bed = scope TweenBed("box { opacity: 1; }");
		let first = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
		defer first.ReleaseRef();
		bool firstFinished = false;
		first.OnFinished(new [&] () => { firstFinished = true; });
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		let second = bed.Widget.Animate("opacity", "1", 1.0f, "linear");
		defer second.ReleaseRef();
		Test.Assert(first.IsDone);
		bed.Frame(0.0);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f)); // no jump
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f));
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
		Test.Assert(!firstFinished); // replaced, not finished
	}

	[Test]
	public static void ADelayWaitsRepeatsRunAgainPingPongComesBackAndTheEndCallsBackOnce()
	{
		let bed = scope TweenBed("box { opacity: 1; }");
		int finished = 0;
		let tween = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
		defer tween.ReleaseRef();
		tween.Delay(0.5f)
			.Repeat(2)
			.PingPong()
			.OnFinished(new [&] () => { finished++; });
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f)); // waiting
		bed.Frame(0.75); // 0.5 into the first run
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		bed.Frame(0.75); // 0.25 into the second, coming back
		Test.Assert(Near(bed.Widget.Alpha, 0.25f));
		Test.Assert(finished == 0);
		bed.Frame(1.0);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f)); // back at the start
		Test.Assert(finished == 1);
		bed.Frame(1.0);
		Test.Assert(finished == 1);

		// Forever: still running long after, and Cancel gives the property back.
		let forever = bed.Widget.Animate("opacity", "0", 0.1f, "linear");
		defer forever.ReleaseRef();
		forever.Repeat(-1);
		for (int i = 0; i < 40; i++)
			bed.Frame(0.25);
		Test.Assert(!forever.IsDone);
		forever.Cancel();
		bed.Frame(0.0);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f)); // the sheet's
	}

	[Test]
	public static void APausedGUIsTweensStandStillADestroyedNodeTakesItsTweensWithIt()
	{
		let bed = scope TweenBed("box { opacity: 1; }");
		let tween = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
		defer tween.ReleaseRef();
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f));
		bed.Root.Paused = true;
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f));
		bed.Root.Paused = false;
		bed.Root.TimeScale = 2.0f; // a GUI's own time, apart from the game's
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.25f));

		bed.Styles.Forget(bed.Widget);
		bed.Root.RemoveChild(bed.Widget);
		bed.Widget.ReleaseRef();
		bed.Widget = null;
		bed.Frame(0.1);
		Test.Assert(bed.Root.ActionManager.IsEmpty);
	}

	[Test]
	public static void OverARunningTransitionAndASheetTransitionAfterItEnds()
	{
		let bed = scope TweenBed("box { opacity: 1; transition: opacity 1s linear; } box.dim { opacity: 0; }");
		bed.Widget.ToggleClass("dim");
		bed.Styles.ApplyTree(bed.Root);
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f));
		let tween = bed.Widget.Animate("opacity", "1", 0.5f, "linear");
		defer tween.ReleaseRef();
		tween.From("0.5");
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f)); // the tween's, over the transition's 0.5
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
		bed.Frame(1.0); // the transition ended; the tween still holds
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
	}

	[Test]
	public static void ASequenceRunsItsStepsInOrderEachFromWhereTheLastLeftTheTime()
	{
		let bed = scope TweenBed("box { opacity: 1; background-color: #000000; }");
		let order = scope List<int>();
		let sequence = new TweenSequence();
		defer sequence.ReleaseRef();
		let fade = bed.Widget.CreateTween("opacity", "0", 1.0f, "linear");
		defer fade.ReleaseRef();
		let colour = bed.Widget.CreateTween("background-color", "#ff0000", 1.0f, "linear");
		defer colour.ReleaseRef();
		sequence.Add(fade)
			.Call(new [&] () => { order.Add(1); })
			.Wait(0.5f)
			.Add(colour)
			.Call(new [&] () => { order.Add(2); });
		int finished = 0;
		sequence.OnFinished(new [&] () => { finished++; });
		bed.Widget.RunAction(sequence);
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		Test.Assert(Near(bed.Red, 0.0f)); // not yet
		bed.Frame(1.25); // the fade ends at 1.0, the call, the wait to 1.5, then 0.25 of the colour
		Test.Assert(Near(bed.Widget.Alpha, 0.0f));
		Test.Assert(order.Count == 1);
		Test.Assert(Near(bed.Red, 0.25f));
		bed.Frame(1.0);
		Test.Assert(Near(bed.Red, 1.0f));
		Test.Assert(order.Count == 2);
		Test.Assert(order[1] == 2);
		Test.Assert(finished == 1);
		Test.Assert(sequence.IsDone);
	}

	[Test]
	public static void AParallelGroupRunsItsStepsTogetherAndEndsWithTheLastAGroupRepeats()
	{
		let bed = scope TweenBed("box { opacity: 1; background-color: #000000; }");
		let together = new TweenParallel();
		defer together.ReleaseRef();
		let fade = bed.Widget.CreateTween("opacity", "0", 0.5f, "linear");
		defer fade.ReleaseRef();
		let colour = bed.Widget.CreateTween("background-color", "#ff0000", 1.0f, "linear");
		defer colour.ReleaseRef();
		together.Add(fade)
			.Add(colour)
			.Repeat(2);
		int finished = 0;
		together.OnFinished(new [&] () => { finished++; });
		bed.Widget.RunAction(together);
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		Test.Assert(Near(bed.Red, 0.25f));
		bed.Frame(0.5); // the fade ended at 0.5; the colour runs on
		Test.Assert(Near(bed.Widget.Alpha, 0.0f));
		Test.Assert(Near(bed.Red, 0.75f));
		bed.Frame(0.5); // the first run ended at 1.0; 0.25 into the second, each from where it showed
		Test.Assert(finished == 0);
		Test.Assert(Near(bed.Red, 1.0f));
		Test.Assert(Near(bed.Widget.Alpha, 0.0f));
		bed.Frame(1.0);
		Test.Assert(finished == 1);
		Test.Assert(together.IsDone);
	}

	[Test]
	public static void ATweenStartedOnItsOwnTakesItsPropertyFromAGroupsStep()
	{
		let bed = scope TweenBed("box { opacity: 1; }");
		let sequence = new TweenSequence();
		defer sequence.ReleaseRef();
		let inGroup = bed.Widget.CreateTween("opacity", "0", 1.0f, "linear");
		defer inGroup.ReleaseRef();
		sequence.Add(inGroup);
		bed.Widget.RunAction(sequence);
		bed.Frame(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		let alone = bed.Widget.Animate("opacity", "1", 0.5f, "linear");
		defer alone.ReleaseRef();
		Test.Assert(inGroup.IsDone);
		bed.Frame(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.75f));
		Test.Assert(bed.Widget.StopAnimation("opacity"));
		bed.Frame(0.0);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
	}

	[Test]
	public static void ASpringSettlesOnItsEndLittleDampingOvershootsAndRingsBack()
	{
		let bed = scope TweenBed("box { opacity: 0; }");
		int finished = 0;
		let spring = bed.Widget.SpringTo("opacity", "1");
		defer spring.ReleaseRef();
		spring.OnFinished(new [&] () => { finished++; });
		Test.Assert(spring.IsSpring);
		float last = 0.0f;
		bool rising = true;
		for (int i = 0; (i < 30) && !spring.IsDone; i++)
		{
			bed.Frame(1.0 / 60.0);
			rising = rising && (bed.Widget.Alpha >= last); // a damped spring comes straight in
			last = bed.Widget.Alpha;
		}
		Test.Assert(rising);
		for (int i = 0; (i < 600) && !spring.IsDone; i++)
			bed.Frame(1.0 / 60.0);
		Test.Assert(spring.IsDone);
		Test.Assert(finished == 1);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));

		// Loose: past the end, then back under it.
		let loose = scope TweenBed("box { width: 100; }");
		let wobbly = loose.Widget.SpringTo("width", "200", 300.0f, 4.0f);
		defer wobbly.ReleaseRef();
		float most = 0.0f;
		float leastAfter = 1000.0f;
		for (int i = 0; i < 240; i++)
		{
			loose.Frame(1.0 / 60.0);
			let w = loose.Widget.Size.X;
			most = (w > most) ? w : most;
			if (most > 200.0f)
				leastAfter = (w < leastAfter) ? w : leastAfter;
		}
		Test.Assert(most > 210.0f);
		Test.Assert(leastAfter < 200.0f);
	}

	[Test]
	public static void ASpringRetargetedMidFlightTurnsFromWhereItIsWithItsSpeed()
	{
		let bed = scope TweenBed("box { width: 100; }");
		let spring = bed.Widget.SpringTo("width", "300");
		defer spring.ReleaseRef();
		for (int i = 0; i < 6; i++)
			bed.Frame(1.0 / 60.0);
		let before = bed.Widget.Size.X;
		bed.Frame(1.0 / 60.0);
		let speed = bed.Widget.Size.X - before; // per frame
		Test.Assert(speed > 0.0f);
		let again = bed.Widget.SpringTo("width", "400");
		defer again.ReleaseRef();
		Test.Assert(again == spring); // the same spring, turned
		let at = bed.Widget.Size.X;
		bed.Frame(1.0 / 60.0);
		let step = bed.Widget.Size.X - at;
		Test.Assert(step > 0.0f);
		Test.Assert(NodeFixtures.Near(step, speed, 0.5f)); // no jolt: about the speed it had
		for (int i = 0; (i < 600) && !spring.IsDone; i++)
			bed.Frame(1.0 / 60.0);
		Test.Assert(NodeFixtures.Near(bed.Widget.Size.X, 400.0f, 0.01f));

		// Toward a value of a different kind of distance (a colour): still continuous.
		let colour = scope TweenBed("box { background-color: #000000; }");
		let red = colour.Widget.SpringTo("background-color", "#ff0000");
		defer red.ReleaseRef();
		for (int i = 0; i < 6; i++)
			colour.Frame(1.0 / 60.0);
		let shown = colour.Red;
		let blue = colour.Widget.SpringTo("background-color", "#0000ff");
		defer blue.ReleaseRef();
		colour.Frame(0.0);
		Test.Assert(Near(colour.Red, shown));
	}

	// === A data value tweened ===

	[Test]
	public static void ADataValuesNewTweenReplacesTheRunningOneFromTheValueShowing()
	{
		let bed = scope TweenDataBed();
		let first = bed.Root.Context.AnimateData("score", 100.0, 1.0f, "linear");
		defer first.ReleaseRef();
		bed.Frame(0.5);
		Test.Assert(bed.Score == 50);
		let second = bed.Root.Context.AnimateData("score", 0.0, 1.0f, "linear");
		defer second.ReleaseRef();
		bed.Frame(0.5);
		Test.Assert(first.IsDone);
		Test.Assert(bed.Score == 25); // from 50 toward 0
		bed.Frame(0.5);
		Test.Assert(bed.Score == 0);
	}

	[Test]
	public static void ADataValueNeverSetMovesAsANumberRetargetedItTurnsFromWhereItIsCancelledItStays()
	{
		let bed = scope TweenDataBed();
		let gui = bed.Root.Context;
		let fill = gui.AnimateData("health", 1.0, 1.0f, "linear");
		defer fill.ReleaseRef();
		bed.Frame(0.5);
		Test.Assert(gui.Data.Peek("health").VariantType == typeof(double));
		Test.Assert(NodeFixtures.Near((float)gui.Data.Peek("health").Get<double>(), 0.5f));
		fill.Retarget("0");
		bed.Frame(0.5);
		Test.Assert(NodeFixtures.Near((float)gui.Data.Peek("health").Get<double>(), 0.25f));
		fill.Cancel();
		bed.Frame(1.0);
		Test.Assert(fill.IsDone);
		Test.Assert(NodeFixtures.Near((float)gui.Data.Peek("health").Get<double>(), 0.25f));
	}

	[Test]
	public static void ADataValuesTweenRunsAsAGroupsStepAfterAWait()
	{
		let bed = scope TweenDataBed();
		let sequence = new TweenSequence();
		defer sequence.ReleaseRef();
		let count = bed.Root.Context.CreateDataTween("score", 10.0, 0.5f, "linear");
		defer count.ReleaseRef();
		sequence.Wait(0.5f).Add(count);
		bed.Holder.Play(sequence);
		bed.Frame(0.5);
		Test.Assert(bed.Score == 0);
		bed.Frame(0.25);
		Test.Assert(bed.Score == 5);
		bed.Frame(0.25);
		Test.Assert(bed.Score == 10);
		Test.Assert(sequence.IsDone);
	}

	[Test]
	public static void ADataValueAScriptSetAFractionsTypeCountsInWholeNumbersWhenAsked()
	{
		let bed = scope TweenDataBed();
		let gui = bed.Root.Context;
		gui.Data.Set("points", System.Variant.Create(0.0)); // as a script's numbers arrive
		let counting = gui.AnimateData("points", 100.0, 1.0f, "linear");
		defer counting.ReleaseRef();
		counting.Whole();
		for (int i = 0; i < 7; i++)
		{
			bed.Frame(1.0 / 7.0);
			let value = gui.Data.Peek("points");
			Test.Assert(value.VariantType == typeof(double));
			let now = value.Get<double>();
			Test.Assert(now == (double)(int64)now); // never a fraction
		}
		Test.Assert(NodeFixtures.Near((float)gui.Data.Peek("points").Get<double>(), 100.0f));
	}
}
