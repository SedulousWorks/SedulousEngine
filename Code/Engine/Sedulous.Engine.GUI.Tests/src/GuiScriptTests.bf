using System;
using Sedulous.Core;
using Sedulous.Engine.Composition;
using Sedulous.Engine.GUI;
using Sedulous.GUI;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;

namespace Sedulous.Engine.GUI.Tests;

/// The scripts: the engine's runtime surface names `Gui` and the three components, a component
/// reaches its tree as a node, and a run's `Gui.Root()` is its screen tier, through the
/// subsystem's facades (ScriptFacadeFor, offered on the application's services and each run's),
/// in AngelScript.
class GuiScriptTests
{
	private static ScriptMethodInfo Method(ScriptTypeInfo t, StringView name)
	{
		for (let m in t.Methods)
		{
			if (m.ScriptName == name)
				return m;
		}
		return null;
	}

	/// The script surface names the `Gui` facade and the GUI components, each type on it once with
	/// its role; a component's tree is reached by a script's `Root()`.
	[Test]
	public static void TheScriptSurfaceNamesGuiAndTheComponentsAndAComponentReachesItsTreeAsANode()
	{
		// What the runtime is bound to: it points into the surface, so the surface outlives it.
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		let gui = surface.Find("Sedulous.GUI.GuiFacade");
		Test.Assert((gui != null) && (gui.Role == .Service) && (gui.DisplayName == "Gui"));
		for (let name in StringView[?]("Sedulous.Engine.GUI.GuiCanvasComponent", "Sedulous.Engine.GUI.GuiBillboardComponent",
			"Sedulous.Engine.GUI.GuiWorldPanelComponent"))
		{
			let component = surface.Find(name);
			Test.Assert((component != null) && (component.Role == .Component), scope String(name));
			let root = Method(component, "Root");
			Test.Assert((root != null) && (root.ReturnTypeName == "Sedulous.GUI.Node"), scope String(name));
		}

		let engine = scope GuiTestEngine();
		Test.Assert(engine.Gui.Screens.Id == "screens", "what a script finds");
		let level = engine.Scenes.CreateScene("level");
		let hud = level.CreateEntity("hud");
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		// BORROWED by the component, which compares it and never frees it.
		let document = GuiTestEngine.MakeDocument("<Panel id=\"hud-root\"/>");
		defer delete document;
		canvases.Add(hud);
		Test.Assert(canvases.Get(hud).RootNode() == null, "not built yet");

		let vm = scope AngelScriptRuntime();
		vm.Bind(surface);
		vm.SetService(engine.Gui.ScriptFacadeFor(null)); // a bare runtime: the shared tier's `Gui`
		let ok = vm.Compile("hud", "hud.as", """
			bool unbuilt(const Entity &in hud) { return GuiCanvasComponent::of(hud).Root() is null; }
			bool built(const Entity &in hud)
			{
				Node@ tree = GuiCanvasComponent::of(hud).Root();
				return tree !is null && tree.Find("hud-root") !is null;
			}
			bool screens()
			{
				Node@ root = Gui.Root();
				return root !is null && root.Find("screens") !is null;
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		var args = ScriptValue[1](.FromEntity(hud, level));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("hud", "bool unbuilt(const Entity &in)", args, ref r) && r.AsBool, "null before the subsystem builds it");
		canvases.Get(hud).Document.SetDirect(document);
		engine.Frame();
		Test.Assert(canvases.Get(hud).RootNode() != null);
		Test.Assert(vm.Call("hud", "bool built(const Entity &in)", args, ref r) && r.AsBool, "the canvas's tree, as a node");
		Test.Assert(vm.Call("hud", "bool screens()", default, ref r) && r.AsBool, "Gui.Root() is the screen tier");
		vm.DiscardModule("hud");
		engine.Scenes.DestroyScene(level);
	}

	/// AngelScript reaches a canvas's, a billboard's and a world panel's tree by Root(), which
	/// returns a Node.
	[Test]
	public static void AngelScriptReachesACanvassABillboardsAndAWorldPanelsTreeByRoot()
	{
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		let engine = scope GuiTestEngine();
		let vm = scope AngelScriptRuntime();
		vm.Bind(surface);
		vm.SetService(engine.Gui.ScriptFacadeFor(null));
		let ok = vm.Compile("roots", "roots.as", """
			Node@ canvas(const Entity &in e) { return GuiCanvasComponent::of(e).Root(); }
			Node@ board(const Entity &in e) { return GuiBillboardComponent::of(e).Root(); }
			Node@ panel(const Entity &in e) { return GuiWorldPanelComponent::of(e).Root(); }
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "each compiles against the engine surface");
		vm.DiscardModule("roots");
	}

	/// With run screens on, a run's facade answers its own tier, made on first use, and the
	/// shared facade the shared tier; both find no root once the subsystem has shut down.
	[Test]
	public static void ARunsGuiIsItsOwnScreenTierAndNoneAfterShutdown()
	{
		let engine = scope GuiTestEngine();
		engine.Gui.RunScreens = true;
		let run = scope GuiTestRun();
		engine.Runs.Add(run);
		run.Start();
		let shared = engine.Gui.ScriptFacadeFor(null);
		let mine = engine.Gui.ScriptFacadeFor(run);
		Test.Assert(shared.Root() === engine.Gui.ScreenRoot);
		Test.Assert(engine.Gui.ScriptFacadeFor(run) === mine, "made once");
		Test.Assert(engine.Gui.RunScriptFacadeCount == 1);
		Test.Assert(mine.Root() === engine.Gui.ScreenRootFor(run));
		Test.Assert(mine.Root() !== engine.Gui.ScreenRoot, "its own tier");
		Test.Assert(engine.Gui.RunScreenCount == 1, "made by the facade's first call");

		// Its screens end with its session; it plays again, and gets a tier back.
		run.Stop();
		Test.Assert(engine.Gui.RunScreenCount == 0);
		run.Start();
		Test.Assert((mine.Root() != null) && (engine.Gui.RunScreenCount == 1));

		// A script's runtime given it: AngelScript finds the root it was given. In a block, so
		// the runtime, which borrows the facade, goes before the facade does.
		{
			let surface = scope ScriptSurface();
			EngineScriptSurface.Populate(surface);
			let vm = scope AngelScriptRuntime();
			vm.Bind(surface);
			vm.SetService(engine.Gui.ScriptFacadeFor(run));
			let ok = vm.Compile("run", "run.as", """
				bool mine() { Node@ root = Gui.Root(); return root !is null && root.Find("screens") !is null; }
				""");
			for (let p in vm.Problems)
				Console.WriteLine("  {}", p);
			Test.Assert(ok, "compiled against the engine surface");
			var r = ScriptValue.Nil;
			Test.Assert(vm.Call("run", "bool mine()", default, ref r) && r.AsBool);
			vm.DiscardModule("run");
		}

		engine.Gui.EndRunScripts(run.Id);
		Test.Assert(engine.Gui.RunScriptFacadeCount == 0);
		engine.Context.Shutdown();
		Test.Assert(shared.Root() == null, "the shared tier is gone, so no root");
	}

	/// The subsystem offers its own `Gui`: the shared tier's on the application's services, and
	/// each run's among that run's, made as the run is; taken back from the runs still alive as it
	/// shuts down.
	[Test]
	public static void TheSharedGuiIsTheApplicationsServiceAndEachRunsItsOwnAmongTheRuns()
	{
		let engine = scope GuiTestEngine();
		let later = scope GuiTestRun(); // after the engine, so it goes first (the registry is the engine's)
		Test.Assert(engine.Context.FindService(typeof(GuiFacade)) === engine.Gui.ScriptFacadeFor(null), "the shared one");
		engine.Runs.Add(later);
		Test.Assert(later.FindService(typeof(GuiFacade)) === engine.Gui.ScriptFacadeFor(later), "made as the run is");
		Test.Assert(later.FindService(typeof(GuiFacade)) !== engine.Gui.ScriptFacadeFor(null));
		Test.Assert(engine.Gui.RunScriptFacadeCount == 1);
		engine.Context.Shutdown();
		Test.Assert(later.FindService(typeof(GuiFacade)) == null, "taken back as the subsystem goes");
	}
}
