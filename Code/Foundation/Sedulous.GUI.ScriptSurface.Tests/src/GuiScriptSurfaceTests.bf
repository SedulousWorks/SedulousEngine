using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.GUI;

namespace Sedulous.GUI.ScriptSurface.Tests;

/// The GUI's script surface: the node, the widget base and what a handler is given, every
/// property the GUI reflects on them, nothing blocked, bound by AngelScript without a word; and
/// Raptor's script stories, in their AngelScript halves, over a root handed in as an argument: a
/// script builds and styles a widget, listens and is called, narrows a handle, and is told a gone
/// node is gone, a handle outliving its GUI included.
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
		// and UIWidget (weakly held, each a seed) and GuiEvent (counted, with a marked
		// constructor), then Core's static block and the fifteen of its types the block's free
		// functions name: AABB, BoundingFrustum, BoundingSphere, Color, Color32, ContainmentType,
		// Float2, Float3, Float3x3, Float4, Float4x4, Plane, PlaneIntersectionType, Quaternion and
		// Ray. Core's other marked types (Transform, Rectangle, the IO and log enums) nothing here
		// reaches.
		Test.Assert(GuiScriptSurface.TypeCount == 21, scope $"the GUI surface has {GuiScriptSurface.TypeCount} types");
		Test.Assert(s.Find("Sedulous.GUI.Node").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.SceneRoot").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UINode").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UIWidget").Role == .Weak);
		Test.Assert(s.Find("Sedulous.GUI.UIWidget").WeakRootTypeName == "Sedulous.GUI.Node");
		Test.Assert(s.Find("Sedulous.GUI.GuiEvent").Role == .Counted);
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
}
