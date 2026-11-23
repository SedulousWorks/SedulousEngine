using System;
using System.Collections;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// The player's rebinding: controls by name, a rebind replacing one device's binding only, the
/// overrides kept over the game's map, a capture taking the next press while every action rests.
class PlayerBindingsTests
{
	private static Binding KeyBinding(KeyCode key)
	{
		var binding = Binding();
		binding.Source = .Key;
		binding.Code = (uint32)key;
		return binding;
	}

	private static Binding PadBinding(GamepadButton button)
	{
		var binding = Binding();
		binding.Source = .GamepadButton;
		binding.Code = (uint32)button;
		return binding;
	}

	/// Gameplay: Jump (Space, then the pad's South) and Move (WASD); Menu: Back (Escape). Held by
	/// the caller.
	private static InputMap TwoSets()
	{
		let map = new InputMap();
		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");
		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Bindings.Add(KeyBinding(.Space));
		jump.Bindings.Add(PadBinding(.South));
		gameplay.Actions.Add(jump);
		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		var wasd = Binding();
		wasd.Source = .Composite2D;
		move.Bindings.Add(wasd);
		gameplay.Actions.Add(move);
		map.Sets.Add(gameplay);
		let menu = new ActionSet();
		menu.Name.Set("Menu");
		menu.Priority = 10;
		let back = new InputAction();
		back.Name.Set("Back");
		back.Bindings.Add(KeyBinding(.Escape));
		menu.Actions.Add(back);
		map.Sets.Add(menu);
		return map;
	}

	private static ScriptedInput KeyAt(double at, KeyCode key, bool down)
	{
		var input = ScriptedInput();
		input.At = at;
		input.Kind = .Key;
		input.Key = key;
		input.Down = down;
		return input;
	}

	private static ScriptedInput PadAt(double at, GamepadButton button, bool down)
	{
		var input = ScriptedInput();
		input.At = at;
		input.Kind = .PadButton;
		input.PadButton = button;
		input.Down = down;
		return input;
	}

	[Test]
	public static void AControlByNameIsABindingInAnyCaseAndAnUnknownOneIsNone()
	{
		Test.Assert(PlayerBindings.ParseControl("Key.Space", var space));
		Test.Assert((space.Source == .Key) && (space.Code == (uint32)KeyCode.Space));
		Test.Assert(PlayerBindings.ParseControl("pad.south", var south));
		Test.Assert(south.Source == .GamepadButton);
		Test.Assert(PlayerBindings.ParseControl("PadAxis.RightTrigger", var trigger));
		Test.Assert(trigger.Source == .GamepadAxis);
		Test.Assert(PlayerBindings.ParseControl("Mouse.Left", ?));
		Test.Assert(!PlayerBindings.ParseControl("Space", ?));
		Test.Assert(!PlayerBindings.ParseControl("Key.Nothing", ?));
		Test.Assert(!PlayerBindings.ParseControl("Wheel.Up", ?));
	}

	[Test]
	public static void ARebindReplacesTheDevicesBindingKeepsTheOthersAndTheSetsAndAResetRestores()
	{
		let runtime = scope ActionRuntime();
		let bindings = scope PlayerBindings();
		int changes = 0;
		let store = scope InputBindingOverrides();
		bindings.SetStore(store, new [&] () => { changes++; });
		let map = TwoSets();
		defer delete map;
		bindings.Install(runtime, map);
		runtime.DisableSet("Menu");

		Test.Assert(bindings.Set("", "Jump", KeyBinding(.J)));
		let jump = runtime.FindAction("Gameplay", "Jump");
		Test.Assert((jump != null) && (jump.Bindings.Count == 2));
		Test.Assert(jump.Bindings[0].Code == (uint32)KeyCode.J);
		Test.Assert(jump.Bindings[1].Source == .GamepadButton, "the pad's kept");
		Test.Assert(!runtime.IsSetEnabled("Menu"), "the sets as the game left them");
		Test.Assert(changes == 1);
		Test.Assert((store.Overrides.Count == 1) && (store.Overrides[0].SetName == "Gameplay"));
		Test.Assert(!bindings.Set("", "Move", KeyBinding(.J)), "two axes");
		Test.Assert(!bindings.Set("", "Fly", KeyBinding(.J)));

		Test.Assert(bindings.Reset("", "Jump"));
		Test.Assert(runtime.FindAction("Gameplay", "Jump").Bindings[0].Code == (uint32)KeyCode.Space);
		Test.Assert(store.Overrides.IsEmpty);
	}

	[Test]
	public static void OverridesSavedBeforeLieOverTheGamesMapWhenTheStoreChanges()
	{
		let saved = scope InputBindingOverrides();
		var pad = Binding[1](PadBinding(.East));
		saved.Set("Gameplay", "Jump", pad);
		let runtime = scope ActionRuntime();
		let bindings = scope PlayerBindings();
		let map = TwoSets();
		defer delete map;
		bindings.Install(runtime, map); // no store yet: the game's own
		Test.Assert(runtime.FindAction("Gameplay", "Jump").Bindings.Count == 2);

		bindings.SetStore(saved, null);
		bindings.Reapply();
		let jump = runtime.FindAction("Gameplay", "Jump");
		Test.Assert((jump.Bindings.Count == 1) && (jump.Bindings[0].Code == (uint32)GamepadButton.East));

		bindings.ResetAll();
		Test.Assert(runtime.FindAction("Gameplay", "Jump").Bindings.Count == 2);
		Test.Assert(saved.Overrides.IsEmpty);
	}

	[Test]
	public static void ACaptureRestsEveryActionTakesTheNextPressOfItsDeviceAndEscapeCancels()
	{
		let runtime = scope ActionRuntime();
		let bindings = scope PlayerBindings();
		let map = TwoSets();
		defer delete map;
		bindings.Install(runtime, map);
		let source = scope ScriptedInputSource();
		Test.Assert(source.Add(KeyAt(0.0, .Space, true))); // held as the capture begins
		Test.Assert(source.Add(PadAt(0.1, .West, true))); // another device: ignored
		Test.Assert(source.Add(KeyAt(0.2, .K, true)));
		Test.Assert(source.Add(KeyAt(0.3, .Escape, true)));
		Test.Assert(source.Add(KeyAt(0.35, .K, false)));
		Test.Assert(source.Add(KeyAt(0.4, .L, true)));
		let jump = runtime.Resolve("Jump");

		source.Advance(0.0);
		bindings.Poll(source);
		runtime.Update(source, 0.016f);
		Test.Assert(runtime.IsDown(jump));

		Test.Assert(bindings.BeginCapture("", "Jump", .Keyboard));
		Test.Assert(!bindings.BeginCapture("", "Move", .Keyboard), "not a button");
		source.Advance(0.1);
		bindings.Poll(source);
		runtime.Update(source, 0.016f);
		Test.Assert(bindings.IsCapturing);
		Test.Assert(!runtime.IsDown(jump), "resting while it listens, Space still held");

		source.Advance(0.2);
		bindings.Poll(source); // K is taken
		runtime.Update(source, 0.016f);
		Test.Assert(!bindings.IsCapturing);
		let rebound = runtime.FindAction("Gameplay", "Jump");
		Test.Assert(rebound.Bindings[0].Code == (uint32)KeyCode.K);
		Test.Assert(rebound.Bindings[1].Source == .GamepadButton);
		Test.Assert(!runtime.IsDown(jump), "K, held through the capture, waits for its release");
		source.Advance(0.25);
		bindings.Poll(source);
		runtime.Update(source, 0.016f);
		Test.Assert(!runtime.IsDown(jump));

		Test.Assert(bindings.BeginCapture("", "Jump", .Keyboard));
		source.Advance(0.3);
		bindings.Poll(source); // Escape cancels
		Test.Assert(!bindings.IsCapturing);
		Test.Assert(runtime.FindAction("Gameplay", "Jump").Bindings[0].Code == (uint32)KeyCode.K);

		// From nothing held: K let go, a capture takes L. The frame that takes it still rests, so
		// L fires nothing as it is taken.
		source.Advance(0.35);
		bindings.Poll(source);
		runtime.Update(source, 0.016f);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(bindings.BeginCapture("", "Jump", .Keyboard));
		source.Advance(0.4);
		bindings.Poll(source); // L is taken
		runtime.Update(source, 0.016f);
		Test.Assert(runtime.FindAction("Gameplay", "Jump").Bindings[0].Code == (uint32)KeyCode.L);
		Test.Assert(!runtime.IsDown(jump), "the press that was captured does not also fire the action");
	}
}
