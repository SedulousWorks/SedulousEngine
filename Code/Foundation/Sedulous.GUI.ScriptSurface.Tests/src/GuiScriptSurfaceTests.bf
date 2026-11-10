using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.GUI;

namespace Sedulous.GUI.ScriptSurface.Tests;

/// The GUI's script surface: the node, the widget base, the simple widgets and the buttons, what a
/// handler is given and the tweens, every property the GUI reflects on them, nothing blocked, bound
/// by AngelScript without a word; and the script stories, in AngelScript, over a
/// root handed in as an argument: a script builds and styles a widget, listens and is called,
/// narrows a handle, and is told a gone node is gone, a handle outliving its GUI included; a script
/// narrows to each widget and sets its properties, and calls their verbs; a script opens windows,
/// menus and popups of its own, fills in a toast request and posts it and hears its action, and
/// works its tabs and a message box; a script fills a list model a list view shows, and works
/// the text, colour and item views; a script tweens, springs and plays a sequence, and a tween it
/// keeps past its GUI is harmless.
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

	/// The simple widgets and the buttons on the surface, as the walker names them.
	private static StringView[20] sWidgets = .("Sedulous.GUI.Label", "Sedulous.GUI.RichText", "Sedulous.GUI.Image",
		"Sedulous.GUI.Panel", "Sedulous.GUI.Separator", "Sedulous.GUI.Spacer", "Sedulous.GUI.Splitter",
		"Sedulous.GUI.SplitterHandle", "Sedulous.GUI.ScrollView", "Sedulous.GUI.RangeWidget", "Sedulous.GUI.Slider",
		"Sedulous.GUI.ProgressBar", "Sedulous.GUI.ScrollBar", "Sedulous.GUI.ListBox", "Sedulous.GUI.ButtonBase",
		"Sedulous.GUI.Button", "Sedulous.GUI.CheckBox", "Sedulous.GUI.RadioButton", "Sedulous.GUI.ToggleSwitch",
		"Sedulous.GUI.Expander");

	/// The menus, windows, tabs and toasts on the surface, held weakly.
	private static StringView[10] sOverlays = .("Sedulous.GUI.ToastHost", "Sedulous.GUI.Tab", "Sedulous.GUI.TabBar",
		"Sedulous.GUI.TabPage", "Sedulous.GUI.TabView", "Sedulous.GUI.Window", "Sedulous.GUI.MessageBox",
		"Sedulous.GUI.MenuItem", "Sedulous.GUI.Menu", "Sedulous.GUI.MenuBar");

	/// The text, colour and item views on the surface, held weakly.
	private static StringView[12] sViews = .("Sedulous.GUI.TextEditBase", "Sedulous.GUI.TextField",
		"Sedulous.GUI.TextArea", "Sedulous.GUI.EditableLabel", "Sedulous.GUI.NumberField", "Sedulous.GUI.ColorSwatch",
		"Sedulous.GUI.ColorPicker", "Sedulous.GUI.ItemView", "Sedulous.GUI.ListView", "Sedulous.GUI.TreeView",
		"Sedulous.GUI.TableView", "Sedulous.GUI.ComboBox");

	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == GuiScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked: the GUI's Node, SceneRoot, UINode
		// and UIWidget (weakly held, each a seed), GuiEvent (counted, with a marked constructor),
		// and the tweens, counted: Tween and TweenGroup (what Node's tween verbs give and take)
		// and TweenSequence and TweenParallel (each a seed by its marked constructor). The simple
		// widgets and the buttons, twenty, each weakly held and so a seed: Label, RichText, Image,
		// Panel, Separator, Spacer, Splitter, SplitterHandle, ScrollView, RangeWidget, Slider,
		// ProgressBar, ScrollBar, ListBox, ButtonBase, Button, CheckBox, RadioButton, ToggleSwitch
		// and Expander; their properties name text, numbers, flags and Color, so no Core type of
		// their own. The menus, windows, tabs and toasts, ten weakly held: ToastHost, Tab, TabBar,
		// TabPage, TabView, Window, MessageBox, MenuItem, Menu and MenuBar; and the toast's two
		// a script fills in, ToastRequest (counted, with a marked constructor) and ToastSeverity.
		// The text, colour and item views, twelve weakly held: TextEditBase, TextField,
		// TextArea, EditableLabel, NumberField, ColorSwatch, ColorPicker, ItemView, ListView,
		// TreeView, TableView and ComboBox; and ListModel, counted, with a marked constructor.
		// GuiFacade, the `Gui` service a host sets.
		// Then Core's static block and the fifteen of its types the block's free
		// functions name: AABB, BoundingFrustum, BoundingSphere, Color, Color32, ContainmentType,
		// Float2, Float3, Float3x3, Float4, Float4x4, Plane, PlaneIntersectionType, Quaternion and
		// Ray. The tweens' verbs name no Core type of their own (text, numbers, a script
		// function). Core's other marked types (Transform, Rectangle, the IO and log enums)
		// nothing here reaches, nor Action, the tweens' unmarked base.
		Test.Assert(GuiScriptSurface.TypeCount == 71, scope $"the GUI surface has {GuiScriptSurface.TypeCount} types");
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
		for (let widget in sWidgets)
		{
			let t = s.Find(widget);
			Test.Assert((t != null) && (t.Role == .Weak) && (t.WeakRootTypeName == "Sedulous.GUI.Node"), scope $"{widget}, held weakly");
		}
		for (let widget in sOverlays)
		{
			let t = s.Find(widget);
			Test.Assert((t != null) && (t.Role == .Weak) && (t.WeakRootTypeName == "Sedulous.GUI.Node"), scope $"{widget}, held weakly");
		}
		for (let widget in sViews)
		{
			let t = s.Find(widget);
			Test.Assert((t != null) && (t.Role == .Weak) && (t.WeakRootTypeName == "Sedulous.GUI.Node"), scope $"{widget}, held weakly");
		}
		Test.Assert(s.Find("Sedulous.GUI.ListModel").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.ToastRequest").Role == .Counted);
		Test.Assert(s.Find("Sedulous.GUI.ToastSeverity") != null);
		// Parts with no script members of their own stay off, and the rest of the
		// widget families come later.
		Test.Assert(s.Find("Sedulous.GUI.ButtonIndicator") == null);
		Test.Assert(s.Find("Sedulous.GUI.ExpanderHeader") == null);
		Test.Assert(s.Find("Sedulous.GUI.TabCloseButton") == null);
		Test.Assert(s.Find("Sedulous.GUI.TabListButton") == null);
		Test.Assert(s.Find("Sedulous.GUI.TabCloseAllButton") == null);
		Test.Assert(s.Find("Sedulous.GUI.TabStrip") == null);
		Test.Assert(s.Find("Sedulous.GUI.TabPageHost") == null);
		Test.Assert(s.Find("Sedulous.GUI.MenuSeparator") == null);
		Test.Assert(s.Find("Sedulous.GUI.ToastCard") == null, "a toast's card is the host's");
		Test.Assert(s.Find("Sedulous.GUI.SpinButton") == null);
		Test.Assert(s.Find("Sedulous.GUI.DragLayer") == null);
		Test.Assert(s.Find("Sedulous.GUI.DragPreview") == null);
		Test.Assert(s.Find("Sedulous.GUI.MarkupChildHost") == null);
		Test.Assert(s.Find("Sedulous.GUI.TreeItem") == null);
		Test.Assert(s.Find("Sedulous.GUI.TableItem") == null);
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
		CheckProperties(s, "Sedulous.GUI.Label", Sedulous.GUI.Label.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.RichText", RichText.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Image", Sedulous.GUI.Image.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Panel", Panel.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Separator", Separator.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Spacer", Spacer.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Splitter", Sedulous.GUI.Splitter.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.SplitterHandle", SplitterHandle.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ScrollView", ScrollView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.RangeWidget", RangeWidget.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Slider", Slider.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ProgressBar", ProgressBar.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ScrollBar", ScrollBar.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ListBox", ListBox.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ButtonBase", ButtonBase.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Button", Button.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.CheckBox", CheckBox.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.RadioButton", RadioButton.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ToggleSwitch", ToggleSwitch.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Expander", Expander.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ToastHost", ToastHost.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Tab", Tab.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TabBar", TabBar.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TabPage", TabPage.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TabView", TabView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Window", Sedulous.GUI.Window.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.MessageBox", MessageBox.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.MenuItem", MenuItem.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Menu", Menu.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.MenuBar", MenuBar.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TextEditBase", TextEditBase.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TextField", TextField.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TextArea", TextArea.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.EditableLabel", EditableLabel.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.NumberField", NumberField.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ColorSwatch", ColorSwatch.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ColorPicker", ColorPicker.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ItemView", ItemView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ListView", ListView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TreeView", TreeView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.TableView", TableView.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ComboBox", ComboBox.StaticGuiType);
		// The tables chain as the types do, so the walk above covers each one's bases.
		Test.Assert(UIWidget.StaticGuiType.Base == UINode.StaticGuiType);
		Test.Assert(UINode.StaticGuiType.Base == Node.StaticGuiType);
		Test.Assert(Node.StaticGuiType.Base == null);
		Test.Assert(!UIWidget.StaticGuiType.OwnProperties.IsEmpty && !Node.StaticGuiType.OwnProperties.IsEmpty);
		Test.Assert(Slider.StaticGuiType.Base == RangeWidget.StaticGuiType);
		Test.Assert(RangeWidget.StaticGuiType.Base == UIWidget.StaticGuiType);
		Test.Assert(CheckBox.StaticGuiType.Base == ButtonBase.StaticGuiType);
		Test.Assert(RichText.StaticGuiType.Base == Sedulous.GUI.Label.StaticGuiType);
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
		Test.Assert(text.Contains("class Label [Weak]") && text.Contains("class Expander [Weak]"), "the widgets, held weakly");
		Test.Assert(text.Contains("class ToastRequest [Counted]"), "the toast request, counted");
		Test.Assert(text.Contains("class ListModel [Counted]"), "the list model, counted");
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

	// The motion story: a Label "box" first under the root, its x tweened to 100 over
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

	// Each simple widget and button made by its tag, narrowed with X::Of and one of its properties
	// set and read back; the first check that fails is the answer (0: none). Each narrowing to the
	// wrong widget is null, and the bases narrow a derived widget.
	private const String cWidgets = """
		int failed = 0;
		int step = 0;
		void check(bool ok) { step += 1; if (!ok && (failed == 0)) failed = step; }
		int roundTrip(Node@ root)
		{
			Node@ labelNode = root.Add("Label");
			Label@ label = Label::Of(labelNode);
			label.Text = "hello"; check(label.Text == "hello");
			check(Slider::Of(labelNode) is null);
			RichText@ rich = RichText::Of(root.Add("RichText"));
			rich.LineClamp = 2; check(rich.LineClamp == 2 && rich.Rich);
			Image@ image = Image::Of(root.Add("Image"));
			image.FitName = "contain"; check(image.FitName == "contain");
			Panel@ panel = Panel::Of(root.Add("Panel"));
			panel.Id = "box"; check(panel.Id == "box");
			Separator@ separator = Separator::Of(root.Add("Separator"));
			separator.Thickness = 3; check(separator.Thickness == 3);
			Spacer@ spacer = Spacer::Of(root.Add("Spacer"));
			spacer.Space = 12; check(spacer.Space == 12);
			Node@ splitNode = root.Add("Splitter");
			Splitter@ splitter = Splitter::Of(splitNode);
			splitter.AxisName = "vertical"; check(splitter.AxisName == "vertical");
			splitNode.Add("Panel");
			splitNode.Add("Panel");
			SplitterHandle@ handle = SplitterHandle::Of(splitNode.ChildAt(1));
			check(handle !is null && SplitterHandle::Of(splitNode.ChildAt(0)) is null);
			handle.Thickness = 4; check(handle.Thickness == 4 && handle.Max == 100);
			ScrollView@ scroll = ScrollView::Of(root.Add("ScrollView"));
			scroll.StickToEnd = true; check(scroll.StickToEnd);
			RangeWidget@ range = RangeWidget::Of(root.Add("ProgressBar"));
			range.Max = 10; check(range.Max == 10);
			Slider@ slider = Slider::Of(root.Add("Slider"));
			slider.Value = 0.25; check(slider.Value == 0.25);
			ProgressBar@ progress = ProgressBar::Of(root.Add("ProgressBar"));
			progress.Indeterminate = true; check(progress.Indeterminate);
			ScrollBar@ bar = ScrollBar::Of(root.Add("ScrollBar"));
			bar.OrientationName = "vertical"; check(bar.OrientationName == "vertical");
			ListBox@ list = ListBox::Of(root.Add("ListBox"));
			list.ItemsText = "one|two"; check(list.ItemsText == "one|two");
			ButtonBase@ core = ButtonBase::Of(root.Add("Button"));
			core.Text = "Go"; check(core.Text == "Go");
			Button@ button = Button::Of(root.Add("Button"));
			button.Repeat = true; check(button.Repeat);
			Node@ boxNode = root.Add("CheckBox");
			CheckBox@ checkBox = CheckBox::Of(boxNode);
			checkBox.Checked = true; check(checkBox.Checked);
			check(ButtonBase::Of(boxNode) !is null && Button::Of(boxNode) is null);
			RadioButton@ radio = RadioButton::Of(root.Add("RadioButton"));
			radio.Name = "pick"; check(radio.Name == "pick");
			ToggleSwitch@ toggle = ToggleSwitch::Of(root.Add("ToggleSwitch"));
			toggle.Checked = true; check(toggle.Checked);
			Expander@ expander = Expander::Of(root.Add("Expander"));
			expander.Title = "More"; check(expander.Title == "More");
			return failed;
		}
		""";

	[Test]
	public static void AScriptNarrowsToEachWidgetAndRoundTripsItsProperties()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("widgets", "widgets.as", cWidgets);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("widgets", "int roundTrip(Node@)", rootArg, ref r), "ran");
		Dump(vm);
		Test.Assert(r.AsInt == 0, scope $"check {r.AsInt} failed");
		Test.Assert(vm.Problems.IsEmpty);

		// What the script wrote is the widgets' own.
		let label = root.GetChildAt(0) as Sedulous.GUI.Label;
		Test.Assert((label != null) && (label.Text == "hello"));
		let image = root.GetChildAt(2) as Sedulous.GUI.Image;
		Test.Assert((image != null) && (image.Fit == .Contain));
		let splitter = root.GetChildAt(6) as Sedulous.GUI.Splitter;
		Test.Assert((splitter != null) && (splitter.Axis == .Vertical) && (splitter.PaneCount == 2));
		let slider = root.GetChildAt(9) as Slider;
		Test.Assert((slider != null) && (Math.Abs(slider.Value - 0.25) < 1e-9));
		let checkBox = root.GetChildAt(15) as CheckBox;
		Test.Assert((checkBox != null) && checkBox.Checked);

		root.ReleaseRef();
		vm.DiscardModule("widgets");
	}

	// The widget verbs: a splitter's shares given back, an expander toggled.
	private const String cVerbs = """
		Splitter@ splitter;
		Expander@ expander;
		void build(Node@ root)
		{
			Node@ split = root.Add("Splitter");
			split.Width = 300; split.Height = 100;
			split.Add("Panel");
			split.Add("Panel");
			@splitter = Splitter::Of(split);
			@expander = Expander::Of(root.Add("Expander"));
		}
		void move() { SplitterHandle::Of(splitter.ChildAt(1)).Value = 25; }
		void reset() { splitter.ResetWeights(); }
		bool toggle() { expander.Toggle(); return expander.Open; }
		""";

	[Test]
	public static void AScriptResetsASplittersSharesAndTogglesAnExpander()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("verbs", "verbs.as", cVerbs);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("verbs", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);
		let splitter = root.GetChildAt(0) as Sedulous.GUI.Splitter;
		let expander = root.GetChildAt(1) as Expander;
		Test.Assert((splitter != null) && (splitter.PaneCount == 2) && (expander != null));
		root.UpdateLayout(); // a handle moves over the sizes last laid out

		let weights = scope List<float>();
		splitter.GetWeights(weights);
		Test.Assert(Math.Abs(weights[0] - 0.5f) < 1e-4f, scope $"an even share first: {weights[0]}");
		Test.Assert(vm.Call("verbs", "void move()", default, ref r), "moved");
		weights.Clear();
		splitter.GetWeights(weights);
		Test.Assert(weights[0] < 0.4f, scope $"the handle moved the shares: {weights[0]}");
		Test.Assert(vm.Call("verbs", "void reset()", default, ref r), "reset");
		weights.Clear();
		splitter.GetWeights(weights);
		Test.Assert(Math.Abs(weights[0] - 0.5f) < 1e-4f, scope $"the shares given back: {weights[0]}");

		Test.Assert(!expander.Open);
		Test.Assert(vm.Call("verbs", "bool toggle()", default, ref r) && r.AsBool && expander.Open, "toggled open");
		Test.Assert(vm.Call("verbs", "bool toggle()", default, ref r) && !r.AsBool && !expander.Open, "and closed");
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("verbs");
	}

	// Windows, menus and popups of a script's own: under the root, a Window opened
	// in place (listened to for `close`), a Menu with one item "open" (its `activate` listened
	// to), a Button and a Panel; `openMenu` opens the menu at (20, 20), `openPanel` the panel as
	// the button's popup.
	private const String cOverlays = """
		int closes = 0;
		bool picked = false;
		bool onClose(GuiEvent@ e) { closes++; return false; }
		bool onActivate(GuiEvent@ e) { picked = e.Id == "open"; return true; }
		Node@ win;
		Node@ panel;
		Node@ menu;
		Node@ anchor;
		void build(Node@ root)
		{
			@win = root.Add("Window"); win.Width = 200; win.Height = 150;
			Window::Of(win).Title = "Settings";
			win.On("close", EventHandler(onClose));
			Window::Of(win).Open();
			@menu = root.Add("Menu");
			Node@ item = menu.Add("MenuItem");
			MenuItem::Of(item).Text = "Open";
			UIWidget::Of(item).Id = "open";
			menu.On("activate", EventHandler(onActivate));
			@anchor = root.Add("Button"); anchor.Width = 80; anchor.Height = 30;
			@panel = root.Add("Panel"); panel.Width = 100; panel.Height = 60;
		}
		void openMenu() { Menu::Of(menu).OpenAt(20, 20); }
		bool menuOpen() { return Menu::Of(menu).IsOpen; }
		bool openBelow() { return Menu::Of(menu).OpenBelow(anchor); }
		void closeMenu() { Menu::Of(menu).Close(); }
		void openPanel() { anchor.Popup(panel); }
		void closeWindow() { Window::Of(win).Close(); }
		bool windowOpen() { return Window::Of(win).IsOpen; }
		void closePanel() { panel.ClosePopup(); }
		int closeCount() { return closes; }
		bool pickedOpen() { return picked; }
		""";

	/// The first node of `type` in the subtree (depth first, `node` first), or null.
	private static Node FindIn(Node node, Type type)
	{
		if (node.GetType().IsSubtypeOf(type))
			return node;
		for (int i = 0; i < node.ChildCount; ++i)
		{
			if (let found = FindIn(node.GetChildAt(i), type))
				return found;
		}
		return null;
	}

	private static bool Run(AngelScriptRuntime vm, StringView module, StringView decl, ref ScriptValue r)
	{
		let ok = vm.Call(module, decl, default, ref r);
		Dump(vm);
		return ok;
	}

	[Test]
	public static void AScriptOpensWindowsMenusAndPopupsOfItsOwn()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("overlays", "overlays.as", cOverlays);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("overlays", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);
		root.UpdateLayout();
		let d = root.EventDispatcher;
		let window = FindIn(root, typeof(Sedulous.GUI.Window)) as Sedulous.GUI.Window;
		let menu = FindIn(root, typeof(Menu)) as Menu;
		let panel = FindIn(root, typeof(Panel)) as Panel;
		Test.Assert((window != null) && (menu != null) && (panel != null));
		Test.Assert(window.IsOpen && (window.Title == "Settings"));

		Test.Assert(Run(vm, "overlays", "void openMenu()", ref r) && menu.IsOpen, "the menu opened at a point");
		Test.Assert(Run(vm, "overlays", "bool menuOpen()", ref r) && r.AsBool, "and the script sees it open");
		root.UpdateLayout();
		let item = menu.GetChildAt(0);
		Test.Assert(item != null);
		let at = item.ConvertToWorldSpace(.(item.Size.X * 0.5f, item.Size.Y * 0.5f));
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		Test.Assert(Run(vm, "overlays", "bool pickedOpen()", ref r) && r.AsBool, "the item's activate heard");
		Test.Assert(!menu.IsOpen);
		// Closed, the script's menu went back where it waits, unseen there, and opens again.
		Test.Assert((menu.Parent != null) && !menu.Displayed);
		Test.Assert(Run(vm, "overlays", "bool openBelow()", ref r) && r.AsBool && menu.IsOpen, "opened below the button");
		Test.Assert(Run(vm, "overlays", "void closeMenu()", ref r) && !menu.IsOpen, "and closed by the script");
		Test.Assert(Run(vm, "overlays", "void openMenu()", ref r) && menu.IsOpen);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!menu.IsOpen, "Escape closes it");

		Test.Assert(Run(vm, "overlays", "void openPanel()", ref r) && d.IsPopupOpen(panel));
		Test.Assert(Run(vm, "overlays", "void closePanel()", ref r) && !d.IsPopupOpen(panel));
		Test.Assert(panel.Parent == root, "back where it stood");

		window.AddRef(); // closing takes the window off the page, its only other owner
		Test.Assert(Run(vm, "overlays", "void closeWindow()", ref r) && !window.IsOpen);
		Test.Assert(Run(vm, "overlays", "bool windowOpen()", ref r) && !r.AsBool);
		Test.Assert(Run(vm, "overlays", "int closeCount()", ref r) && (r.AsInt == 1), "close heard once");
		window.ReleaseRef();
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("overlays");
	}

	// Toasts from a script: the script finds the host the test placed, fills in a request
	// (a title, a message, success, staying, the class `pop`, an action "reveal") and posts it,
	// posts a widget's toast, and listens for `activate` on the host, keeping the pressed action's
	// id.
	private const String cToasts = """
		string pressed = "";
		bool onAction(GuiEvent@ e) { pressed = e.Id; return true; }
		void post(Node@ root)
		{
			ToastHost@ host = ToastHost::Nearest(root);
			ToastRequest@ r = ToastRequest();
			r.Title = "Exported";
			r.Message = "Town is in Dist/Town.";
			r.Severity = ToastSeverity::Success;
			r.Duration = 0;
			r.Classes = "pop";
			r.AddAction("reveal", "Reveal", "");
			host.Post(r);
			host.On("activate", EventHandler(onAction));
			Node@ label = root.Add("Label");
			ToastRequest@ w = ToastRequest();
			w.Announcement = "From a widget";
			host.PostContent(w, label);
		}
		int shown(Node@ root) { return ToastHost::Nearest(root).ShownCount; }
		// From a node away from the host: the host is found from the node's root, not its subtree.
		int shownFromDeep(Node@ root) { Node@ deep = root.Add("Panel").Add("Panel"); return ToastHost::Nearest(deep).ShownCount; }
		string pressedId() { return pressed; }
		bool dismissAll(Node@ root) { ToastHost@ host = ToastHost::Nearest(root); host.DismissAll(); return host.ShownCount == 0; }
		""";

	[Test]
	public static void AScriptFillsInAToastRequestPostsItAndHearsItsAction()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("toasts", "toasts.as", cToasts);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		let host = new ToastHost();
		root.AddChild(host);
		host.ReleaseRef(); // the root's keeps it
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("toasts", "void post(Node@)", rootArg, ref r), "posted");
		Dump(vm);
		Test.Assert(host.ShownCount == 2);
		Test.Assert(vm.Call("toasts", "int shown(Node@)", rootArg, ref r) && (r.AsInt == 2), "the script counts them");
		Test.Assert(vm.Call("toasts", "int shownFromDeep(Node@)", rootArg, ref r) && (r.AsInt == 2), "found from a node deep in the GUI");
		Dump(vm);
		let card = host.GetChildAt(0) as ToastCard;
		Test.Assert((card != null) && (card.TitlePart != null));
		Test.Assert(card.TitlePart.Text == "Exported");
		Test.Assert(card.MessagePart.Text == "Town is in Dist/Town.");
		Test.Assert(card.HasClass("success") && card.HasClass("pop"));
		Test.Assert(card.Remaining < 0.0f, "duration 0: until closed");
		Test.Assert((card.ActionCount == 1) && (card.ActionAt(0).Text == "Reveal"));
		let widget = host.GetChildAt(1) as ToastCard;
		Test.Assert((widget != null) && (widget.Content is Sedulous.GUI.Label));
		Test.Assert(widget.Announcement == "From a widget");

		card.ActionAt(0).HandleActivate();
		Test.Assert(vm.Call("toasts", "string pressedId()", default, ref r) && (r.AsString == "reveal"), "the action heard");
		Test.Assert(host.ShownCount == 1);
		Test.Assert(vm.Call("toasts", "bool dismissAll(Node@)", rootArg, ref r) && r.AsBool, "all dismissed");
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("toasts");
	}

	// A script's tabs and a message box: pages counted and removed, a bar's tabs counted, moved and
	// removed, a box shown over the GUI.
	private const String cTabs = """
		TabView@ view;
		TabBar@ bar;
		void build(Node@ root)
		{
			@view = TabView::Of(root.Add("TabView"));
			Node@ first = view.Add("TabPage");
			TabPage::Of(first).Title = "One";
			Node@ second = view.Add("TabPage");
			TabPage::Of(second).Title = "Two";
			@bar = TabBar::Of(root.Add("TabBar"));
			Tab::Of(bar.Add("Tab")).Text = "a";
			bar.Add("Tab");
		}
		int pages() { return view.PageCount; }
		void removeFirstPage() { view.RemovePage(0); }
		int tabs() { return bar.TabCount; }
		void swap() { bar.MoveTab(0, 1); }
		void removeTab() { bar.RemoveTab(0); }
		bool show(Node@ root) { MessageBox@ box = MessageBox::Of(root.Add("MessageBox")); box.Title = "Sure?"; return box.Show(); }
		""";

	[Test]
	public static void AScriptWorksItsTabsAndShowsAMessageBox()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("tabs", "tabs.as", cTabs);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("tabs", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);
		root.UpdateLayout();
		let view = root.GetChildAt(0) as TabView;
		let bar = root.GetChildAt(1) as TabBar;
		Test.Assert((view != null) && (bar != null));
		Test.Assert(Run(vm, "tabs", "int pages()", ref r) && (r.AsInt == 2) && (view.PageCount == 2), "two pages");
		Test.Assert(Run(vm, "tabs", "void removeFirstPage()", ref r) && (view.PageCount == 1));
		Test.Assert(Run(vm, "tabs", "int tabs()", ref r) && (r.AsInt == bar.TabCount));
		let tabCount = bar.TabCount;
		Test.Assert(tabCount == 2, scope $"the bar's two tabs: {tabCount}");
		let first = bar.GetTab(0);
		Test.Assert(Run(vm, "tabs", "void swap()", ref r) && (bar.GetTab(1) == first), "moved");
		Test.Assert(Run(vm, "tabs", "void removeTab()", ref r) && (bar.TabCount == 1) && (bar.GetTab(0) == first), "removed");
		Test.Assert(vm.Call("tabs", "bool show(Node@)", rootArg, ref r) && r.AsBool, "the box shown");
		Dump(vm);
		let shown = FindIn(root, typeof(MessageBox)) as MessageBox;
		Test.Assert((shown != null) && shown.IsOpen && (shown.Title == "Sure?"));
		shown.Close();
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("tabs");
	}

	// A list model from a script: the script makes a ListModel of three rows, shown by
	// a ListView it puts first under the root, and keeps it to change it.
	private const String cModel = """
		ListModel@ model;
		void build(Node@ root)
		{
			@model = ListModel();
			model.Add("one"); model.Add("two"); model.Add("three");
			ListView::Of(root.Add("ListView")).SetModel(model);
		}
		void edit() { model.Insert(1, "new"); model.Remove(model.Count - 1); model.Set(0, "alpha"); }
		bool firstIsAlpha() { return model.Get(0) == "alpha"; }
		bool secondIsNew() { return model.Get(1) == "new"; }
		bool pastTheEnd() { return model.Get(9) == ""; }
		int cleared() { model.Clear(); return model.Count; }
		void drop() { @model = null; }
		""";

	[Test]
	public static void AScriptFillsAListModelAListViewShows()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("model", "model.as", cModel);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("model", "void build(Node@)", rootArg, ref r), "built");
		Dump(vm);
		let list = root.GetChildAt(0) as ListView;
		Test.Assert((list != null) && (list.Model != null) && (list.Model.RowCount() == 3), "the view shows the script's three rows");
		Test.Assert(Run(vm, "model", "void edit()", ref r), "edited"); // insert at 1, remove the last, rename the first
		Test.Assert(list.Model.RowCount() == 3);
		Test.Assert(Run(vm, "model", "bool firstIsAlpha()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "model", "bool secondIsNew()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "model", "bool pastTheEnd()", ref r) && r.AsBool, "empty past the end");
		// The view keeps the model alive once the script lets go of it.
		Test.Assert(Run(vm, "model", "void drop()", ref r));
		Test.Assert(list.Model.RowCount() == 3, "kept by the view");
		Test.Assert(vm.Problems.IsEmpty);

		root.ReleaseRef();
		vm.DiscardModule("model");
	}

	// The text, colour and item views from a script: each made by its tag, narrowed, a property
	// set and read back, and the views' verbs called; the first check that fails is the answer
	// (0: none).
	private const String cViews = """
		int failed = 0;
		int step = 0;
		void check(bool ok) { step += 1; if (!ok && (failed == 0)) failed = step; }
		int roundTrip(Node@ root)
		{
			TextField@ field = TextField::Of(root.Add("TextField"));
			field.Text = "hello"; check(field.Text == "hello");
			field.IsPassword = true; check(field.IsPassword);
			check(TextEditBase::Of(field) !is null);
			TextArea@ area = TextArea::Of(root.Add("TextArea"));
			area.Rows = 4; check(area.Rows == 4);
			NumberField@ number = NumberField::Of(root.Add("NumberField"));
			number.Max = 10; number.Value = 3; check(number.Value == 3);
			check(TextField::Of(number) !is null);
			ColorPicker@ picker = ColorPicker::Of(root.Add("ColorPicker"));
			picker.ShowsAlpha = false; check(!picker.ShowsAlpha);
			ColorSwatch@ swatch = ColorSwatch::Of(root.Add("ColorSwatch"));
			check(swatch !is null);
			ComboBox@ combo = ComboBox::Of(root.Add("ComboBox"));
			combo.ItemsText = "a|b|c"; combo.SelectedIndex = 2; check(combo.SelectedIndex == 2);
			TableView@ table = TableView::Of(root.Add("TableView"));
			table.ColumnsText = "Name|Size"; check(table.ColumnsText == "Name|Size");
			check(ItemView::Of(table) !is null);
			check(ListView::Of(table) is null);
			return failed;
		}
		ListView@ list;
		TreeView@ tree;
		EditableLabel@ label;
		void build(Node@ root)
		{
			@list = ListView::Of(root.Add("ListView"));
			list.ItemsText = "a|b|c";
			list.SelectionModeName = "multi";
			@tree = TreeView::Of(root.Add("TreeView"));
			@label = EditableLabel::Of(root.Add("EditableLabel"));
			label.Text = "name";
		}
		void selectAll() { list.SelectAll(); }
		void clearSelection() { list.ClearSelection(); }
		void beginEdit() { label.BeginEdit(); }
		void expand(int item) { tree.ExpandItem(item); }
		void collapse(int item) { tree.CollapseItem(item); }
		""";

	[Test]
	public static void AScriptWorksTheTextColourAndItemViews()
	{
		RegisterGuiElements();
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let vm = new AngelScriptRuntime();
		defer delete vm;
		vm.Bind(s);
		let ok = vm.Compile("views", "views.as", cViews);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		let root = NewScene();
		var rootArg = ScriptValue[1](.FromWeak(root));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("views", "int roundTrip(Node@)", rootArg, ref r), "ran");
		Dump(vm);
		Test.Assert(r.AsInt == 0, scope $"check {r.AsInt} failed");
		let field = root.GetChildAt(0) as TextField;
		Test.Assert((field != null) && (field.Text == "hello") && field.IsPassword, "the field's own");
		root.ReleaseRef();

		let views = NewScene();
		var viewsArg = ScriptValue[1](.FromWeak(views));
		Test.Assert(vm.Call("views", "void build(Node@)", viewsArg, ref r), "built");
		Dump(vm);
		views.UpdateLayout();
		let list = views.GetChildAt(0) as ListView;
		let tree = views.GetChildAt(1) as TreeView;
		let label = views.GetChildAt(2) as EditableLabel;
		Test.Assert((list != null) && (tree != null) && (label != null));
		Test.Assert(Run(vm, "views", "void selectAll()", ref r) && (list.SelectionCount == 3), "all selected");
		Test.Assert(Run(vm, "views", "void clearSelection()", ref r) && (list.SelectionCount == 0), "none selected");
		Test.Assert(Run(vm, "views", "void beginEdit()", ref r) && label.IsEditing, "editing");
		Test.Assert(vm.Problems.IsEmpty);

		views.ReleaseRef();
		vm.DiscardModule("views");
	}
}
