using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Node.Leave puts a node in `:leaving`, where the sheet's exit transition or animation plays, keeps
// input off it, and removes it once that ends; `transitionend` and `animationend` tell a node a
// sheet's motion on it ended.

/// A GUI with a sheet and one widget of class "card" under its root, sized 400 x 300. The root,
/// the card and the styles go with it.
class LeaveBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public UIWidget Card ~ _.ReleaseRef();
	public StyleManager Styles = new .() ~ delete _;

	public this(StringView css)
	{
		Root = SceneFixtures.NewScene(400.0f, 300.0f);
		Card = new UIWidget();
		Card.AddClass("card");
		Card.Size = .(100.0f, 40.0f);
		Root.AddChild(Card);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.StyleSheet = sheet;
		Frame(0.0);
	}

	/// One frame as a host runs it: the GUI's update, then the style pass.
	public void Frame(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
		Styles.ApplyTree(Root);
	}

	public bool Attached => Card.Parent == Root;
}

/// What a motion's end told: its name, its elapsed time, how many times.
class LeaveHeard
{
	public String Name = new .() ~ delete _;
	public float Elapsed = -1.0f;
	public int Count = 0;

	/// Listens on `node` for `type` (a MotionEndEvent), into this.
	public void Listen(Node node, EventType type)
	{
		node.AddEventListener(type, new (e) =>
			{
				let end = (MotionEndEvent)e;
				Name.Set(end.Name);
				Elapsed = end.Elapsed;
				Count++;
			});
	}
}

/// Leaving: a node that goes plays its way out first, out of input at once.
class LeaveTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void InAGUINoStylePassRunsOverItGoesAtTheNextUpdateNeverInsideTheEventThatSentItDetachedAtOnce()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let widget = new UIWidget();
		defer widget.ReleaseRef();
		root.AddChild(widget);
		widget.Leave();
		Test.Assert(widget.Parent == root); // a click handler that closed it still finds it there
		Test.Assert(widget.IsLeaving);
		root.Context.Update(TimeSpan(0));
		Test.Assert(widget.Parent == null);
		Test.Assert(!widget.IsLeaving);

		let parent = new UIWidget();
		defer parent.ReleaseRef();
		let child = new UIWidget();
		defer child.ReleaseRef();
		parent.AddChild(child);
		child.Leave();
		Test.Assert(child.Parent == null);
	}

	// Raptor's card is a Button; nothing here reads a button's own behaviour, so a plain widget
	// stands in for it.
	[Test]
	public static void TheSheetsExitTransitionPlaysThenTheNodeGoes()
	{
		let bed = scope LeaveBed(".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }");
		let ended = scope LeaveHeard();
		ended.Listen(bed.Card, .TransitionEnd);

		bed.Card.Leave();
		Test.Assert(bed.Card.IsLeaving);
		bed.Frame(0.0); // the style pass: `:leaving` matches, the transition starts
		Test.Assert(bed.Attached);
		Test.Assert(Near(bed.Card.Alpha, 1.0f));

		bed.Frame(0.25);
		Test.Assert(bed.Attached);
		Test.Assert(Near(bed.Card.Alpha, 0.5f));
		Test.Assert(ended.Count == 0);

		bed.Frame(0.25); // it ends: told, and taken off at the update's drain
		Test.Assert(ended.Count == 1);
		Test.Assert(ended.Name == "opacity");
		Test.Assert(Near(ended.Elapsed, 0.5f));
		Test.Assert(!bed.Attached);
		Test.Assert(!bed.Card.IsLeaving); // out of its parent, it has left
	}

	[Test]
	public static void WithNoExitInTheSheetItGoesAtTheNextUpdate()
	{
		let bed = scope LeaveBed(".card { opacity: 1; }");
		bed.Card.Leave();
		bed.Styles.ApplyTree(bed.Root);
		Test.Assert(bed.Attached); // never inside the style pass's walk
		bed.Root.Context.Update(SceneFixtures.Seconds(0.0));
		Test.Assert(!bed.Attached);
	}

	[Test]
	public static void AKeyframeExitIsToldOnceAsAnimationendAndAForwardsFillStillLetsItGo()
	{
		let bed = scope LeaveBed("@keyframes out { from { opacity: 1; } to { opacity: 0; } }" +
			".card:leaving { animation: out 0.3s linear forwards; }");
		let ended = scope LeaveHeard();
		ended.Listen(bed.Card, .AnimationEnd);
		bed.Card.Leave();
		bed.Frame(0.0);
		bed.Frame(0.15);
		Test.Assert(bed.Attached);
		Test.Assert(Near(bed.Card.Alpha, 0.5f));
		bed.Frame(0.15);
		Test.Assert(ended.Count == 1);
		Test.Assert(ended.Name == "out");
		Test.Assert(Near(ended.Elapsed, 0.3f));
		Test.Assert(!bed.Attached);
	}

	[Test]
	public static void AnInfiniteAnimationRunningIsNotWaitedFor()
	{
		let bed = scope LeaveBed("@keyframes pulse { from { opacity: 1; } to { opacity: 0.5; } }" +
			".card { animation: pulse 1s infinite; }");
		bed.Frame(0.25);
		bed.Card.Leave();
		bed.Frame(0.0);
		bed.Root.Context.Update(SceneFixtures.Seconds(0.0));
		Test.Assert(!bed.Attached);
	}

	[Test]
	public static void ANodeTakenBackBeforeItsExitEndsStaysWhole()
	{
		let bed = scope LeaveBed(".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }");
		let shelf = new UIWidget();
		defer shelf.ReleaseRef();
		bed.Root.AddChild(shelf);
		bed.Frame(0.0);
		bed.Card.Leave();
		bed.Frame(0.0);
		shelf.AddChild(bed.Card); // moved elsewhere mid-exit
		Test.Assert(!bed.Card.IsLeaving);
		for (int i = 0; i < 4; i++)
			bed.Frame(0.25);
		Test.Assert(bed.Card.Parent == shelf);
		Test.Assert(Near(bed.Card.Alpha, 1.0f));
	}

	[Test]
	public static void TransitionendTellsEachPropertyOnceAndAReplacedTransitionIsNotTold()
	{
		let bed = scope LeaveBed(".card { opacity: 1; transition: opacity 0.4s linear; } .card.dim { opacity: 0.2; }");
		let ended = scope LeaveHeard();
		ended.Listen(bed.Card, .TransitionEnd);
		bed.Card.AddClass("dim");
		bed.Frame(0.0);
		bed.Frame(0.2);
		bed.Card.RemoveClass("dim"); // replaced halfway: back toward 1
		bed.Frame(0.0);
		Test.Assert(ended.Count == 0);
		bed.Frame(0.4);
		Test.Assert(ended.Count == 1); // the one that ran to its end
		Test.Assert(ended.Name == "opacity");
		bed.Frame(1.0);
		Test.Assert(ended.Count == 1);
		Test.Assert(bed.Attached); // a node not leaving stays
	}

	[Test]
	public static void LeavingReadsThroughAnAncestor()
	{
		let bed = scope LeaveBed(".card:leaving .label { opacity: 0.25; }");
		let label = new UIWidget();
		defer label.ReleaseRef();
		label.AddClass("label");
		bed.Card.AddChild(label);
		bed.Frame(0.0);
		Test.Assert(Near(label.Alpha, 1.0f));
		bed.Card.Leave();
		bed.Styles.ApplyTree(bed.Root);
		Test.Assert(Near(label.Alpha, 0.25f));
	}
}
