using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Gamekit.Tests;

/// The screen stack: push, pop, replace and clear; covering, blocking and pausing; focus per
/// screen; `back` from the keys and the pad; the lifecycle events; screens from markup and
/// documents.
class ScreenStackTests
{
	private static bool Near(float a, float b) => GamekitFixtures.Near(a, b);

	[Test]
	public static void APushShowsOnTopAndTakesTheFocusABlockingTopMakesThoseUnderItInert()
	{
		let bed = scope Bed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let pause = bed.MakeScreen("resume", 200.0f);
		defer pause.ReleaseRef();
		Test.Assert(bed.Stack.Push(title) == title);
		Test.Assert(bed.Focused == "play");
		Test.Assert(bed.Stack.Push(pause) == pause);
		Test.Assert(bed.Stack.Count == 2);
		Test.Assert(bed.Stack.Top == pause);
		Test.Assert(bed.Focused == "resume");
		Test.Assert(title.IsInert);
		Test.Assert(!pause.IsInert);
		Test.Assert(title.Visible); // blocked, not covered: it still shows
		bed.Layout();
		int clicks = 0;
		(title.GetChildAt(0) as Button).SetOnClick(new [&] () => { clicks++; });
		bed.D.InjectMouseDown(.(20.0f, 20.0f), .Left);
		bed.D.InjectMouseUp(.(20.0f, 20.0f), .Left);
		Test.Assert(clicks == 0);
		Test.Assert(bed.Stack.Push(pause) == null); // on the stack already
	}

	[Test]
	public static void APopRefocusesTheScreenUnderItWhereItsFocusWasACoveringScreenHidesThoseUnderIt()
	{
		let bed = scope Bed();
		let menu = bed.MakeScreen("first");
		defer menu.ReleaseRef();
		let second = new Button();
		defer second.ReleaseRef();
		second.Id = "second";
		second.Position = .(10.0f, 60.0f);
		second.Size = .(80.0f, 30.0f);
		menu.AddChild(second);
		let log = scope Log();
		log.Watch(menu, "screenhidden", "screenrevealed");
		bed.Stack.Push(menu);
		bed.Layout();
		bed.D.MoveFocus(.Down);
		Test.Assert(bed.Focused == "second");
		let options = bed.MakeScreen("volume");
		defer options.ReleaseRef();
		options.Covers = true;
		bed.Stack.Push(options);
		Test.Assert(!menu.Visible);
		Test.Assert(menu.IsCovered);
		Test.Assert(bed.Stack.Pop());
		Test.Assert(menu.Visible);
		Test.Assert(bed.Focused == "second"); // where it was, not its first
		Test.Assert(log.Heard.Count == 2);
		Test.Assert(log.Heard[0] == "screenhidden");
		Test.Assert(log.Heard[1] == "screenrevealed");
	}

	[Test]
	public static void AHUDThatDoesNotBlockLeavesTheGameScreenUnderItLive()
	{
		let bed = scope Bed();
		let game = bed.MakeScreen("world");
		defer game.ReleaseRef();
		let hud = new Screen();
		defer hud.ReleaseRef();
		hud.Blocks = false;
		bed.Stack.Push(game);
		bed.Stack.Push(hud);
		Test.Assert(!game.IsInert);
		Test.Assert(bed.Stack.WantsGameInput(.(350.0f, 250.0f)));
		let pause = bed.MakeScreen("resume");
		defer pause.ReleaseRef();
		bed.Stack.Push(pause);
		Test.Assert(game.IsInert);
		Test.Assert(hud.IsInert);
		Test.Assert(!bed.Stack.WantsGameInput(.(350.0f, 250.0f)));
	}

	[Test]
	public static void BackPopsTheTopNeverTheLastNotOneThatKeepsItNotInTheFrameThatPushedIt()
	{
		let bed = scope Bed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let options = bed.MakeScreen("volume");
		defer options.ReleaseRef();
		bed.Stack.Push(title);
		bed.Frame();
		bed.Escape();
		Test.Assert(bed.Stack.Count == 1); // the last stays
		bed.Stack.Push(options);
		bed.Escape(); // the frame that pushed it
		Test.Assert(bed.Stack.Count == 2);
		bed.Frame();
		bed.D.InjectPadButton(.East);
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Focused == "play");

		let keeps = bed.MakeScreen("stay");
		defer keeps.ReleaseRef();
		keeps.Back = "none";
		bed.Stack.Push(keeps);
		bed.Frame();
		bed.Escape();
		Test.Assert(bed.Stack.Top == keeps);
	}

	[Test]
	public static void TheTopScreensOwnBackHandlerTakesItBeforeTheStack()
	{
		let bed = scope Bed();
		let game = bed.MakeScreen("world");
		defer game.ReleaseRef();
		let pause = bed.MakeScreen("resume");
		defer pause.ReleaseRef();
		bed.Stack.Push(game);
		bed.Frame();
		// The game screen's Escape opens the pause screen, rather than popping anything.
		let stack = bed.Stack;
		game.OnCommand(cBackCommand, new [&] (command) => { stack.Push(pause); });
		bed.Escape();
		Test.Assert(bed.Stack.Top == pause);
		Test.Assert(bed.Stack.Count == 2);
		bed.Frame();
		bed.Escape(); // the pause screen has no handler: the stack pops it
		Test.Assert(bed.Stack.Top == game);
	}

	[Test]
	public static void AScreenWithNothingFocusableTakesTheFocusItselfSoBackAndItsCommandsStartThere()
	{
		let bed = scope Bed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let hud = new Screen(); // nothing focusable on it
		defer hud.ReleaseRef();
		bed.Stack.Push(title);
		bed.Stack.Push(hud);
		Test.Assert(bed.D.FocusNode == hud);
		int paused = 0;
		hud.OnCommand(cBackCommand, new [&] (command) => { paused++; });
		bed.Frame();
		bed.Escape();
		Test.Assert(paused == 1); // the HUD's own back: it opens a pause screen in a game
		Test.Assert(bed.Stack.Top == hud);
	}

	[Test]
	public static void APressOnAScreensEmptyAreaKeepsTheFocusSoBackStillReachesIt()
	{
		let bed = scope Bed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let options = bed.MakeScreen("volume");
		defer options.ReleaseRef();
		bed.Stack.Push(title);
		bed.Stack.Push(options);
		bed.Frame();
		bed.Layout();
		bed.D.InjectMouseDown(.(300.0f, 250.0f), .Left);
		bed.D.InjectMouseUp(.(300.0f, 250.0f), .Left);
		Test.Assert(bed.Focused == "volume");
		bed.Escape();
		Test.Assert(bed.Stack.Top == title);
	}

	[Test]
	public static void TheStackReportsThePauseTheGameDecidesWhatItMeans()
	{
		let bed = scope Bed();
		let told = scope List<bool>();
		bed.Stack.SetOnPausedChanged(new [&] (paused) => { told.Add(paused); });
		let log = scope Log();
		log.Watch(bed.Stack, "pausechange");
		let game = bed.MakeScreen("world");
		defer game.ReleaseRef();
		let pause = bed.MakeScreen("resume");
		defer pause.ReleaseRef();
		pause.Pauses = true;
		bed.Stack.Push(game);
		Test.Assert(!bed.Stack.IsPaused);
		bed.Stack.Push(pause);
		Test.Assert(bed.Stack.IsPaused);
		bed.Stack.Pop();
		Test.Assert(!bed.Stack.IsPaused);
		Test.Assert(told.Count == 2);
		Test.Assert(told[0]);
		Test.Assert(!told[1]);
		Test.Assert(log.Heard.Count == 2);
		Test.Assert(log.Heard[0] == "pausechange:paused");
		Test.Assert(log.Heard[1] == "pausechange:running");
	}

	[Test]
	public static void LifecycleEventsReplaceAndClear()
	{
		let bed = scope Bed();
		let a = bed.MakeScreen("a");
		defer a.ReleaseRef();
		let b = bed.MakeScreen("b");
		defer b.ReleaseRef();
		let c = bed.MakeScreen("c");
		defer c.ReleaseRef();
		let log = scope Log();
		log.Watch(a, "screenenter", "screenshown", "screenleave");
		log.Watch(b, "screenenter", "screenleave");
		bed.Stack.Push(a);
		bed.Stack.Replace(b);
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Top == b);
		Test.Assert(a.Stack == null);
		Test.Assert(a.IsLeaving); // no style pass here: it goes at the next update
		bed.Frame();
		Test.Assert(a.Parent == null);
		bed.Stack.Push(c);
		bed.Stack.Clear();
		Test.Assert(bed.Stack.Count == 0);
		Test.Assert(bed.Stack.Top == null);
		Test.Assert(!bed.Stack.Pop());
		Test.Assert(log.Heard.Count == 5);
		Test.Assert(log.Heard[0] == "screenenter");
		Test.Assert(log.Heard[1] == "screenshown");
		Test.Assert(log.Heard[2] == "screenleave");
		Test.Assert(log.Heard[3] == "screenenter");
		Test.Assert(log.Heard[4] == "screenleave");
	}

	[Test]
	public static void ContentThatIsNotAScreenIsPushedInOneAPoppedScreenWithAnExitStillDrawsOffTheStack()
	{
		let bed = scope Bed();
		let styles = scope StyleManager();
		GamekitFixtures.UseSheet(styles, "screen { opacity: 1; transition: opacity 0.5s linear; } screen:leaving { opacity: 0; }");
		styles.ApplyTree(bed.Root);
		let first = bed.MakeScreen("first");
		defer first.ReleaseRef();
		bed.Stack.Push(first);
		let label = new Label();
		defer label.ReleaseRef();
		let wrapped = bed.Stack.Push(label);
		Test.Assert(wrapped != null);
		wrapped.AddRef(); // read after it has gone from the tree
		defer wrapped.ReleaseRef();
		Test.Assert(label.Parent == wrapped);
		styles.ApplyTree(bed.Root);
		Test.Assert(bed.Stack.Pop());
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(wrapped.Parent == bed.Stack); // leaving: it still draws
		Test.Assert(wrapped.IsLeaving);
		Test.Assert(bed.Focused == "first");
		styles.ApplyTree(bed.Root);
		for (int i = 0; i < 3; i++)
		{
			bed.Root.Context.Update(GamekitFixtures.Seconds(0.25));
			styles.ApplyTree(bed.Root);
		}
		Test.Assert(wrapped.Parent == null);
	}

	[Test]
	public static void FromMarkupTheScreensAStackHoldsArePushedInOrderADocumentIsLoadedFreshBoundToTheData()
	{
		RegisterGuiElements();
		RegisterGamekitElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		let made = loader.LoadFromString(
			"<Screens><Screen id=\"game\" blocks=\"false\"/><Screen id=\"menu\" covers=\"true\" back=\"none\"/></Screens>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let stack = made as ScreenStack;
		Test.Assert(stack != null);
		Test.Assert(stack.Count == 2);
		Test.Assert(stack.At(0).Id == "game");
		Test.Assert(!stack.At(0).Blocks);
		Test.Assert(stack.Top.Id == "menu");
		Test.Assert(stack.Top.Covers);
		Test.Assert(!stack.Top.PopsOnBack);
		Test.Assert(stack.At(0).IsCovered);

		let bed = scope Bed();
		let documents = scope Documents();
		bed.Root.Context.ResourceProvider = documents;
		var name = TextVariant("Ada");
		defer name.Dispose();
		bed.Root.Context.Data.Set("name", name);
		let first = bed.Stack.PushDocument("pause.xml");
		let second = bed.Stack.PushDocument("pause.xml");
		Test.Assert(first != null);
		Test.Assert(second != null);
		Test.Assert(first != second); // fresh each time
		Test.Assert(second.Pauses);
		Test.Assert(bed.Stack.IsPaused);
		Test.Assert(bed.Focused == "resume");
		bed.Frame();
		Test.Assert((second.GetChildAt(1) as Label).Text == "Ada");
		Test.Assert(bed.Stack.PushDocument("missing.xml") == null);
	}

	[Test]
	public static void APushedScreenIsEnteringWhileItsSheetsEntrancePlaysAndShownOnceItHas()
	{
		let bed = scope StyledBed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let log = scope Log();
		log.Watch(title, "screenenter", "screenshown");
		bed.Stack.Push(title);
		Test.Assert(title.IsEntering);
		Test.Assert(bed.Focused == "play"); // it takes the focus at once, entrance or not
		bed.Frame(0.0);
		Test.Assert(Near(title.Alpha, 0.0f));
		bed.Frame(0.0);
		bed.Frame(0.2);
		Test.Assert(Near(title.Alpha, 0.5f));
		Test.Assert(log.Heard.Count == 1);
		bed.Frame(0.2);
		Test.Assert(Near(title.Alpha, 1.0f));
		Test.Assert(log.Heard.Count == 2);
		Test.Assert(log.Heard[1] == "screenshown");
	}

	[Test]
	public static void APopDuringAnEntranceLeavesFromWhereItIsTheScreenUnderItShowsAndTakesTheFocusAtOnce()
	{
		let bed = scope StyledBed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		bed.Stack.Push(title);
		for (int i = 0; i < 4; i++)
			bed.Frame(0.2);
		let options = bed.MakeScreen("volume");
		defer options.ReleaseRef();
		options.Covers = true;
		let log = scope Log();
		log.Watch(options, "screenshown");
		bed.Stack.Push(options);
		Test.Assert(!title.Visible);
		bed.Frame(0.0);
		bed.Frame(0.0);
		bed.Frame(0.2); // half in
		Test.Assert(Near(options.Alpha, 0.5f));
		Test.Assert(bed.Stack.Pop());
		Test.Assert(title.Visible); // shown as the cover starts leaving
		Test.Assert(bed.Focused == "play");
		bed.Frame(0.0);
		bed.Frame(0.2);
		Test.Assert(Near(options.Alpha, 0.25f)); // from 0.5, not from 1
		bed.Frame(0.2);
		Test.Assert(options.Parent == null);
		Test.Assert(log.Heard.IsEmpty);
	}

	// === Behaviour no Raptor test covers ===

	[Test]
	public static void AReplaceOnAnEmptyStackPushesAndAScreenOnAStackIsNotReplacedIn()
	{
		let bed = scope Bed();
		let a = bed.MakeScreen("a");
		defer a.ReleaseRef();
		Test.Assert(bed.Stack.Replace(a) == a);
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Replace(a) == null); // on the stack already: the top stays
		Test.Assert(bed.Stack.Top == a);
		Test.Assert(!a.IsLeaving);
		Test.Assert(bed.Stack.At(1) == null);
		Test.Assert(bed.Stack.At(-1) == null);
	}

	[Test]
	public static void AScreensBackReadsPopOrNoneAndAnyOtherWordPops()
	{
		let screen = new Screen();
		defer screen.ReleaseRef();
		Test.Assert(screen.Back == "pop");
		screen.Back = "none";
		Test.Assert(screen.Back == "none");
		Test.Assert(!screen.PopsOnBack);
		screen.Back = "anything";
		Test.Assert(screen.Back == "pop");
		Test.Assert(screen.PopsOnBack);
	}

	[Test]
	public static void AScreenLeavingPushedAgainIsWholeAgainOnTop()
	{
		let bed = scope StyledBed();
		let title = bed.MakeScreen("play");
		defer title.ReleaseRef();
		let options = bed.MakeScreen("volume");
		defer options.ReleaseRef();
		bed.Stack.Push(title);
		bed.Stack.Push(options);
		bed.Frame(0.0);
		Test.Assert(bed.Stack.Pop());
		Test.Assert(options.IsLeaving);
		Test.Assert(bed.Stack.Push(options) == options); // back before its exit ended
		Test.Assert(!options.IsLeaving);
		Test.Assert(options.Parent == bed.Stack);
		Test.Assert(options.Stack == bed.Stack);
		Test.Assert(bed.Stack.Count == 2);
		Test.Assert(bed.Focused == "volume");
	}

	[Test]
	public static void AStackGoneLeavesItsScreensOnNoStack()
	{
		let screen = new Screen();
		defer screen.ReleaseRef();
		let stack = new ScreenStack();
		Test.Assert(stack.Push(screen) == screen);
		Test.Assert(screen.Stack == stack);
		stack.ReleaseRef(); // the last reference: the stack goes
		Test.Assert(screen.Stack == null);
		Test.Assert(screen.Parent == null);
	}

	[Test]
	public static void TheGamekitsElementsRegisterOnceUnderTheirTags()
	{
		RegisterGamekitElements();
		RegisterGamekitElements(); // again: nothing
		Test.Assert(ElementTypes.Find("Screens") == ScreenStack.StaticGuiType);
		Test.Assert(ElementTypes.Find("Screen") == Screen.StaticGuiType);
		Test.Assert(ElementTypes.Find("Prompt") == Prompt.StaticGuiType);
		Test.Assert(ScreenStack.StaticGuiType.FindCss("covers") == null); // a screen's, not the stack's
		Test.Assert(Screen.StaticGuiType.FindCss("covers") != null);
	}
}
