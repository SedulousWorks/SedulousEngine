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

	/// A run of its own (a ApplicationRun is the real one).
	private class TestRun : RunBase
	{
		public this() : base("test") {}
	}

	/// The runtimes in play: the subsystem's own, then each run's (an application run's, the
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

	/// A run with input of its own, as an application run has.
	private class InputRun : RunBase, IRunInput
	{
		public ActionRuntime Runtime = new .() ~ delete _;
		public PadSource Devices = new .() ~ delete _;

		public this() : base("input")
		{
			Register<IRunInput>(this);
		}

		public void DriveInput(float deltaTime, float timeScale)
		{
			Runtime.SetTimeScale(timeScale);
			Runtime.Update(Devices, deltaTime);
		}
	}

	/// Actions were evaluated in Update at order 0 (and a game's in the app's update, later
	/// still), after the scenes had stepped and updated on the last frame's input.
	[Test]
	public static void ActionsAreEvaluatedAsTheFrameBeginsTheSubsystemsAndEveryRuns()
	{
		let runs = scope RunRegistry();
		let run = scope InputRun();
		let runMap = JumpAndConfirm();
		defer delete runMap;
		run.Runtime.SetMap(runMap);
		run.Runtime.DisableSet("Menu");
		runs.Add(run);

		let context = scope SubsystemManager();
		let input = scope InputSubsystem(null);
		context.RegisterSubsystem(input);
		context.SetRunManager(runs);
		let devices = scope PadSource();
		input.SetSourceProvider(devices);
		let map = JumpAndConfirm();
		defer delete map;
		input.SetMap(map);
		input.Runtime.DisableSet("Menu");

		devices.Gamepad.Pressed = .South;
		run.Devices.Gamepad.Pressed = .South;
		context.BeginFrame(1.0f / 60.0f);
		Test.Assert(input.Runtime.WasPressed(input.Runtime.Resolve("Jump")), "the subsystem's, at BeginFrame");
		Test.Assert(run.Runtime.WasPressed(run.Runtime.Resolve("Jump")), "and the run's");
		// Before the scenes, which step in their BeginFrame at -500, and after the GUI (-640),
		// which marks what it takes on every runtime first.
		Test.Assert((input.UpdateOrder < -500) && (input.UpdateOrder > -640));
		context.RemoveSubsystem<InputSubsystem>();
	}

	/// A map with Jump on Space then the pad's south button, in Gameplay, and Confirm on Space in
	/// Menu. The CALLER owns it.
	private static InputMap JumpAndConfirm()
	{
		let map = new InputMap();
		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");
		map.Sets.Add(gameplay);
		let jump = new InputAction();
		jump.Name.Set("Jump");
		var space = Binding();
		space.Source = .Key;
		space.Code = (uint32)Sedulous.Shell.KeyCode.Space;
		jump.Bindings.Add(space);
		var south = Binding();
		south.Source = .GamepadButton;
		south.Code = (uint32)Sedulous.Shell.GamepadButton.South;
		jump.Bindings.Add(south);
		gameplay.Actions.Add(jump);
		let menu = new ActionSet();
		menu.Name.Set("Menu");
		map.Sets.Add(menu);
		let confirm = new InputAction();
		confirm.Name.Set("Confirm");
		confirm.Bindings.Add(space);
		menu.Actions.Add(confirm);
		return map;
	}

	/// The subsystem tracks the input kind from its active source, before its actions read, and
	/// offers the tracker on the application's services while it is registered.
	[Test]
	public static void TheSubsystemTracksTheInputKindFromItsActiveSource()
	{
		let devices = scope PadSource();
		let input = scope InputSubsystem(null);
		input.SetSourceProvider(devices);
		input.BeginFrame(1.0f / 60.0f);
		Test.Assert(input.InputKinds.Kind == .Pointer, "nothing deliberate yet");
		devices.Gamepad.Pressed = .South;
		input.BeginFrame(1.0f / 60.0f);
		Test.Assert(input.InputKinds.Kind == .Pad);

		let context = scope SubsystemManager();
		context.RegisterSubsystem(input);
		Test.Assert(context.FindService(typeof(InputKindTracker)) === input.InputKinds);
		context.RemoveSubsystem<InputSubsystem>();
		Test.Assert(context.FindService(typeof(InputKindTracker)) == null, "gone as it leaves");
	}

	/// `Input.Describe` names the control for the device in hand, as a prompt shows it: the
	/// keyboard's under the pointer, the pad's once a pad is picked up, a named set's enabled or
	/// not, and nothing for an action with no binding or with no runtime.
	[Test]
	public static void DescribeNamesTheControlForTheDeviceInHandAsAPromptShowsIt()
	{
		let runtime = scope ActionRuntime();
		let map = JumpAndConfirm();
		defer delete map;
		runtime.SetMap(map);
		runtime.DisableSet("Menu");
		let kinds = scope InputKindTracker();
		let facade = scope InputFacade(runtime);
		Test.Assert(facade.Describe("Jump") == "Space", "no tracker: the keyboard's");
		facade.InputKinds = kinds;
		Test.Assert(facade.Describe("Jump") == "Space", "the pointer: the keyboard's");
		Test.Assert(facade.Describe("Confirm", "Menu") == "Space", "a named set, enabled or not");
		Test.Assert(facade.Describe("Confirm").IsEmpty, "unnamed, only an enabled set");
		Test.Assert(facade.Describe("Fly").IsEmpty);

		// A pad picked up: the pad's button.
		let devices = scope PadSource();
		devices.Gamepad.Pressed = .South;
		kinds.Update(devices);
		Test.Assert(kinds.Kind == .Pad);
		Test.Assert(facade.Describe("Jump") == "Pad South");
		// No binding of the pad's: its first.
		Test.Assert(facade.Describe("Confirm", "Menu") == "Space");

		// The idle one, over no runtime: nothing to name, never a fault.
		let idle = scope InputFacade(null);
		idle.InputKinds = kinds;
		Test.Assert(idle.Describe("Jump").IsEmpty);
	}

	/// The subsystem points its idle `Input` and every run's (made before it was ready or after)
	/// at its tracker, and lets them go as it shuts down.
	[Test]
	public static void EveryRunsInputFollowsTheSubsystemsInputKind()
	{
		// The facades outlive the runs that borrow them, and the runs their registry.
		let earlyInput = scope InputFacade(null);
		let lateInput = scope InputFacade(null);
		let runs = scope RunRegistry();
		let early = scope TestRun();
		early.Register<InputFacade>(earlyInput);
		runs.Add(early);
		let input = scope InputSubsystem(null);
		Test.Assert(input.ScriptFacade.InputKinds === input.InputKinds, "its idle one, from the start");
		let context = scope SubsystemManager();
		context.RegisterSubsystem(input);
		context.SetRunManager(runs);
		context.Startup();
		Test.Assert(earlyInput.InputKinds === input.InputKinds, "a run made before it was ready");

		let late = scope TestRun();
		late.Register<InputFacade>(lateInput);
		runs.Add(late);
		Test.Assert(lateInput.InputKinds === input.InputKinds, "a run made after");

		context.Shutdown();
		Test.Assert((earlyInput.InputKinds == null) && (lateInput.InputKinds == null), "let go as it shuts down");
	}

	/// `Input.LockPointer` asks the run's own runtime, which reads it back only once an update has
	/// applied it; the idle one, over no runtime, is a no-op reading unlocked, never a fault.
	[Test]
	public static void LockPointerAsksTheRunsRuntimeAndTheIdleOneIsANoOp()
	{
		let runtime = scope ActionRuntime();
		let facade = scope InputFacade(runtime);
		facade.LockPointer(true);
		Test.Assert(!facade.PointerLocked(), "asked, not yet applied");
		Test.Assert(!runtime.PointerLockApplied);

		let idle = scope InputFacade(null);
		idle.LockPointer(true);
		Test.Assert(!idle.PointerLocked());
	}
}
