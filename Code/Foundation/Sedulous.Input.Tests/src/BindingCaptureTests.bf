using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// Listening for the next physical input, for a rebind screen.
class BindingCaptureTests
{
	private static CaptureFilter KeysOnly()
	{
		var filter = CaptureFilter();
		filter.MouseButtons = false;
		filter.GamepadButtons = false;
		return filter;
	}

	[Test]
	public static void NothingActiveKeepsListening()
	{
		let devices = scope FakeDevices();
		devices.AddPad();
		Test.Assert(!BindingCapture.Capture(devices, KeysOnly(), var binding));
	}

	[Test]
	public static void AKeyPressCapturesAsAKeyBinding()
	{
		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetPressed(.F);

		Test.Assert(BindingCapture.Capture(devices, KeysOnly(), var binding));
		Test.Assert(binding.Source == .Key);
		Test.Assert(binding.Code == (uint32)KeyCode.F);
	}

	/// A rebind captures the PRESS edge, not the hold: a key still down from the click
	/// that opened the rebind screen must not bind itself.
	[Test]
	public static void AHeldKeyIsNotACapture()
	{
		let devices = scope FakeDevices();
		devices.FakeKeyboard.SetDown(.F);
		Test.Assert(!BindingCapture.Capture(devices, KeysOnly(), var binding));
	}

	/// Stick drift is ignored unless the screen asked for sticks, which is the whole
	/// reason the analog filters default off.
	[Test]
	public static void StickNoiseIsIgnoredUnlessAskedFor()
	{
		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetAxis(.RightX, 0.9f);

		Test.Assert(!BindingCapture.Capture(devices, KeysOnly(), var ignored));

		var sticks = CaptureFilter();
		sticks.Keys = false;
		sticks.MouseButtons = false;
		sticks.GamepadButtons = false;
		sticks.GamepadSticks = true;

		Test.Assert(BindingCapture.Capture(devices, sticks, var binding));
		Test.Assert(binding.Source == .GamepadStick);
		Test.Assert(binding.Code == (uint32)StickCode.Right);
	}

	/// And a stick barely off centre is not an activation either: the threshold is well
	/// above the press point precisely so drift never binds.
	[Test]
	public static void ASlightlyDeflectedStickIsNotAnActivation()
	{
		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetAxis(.LeftX, 0.5f);

		var sticks = CaptureFilter();
		sticks.Keys = false;
		sticks.MouseButtons = false;
		sticks.GamepadButtons = false;
		sticks.GamepadSticks = true;
		Test.Assert(!BindingCapture.Capture(devices, sticks, var binding));
	}

	[Test]
	public static void APadButtonCapturesWhileKeysAreFilteredOut()
	{
		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetPressed(.North);

		var filter = CaptureFilter();
		filter.Keys = false;
		filter.MouseButtons = false;

		Test.Assert(BindingCapture.Capture(devices, filter, var binding));
		Test.Assert(binding.Source == .GamepadButton);
		Test.Assert(binding.Code == (uint32)GamepadButton.North);
	}

	[Test]
	public static void AMouseButtonCaptures()
	{
		let devices = scope FakeDevices();
		devices.FakeMouse.SetPressed(.Right);

		Test.Assert(BindingCapture.Capture(devices, .(), var binding));
		Test.Assert(binding.Source == .MouseButton);
		Test.Assert(binding.Code == (uint32)MouseButton.Right);
	}

	/// An axis rebind opts in, and then a trigger past the threshold binds as an axis.
	[Test]
	public static void AnAxisCapturesOnlyWhenOptedIn()
	{
		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetAxis(.RightTrigger, 0.9f);

		var noAxes = CaptureFilter();
		noAxes.Keys = false;
		noAxes.MouseButtons = false;
		noAxes.GamepadButtons = false;
		Test.Assert(!BindingCapture.Capture(devices, noAxes, var ignored));

		var axes = noAxes;
		axes.GamepadAxes = true;
		Test.Assert(BindingCapture.Capture(devices, axes, var binding));
		Test.Assert(binding.Source == .GamepadAxis);
		Test.Assert(binding.Code == (uint32)GamepadAxis.RightTrigger);
	}

	/// A disconnected pad is not a source: it reports whatever it last held, and binding
	/// that would bind a ghost.
	[Test]
	public static void ADisconnectedPadCapturesNothing()
	{
		let devices = scope FakeDevices();
		let pad = devices.AddPad();
		pad.SetPressed(.South);
		pad.Connected = false;

		var filter = CaptureFilter();
		filter.Keys = false;
		filter.MouseButtons = false;
		Test.Assert(!BindingCapture.Capture(devices, filter, var binding));
	}

	/// A provider with no devices keeps listening rather than faulting.
	[Test]
	public static void NoDevicesKeepsListening()
	{
		let devices = scope ShellInputSource(null);
		var filter = CaptureFilter();
		filter.GamepadAxes = true;
		filter.GamepadSticks = true;
		Test.Assert(!BindingCapture.Capture(devices, filter, var binding));
	}
}
