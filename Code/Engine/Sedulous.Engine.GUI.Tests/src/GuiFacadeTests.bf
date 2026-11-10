using System;
using Sedulous.Core;
using Sedulous.Engine.Composition;
using Sedulous.Engine.GUI;
using Sedulous.GUI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI.Tests;

/// The facades game code reaches the GUI through: a component reaches its tree as a node, and a
/// run's `Gui.Root()` is its screen tier, through the subsystem's facades (FacadeFor, offered on
/// the application's services and each run's).
class GuiFacadeTests
{
	/// A component reaches its tree as a node once the subsystem builds it, and the shared `Gui`'s
	/// root is the screen tier, its stack found by id.
	[Test]
	public static void AComponentReachesItsTreeAsANodeAndTheSharedGuisRootIsTheScreenTier()
	{
		let engine = scope GuiTestEngine();
		Test.Assert(engine.Gui.Screens.Id == "screens", "what game code finds");
		let level = engine.Scenes.CreateScene("level");
		let hud = level.CreateEntity("hud");
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		// BORROWED by the component, which compares it and never frees it.
		let document = GuiTestEngine.MakeDocument("<Panel id=\"hud-root\"/>");
		defer delete document;
		canvases.Add(hud);
		Test.Assert(canvases.Get(hud).Root == null, "not built yet");

		canvases.Get(hud).Document.SetDirect(document);
		engine.Frame();
		let tree = canvases.Get(hud).Root;
		Test.Assert((tree != null) && (tree.FindElement("hud-root") != null), "the canvas's tree, as a node");
		let root = engine.Gui.FacadeFor(null).Root();
		Test.Assert((root != null) && (root.FindElement("screens") != null), "the shared Gui's root is the screen tier");
		engine.Scenes.DestroyScene(level);
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
		let shared = engine.Gui.FacadeFor(null);
		let mine = engine.Gui.FacadeFor(run);
		Test.Assert(shared.Root() === engine.Gui.ScreenRoot);
		Test.Assert(engine.Gui.FacadeFor(run) === mine, "made once");
		Test.Assert(engine.Gui.RunFacadeCount == 1);
		Test.Assert(mine.Root() === engine.Gui.ScreenRootFor(run));
		Test.Assert(mine.Root() !== engine.Gui.ScreenRoot, "its own tier");
		Test.Assert(engine.Gui.RunScreenCount == 1, "made by the facade's first call");

		// Its screens end with its session; it plays again, and gets a tier back.
		run.Stop();
		Test.Assert(engine.Gui.RunScreenCount == 0);
		run.Start();
		Test.Assert((mine.Root() != null) && (engine.Gui.RunScreenCount == 1));
		Test.Assert(mine.Root().FindElement("screens") != null, "its tier's stack");

		engine.Gui.EndRunFacade(run.Id);
		Test.Assert(engine.Gui.RunFacadeCount == 0);
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
		Test.Assert(engine.Context.FindService(typeof(GuiFacade)) === engine.Gui.FacadeFor(null), "the shared one");
		engine.Runs.Add(later);
		Test.Assert(later.FindService(typeof(GuiFacade)) === engine.Gui.FacadeFor(later), "made as the run is");
		Test.Assert(later.FindService(typeof(GuiFacade)) !== engine.Gui.FacadeFor(null));
		Test.Assert(engine.Gui.RunFacadeCount == 1);
		engine.Context.Shutdown();
		Test.Assert(later.FindService(typeof(GuiFacade)) == null, "taken back as the subsystem goes");
	}
}
