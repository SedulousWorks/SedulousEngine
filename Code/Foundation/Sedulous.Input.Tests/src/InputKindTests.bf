using System;
using System.Collections;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// The input kind in use: the pointer, the keyboard or a pad, from deliberate input only, with
/// a change told to listeners.
class InputKindTests
{
	/// One frame's devices: each test sets this frame's edges, then the tracker reads them.
	private class Bed
	{
		public FakeDevices Devices = new .() ~ delete _;
		public FakeGamepad Pad;
		public InputKindTracker Tracker = new .() ~ delete _;

		public this()
		{
			Pad = Devices.AddPad();
		}

		/// The edges of the last frame end, as the shell's pump ends them.
		public void NextFrame()
		{
			for (uint32 code < (uint32)KeyCode.Count)
				Devices.FakeKeyboard.SetPressed((KeyCode)code, false);
			for (uint32 code < (uint32)MouseButton.Count)
				Devices.FakeMouse.SetPressed((MouseButton)code, false);
			for (uint32 code < (uint32)GamepadButton.Count)
				Pad.SetPressed((GamepadButton)code, false);
			Devices.FakeMouse.DeltaX = 0.0f;
			Devices.FakeMouse.DeltaY = 0.0f;
			Devices.FakeMouse.ScrollY = 0.0f;
		}

		public InputKind Frame()
		{
			Tracker.Update(Devices);
			NextFrame();
			return Tracker.Kind;
		}

		public void Press(KeyCode key) => Devices.FakeKeyboard.SetPressed(key);
		public void PressPad(GamepadButton button) => Pad.SetPressed(button);
		public void Click() => Devices.FakeMouse.SetPressed(.Left);
	}

	[Test]
	public static void ItStartsAsThePointerAndFollowsAKeyAPadButtonAndAClick()
	{
		let bed = scope Bed();
		Test.Assert(bed.Tracker.Kind == .Pointer);
		bed.Press(.A);
		Test.Assert(bed.Frame() == .Keyboard);
		bed.PressPad(.South);
		Test.Assert(bed.Frame() == .Pad);
		Test.Assert(bed.Frame() == .Pad, "nothing new: it stays");
		bed.Click();
		Test.Assert(bed.Frame() == .Pointer);
	}

	[Test]
	public static void TheMouseCountsPastAFewPixelsOrAWheelTurnNotANudge()
	{
		let bed = scope Bed();
		bed.Tracker.SetKind(.Pad);
		bed.Devices.FakeMouse.DeltaX = 1.0f;
		bed.Devices.FakeMouse.DeltaY = 1.0f;
		Test.Assert(bed.Frame() == .Pad);
		bed.Devices.FakeMouse.DeltaX = 6.0f;
		Test.Assert(bed.Frame() == .Pointer);
		bed.Tracker.SetKind(.Keyboard);
		bed.Devices.FakeMouse.ScrollY = 1.0f;
		Test.Assert(bed.Frame() == .Pointer);
	}

	[Test]
	public static void AStickCountsWhenPushedPastThePressPointNotWhileItRestsOrStaysHeldThere()
	{
		let bed = scope Bed();
		bed.Pad.SetAxis(.LeftX, 0.2f); // drift
		Test.Assert(bed.Frame() == .Pointer);
		bed.Pad.SetAxis(.LeftX, 0.9f); // pushed
		Test.Assert(bed.Frame() == .Pad);
		bed.Click();
		Test.Assert(bed.Frame() == .Pointer);
		Test.Assert(bed.Frame() == .Pointer, "still held past it: not a fresh push");
		bed.Pad.SetAxis(.LeftX, 0.0f);
		Test.Assert(bed.Frame() == .Pointer);
		bed.Pad.SetAxis(.RightTrigger, 1.0f); // a trigger too
		Test.Assert(bed.Frame() == .Pad);
	}

	[Test]
	public static void InOneFrameAPressOutranksMotionAPadTheKeyboardTheKeyboardTheMouse()
	{
		let bed = scope Bed();
		bed.Press(.W);
		bed.Devices.FakeMouse.DeltaX = 40.0f;
		Test.Assert(bed.Frame() == .Keyboard);
		bed.Press(.W);
		bed.PressPad(.East);
		Test.Assert(bed.Frame() == .Pad);
		bed.Click();
		bed.Press(.Space);
		Test.Assert(bed.Frame() == .Keyboard);
	}

	[Test]
	public static void AFingerPutDownIsThePointerAndOneHeldIsNotAgain()
	{
		let bed = scope Bed();
		bed.Tracker.SetKind(.Pad);
		bed.Devices.FakeTouch.Set(1, 0.5f, 0.5f);
		Test.Assert(bed.Frame() == .Pointer);
		bed.Tracker.SetKind(.Pad);
		Test.Assert(bed.Frame() == .Pad, "still down: nothing new");
	}

	[Test]
	public static void ListenersHearEachChangeOnceAndOneMayLeaveFromInside()
	{
		let bed = scope Bed();
		let heard = scope List<InputKind>();
		uint32 token = 0;
		bool removed = false;
		token = bed.Tracker.AddListener(new [&](kind) =>
			{
				heard.Add(kind);
				if (kind == .Pointer)
					removed = bed.Tracker.RemoveListener(token);
			});
		// One after it still hears the change the first left during.
		let after = scope List<InputKind>();
		bed.Tracker.AddListener(new [&](kind) => after.Add(kind));
		bed.PressPad(.South);
		bed.Frame();
		bed.PressPad(.South);
		bed.Frame(); // the same kind: no change
		bed.Click();
		bed.Frame();
		bed.Press(.A);
		bed.Frame(); // it left
		Test.Assert(removed);
		Test.Assert(heard.Count == 2);
		Test.Assert(heard[0] == .Pad);
		Test.Assert(heard[1] == .Pointer);
		Test.Assert(after.Count == 3);
		Test.Assert(after[1] == .Pointer);
		Test.Assert(!bed.Tracker.RemoveListener(token));
		Test.Assert(InputKind.Pad.Name == "pad");
		Test.Assert(InputKind.Keyboard.Name == "keyboard");
		Test.Assert(InputKind.Pointer.Name == "pointer");
	}

	[Test]
	public static void ADisconnectedPadCountsForNothing()
	{
		let bed = scope Bed();
		bed.Pad.Connected = false;
		bed.PressPad(.South);
		Test.Assert(bed.Frame() == .Pointer);
	}

	/// What `binding` reads as, for the asserts.
	private static void Describe(Binding? binding, String outName)
	{
		if (binding.HasValue)
			BindingNames.DescribeBinding(binding.Value, outName);
	}

	[Test]
	public static void AnActionShowsItsBindingForTheDeviceInHandElseItsFirst()
	{
		let runtime = scope ActionRuntime();
		let map = InputTestMaps.Gameplay(); // Jump: Space, then the pad's south button
		defer delete map;
		runtime.SetMap(map);
		runtime.DisableSet("Menu");

		Test.Assert(ShownBinding.For(runtime, "Jump", "", .Keyboard).HasValue);
		Test.Assert(Describe(ShownBinding.For(runtime, "Jump", "", .Keyboard), .. scope .()) == "Space");
		Test.Assert(Describe(ShownBinding.For(runtime, "Jump", "", .Pad), .. scope .()) == "Pad South");
		// The pointer has no keys of its own: it shows the keyboard's.
		Test.Assert(Describe(ShownBinding.For(runtime, "Jump", "", .Pointer), .. scope .()) == "Space");

		// An action with no binding of the kind in hand shows its first; an unknown one shows none.
		runtime.EnableSet("Menu");
		let confirm = ShownBinding.For(runtime, "Confirm", "", .Pad);
		Test.Assert(confirm.HasValue);
		Test.Assert(Describe(confirm, .. scope .()) == "Space");
		Test.Assert(!ShownBinding.For(runtime, "Fly", "", .Keyboard).HasValue);
		Test.Assert(!ShownBinding.For(runtime, "", "", .Keyboard).HasValue);
		Test.Assert(!ShownBinding.For(null, "Jump", "", .Keyboard).HasValue);

		// Named, a set is read whether enabled or not; unnamed, only an enabled set is.
		runtime.DisableSet("Menu");
		Test.Assert(!ShownBinding.For(runtime, "Confirm", "", .Keyboard).HasValue);
		Test.Assert(ShownBinding.For(runtime, "Confirm", "Menu", .Keyboard).HasValue);

		var stick = Binding();
		stick.Source = .GamepadStick;
		Test.Assert(ShownBinding.KindOf(stick) == .Pad);
		var touch = Binding();
		touch.Source = .TouchButton;
		Test.Assert(ShownBinding.KindOf(touch) == .Pointer);
		var mouse = Binding();
		mouse.Source = .MouseButton;
		Test.Assert(ShownBinding.KindOf(mouse) == .Keyboard);
	}
}
