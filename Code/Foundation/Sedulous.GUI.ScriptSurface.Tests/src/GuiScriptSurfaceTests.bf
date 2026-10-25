using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.GUI;

namespace Sedulous.GUI.ScriptSurface.Tests;

/// The GUI's script surface: the node, the widget base, what a handler is given and the tweens,
/// every property the GUI reflects on them, nothing blocked, bound by AngelScript without a word;
/// and Raptor's script stories, in their AngelScript halves, over a root handed in as an argument:
/// a script builds and styles a widget, listens and is called, narrows a handle, and is told a gone
/// node is gone, a handle outliving its GUI included; a script tweens, springs and plays a
/// sequence, and a tween it keeps past its GUI is harmless.
static class GuiScriptSurfaceTests
{
	private static void Dump(AngelScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}

	/// A root of a GUI of its own, 400 by 300, held by the caller.
	private static SceneRoot NewScene()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(400.0f, 300.0f);
		return root;
	}

	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == GuiScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked: the GUI's Node, SceneRoot, UINode
		// and UIWidget (weakly held, each a seed), GuiEvent (counted, with a marked constructor),
		// and the tweens, counted: Tween and TweenGroup (what Node's tween verbs give and take)
		// and TweenSequence and TweenParallel (each a seed by its marked constructor). Then Core's
		// static block and the fifteen of its types the block's free functions name: AABB,
		// BoundingFrustum, BoundingSphere, Color, Color32, ContainmentType, Float2, Float3,
		// Float3x3, Float4, Float4x4, Plane, PlaneIntersectionType, Quaternion and Ray. The tweens'
		// verbs name no Core type of their own (text, numbers, a script function). Core's other
		// marked types (Transform, Rectangle, the IO and log enums) nothing here reaches, nor
		// Action, the tweens' unmarked base.
		Test.Assert(GuiScriptSurface.TypeCount == 25, scope $"the GUI surface has {GuiScriptSurface.TypeCount} types");
		Test.Assert(s.Find("Sedulous.GUI.Node").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.SceneRoot").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UINode").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UIWidget").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UIWidget").WeakRootTypeName == "Sedulous.GUI.Node");
		Test.Assert(s.Find("Sedulous.GUI.GuiEvent").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.Tween").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.TweenGroup").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.TweenSequence").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.TweenParallel").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.Action") == null, "the tweens' base is not a script's");
		Test.Assert(s.Find("Sedulous.GUI.Button") == null, "the widget families come later");
	}

	/// Every property the GUI reflects on the marked types is a script's to read, and to write
	/// where the GUI writes it, under its own name.
	[Test]
	public static void EveryReflectedPropertyIsOnTheSurface()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		CheckProperties(s, "Sedulous.GUI.Node", Node.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.UINode", UINode.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.UIWidget", UIWidget.StaticGuiType);
		// The tables chain as the types do, so the walk above covers each one's bases.
		Test.Assert(UIWidget.StaticGuiType.Base == UINode.StaticGuiType);
		Test.Assert(UINode.StaticGuiType.Base == Node.StaticGuiType);
		Test.Assert(Node.StaticGuiType.Base == null);
		Test.Assert(!UIWidget.StaticGuiType.OwnProperties.IsEmpty && !Node.StaticGuiType.OwnProperties.IsEmpty);
	}

	private static void CheckProperties(ScriptSurface s, StringView typeName, GuiTypeInfo info)
	{
		let t = s.Find(typeName);
		Test.Assert(t != null, scope $"{typeName} is on the surface");
		for (let property in info.OwnProperties)
		{
			ScriptFieldInfo found = null;
			for (let f in t.Fields)
			{
				if (f.Name == property.Name)
					found = f;
			}
			Test.Assert(found != null, scope $"{typeName}.{property.Name} is on the surface");
			Test.Assert(found.Get != null, scope $"{typeName}.{property.Name} reads");
			Test.Assert(found.CanWrite == property.CanWrite, scope $"{typeName}.{property.Name} writes as the GUI does");
		}
	}

	[Test]
	public static void TheSurfaceBlocksNothing()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = scope Sedulous.Script.Null.NullScriptRuntime();
		vm.Bind(s);
		let text = scope String();
		vm.Describe(text);
		Test.Assert(text.Contains("0 blocked"), "the GUI surface blocks nothing");
		Test.Assert(text.Contains("class Node [Weak]"), "the node, held weakly");
		Test.Assert(text.Contains("class GuiEvent [Counted]"), "the event, counted");
		Test.Assert(text.Contains("class Tween [Counted]"), "the tween, counted");
	}

	[Test]
	public static void AngelScriptBindsItWithNothingToSay()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		Dump(vm);
		Test.Assert(vm.Problems.IsEmpty, "bound, with nothing to say");
		// The shapes the node's verbs take are funcdefs a script names without declaring them.
		let ok = vm.Compile("shapes", "shapes.as", """
			bool onEvent(GuiEvent@ e) { return e.Type == "click"; }
			bool onCommand() { return false; }
			string text() { return "x"; }
			double number() { return 1; }
			bool flag() { return true; }
			void wire(Node@ n)
			{
				n.On("click", EventHandler(onEvent));
				n.OnCommand("save", CommandHandler(onCommand));
				n.Bind("id", TextExpression(text));
				n.BindNumber("opacity", NumberExpression(number));
				n.BindBool("visible", BoolExpression(flag));
			}
			GuiEvent@ make() { GuiEvent@ e = GuiEvent(); e.Index = 3; return e; }
			void tick() { }
			bool motion(Node@ n)
			{
				// Node's `Tween` is a method beside the type of the name.
				Tween@ t = n.Tween("x", "10", 1.0f).From("0").Delay(0.5f).Repeats(2).PingPong().Ease("linear")
					.Whole().Spring(170.0f, 26.0f, 1.0f).OnFinished(ScriptCallback(tick));
				t.Retarget("20");
				t.Cancel();
				TweenParallel@ together = TweenParallel();
				together.Add(n.CreateTween("y", "5", 1.0f, "ease-in")).AddGroup(TweenSequence().Wait(1.0f))
					.Call(ScriptCallback(tick)).Repeats(1).OnFinished(ScriptCallback(tick));
				n.Play(together);
				n.SpringTo("x", "0");
				return n.StopAnimation("x") && t.IsDone && !together.IsDone;
			}
			""");
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");
	}

	private const String cStory = """
		int clicks = 0;
		string clickedType;
		float clickedX = -1;
		Node@ kept;
		bool onClick(GuiEvent@ e) { clicks += 1; clickedType = e.Type; clickedX = e.LocalX; return true; }
		void build(Node@ root)
		{
			Node@ go = root.Add("Button");
			UIWidget@ widget = UIWidget::Of(go);
			widget.Id = "go";
			widget.AddClass("primary");
			go.Width = 80; go.Height = 30;
			go.On("click", EventHandler(onClick));
			@kept = go;
		}
		int clickCount() { return clicks; }
		bool clickedAt() { return clickedType == "click" && clickedX == 10; }
		bool narrowed(Node@ root) { return UIWidget::Of(root) is null && UIWidget::Of(root.ChildAt(0)) !is null && root.ChildCount == 1; }
		bool found(Node@ root) { return root.Find("go") == kept && kept.Parent() == root; }
		bool keptValid() { return kept.IsValid; }
		float keptWidth() { return kept.Width; }
		void keepAnother(Node@ root) { @kept = root.Add("Label"); }
		""";

	[Test]
	public static void AScriptBuildsListensNarrowsAndIsToldAGoneNodeIsGone()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("story", "story.as", cStory);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		var root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("story", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);

		// What the script built: a button under the root, its id, class and size as set.
		Test.Assert(root.ChildCount == 1);
		let go = root.GetChildAt(0) as Button;
		Test.Assert(go != null);
		Test.Assert(go.Id == "go");
		Test.Assert(go.HasClass("primary"));
		Test.Assert(Math.Abs(go.Width - 80.0f) < 1e-4f);
		Test.Assert(vm.Call("story", "bool narrowed(Node@)", rootArg, ref r) && r.AsBool, "narrowed: the root is no widget, its child is");
		Test.Assert(vm.Call("story", "bool found(Node@)", rootArg, ref r) && r.AsBool, "found by id, its parent the root");

		// A click through the dispatcher reaches the script's handler, which reads the event.
		root.UpdateLayout();
		root.EventDispatcher.InjectMouseDown(.(10.0f, 10.0f), .Left);
		root.EventDispatcher.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(vm.Call("story", "int clickCount()", default, ref r) && (r.AsInt == 1), scope $"{r.AsInt} clicks");
		Test.Assert(vm.Call("story", "bool clickedAt()", default, ref r) && r.AsBool, "the handler read the event, from the node it is on");
		Test.Assert(vm.Call("story", "float keptWidth()", default, ref r) && (Math.Abs(r.AsFloat - 80.0) < 1e-4));

		// The node goes: its handle is not valid, and any other use is the gone-object error.
		go.RemoveFromParent(); // the tree's was its last hold
		Test.Assert(vm.Call("story", "bool keptValid()", default, ref r) && !r.AsBool, "gone: not valid");
		Test.Assert(vm.Problems.IsEmpty, "and that is no error");
		Test.Assert(!vm.Call("story", "float keptWidth()", default, ref r), "gone: the read fails");
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains(ScriptErrors.ObjectGone), "saying the object is gone");
		ClearAndDeleteItems!(vm.Problems);

		// A handle outliving its GUI reads as gone, never as freed memory.
		Test.Assert(vm.Call("story", "void keepAnother(Node@)", rootArg, ref r));
		Test.Assert(vm.Call("story", "bool keptValid()", default, ref r) && r.AsBool, "the label is there");
		root.ReleaseRef();
		root = null;
		Test.Assert(vm.Call("story", "bool keptValid()", default, ref r) && !r.AsBool, "its GUI gone: not valid");
		Test.Assert(!vm.Call("story", "float keptWidth()", default, ref r), "and the read fails");
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains(ScriptErrors.ObjectGone), "saying the object is gone");
		ClearAndDeleteItems!(vm.Problems);
		vm.DiscardModule("story");
	}

	/// Runs the GUI's clock `seconds` on.
	private static void Advance(SceneRoot root, double seconds)
	{
		root.Context.Update(TimeSpan((int64)(seconds * (double)TimeSpan.TicksPerSecond)));
	}

	// Raptor's motion story (E14): a Label "box" first under the root, its x tweened to 100 over
	// a second (a callback at the end) and kept; a sequence that moves its y to 50 over a second,
	// waits half a second and calls back; and a Slider second, its value springing to 0.4.
	private const String cMotion = """
		int finished = 0;
		void tick() { finished += 1; }
		Tween@ kept;
		void build(Node@ root)
		{
			Node@ box = root.Add("Label");
			@kept = box.Tween("x", "100", 1.0f, "linear").OnFinished(ScriptCallback(tick));
			box.Play(TweenSequence().Add(box.CreateTween("y", "50", 1.0f, "linear")).Wait(0.5f).Call(ScriptCallback(tick)));
			Node@ slider = root.Add("Slider");
			slider.SpringTo("value", "0.4", 400.0f, 40.0f, 1.0f);
		}
		int finishedCount() { return finished; }
		bool keptDone() { return kept.IsDone; }
		""";

	[Test]
	public static void AScriptTweensSpringsAndPlaysASequence()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("motion", "motion.as", cMotion);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("motion", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);
		Test.Assert(root.ChildCount == 2);
		let moving = root.GetChildAt(0);
		let slider = root.GetChildAt(1) as Slider;
		Test.Assert((moving is Sedulous.GUI.Label) && (slider != null));

		// Who holds what, the references the calls handed over let go: the kept tween, the manager
		// and the script's handle; the sequence and the spring, the manager alone; the sequence's
		// running step, the sequence alone.
		int seen = 0;
		root.ActionManager.ForEachAction(scope [&] (action) =>
			{
				if (let tween = action as Tween)
				{
					if (tween.Property == "x")
					{
						Test.Assert(tween.RefCount == 2, scope $"the kept tween has {tween.RefCount} references");
						seen++;
					}
					else if (tween.Property == "value")
					{
						Test.Assert(tween.RefCount == 1, scope $"the spring has {tween.RefCount} references");
						seen++;
					}
				}
				else if (let sequence = action as TweenSequence)
				{
					Test.Assert(sequence.RefCount == 1, scope $"the sequence has {sequence.RefCount} references");
					sequence.ForEachRunning(scope [&] (step) =>
						{
							Test.Assert(step.RefCount == 1, scope $"the sequence's step has {step.RefCount} references");
							seen++;
						});
					seen++;
				}
			});
		Test.Assert(seen == 4, scope $"{seen} of the four seen");

		Advance(root, 0.5);
		Test.Assert(Math.Abs(moving.X - 50.0f) < 1e-3f, scope $"x {moving.X}");
		Test.Assert(Math.Abs(moving.Y - 25.0f) < 1e-3f, scope $"y {moving.Y}");
		Test.Assert(vm.Call("motion", "bool keptDone()", default, ref r) && !r.AsBool, "the kept tween runs");
		Advance(root, 0.5);
		Test.Assert(Math.Abs(moving.X - 100.0f) < 1e-3f);
		Test.Assert(Math.Abs(moving.Y - 50.0f) < 1e-3f);
		Test.Assert(vm.Call("motion", "int finishedCount()", default, ref r) && (r.AsInt == 1), scope $"{r.AsInt} finished: the tween's");
		// The manager let go of it at its end: the script's handle keeps it, to read.
		Test.Assert(vm.Call("motion", "bool keptDone()", default, ref r) && r.AsBool, "the kept tween is done");
		Advance(root, 0.5);
		Test.Assert(vm.Call("motion", "int finishedCount()", default, ref r) && (r.AsInt == 2), scope $"{r.AsInt} finished: and the sequence's call");
		for (int i = 0; i < 300; i++)
			Advance(root, 1.0 / 60.0);
		Test.Assert(Math.Abs(slider.Value - 0.4) < 0.004, scope $"the spring at {slider.Value}");
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("motion");
	}

	private const String cShortTween = """
		Tween@ held;
		void hold(Node@ root) { @held = root.Add("Label").Tween("x", "10", 1.0f); }
		""";

	/// The tween verb without an easing hands over its reference too: a running tween a script keeps
	/// has the manager's and the script's, no more.
	[Test]
	public static void TheShortTweenVerbHandsOverItsReferenceToo()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		Test.Assert(vm.Compile("short", "short.as", cShortTween) && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("short", "void hold(Node@)", rootArg, ref r), "held");
		int seen = 0;
		root.ActionManager.ForEachAction(scope [&] (action) =>
			{
				if (let tween = action as Tween)
				{
					Test.Assert(tween.RefCount == 2, scope $"the held tween has {tween.RefCount} references");
					seen++;
				}
			});
		Test.Assert(seen == 1);

		root.ReleaseRef();
		vm.DiscardModule("short");
	}

	private const String cKept = """
		Tween@ kept;
		void keep(Node@ root) { @kept = root.Add("Label").Tween("opacity", "0", 1.0f, "linear"); }
		bool keptDone() { return kept.IsDone; }
		bool outlive() { kept.Retarget("1"); kept.Cancel(); return kept.IsDone; }
		""";

	/// A tween a script keeps past its GUI finds no target: Retarget and Cancel touch no freed
	/// table (the tween keeps a reference on its target's), and it reads as done.
	[Test]
	public static void ATweenAScriptKeepsPastItsGUIIsHarmless()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("kept", "kept.as", cKept);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		var root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("kept", "void keep(Node@)", rootArg, ref r), "kept");
		Advance(root, 0.25);
		Test.Assert(vm.Call("kept", "bool keptDone()", default, ref r) && !r.AsBool, "it runs");

		// The GUI goes, its manager's reference with it; the script's keeps the tween.
		root.ReleaseRef();
		root = null;
		Test.Assert(vm.Call("kept", "bool outlive()", default, ref r) && r.AsBool, "retargeted, cancelled, done");
		Dump(vm);
		Test.Assert(vm.Problems.IsEmpty, "and that is no error");
		vm.DiscardModule("kept");
	}
}
