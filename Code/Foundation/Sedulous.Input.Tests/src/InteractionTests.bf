using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// The press state machines, so a game does not write the same timing logic for every
/// ability it has.
class InteractionTests
{
	private const float cStep = 1.0f / 60.0f;

	private static InputMap Button(InteractionKind kind, float seconds)
	{
		let map = InputTestMaps.Single("Act", .Button, InputTestMaps.Key(.Space));
		map.Sets[0].Actions[0].Interaction.Kind = kind;
		map.Sets[0].Actions[0].Interaction.Seconds = seconds;
		return map;
	}

	/// Hold: nothing until the threshold, then a single edge and a press that STAYS down
	/// rather than pulsing on the one frame that crossed it.
	[Test]
	public static void AHoldWaitsForItsThresholdAndThenStaysDown()
	{
		let map = Button(.Hold, 0.2f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.Space);
		for (int i = 0; i < 6; i++)
		{
			runtime.Update(devices, cStep);
			Test.Assert(!runtime.IsDown(act), "0.1s is not 0.2s");
		}

		var edged = false;
		for (int i = 0; i < 8; i++)
		{
			runtime.Update(devices, cStep);
			edged = edged || runtime.WasPressed(act);
		}
		Test.Assert(edged, "exactly one edge, once the threshold was crossed");
		Test.Assert(runtime.IsDown(act));

		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(act), "and it does not fall back off while still held");
		Test.Assert(!runtime.WasPressed(act));

		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(act));
		Test.Assert(runtime.WasReleased(act));
	}

	/// Releasing a hold before its threshold rearms it: the next press starts from zero
	/// rather than inheriting the time already spent.
	[Test]
	public static void AnAbandonedHoldRestartsItsClock()
	{
		let map = Button(.Hold, 0.2f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.Space);
		for (int i = 0; i < 10; i++)
			runtime.Update(devices, cStep);
		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);

		devices.FakeKeyboard.SetDown(.Space);
		for (int i = 0; i < 6; i++)
		{
			runtime.Update(devices, cStep);
			Test.Assert(!runtime.IsDown(act), "the abandoned 0.16s did not carry over");
		}
	}

	/// Tap: a pulse at RELEASE and only if the press was short. A tap cannot be recognised
	/// while it is still going on, which is why it fires late rather than early.
	[Test]
	public static void ATapPulsesOnceAtReleaseAndOnlyIfItWasShort()
	{
		let map = Button(.Tap, 0.15f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.Space);
		for (int i = 0; i < 4; i++)
		{
			runtime.Update(devices, cStep);
			Test.Assert(!runtime.IsDown(act), "nothing fires while the finger is still down");
		}

		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.WasPressed(act));
		Test.Assert(runtime.IsDown(act));

		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(act), "one frame, then gone");
		Test.Assert(runtime.WasReleased(act));

		// A long press is not a tap, and produces nothing at all.
		devices.FakeKeyboard.SetDown(.Space);
		for (int i = 0; i < 20; i++)
			runtime.Update(devices, cStep);
		devices.FakeKeyboard.SetDown(.Space, false);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.WasPressed(act));
		Test.Assert(!runtime.IsDown(act));
	}

	/// DoubleTap: the pulse is on the SECOND press, and only if it lands inside the window.
	[Test]
	public static void ADoubleTapFiresOnTheSecondPressInsideTheWindow()
	{
		let map = Button(.DoubleTap, 0.25f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		bool Tap(int gapFrames)
		{
			devices.FakeKeyboard.SetDown(.Space);
			runtime.Update(devices, cStep);
			let fired = runtime.WasPressed(act);

			devices.FakeKeyboard.SetDown(.Space, false);
			runtime.Update(devices, cStep);
			for (int i = 0; i < gapFrames; i++)
				runtime.Update(devices, cStep);
			return fired;
		}

		Test.Assert(!Tap(2), "the first tap only arms the window");
		Test.Assert(Tap(2), "the second inside it fires");
		Test.Assert(!Tap(30), "the pair was consumed, so this arms again");
		Test.Assert(!Tap(30), "and a tap outside the window never completes a pair");
	}

	/// None passes the press straight through, which is what most actions want.
	[Test]
	public static void NoInteractionPassesThePressThrough()
	{
		let map = Button(.None, 0.3f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(act));
		Test.Assert(runtime.WasPressed(act));
	}

	/// An interaction reshapes the reported PRESS, not the value: a hold below its
	/// threshold still reports the physical value, which is what a charge meter reads.
	[Test]
	public static void AnInteractionShapesThePressNotTheValue()
	{
		let map = Button(.Hold, 0.2f);
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let act = runtime.Resolve("Act");
		let devices = scope FakeDevices();

		devices.FakeKeyboard.SetDown(.Space);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(act));
		Test.Assert(runtime.Value(act) == 1.0f);
	}
}
