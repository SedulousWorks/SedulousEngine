using System;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.GUI;
using Sedulous.Resource;

namespace Sedulous.Engine.DefaultApp.Tests;

/// Every game has the engine's GUI beside the UI: registered on the host's context, resolving
/// guids through the game's resource manager, and each run's scripts given a `Gui` of their own
/// that goes, with the run's screen tier, when the run does.
class GuiWiringTests
{
	[Test]
	public static void EveryGameHasTheGuiAndItResolvesGuidsThroughTheGamesResourceManager()
	{
		let resources = scope ResourceManager(null);
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Context.Startup();
		app.OnStartup(host);
		Test.Assert(app.Gui != null);
		Test.Assert(host.Context.GetSubsystem<GuiSubsystem>() === app.Gui);
		app.AttachResourceManager(resources, host);
		Test.Assert(app.Gui.Resources.GetResourceManager() === resources);
		app.AttachResourceManager(null, host);
		Test.Assert(app.Gui.Resources.GetResourceManager() == null);

		host.Context.Shutdown();
		app.OnShutdown(host);
		host.Context.Dispose();
	}

	[Test]
	public static void AReleasedRunsGuiAndScreenTierGoWithIt()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Context.Startup();
		app.OnStartup(host);
		app.Gui.RunScreens = true;
		// The primary's Gui was installed with the subsystem.
		Test.Assert(app.Gui.RunScriptFacadeCount == 1);

		let instance = app.CreateInstance(true);
		Test.Assert(instance != null);
		Test.Assert(app.Gui.RunScriptFacadeCount == 2, "an extra run's own Gui");
		Test.Assert(app.Gui.ScreenRootFor(instance) !== app.Gui.ScreenRoot);
		Test.Assert(app.Gui.RunScreenCount == 1);
		app.ReleaseInstance(instance);
		Test.Assert(app.Gui.RunScriptFacadeCount == 1, "its Gui gone with it");
		Test.Assert(app.Gui.RunScreenCount == 0, "and its screen tier");

		host.Context.Shutdown();
		app.OnShutdown(host);
		host.Context.Dispose();
	}
}
