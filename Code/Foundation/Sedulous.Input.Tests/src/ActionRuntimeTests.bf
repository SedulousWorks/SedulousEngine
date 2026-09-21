using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// Evaluating a map against devices: edges, folding, dead zones and the set model.
class ActionRuntimeTests
{
	private const float cStep = 1.0f / 60.0f;

	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	[Test]
	public static void APressGivesOneEdgeAndThenReadsHeld()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		// So Space resolves to Gameplay's Jump rather than the higher priority Confirm.
		runtime.DisableSet("Menu");

		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		let jump = runtime.Resolve("Jump");
		Test.Assert(jump.IsValid);

		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));

		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
		Test.Assert(runtime.WasPressed(jump), "the edge lands on the frame the press did");

		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
		Test.Assert(!runtime.WasPressed(jump), "and does not repeat while it is held");

		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(runtime.WasReleased(jump));

		// The same action off a different device: two bindings fold into one press.
		pad.SetDown(.South);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
	}

	/// A modifier gated binding waits for its modifier.
	[Test]
	public static void AModifierGatedBindingNeedsItsModifier()
	{
		let map = InputTestMaps.Single("QuickSave", .Button,
			InputTestMaps.Key(.S, (.)KeyModifiers.LeftCtrl));
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let quickSave = runtime.Resolve("QuickSave");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.S);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(quickSave), "the key alone is not the binding");

		devices.FakeKeyboard.Modifiers = .LeftCtrl;
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(quickSave));
	}

	/// A modifier GROUP is satisfied by either side. Requiring every bit of the mask would
	/// make a Shift binding unreachable: nobody holds both shifts to fire one action.
	[Test]
	public static void AModifierGroupIsSatisfiedByEitherSide()
	{
		let map = InputTestMaps.Single("Sprint", .Button,
			InputTestMaps.Key(.W, (.)KeyModifiers.Shift));
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let sprint = runtime.Resolve("Sprint");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.W);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(sprint), "no shift at all");

		devices.FakeKeyboard.Modifiers = .LeftShift;
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(sprint), "the left one is a shift");

		devices.FakeKeyboard.Modifiers = .RightShift;
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(sprint), "and so is the right one");

		devices.FakeKeyboard.Modifiers = .LeftCtrl;
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(sprint), "a different modifier is not a shift");
	}

	/// Naming ONE side still means that side, because a one bit requirement leaves one bit
	/// to match.
	[Test]
	public static void ASpecificModifierSideStaysSpecific()
	{
		let map = InputTestMaps.Single("Act", .Button,
			InputTestMaps.Key(.W, (.)KeyModifiers.LeftAlt));
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.W);
		devices.FakeKeyboard.Modifiers = .RightAlt;
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(act));

		devices.FakeKeyboard.Modifiers = .LeftAlt;
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(act));
	}

	[Test]
	public static void ACompositeNormalisesItsDiagonal()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		runtime.DisableSet("Menu");
		let move = runtime.Resolve("Move");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.W);
		devices.FakeKeyboard.SetDown(.D);
		runtime.Update(devices, cStep);

		let value = runtime.Value2D(move);
		Test.Assert(Near(value.X, 0.7071f), "a diagonal is not faster than a cardinal");
		Test.Assert(Near(value.Y, 0.7071f));
		Test.Assert(runtime.IsDown(move));
	}

	[Test]
	public static void AStickReadsZeroInsideItsDeadZoneAndRescalesOutside()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		runtime.DisableSet("Menu");
		let move = runtime.Resolve("Move");

		let devices = scope FakeDevices();
		let pad = devices.AddPad();

		pad.SetAxis(.LeftX, 0.1f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 0.0f), "drift inside the zone is not input");

		// Full deflection still reaches one: the zone rescales rather than clipping, so
		// the top of the range is not lost along with the bottom.
		pad.SetAxis(.LeftX, 1.0f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 1.0f));
	}

	/// Two bindings on one action fold by MAGNITUDE, so the quieter source does not drag
	/// the louder one down or cancel it out.
	[Test]
	public static void TheLargerMagnitudeWinsTheFold()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		runtime.DisableSet("Menu");
		let move = runtime.Resolve("Move");

		let devices = scope FakeDevices();
		let pad = devices.AddPad();

		// A full press left on the keys against a light push right on the stick.
		devices.FakeKeyboard.SetDown(.A);
		pad.SetAxis(.LeftX, 0.4f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, -1.0f), "the key out-magnitudes the nudge");
	}

	/// The same name in two sets: the highest priority ENABLED one answers.
	[Test]
	public static void PriorityDecidesWhichSetAnswers()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);

		// Both sets are enabled and both hold Space, but each name resolves on its own.
		Test.Assert(runtime.IsDown(runtime.Resolve("Confirm")));
		Test.Assert(runtime.IsDown(runtime.Resolve("Jump")));
		Test.Assert(runtime.IsSetEnabled("Menu"));

		runtime.DisableSet("Menu");
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsSetEnabled("Menu"));
		Test.Assert(!runtime.IsDown(runtime.Resolve("Confirm")), "a disabled set answers nothing");
	}

	/// The whole modal contract, which is the reason held latching exists: a key held
	/// across a modal boundary fires nothing on either side of it.
	[Test]
	public static void AnExclusiveSetSuppressesAndLatchesWhatIsHeld()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");
		let confirm = runtime.Resolve("Confirm");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));

		// The menu opens mid hold.
		runtime.PushExclusiveSet("Menu");
		Test.Assert(runtime.ExclusiveDepth == 1);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(runtime.WasReleased(jump), "the release edge still fires, exactly once");
		Test.Assert(!runtime.IsDown(confirm), "the held key must not confirm the menu it opened");

		// Released and pressed again INSIDE the menu: Confirm takes it, Jump does not.
		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(confirm));
		Test.Assert(runtime.WasPressed(confirm));
		Test.Assert(!runtime.IsDown(jump));

		// The menu closes while Space is STILL held.
		runtime.PopExclusiveSet();
		Test.Assert(runtime.ExclusiveDepth == 0);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump), "and the held key must not re-fire on the way out");

		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump), "a fresh press works normally");
		Test.Assert(runtime.WasPressed(jump));
	}

	/// Pushing a set the map does not have suppresses NOTHING. A typo should not make the
	/// game unplayable.
	///
	/// The transition still latches what is held, because that part is about the boundary
	/// rather than about which set is on top: a press that spans the boundary needs a fresh
	/// press either way.
	[Test]
	public static void AnUnknownExclusiveSetSuppressesNothing()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");

		let devices = scope FakeDevices();
		runtime.PushExclusiveSet("Inventory");
		Test.Assert(runtime.ExclusiveDepth == 1);

		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump), "the boundary latched the press that spanned it");

		// The stack is STILL non-empty here. A real exclusive set would keep Jump released
		// for as long as it is on top; an unknown one lets the next press straight through.
		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.ExclusiveDepth == 1);
		Test.Assert(runtime.IsDown(jump));
	}

	/// A device filtered binding reads only the pad it names.
	[Test]
	public static void ADeviceFilteredBindingIgnoresOtherPads()
	{
		var padButton = Binding();
		padButton.Source = .GamepadButton;
		padButton.Code = (.)GamepadButton.South;
		padButton.Device = 1;

		let map = InputTestMaps.Single("Jump", .Button, padButton);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");

		let devices = scope FakeDevices();
		let first = devices.AddPad();
		let second = devices.AddPad();

		first.SetDown(.South);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump), "player one's pad is not player two's");

		first.SetDown(.South, false);
		second.SetDown(.South);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
	}

	/// A disconnected pad reads as released rather than as an error: pads come and go.
	[Test]
	public static void ADisconnectedPadReadsAsReleased()
	{
		var padButton = Binding();
		padButton.Source = .GamepadButton;
		padButton.Code = (.)GamepadButton.South;

		let map = InputTestMaps.Single("Jump", .Button, padButton);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");

		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetDown(.South);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));

		pad.Connected = false;
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(runtime.WasReleased(jump), "and it is a proper release, not a freeze");
	}

	/// An unresolvable name never crashes a query, it just reads released. A game asking
	/// for an action a designer removed keeps running.
	[Test]
	public static void AnUnknownActionReadsReleased()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);

		let missing = runtime.Resolve("Teleport");
		Test.Assert(missing.IsValid, "it resolves to a handle with no candidates");
		Test.Assert(!runtime.IsDown(missing));
		Test.Assert(!runtime.WasPressed(missing));
		Test.Assert(runtime.Value(missing) == 0.0f);
		Test.Assert(runtime.Value2D(missing) == Float2.Zero);

		let never = ActionRef();
		Test.Assert(!never.IsValid);
		Test.Assert(!runtime.IsDown(never));
	}

	/// Resolving the same name twice hands back the same handle rather than growing the
	/// table every frame a caller asks.
	[Test]
	public static void ResolvingTheSameNameTwiceIsTheSameHandle()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		Test.Assert(runtime.Resolve("Jump").Index == runtime.Resolve("Jump").Index);
	}

	[Test]
	public static void AdHocCompositionBuildsAnAxisAndAVector()
	{
		let map = new InputMap();
		defer delete map;
		let set = new ActionSet();
		set.Name.Set("S");
		map.Sets.Add(set);

		for (let pair in scope (StringView name, KeyCode key)[](
			("Left", .A), ("Right", .D), ("Back", .S), ("Forward", .W)))
		{
			let action = new InputAction();
			action.Name.Set(pair.name);
			action.Kind = .Button;
			action.Bindings.Add(InputTestMaps.Key(pair.key));
			set.Actions.Add(action);
		}

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let left = runtime.Resolve("Left");
		let right = runtime.Resolve("Right");
		let back = runtime.Resolve("Back");
		let forward = runtime.Resolve("Forward");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.D);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Axis(left, right), 1.0f));

		devices.FakeKeyboard.SetDown(.W);
		runtime.Update(devices, cStep);
		let vector = runtime.Vector2(left, right, back, forward);
		Test.Assert(Near(vector.X, 0.7071f), "clamped to length one, like a composite");
		Test.Assert(Near(vector.Y, 0.7071f));
	}

	[Test]
	public static void TheTimeScaleScalesFlaggedValuesAndLeavesThePressAlone()
	{
		let map = new InputMap();
		defer delete map;
		let set = new ActionSet();
		set.Name.Set("S");
		map.Sets.Add(set);

		for (let pair in scope (StringView name, bool scaled)[](("Scaled", true), ("Raw", false)))
		{
			let action = new InputAction();
			action.Name.Set(pair.name);
			action.Kind = .Axis1D;
			action.Bindings.Add(InputTestMaps.Key(.W));
			action.Processors.TimeScale = pair.scaled;
			set.Actions.Add(action);
		}

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let scaled = runtime.Resolve("Scaled");
		let raw = runtime.Resolve("Raw");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.W);

		runtime.SetTimeScale(0.25f);
		Test.Assert(runtime.TimeScale == 0.25f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(scaled), 0.25f));
		Test.Assert(Near(runtime.Value(raw), 1.0f), "an unflagged action is untouched");
		Test.Assert(runtime.IsDown(raw));

		// A paused world: the flagged VALUE is zero and the press is still a press,
		// because being held is physical and has nothing to do with the clock.
		runtime.SetTimeScale(0.0f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(scaled), 0.0f));
		Test.Assert(runtime.IsDown(scaled));

		// A negative scale is meaningless, so it clamps rather than inverting everything.
		runtime.SetTimeScale(-2.0f);
		Test.Assert(runtime.TimeScale == 0.0f);
	}

	[Test]
	public static void TheConsumptionMaskGatesDeviceClassesIndependently()
	{
		let map = new InputMap();
		defer delete map;
		let set = new ActionSet();
		set.Name.Set("G");
		map.Sets.Add(set);

		let jumpAction = new InputAction();
		jumpAction.Name.Set("Jump");
		jumpAction.Kind = .Button;
		jumpAction.Bindings.Add(InputTestMaps.Key(.Space));
		set.Actions.Add(jumpAction);

		let shootAction = new InputAction();
		shootAction.Name.Set("Shoot");
		shootAction.Kind = .Button;
		var button = Binding();
		button.Source = .MouseButton;
		button.Code = (.)MouseButton.Left;
		shootAction.Bindings.Add(button);
		set.Actions.Add(shootAction);

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");
		let shoot = runtime.Resolve("Shoot");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.Space);
		devices.FakeMouse.SetDown(.Left);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
		Test.Assert(runtime.IsDown(shoot));

		// A menu under the mouse eats the pointer. Movement on the keyboard keeps working,
		// which is the whole reason the classes are separate.
		runtime.SetConsumptionMask(.() { Pointer = true });
		Test.Assert(runtime.GetConsumptionMask().Pointer);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
		Test.Assert(!runtime.IsDown(shoot));

		// A focused text field eats the keyboard too.
		runtime.SetConsumptionMask(.() { Pointer = true, Keyboard = true });
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(!runtime.IsDown(shoot));

		// Cleared, both come back: consumption is a mask, not a latch.
		runtime.SetConsumptionMask(.());
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(jump));
		Test.Assert(runtime.IsDown(shoot));
	}

	[Test]
	public static void SmoothingRampsRecentresAndSnapsOnAFlip()
	{
		let map = new InputMap();
		defer delete map;
		let set = new ActionSet();
		set.Name.Set("S");
		map.Sets.Add(set);

		let throttle = new InputAction();
		throttle.Name.Set("Throttle");
		throttle.Kind = .Axis1D;
		throttle.Bindings.Add(InputTestMaps.Key(.W));
		var back = InputTestMaps.Key(.S);
		back.Scale = -1.0f;
		throttle.Bindings.Add(back);
		throttle.Processors.Sensitivity = 5.0f;  // 0.2s to full
		throttle.Processors.Gravity = 10.0f;     // 0.1s back to centre
		throttle.Processors.Snap = true;
		set.Actions.Add(throttle);

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let action = runtime.Resolve("Throttle");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.W);
		for (int i = 0; i < 6; i++)
			runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(action), 0.5f, 0.05f), "0.1s at 5/sec is half way");

		for (int i = 0; i < 12; i++)
			runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(action), 1.0f));

		// Snap: a reversal zeroes first rather than crossfading back through the middle.
		devices.FakeKeyboard.SetDown(.W, false);
		devices.FakeKeyboard.SetDown(.S);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.Value(action) <= 0.0f);

		// Gravity recentres faster than the ramp climbed.
		devices.FakeKeyboard.SetDown(.S, false);
		for (int i = 0; i < 8; i++)
			runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(action), 0.0f));
	}

	/// Smoothing is for axes. A button's press has no ramp, and one would only delay the
	/// edge a player is waiting on.
	[Test]
	public static void AButtonIsNeverSmoothed()
	{
		var key = InputTestMaps.Key(.Space);
		let map = InputTestMaps.Single("Act", .Button, key);
		defer delete map;
		map.Sets[0].Actions[0].Processors.Sensitivity = 1.0f;

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");

		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(act), "the press lands on the first frame regardless");
		Test.Assert(Near(runtime.Value(act), 1.0f));
	}

	/// The response curve keeps the sign and bends the magnitude, which is what a stick
	/// wants for aiming: fine control near the centre, full travel still available.
	[Test]
	public static void TheResponseCurveKeepsTheSign()
	{
		var axis = Binding();
		axis.Source = .GamepadAxis;
		axis.Code = (.)GamepadAxis.LeftX;
		axis.DeadZone = 0.0f;

		let map = InputTestMaps.Single("Look", .Axis1D, axis);
		defer delete map;
		map.Sets[0].Actions[0].Processors.ResponseExponent = 2.0f;

		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let look = runtime.Resolve("Look");

		let devices = scope FakeDevices();
		let pad = devices.AddPad();

		pad.SetAxis(.LeftX, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(look), 0.25f), "half deflection squared");

		pad.SetAxis(.LeftX, -0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(look), -0.25f), "and the direction survives it");

		pad.SetAxis(.LeftX, 1.0f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value(look), 1.0f), "full travel is still full travel");
	}

	/// A provider with no devices at all evaluates to released rather than crashing: an
	/// unfocused editor viewport hands over exactly this.
	[Test]
	public static void AProviderWithNoDevicesReadsReleased()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let jump = runtime.Resolve("Jump");
		let move = runtime.Resolve("Move");

		let devices = scope ShellInputSource(null);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(jump));
		Test.Assert(runtime.Value2D(move) == Float2.Zero);
		Test.Assert(devices.GamepadCount == 0);
		Test.Assert(devices.Keyboard == null);
		Test.Assert(devices.Events.IsEmpty);
	}
}
