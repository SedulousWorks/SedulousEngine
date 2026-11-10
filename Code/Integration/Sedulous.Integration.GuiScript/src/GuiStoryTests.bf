using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Integration.GuiScript;

/// The GUI script stories, in AngelScript, that the script surface's own tests do not tell: a
/// sheet styles what a script classed and the
/// script reads the styled value; the weak-handle rule's middle (a destroy inside a click handler
/// completes after it, a gone handle refuses writes and calls as it refuses reads, and a reused slot
/// does not answer to the old handle); a handler reads a press and takes it; a handler takes a
/// node's gestures; a script's source and targets drag and drop; a script makes a node leave and
/// hears its transition end; and a script turns its listeners off, from inside one too. The rest of
/// the stories run in Sedulous.GUI.ScriptSurface.Tests and Sedulous.GUI.Gamekit.ScriptSurface.Tests.
static class GuiStoryTests
{
	/// `styles` styling by `css`.
	private static void UseSheet(StyleManager styles, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
	}

	// The building story, the parts AScriptBuildsListensNarrowsAndIsToldAGoneNodeIsGone leaves:
	// under the root a Panel holding a Label "title" (text "Hunt"), a Button "go" (80 x 30 at the
	// origin, class "primary"), and a Button "bye" at (100, 0) whose click handler destroys it and
	// records whether it was still valid inside the handler.
	private const String cHandles = """
		Button@ go;
		Button@ bye;
		Node@ temp;
		Node@ another;
		int byeInHandler = -1;
		bool onBye(GuiEvent@ e) { bye.Destroy(); byeInHandler = bye.IsValid ? 1 : 0; return false; }
		void main()
		{
			Node@ root = Gui.Root();
			Node@ panel = root.Add("Panel");
			Label@ title = Label::Of(panel.Add("Label"));
			title.Text = "Hunt";
			title.Id = "title";
			@go = Button::Of(root.Add("Button"));
			go.Text = "Go";
			go.AddClass("primary");
			go.Width = 80; go.Height = 30;
			@bye = Button::Of(root.Add("Button"));
			bye.X = 100; bye.Width = 80; bye.Height = 30;
			bye.On("click", EventHandler(onBye));
		}
		bool foundTitle() { Label@ t = Label::Of(Gui.Root().Find("title")); return t !is null && t.Text == "Hunt"; }
		float goOpacity() { return go.Opacity; }
		int byeValidInHandler() { return byeInHandler; }
		bool byeValid() { return bye.IsValid; }
		string readBye() { return bye.Text; }
		void writeBye() { bye.Text = "x"; }
		void callBye() { bye.AddClass("x"); }
		void makeAndDestroyTemp() { @temp = Gui.Root().Add("Label"); temp.Destroy(); }
		void makeAnother() { @another = Gui.Root().Add("Label"); }
		bool tempValid() { return temp.IsValid; }
		bool anotherValid() { return another.IsValid; }
		""";

	[Test]
	public static void ASheetStylesWhatAScriptClassedAndAGoneHandleRefusesEveryUse()
	{
		let bed = scope GuiBed("handles", cHandles);
		bed.Call("void main()");
		let panel = bed.Root.GetChildAt(0) as Panel;
		Test.Assert(panel != null);
		let title = panel.GetChildAt(0) as Sedulous.GUI.Label;
		Test.Assert((title != null) && (title.Text == "Hunt") && (title.Id == "title"));
		let go = bed.Root.GetChildAt(1) as Button;
		Test.Assert((go != null) && (go.Text == "Go") && go.HasClass("primary"));
		Test.Assert(GuiBed.Near(go.Width, 80.0));
		Test.Assert(bed.Call("bool foundTitle()").AsBool, "found by id, narrowed by Label::Of");

		// A sheet styles what the script classed; the script reads the styled value back.
		let styles = scope StyleManager();
		UseSheet(styles, ".primary { opacity: 0.5; }");
		styles.ApplyTree(bed.Root);
		Test.Assert(GuiBed.Near(go.Alpha, 0.5), scope $"styled to {go.Alpha}");
		Test.Assert(GuiBed.Near(bed.Call("float goOpacity()").AsFloat, 0.5), "and the script reads it");

		// A destroy inside a click handler completes after it: valid in the handler and until the
		// GUI's update ends.
		bed.Root.UpdateLayout();
		bed.Click(.(110.0f, 10.0f));
		Test.Assert(bed.Call("int byeValidInHandler()").AsInt == 1, "valid in its handler");
		Test.Assert(bed.Call("bool byeValid()").AsBool, "and until the GUI's update");
		bed.Update();
		Test.Assert(!bed.Call("bool byeValid()").AsBool, "gone once it ran");
		bed.Refused("string readBye()");
		bed.Refused("void writeBye()");
		bed.Refused("void callBye()");

		// A slot freed and taken again does not answer to the old handle.
		bed.Call("void makeAndDestroyTemp()");
		bed.Update();
		bed.Call("void makeAnother()");
		Test.Assert(!bed.Call("bool tempValid()").AsBool, "the old handle is gone");
		Test.Assert(bed.Call("bool anotherValid()").AsBool, "the new one is there");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// The event story: a Button at (20, 10), 80 x 30, whose mousedown handler reads the event
	// and takes it, so the root's handler never hears it.
	private const String cEvents = """
		float x = -1;
		float localX = -1;
		int count = 0;
		int saw = 0;
		bool onDown(GuiEvent@ e) { x = e.X; localX = e.LocalX; count = e.ClickCount; return true; }
		bool onRoot(GuiEvent@ e) { saw += 1; return false; }
		void main()
		{
			Node@ root = Gui.Root();
			Node@ button = root.Add("Button");
			button.X = 20; button.Y = 10; button.Width = 80; button.Height = 30;
			button.On("mousedown", EventHandler(onDown));
			root.On("mousedown", EventHandler(onRoot));
		}
		float lastX() { return x; }
		float lastLocalX() { return localX; }
		int lastCount() { return count; }
		int rootSaw() { return saw; }
		""";

	[Test]
	public static void AHandlerReadsThePressAndTakesIt()
	{
		let bed = scope GuiBed("events", cEvents);
		bed.Call("void main()");
		bed.Root.UpdateLayout();
		let d = bed.D;
		d.InjectMouseDown(.(30.0f, 15.0f), .Left);
		d.InjectMouseUp(.(30.0f, 15.0f), .Left);
		Test.Assert(GuiBed.Near(bed.Call("float lastX()").AsFloat, 30.0), "where, in the root");
		Test.Assert(GuiBed.Near(bed.Call("float lastLocalX()").AsFloat, 10.0), "and in the button");
		Test.Assert(bed.Call("int lastCount()").AsInt == 1);
		Test.Assert(bed.Call("int rootSaw()").AsInt == 0, "taken: the root never heard it");
		d.InjectMouseDown(.(30.0f, 15.0f), .Left);
		Test.Assert(bed.Call("int lastCount()").AsInt == 2, "a second press counts two");
		d.InjectMouseUp(.(30.0f, 15.0f), .Left);
		d.InjectMouseDown(.(300.0f, 200.0f), .Left); // off the button
		Test.Assert(bed.Call("int rootSaw()").AsInt == 1, "the root hears what no handler took");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// The gesture story: a pad whose touch-action leaves pinches and turns to its
	// handlers, which take them.
	private const String cGestures = """
		float scale = 0;
		float rotation = 0;
		int startCount = 0;
		int endCount = 0;
		bool onStart(GuiEvent@ e) { startCount += 1; return true; }
		bool onChange(GuiEvent@ e) { scale = e.Scale; rotation = e.Rotation; return true; }
		bool onEnd(GuiEvent@ e) { endCount += 1; return true; }
		void main()
		{
			Node@ pad = Gui.Root().Add("Panel");
			pad.X = 50; pad.Y = 50; pad.Width = 300; pad.Height = 300;
			pad.TouchActionName = "pan-x pan-y";
			pad.On("gesturestart", EventHandler(onStart));
			pad.On("gesturechange", EventHandler(onChange));
			pad.On("gestureend", EventHandler(onEnd));
		}
		float lastScale() { return scale; }
		float lastRotation() { return rotation; }
		int started() { return startCount; }
		int ended() { return endCount; }
		""";

	[Test]
	public static void AHandlerTakesANodesGesturesDeclaredByItsTouchAction()
	{
		let bed = scope GuiBed("gestures", cGestures);
		bed.Call("void main()");
		bed.Root.UpdateLayout();
		let d = bed.D;
		// Two fingers spread from 100 apart to 200 over the pad, then turned a quarter.
		d.InjectTouchDown(1, .(150.0f, 200.0f));
		d.InjectTouchDown(2, .(250.0f, 200.0f));
		d.InjectTouchMove(1, .(100.0f, 200.0f));
		d.InjectTouchMove(2, .(300.0f, 200.0f));
		Test.Assert(GuiBed.Near(bed.Call("float lastScale()").AsFloat, 2.0), "spread to twice");
		d.InjectTouchMove(1, .(200.0f, 100.0f));
		d.InjectTouchMove(2, .(200.0f, 300.0f));
		let rotation = bed.Call("float lastRotation()").AsFloat;
		Test.Assert(GuiBed.Near(rotation, 1.5708, 0.01), scope $"turned a quarter: {rotation}");
		d.InjectTouchUp(2, .(200.0f, 300.0f));
		d.InjectTouchUp(1, .(200.0f, 100.0f));
		Test.Assert(bed.Call("int started()").AsInt == 1);
		Test.Assert(bed.Call("int ended()").AsInt == 1);
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// The drag and drop story: a swatch that drags "red" as a "color", a canvas that takes the
	// type by its drop-types, and an easel whose dragquery handler takes it.
	private const String cDrag = """
		int dropped = 0;
		int right = 0;
		int asked = 0;
		int ended = 0;
		bool onDrop(GuiEvent@ e) { dropped += 1; if (e.DragType == "color" && e.Text == "red" && e.Effect == "move") right += 1; return true; }
		bool onQuery(GuiEvent@ e) { asked += 1; return e.DragType == "color"; }
		bool onEnd(GuiEvent@ e) { if (e.Effect == "move") ended += 1; return false; }
		void main()
		{
			Node@ root = Gui.Root();
			UIWidget@ swatch = UIWidget::Of(root.Add("Panel"));
			swatch.X = 10; swatch.Y = 10; swatch.Width = 60; swatch.Height = 30;
			swatch.DragType = "color"; swatch.DragValue = "red";
			swatch.On("dragend", EventHandler(onEnd));
			Node@ canvas = root.Add("Panel");
			canvas.X = 200; canvas.Y = 10; canvas.Width = 100; canvas.Height = 100;
			canvas.DropTypes = "color";
			canvas.On("drop", EventHandler(onDrop));
			Node@ easel = root.Add("Panel");
			easel.X = 200; easel.Y = 150; easel.Width = 100; easel.Height = 100;
			easel.On("dragquery", EventHandler(onQuery));
			easel.On("drop", EventHandler(onDrop));
		}
		int droppedCount() { return dropped; }
		int rightCount() { return right; }
		int askedCount() { return asked; }
		int endedCount() { return ended; }
		""";

	/// A drag from the swatch to `to`, released there.
	private static void DragTo(EventDispatcher d, Float2 to)
	{
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.InjectMouseMove(.(40.0f, 20.0f));
		d.InjectMouseMove(to);
		d.InjectMouseUp(to, .Left);
	}

	[Test]
	public static void AScriptsSourceAndTargetsDragAndDropADragQueryHandlerTakingADrop()
	{
		let bed = scope GuiBed("drag", cDrag);
		bed.Call("void main()");
		bed.Root.UpdateLayout();
		DragTo(bed.D, .(250.0f, 50.0f)); // onto the canvas (drop-types)
		Test.Assert(bed.Call("int droppedCount()").AsInt == 1, "dropped on the canvas");
		Test.Assert(bed.Call("int rightCount()").AsInt == 1, "its type, value and effect read");
		Test.Assert(bed.Call("int endedCount()").AsInt == 1, "the source heard it end, moved");
		DragTo(bed.D, .(250.0f, 200.0f)); // onto the easel, which a dragquery handler takes
		Test.Assert(bed.Call("int askedCount()").AsInt >= 1, "the easel was asked");
		Test.Assert(bed.Call("int droppedCount()").AsInt == 2, "and took it");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// The leaving story: a Button of class "card" under the root, listening for
	// `transitionend`; goAway() makes it leave, leaving() reads whether it is.
	private const String cLeaving = """
		bool heard = false;
		float elapsed = 0;
		Button@ card;
		bool onEnd(GuiEvent@ e) { if (e.Text == "opacity") { heard = true; elapsed = e.Elapsed; } return false; }
		void main()
		{
			@card = Button::Of(Gui.Root().Add("Button"));
			card.AddClass("card");
			card.On("transitionend", EventHandler(onEnd));
		}
		void goAway() { card.Leave(); }
		bool leaving() { return card.IsLeaving; }
		bool heardOpacity() { return heard; }
		float heardElapsed() { return elapsed; }
		""";

	[Test]
	public static void AScriptMakesANodeLeaveAndHearsItsTransitionEnd()
	{
		let bed = scope GuiBed("leaving", cLeaving);
		bed.Call("void main()");
		Test.Assert(bed.Root.ChildCount == 1);
		let styles = scope StyleManager();
		UseSheet(styles, ".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }");
		// A frame as a host runs one: the GUI's update, then the style pass.
		delegate void(double seconds) frame = scope [&] (seconds) =>
			{
				bed.Update(seconds);
				styles.ApplyTree(bed.Root);
			};
		frame(0.0);
		bed.Call("void goAway()");
		Test.Assert(bed.Call("bool leaving()").AsBool, "leaving");
		frame(0.0);
		frame(0.25);
		Test.Assert(bed.Root.ChildCount == 1, "still there while its exit plays");
		Test.Assert(!bed.Call("bool heardOpacity()").AsBool);
		frame(0.25);
		Test.Assert(bed.Call("bool heardOpacity()").AsBool, "the opacity's transition ended");
		Test.Assert(GuiBed.Near(bed.Call("float heardElapsed()").AsFloat, 0.5), "after its half second");
		Test.Assert(bed.Root.ChildCount == 0, "and then it went");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// The listener tokens: a Button 80 x 30 at the origin listening for clicks twice:
	// `once` stops itself from inside, `always` stays until stopAlways() turns it off.
	private const String cOff = """
		int onces = 0;
		int alwayses = 0;
		int onceToken = 0;
		int alwaysToken = 0;
		bool once(GuiEvent@ e) { onces++; Gui.Root().ChildAt(0).Off(onceToken); return false; }
		bool always(GuiEvent@ e) { alwayses++; return false; }
		void main()
		{
			Node@ button = Gui.Root().Add("Button");
			button.Width = 80; button.Height = 30;
			onceToken = button.On("click", EventHandler(once));
			alwaysToken = button.On("click", EventHandler(always));
		}
		int onceCount() { return onces; }
		int alwaysCount() { return alwayses; }
		bool stopAlways() { return Gui.Root().ChildAt(0).Off(alwaysToken); }
		""";

	[Test]
	public static void AScriptTurnsListenersOffFromInsideOneToo()
	{
		let bed = scope GuiBed("off", cOff);
		bed.Call("void main()");
		bed.Root.UpdateLayout();
		bed.Click(.(10.0f, 10.0f));
		Test.Assert(bed.Call("int onceCount()").AsInt == 1);
		Test.Assert(bed.Call("int alwaysCount()").AsInt == 1);
		bed.Click(.(10.0f, 10.0f));
		Test.Assert(bed.Call("int onceCount()").AsInt == 1, "it stopped itself");
		Test.Assert(bed.Call("int alwaysCount()").AsInt == 2);
		Test.Assert(bed.Call("bool stopAlways()").AsBool, "Off said it was there");
		bed.Click(.(10.0f, 10.0f));
		Test.Assert(bed.Call("int alwaysCount()").AsInt == 2);
		Test.Assert(!bed.Call("bool stopAlways()").AsBool, "and now it is not");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}
}
