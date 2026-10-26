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

	[Test]
	public static void APopupEntersEachTimeItOpens()
	{
		// A menu, a combo box's list, a tooltip or a dialog plays the sheet's entrance when it
		// opens, and again when it opens the next time (it left the tree between).
		let bed = scope EnterBed(".card { opacity: 1; transition: opacity 0.2s linear; } .card:entering { opacity: 0; }");
		let d = bed.Root.EventDispatcher;
		for (int open = 0; open < 2; open++)
		{
			let options = new PopupOptions();
			options.AnchorRect = .(20.0f, 20.0f, 0.0f, 0.0f);
			options.HasAnchorRect = true;
			d.OpenPopup(bed.Root, bed.Card, options);
			Test.Assert(bed.Card.IsEntering);
			bed.Frame(0.0);
			Test.Assert(Near(bed.Card.Alpha, 0.0f));
			bed.Frame(0.0);
			bed.Frame(0.1);
			Test.Assert(Near(bed.Card.Alpha, 0.5f));
			bed.Frame(0.1);
			Test.Assert(Near(bed.Card.Alpha, 1.0f));
			Test.Assert(d.ClosePopup(bed.Card));
			bed.Frame(0.0);
		}
		Test.Assert(bed.Entered == 2);
	}

	[Test]
	public static void ADialogClosedPlaysItsExitOnTopThenGoesOpenedAgainMeanwhileItIsWhole()
	{
		// Closed, a modal window is out of the popups at once (input and IsOpen move on) and fades
		// on top, taking no input, until its exit ends; then it goes and hears it has. Menus close
		// at once.
		let bed = scope EnterBed(".card { opacity: 1; transition: opacity 0.2s linear; } .card:leaving { opacity: 0; }");
		let dialog = new Window();
		defer dialog.ReleaseRef();
		dialog.AddClass("card");
		dialog.Size = .(120.0f, 80.0f);
		int closed = 0;
		dialog.SetOnClose(new [&] () => { closed++; });
		let d = bed.Root.EventDispatcher;

		dialog.OpenModal(bed.Root);
		bed.Frame(0.0);
		bed.Frame(0.0);
		Test.Assert(dialog.IsOpen);
		dialog.Close();
		Test.Assert(!dialog.IsOpen);
		Test.Assert(closed == 1);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(dialog.Parent == bed.Root); // still there, fading
		Test.Assert(dialog.InTopLayer);
		Test.Assert(dialog.IsTreeInert);
		bed.Frame(0.0);
		bed.Frame(0.1);
		Test.Assert(Near(dialog.Alpha, 0.5f));
		bed.Frame(0.1);
		bed.Frame(0.0); // the exit ended: it goes at the next drain
		bed.Frame(0.0);
		Test.Assert(dialog.Parent == null);
		Test.Assert(!dialog.InTopLayer);

		// Opened again halfway through its exit: whole and open, and it does not go.
		dialog.OpenModal(bed.Root);
		bed.Frame(0.0);
		bed.Frame(0.0);
		dialog.Close();
		bed.Frame(0.0);
		bed.Frame(0.1);
		dialog.OpenModal(bed.Root);
		Test.Assert(dialog.IsOpen);
		Test.Assert(!dialog.IsLeaving);
		Test.Assert(d.PopupCount == 1);
		for (int i = 0; i < 4; i++)
			bed.Frame(0.1);
		Test.Assert(dialog.Parent == bed.Root);
		Test.Assert(dialog.IsOpen);
		Test.Assert(Near(dialog.Alpha, 1.0f));
	}

	[Test]
	public static void AMessageBoxShownFromAPageGoesBackThereOnceItsExitHasPlayed()
	{
		let bed = scope EnterBed("messagebox { opacity: 1; transition: opacity 0.2s linear; } messagebox:leaving { opacity: 0; }");
		let page = new Panel();
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		let @box = new MessageBox();
		defer @box.ReleaseRef();
		page.AddChild(@box);
		@box.Configure("Delete?", "It goes to the trash.", .OkCancel);
		Test.Assert(@box.Show());
		bed.Frame(0.0);
		bed.Frame(0.0);
		@box.RequestClose(); // as Escape would
		Test.Assert(@box.ResultName == "cancel");
		Test.Assert(@box.Parent == bed.Root); // fading over the root
		for (int i = 0; i < 5; i++)
			bed.Frame(0.1);
		Test.Assert(@box.Parent == page); // home, unseen
		Test.Assert(!@box.Displayed);
	}
}
