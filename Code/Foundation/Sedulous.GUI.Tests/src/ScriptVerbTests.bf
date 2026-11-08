using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A script function as a test fakes one: it counts its calls, answers `Result` (or what `Body`
/// makes of it), and may be dead. `Live` counts the ones not yet deleted, so a test sees the GUI
/// let go of what it was handed.
class FakeScriptDelegate : ScriptDelegate
{
	public static int Live = 0;

	public bool Alive = true;
	public int Calls = 0;
	public ScriptValue Result = .Nil;
	/// Run on each call, with the arguments and the result so far. Owned.
	public delegate void(Span<ScriptValue> args, ref ScriptValue result) Body ~ delete _;

	public this()
	{
		Live++;
	}

	public this(ScriptValue result) : this()
	{
		Result = result;
	}

	public ~this()
	{
		Live--;
	}

	public override bool IsAlive => Alive;

	public override bool Invoke(Span<ScriptValue> args, ref ScriptValue result)
	{
		if (!Alive)
			return false;
		Calls++;
		result = Result;
		if (Body != null)
			Body(args, ref result);
		return true;
	}
}

/// The node verbs a script calls with its functions: On hands a handler the event's data and a
/// true answer takes the event; a name the core does not know listens for a named event; Off works
/// from inside a handler; OnCommand's answer lets a command go on up; Bind follows what its
/// expression read; the GUI deletes what it was handed with the listener or the node; a dead
/// function is never called.
class ScriptVerbTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void OnHandsTheHandlerTheEventsDataAndATrueAnswerTakesIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let pad = SceneFixtures.NewWidget(root, 20.0f, 10.0f, 80.0f, 30.0f, "pad");
		defer pad.ReleaseRef();

		let handler = new FakeScriptDelegate(.FromBool(true));
		float x = -1.0f, localX = -1.0f, localY = -1.0f;
		int32 clickCount = 0, button = -1;
		let type = scope String();
		let phase = scope String();
		let id = scope String();
		let pointer = scope String();
		handler.Body = new [&] (args, result) =>
			{
				Test.Assert(args.Length == 1);
				let e = args[0].AsCounted as GuiEvent;
				Test.Assert(e != null);
				x = e.X;
				localX = e.LocalX;
				localY = e.LocalY;
				clickCount = e.ClickCount;
				button = e.Button;
				type.Set(e.Type);
				phase.Set(e.Phase);
				id.Set(e.Id);
				pointer.Set(e.Pointer);
			};
		let token = pad.On("mousedown", handler);
		Test.Assert(token > 0);

		let down = scope MouseEvent(.MouseDown, pad, .(30.0f, 15.0f), .Right);
		down.ClickCount = 2;
		pad.SendEvent(down);
		Test.Assert(handler.Calls == 1);
		Test.Assert(down.Handled); // the handler answered true
		Test.Assert(Near(x, 30.0f)); // from the root
		Test.Assert(Near(localX, 10.0f) && Near(localY, 5.0f)); // from the node it is on
		Test.Assert(clickCount == 2);
		Test.Assert(button == 1);
		Test.Assert(type == "mousedown");
		Test.Assert(phase == "target");
		Test.Assert(id == "pad");
		Test.Assert(pointer == "mouse");

		// Answering false leaves the event to go on.
		handler.Result = .FromBool(false);
		let again = scope MouseEvent(.MouseDown, pad, .(30.0f, 15.0f));
		pad.SendEvent(again);
		Test.Assert(handler.Calls == 2);
		Test.Assert(!again.Handled);

		// No handler, or no name: nothing listens, and what it was handed is let go.
		let live = FakeScriptDelegate.Live;
		Test.Assert(pad.On("", new FakeScriptDelegate()) == 0);
		Test.Assert(pad.On("click", (ScriptDelegate)null) == 0);
		Test.Assert(FakeScriptDelegate.Live == live);
	}

	[Test]
	public static void ANameTheCoreDoesNotKnowListensForThatNamedEventOnly()
	{
		let node = new UIWidget();
		defer node.ReleaseRef();
		let handler = new FakeScriptDelegate();
		let type = scope String();
		let text = scope String();
		handler.Body = new [&] (args, result) =>
			{
				let e = args[0].AsCounted as GuiEvent;
				type.Set(e.Type);
				text.Set(e.Text);
			};
		Test.Assert(node.On("screenenter", handler) > 0);

		node.SendNamedEvent("screenleave", "menu");
		Test.Assert(handler.Calls == 0); // another name
		node.SendNamedEvent("screenenter", "title");
		Test.Assert(handler.Calls == 1);
		Test.Assert(type == "screenenter");
		Test.Assert(text == "title"); // the detail
	}

	[Test]
	public static void OffWorksFromInsideTheHandlerItStops()
	{
		let node = new UIWidget();
		defer node.ReleaseRef();
		let live = FakeScriptDelegate.Live;
		int32 onceToken = 0;
		let once = new FakeScriptDelegate();
		once.Body = new [&] (args, result) => { Test.Assert(node.Off(onceToken)); };
		let always = new FakeScriptDelegate();
		onceToken = node.On("click", once);
		let alwaysToken = node.On("click", always);

		node.SendEvent(scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f)));
		Test.Assert(always.Calls == 1);
		// It stopped itself, and went (its function with it) once the listeners returned.
		Test.Assert(FakeScriptDelegate.Live == live + 1);
		node.SendEvent(scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f)));
		Test.Assert(always.Calls == 2);
		Test.Assert(!node.Off(onceToken)); // gone already

		Test.Assert(node.Off(alwaysToken));
		Test.Assert(FakeScriptDelegate.Live == live);
		Test.Assert(!node.Off(alwaysToken));
		Test.Assert(!node.Off(0));
	}

	[Test]
	public static void OnCommandsAnswerLetsTheCommandGoOnUpTheFocusPath()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let field = new Button();
		defer field.ReleaseRef();
		field.TabFocusable = true;
		root.AddChild(field);
		root.EventDispatcher.FocusNode = field;

		let fieldOpen = new FakeScriptDelegate(.FromBool(true)); // goes on up
		let rootOpen = new FakeScriptDelegate(.FromBool(false));
		Test.Assert(field.OnCommandScript("open", fieldOpen) > 0);
		Test.Assert(root.OnCommandScript("open", rootOpen) > 0);
		Test.Assert(root.RunCommand("open"));
		Test.Assert((fieldOpen.Calls == 1) && (rootOpen.Calls == 1));

		let fieldSave = new FakeScriptDelegate(.FromBool(false)); // stops it
		let rootSave = new FakeScriptDelegate(.FromBool(false));
		let token = field.OnCommandScript("save", fieldSave);
		root.OnCommandScript("save", rootSave);
		Test.Assert(root.RunCommand("save"));
		Test.Assert((fieldSave.Calls == 1) && (rootSave.Calls == 0));

		// Off takes a command's token as it takes a listener's (the field's function goes with it).
		Test.Assert(field.Off(token));
		Test.Assert(root.RunCommand("save"));
		Test.Assert(rootSave.Calls == 1);
		Test.Assert(field.OnCommandScript("none", null) == 0);
	}

	[Test]
	public static void BindRunsTheExpressionAgainWhenWhatItReadChanged()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		root.AddChild(label);
		let data = root.Context.Data;
		data.Set("score", System.Variant.Create((int32)3));

		let text = scope String();
		let expression = new FakeScriptDelegate();
		expression.Body = new [&] (args, result) =>
			{
				var score = data.Get("score"); // a read the binding follows
				defer score.Dispose();
				text.Set("Score: ");
				FormatVariant(score, text);
				result = .FromString(text);
			};
		Test.Assert(label.BindScript("text", expression));
		Test.Assert(label.Text == "Score: 3"); // bound at once
		Test.Assert(expression.Calls == 1);

		data.Set("score", System.Variant.Create((int32)4));
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(label.Text == "Score: 4");
		Test.Assert(expression.Calls == 2);

		// A number and a boolean, converted to the property's type.
		Test.Assert(label.BindNumberScript("opacity", new FakeScriptDelegate(.FromFloat(0.25))));
		Test.Assert(Near(label.Opacity, 0.25f));
		Test.Assert(label.BindBoolScript("visible", new FakeScriptDelegate(.FromBool(false))));
		Test.Assert(!label.Visible);

		// No such property: nothing binds, and the function is let go.
		let live = FakeScriptDelegate.Live;
		Test.Assert(!label.BindScript("nonsense", new FakeScriptDelegate()));
		Test.Assert(!label.BindScript("text", null));
		Test.Assert(FakeScriptDelegate.Live == live);
	}

	[Test]
	public static void TheGUIDeletesWhatItWasHandedWithTheListenerOrTheNode()
	{
		let live = FakeScriptDelegate.Live;
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		var node = new UIWidget();
		root.AddChild(node);

		let token = node.On("click", new FakeScriptDelegate());
		Test.Assert(FakeScriptDelegate.Live == live + 1);
		Test.Assert(node.Off(token));
		Test.Assert(FakeScriptDelegate.Live == live); // with its listener

		node.On("click", new FakeScriptDelegate());
		node.OnCommandScript("save", new FakeScriptDelegate());
		node.BindBoolScript("visible", new FakeScriptDelegate(.FromBool(true)));
		Test.Assert(FakeScriptDelegate.Live == live + 3);
		node.RemoveFromParent();
		node.ReleaseRef(); // the last hold: the node goes
		node = null;
		Test.Assert(FakeScriptDelegate.Live == live); // with its node
	}

	[Test]
	public static void ADeadFunctionIsNeverCalled()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new UIWidget();
		defer node.ReleaseRef();
		root.AddChild(node);

		let handler = new FakeScriptDelegate(.FromBool(true));
		handler.Alive = false; // its runtime went
		node.On("click", handler);
		let click = scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f));
		node.SendEvent(click);
		Test.Assert(handler.Calls == 0);
		Test.Assert(!click.Handled);

		let command = new FakeScriptDelegate(.FromBool(true));
		command.Alive = false;
		node.OnCommandScript("save", command);
		root.EventDispatcher.FocusNode = node;
		root.RunCommand("save");
		Test.Assert(command.Calls == 0);

		let expression = new FakeScriptDelegate(.FromFloat(0.5));
		expression.Alive = false;
		Test.Assert(node.BindNumberScript("opacity", expression));
		Test.Assert(expression.Calls == 0);
		Test.Assert(Near(node.Opacity, 1.0f)); // nothing set
	}
}
