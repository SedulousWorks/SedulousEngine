using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Entering: Node.Enter puts a node in `:entering` while the sheet's entrance plays (a keyframe
// animation, or values it starts from), then moves it to its own style and tells `entered` once
// that has settled; a Leave cuts it short from where it is; and the GUI's clock may be capped so a
// hitch slows motion rather than skipping it.

/// A GUI (400 x 300) with a sheet a style pass has run over, and a card of class "card" not yet
/// in it, counting the `entered` it hears. The root, the card and the styles go with it.
class EnterBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public UIWidget Card ~ _.ReleaseRef();
	public StyleManager Styles = new .() ~ delete _;
	public int Entered = 0;

	public this(StringView css)
	{
		Root = SceneFixtures.NewScene(400.0f, 300.0f);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.StyleSheet = sheet;
		Styles.ApplyTree(Root); // a style pass runs over this GUI
		Card = new UIWidget();
		Card.AddClass("card");
		Card.Size = .(100.0f, 40.0f);
		Card.AddEventListener(.Entered, new (e) => { Entered++; });
	}

	/// One frame as a host runs it: the GUI's update, then the style pass.
	public void Frame(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
		Styles.ApplyTree(Root);
	}

	/// The card arrives: added and entering before its first style.
	public void Arrive()
	{
		Root.AddChild(Card);
		Card.Enter();
	}
}

/// Entering: an entrance under `:entering`, then `entered` once it has settled.
class EnterTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void AKeyframeEntrancePlaysUnderEnteringThenTheNodeHearsEntered()
	{
		let bed = scope EnterBed("@keyframes rise { from { opacity: 0; } to { opacity: 1; } }" +
			".card:entering { animation: rise 0.4s linear; }");
		bed.Arrive();
		Test.Assert(bed.Card.IsEntering);
		bed.Frame(0.0);
		Test.Assert(Near(bed.Card.Alpha, 0.0f));
		bed.Frame(0.2);
		Test.Assert(Near(bed.Card.Alpha, 0.5f));
		Test.Assert(bed.Card.IsEntering);
		bed.Frame(0.2); // it ends: :entering goes
		Test.Assert(!bed.Card.IsEntering);
		Test.Assert(bed.Card.IsArriving);
		Test.Assert(bed.Entered == 0);
		bed.Frame(0.0); // its own style moved nothing: settled
		Test.Assert(bed.Entered == 1);
		Test.Assert(!bed.Card.IsArriving);
		Test.Assert(Near(bed.Card.Alpha, 1.0f));
	}

	[Test]
	public static void ValuesEnteringStartsFromMoveToTheNodesOwnThroughItsTransitionAsStartingStyle()
	{
		let bed = scope EnterBed(".card { opacity: 1; transition: opacity 0.4s linear; } .card:entering { opacity: 0; }");
		bed.Arrive();
		bed.Frame(0.0); // its first style: where it starts, with nothing to move from
		Test.Assert(Near(bed.Card.Alpha, 0.0f));
		bed.Frame(0.0); // :entering goes: toward its own
		Test.Assert(!bed.Card.IsEntering);
		bed.Frame(0.2);
		Test.Assert(Near(bed.Card.Alpha, 0.5f));
		Test.Assert(bed.Entered == 0);
		bed.Frame(0.2);
		Test.Assert(Near(bed.Card.Alpha, 1.0f));
		Test.Assert(bed.Entered == 1);
	}

	[Test]
	public static void WithNoEntranceInTheSheetItSettlesInACoupleOfUpdatesWithNoStylePassAtOnce()
	{
		let bed = scope EnterBed(".card { opacity: 1; }");
		bed.Arrive();
		for (int i = 0; i < 3; i++)
			bed.Frame(0.0);
		Test.Assert(bed.Entered == 1);

		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let widget = new UIWidget();
		defer widget.ReleaseRef();
		int heard = 0;
		widget.AddEventListener(.Entered, new [&] (e) => { heard++; });
		root.AddChild(widget);
		widget.Enter();
		Test.Assert(heard == 1);
		Test.Assert(!widget.IsArriving);
	}

	[Test]
	public static void ALeaveCutsTheEntranceShortAndLeavesFromWhereItIs()
	{
		let bed = scope EnterBed(".card { opacity: 1; transition: opacity 0.4s linear; } .card:entering { opacity: 0; }" +
			".card:leaving { opacity: 0; }");
		bed.Arrive();
		bed.Frame(0.0);
		bed.Frame(0.0);
		bed.Frame(0.2); // half in
		Test.Assert(Near(bed.Card.Alpha, 0.5f));
		bed.Card.Leave();
		Test.Assert(!bed.Card.IsArriving);
		bed.Frame(0.0);
		bed.Frame(0.2); // from 0.5 toward 0, halfway
		Test.Assert(Near(bed.Card.Alpha, 0.25f));
		bed.Frame(0.2);
		Test.Assert(bed.Card.Parent == null);
		Test.Assert(bed.Entered == 0);
	}

	[Test]
	public static void ACappedClockSlowsAHitchsMotionRatherThanSkippingIt()
	{
		let bed = scope EnterBed(".card { opacity: 1; transition: opacity 0.5s linear; } .card.dim { opacity: 0; }");
		bed.Root.AddChild(bed.Card);
		bed.Frame(0.0);
		bed.Root.Context.MaxClockStep = 0.1f;
		bed.Card.AddClass("dim");
		bed.Frame(0.0);
		bed.Frame(1.0); // a one-second hitch moves it a tenth of a second
		Test.Assert(Near(bed.Card.Alpha, 0.8f));
		Test.Assert(Near(bed.Root.Context.MaxClockStep, 0.1f));
	}
}
