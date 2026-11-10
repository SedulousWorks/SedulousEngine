using System;
using Sedulous.Image;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Gamekit.ScriptSurface.Tests;

/// The gamekit on the script surface: its screens, its stack and its prompts, every property the
/// GUI reflects on them, nothing blocked; and the gamekit story in AngelScript: a script pushes,
/// reads and pops screens, and hears one leave.
static class GamekitScriptSurfaceTests
{
	/// The one document a script pushes: a covering, pausing screen.
	private class Documents : IResourceProvider
	{
		public override ImageData LoadImage(StringView path) => null;

		public override bool LoadText(StringView path, String outText)
		{
			if (path != "pause.xml")
				return false;
			outText.Append("<Screen pauses=\"true\" covers=\"true\"><Button id=\"resume\"/></Screen>");
			return true;
		}

		public override SVGDocument LoadSvg(StringView path) => null;
	}

	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope Sedulous.Script.ScriptSurface();
		GamekitScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == GamekitScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked: the GUI's 71 (as
		// Sedulous.GUI.ScriptSurface counts them), and the gamekit's Screen, ScreenStack and
		// Prompt, each weakly held and so a seed.
		Test.Assert(GamekitScriptSurface.TypeCount == 74, scope $"the gamekit surface has {GamekitScriptSurface.TypeCount} types");
		for (let name in scope StringView[]("Sedulous.GUI.Screen", "Sedulous.GUI.ScreenStack", "Sedulous.GUI.Prompt"))
		{
			let t = s.Find(name);
			Test.Assert((t != null) && (t.Role == .Weak) && (t.WeakRootTypeName == "Sedulous.GUI.Node"), scope $"{name}, held weakly");
		}
	}

	[Test]
	public static void EveryReflectedPropertyIsOnTheSurface()
	{
		let s = scope Sedulous.Script.ScriptSurface();
		GamekitScriptSurface.Populate(s);
		CheckProperties(s, "Sedulous.GUI.Screen", Screen.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.ScreenStack", ScreenStack.StaticGuiType);
		CheckProperties(s, "Sedulous.GUI.Prompt", Prompt.StaticGuiType);
	}

	private static void CheckProperties(Sedulous.Script.ScriptSurface s, StringView typeName, GuiTypeInfo info)
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
		let s = scope Sedulous.Script.ScriptSurface();
		GamekitScriptSurface.Populate(s);
		let vm = scope Sedulous.Script.Null.NullScriptRuntime();
		vm.Bind(s);
		let text = scope String();
		vm.Describe(text);
		Test.Assert(text.Contains("0 blocked"), "the gamekit surface blocks nothing");
		Test.Assert(text.Contains("class ScreenStack [Weak]"), "the stack, held weakly");
	}

	// The gamekit story: the script makes a stack under the root and pushes a node and
	// pause.xml, listening for the pause screen's `screenleave`; it offers count(), paused(),
	// covers(), popIt() and left().
	private const String cStack = """
		ScreenStack@ stack;
		double leaves = 0;
		bool onLeave(GuiEvent@ e) { leaves += 1; return false; }
		void main()
		{
			Node@ root = Gui.Root();
			@stack = ScreenStack::Of(root.Add("Screens"));
			stack.Id = "screens";
			stack.PushNode(root.Add("Panel"));
			Screen@ pause = stack.Push("pause.xml");
			pause.On("screenleave", EventHandler(onLeave));
		}
		int count() { return stack.Count; }
		bool paused() { return stack.IsPaused; }
		bool covers() { return stack.Top.Covers; }
		bool popIt() { return stack.Pop(); }
		double left() { return leaves; }
		// Two handles to one node are two handles: the stack is told by its id.
		bool coveredBelow() { return stack.Count == 2 && stack.Top.Stack.Id == "screens"; }
		bool replaced() { Screen@ s = stack.ReplaceNode(Gui.Root().Add("Panel")); return s !is null && stack.Count == 1; }
		bool replacedByDocument() { return stack.Replace("pause.xml") !is null && stack.Top.Covers; }
		bool backKeepsTheLast() { return !stack.Back() && stack.Count == 1; }
		int cleared() { stack.Clear(); return stack.Count; }
		""";

	[Test]
	public static void AScriptPushesReadsAndPopsScreensAndHearsOneLeave()
	{
		RegisterGuiElements();
		RegisterGamekitElements();
		let surface = scope Sedulous.Script.ScriptSurface();
		GamekitScriptSurface.Populate(surface);
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(400.0f, 300.0f);
		let documents = scope Documents();
		root.Context.ResourceProvider = documents;
		let gui = scope GuiFacade(root);
		let vm = new AngelScriptRuntime();
		vm.Bind(surface);
		vm.SetService(gui);
		defer
		{
			vm.DiscardModule("stack");
			delete vm;
			gui.RootNode = null;
			root.Context.ResourceProvider = null;
			root.ReleaseRef();
		}
		let ok = vm.Compile("stack", "stack.as", cStack);
		Dump(vm);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		var r = ScriptValue.Nil;
		Test.Assert(Run(vm, "void main()", ref r));
		Test.Assert(Run(vm, "int count()", ref r) && (r.AsInt == 2));
		Test.Assert(Run(vm, "bool paused()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "bool covers()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "bool coveredBelow()", ref r) && r.AsBool, "the top is on the stack");
		let stack = root.GetChildAt(0) as ScreenStack;
		Test.Assert((stack != null) && stack.At(0).IsCovered, "the screen under the pause is covered");
		Test.Assert(Run(vm, "bool popIt()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "int count()", ref r) && (r.AsInt == 1));
		Test.Assert(Run(vm, "bool paused()", ref r) && !r.AsBool);
		Test.Assert(Run(vm, "double left()", ref r) && (r.AsFloat == 1.0), "the pause screen's leave heard");
		Test.Assert(Run(vm, "bool replaced()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "bool replacedByDocument()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "bool backKeepsTheLast()", ref r) && r.AsBool);
		Test.Assert(Run(vm, "int cleared()", ref r) && (r.AsInt == 0));
		Test.Assert(vm.Problems.IsEmpty);
	}

	private static bool Run(AngelScriptRuntime vm, StringView decl, ref ScriptValue r)
	{
		let ok = vm.Call("stack", decl, default, ref r);
		Dump(vm);
		return ok;
	}

	private static void Dump(AngelScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}
}
