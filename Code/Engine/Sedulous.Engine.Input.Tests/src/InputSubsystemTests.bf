using System;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Input;
using Sedulous.Engine.Input;

namespace Sedulous.Engine.Input.Tests;

/// The runtime hookup around the action runtime: which source is active, and the scene the
/// active source speaks for.
class InputSubsystemTests
{
	/// The subsystem offers its idle `Input` on the application's services while it is registered.
	[Test]
	public static void TheIdleInputIsTheApplicationsServiceWhileRegistered()
	{
		let context = scope SubsystemManager();
		let input = scope InputSubsystem(null);
		context.RegisterSubsystem(input);
		Test.Assert(context.FindService(typeof(InputFacade)) === input.ScriptFacade);
		Test.Assert(!input.ScriptFacade.IsDown("jump"), "idle: every action released");
		context.RemoveSubsystem<InputSubsystem>();
		Test.Assert(context.FindService(typeof(InputFacade)) == null, "gone as it leaves");
	}

	/// The binding rides the override rather than being set on its own, so a source and the
	/// scene it represents can never disagree.
	[Test]
	public static void ThePerSurfaceSceneBindingRidesTheSourceOverride()
	{
		let input = scope InputSubsystem(null);
		Test.Assert(input.BoundSceneKey == null);
		Test.Assert(input.UnboundScenePolicy == .AllScenes, "the player's default");

		let devices = scope StubSource();
		int sceneStandIn = 0; // any stable address serves as a key
		input.SetSourceProvider(devices, &sceneStandIn);
		Test.Assert(input.BoundSceneKey == &sceneStandIn);
		Test.Assert(input.ActiveSource === devices);

		// Re-setting without a scene UN-binds: the tab stops playing, its provider stays.
		input.SetSourceProvider(devices, null);
		Test.Assert(input.BoundSceneKey == null);

		// Clearing the provider always clears the binding, since the shell source is
		// un-bound by definition.
		input.SetSourceProvider(devices, &sceneStandIn);
		input.SetSourceProvider(null, &sceneStandIn);
		Test.Assert(input.BoundSceneKey == null);

		input.UnboundScenePolicy = .ScreenTierOnly;
		Test.Assert(input.UnboundScenePolicy == .ScreenTierOnly);
	}

	/// A closing tab clears its own source before it is destroyed, and must not disturb a
	/// different one that is still open.
	[Test]
	public static void ClearSourceProviderIfDropsOnlyItsOwnDanglingOverride()
	{
		let input = scope InputSubsystem(null);
		let tabA = scope StubSource();
		let tabB = scope StubSource();
		int keyA = 0;

		input.SetSourceProvider(tabA, &keyA);
		Test.Assert(input.ActiveSource === tabA);

		// A NON active tab closing leaves the active override alone.
		input.ClearSourceProviderIf(tabB);
		Test.Assert(input.ActiveSource === tabA);
		Test.Assert(input.BoundSceneKey == &keyA);

		// The ACTIVE tab closing drops the override and its binding, and the active source
		// falls back to the always valid shell one, so the next pump cannot dangle.
		input.ClearSourceProviderIf(tabA);
		Test.Assert(input.ActiveSource !== tabA);
		Test.Assert(input.BoundSceneKey == null);

		// Idempotent once cleared.
		input.ClearSourceProviderIf(tabA);
		Test.Assert(input.ActiveSource !== tabA);
	}

	/// A run of its own (a GameInstance is the real one).
	private class TestRun : RunBase
	{
		public this() : base("test") {}
	}

	/// The runtimes in play: the subsystem's own, then each run's (a game instance's, the
	/// ActionRuntime it holds as a service), found through the runs on its subsystem manager, so
	/// the UI's consumption and the touch guide reach the game too.
	[Test]
	public static void EveryRuntimeInPlayIsReached()
	{
		let input = scope InputSubsystem(null);
		int seen = 0;
		input.ForEachActionRuntime(scope [&] (runtime) => { Test.Assert(runtime === input.Runtime); seen++; });
		Test.Assert(seen == 1, "no runs: its own alone");

		let first = scope ActionRuntime();
		let second = scope ActionRuntime();
		let runs = scope RunRegistry();
		let runA = scope TestRun();
		let runB = scope TestRun();
		runA.Register<ActionRuntime>(first);
		runB.Register<ActionRuntime>(second);
		runs.Add(runA);
		runs.Add(runB);
		// Registered, so the context drives it and finds the runs for it; it goes first.
		let context = scope SubsystemManager();
		context.RegisterSubsystem(input);
		context.SetRunManager(runs);
		let order = scope System.Collections.List<ActionRuntime>();
		input.ForEachActionRuntime(scope [&] (runtime) => { order.Add(runtime); });
		Test.Assert((order.Count == 3) && (order[0] === input.Runtime) && (order[1] === first) && (order[2] === second));
	}
}
