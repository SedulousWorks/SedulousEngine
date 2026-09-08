using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// The touch sources, which are the only ones carrying per action state: a virtual stick
/// has to remember which finger owns it and where that finger landed.
class TouchBindingTests
{
	private const float cStep = 1.0f / 60.0f;

	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	/// Fire on the bottom right quadrant, Move as a floating stick on the left half.
	private static InputMap TouchMap()
	{
		let map = new InputMap();
		let set = new ActionSet();
		set.Name.Set("S");
		map.Sets.Add(set);

		let fire = new InputAction();
		fire.Name.Set("Fire");
		fire.Kind = .Button;
		var region = Binding();
		region.Source = .TouchButton;
		region.RegionX = 0.5f;
		region.RegionY = 0.5f;
		region.RegionW = 0.5f;
		region.RegionH = 0.5f;
		fire.Bindings.Add(region);
		set.Actions.Add(fire);

		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		var stick = Binding();
		stick.Source = .TouchStick;
		stick.RegionX = 0.0f;
		stick.RegionY = 0.0f;
		stick.RegionW = 0.5f;
		stick.RegionH = 1.0f;
		stick.StickRadius = 0.1f;
		stick.DeadZone = 0.1f;
		move.Bindings.Add(stick);
		set.Actions.Add(move);

		return map;
	}

	[Test]
	public static void TheTouchMapIsWellFormed()
	{
		let map = TouchMap();
		defer delete map;
		let error = scope String();
		Test.Assert(InputMapValidation.Validate(map, error), error);

		// And the kinds are still enforced: a stick is not a button.
		var wrong = Binding();
		wrong.Source = .TouchStick;
		map.Sets[0].Actions[0].Bindings.Add(wrong);
		Test.Assert(!InputMapValidation.Validate(map));
	}

	[Test]
	public static void ARegionButtonOnlyFiresInsideItsRegion()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let fire = runtime.Resolve("Fire");
		let devices = scope FakeDevices();

		devices.FakeTouch.Set(1, 0.2f, 0.2f);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(fire));

		devices.FakeTouch.Set(1, 0.8f, 0.8f);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(fire));
		Test.Assert(runtime.WasPressed(fire));

		devices.FakeTouch.Remove(1);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(fire));
		Test.Assert(runtime.WasReleased(fire));
	}

	/// The stick anchors where the finger LANDED, deflects over its radius, and clamps at
	/// full. Anchoring on the finger rather than on the art is what makes one usable
	/// without looking down at it.
	[Test]
	public static void AFloatingStickAnchorsDeflectsAndClamps()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let move = runtime.Resolve("Move");
		let devices = scope FakeDevices();

		devices.FakeTouch.Set(2, 0.25f, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 0.0f), "the anchor IS the position");

		// Half the radius out, minus what the dead zone takes off the bottom.
		devices.FakeTouch.Set(2, 0.30f, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.Value2D(move).X > 0.30f);
		Test.Assert(runtime.Value2D(move).X < 0.60f);

		devices.FakeTouch.Set(2, 0.60f, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 1.0f), "way past the radius is still full");
		Test.Assert(Near(runtime.Value2D(move).Y, 0.0f));

		devices.FakeTouch.Remove(2);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 0.0f), "and it lets go when the finger does");
	}

	/// A finger that wanders in re-anchors where it entered, so it never arrives already
	/// deflected: the value starts at zero either way.
	[Test]
	public static void AFingerEnteringTheRegionAnchorsWhereItEntered()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let move = runtime.Resolve("Move");
		let devices = scope FakeDevices();

		devices.FakeTouch.Set(3, 0.9f, 0.9f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 0.0f));

		devices.FakeTouch.Set(3, 0.25f, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(Near(runtime.Value2D(move).X, 0.0f), "no jump on the frame it arrived");

		devices.FakeTouch.Set(3, 0.35f, 0.5f);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.Value2D(move).X > 0.0f, "and it deflects from there");
	}

	/// A second finger does not steal a stick that is already owned. The contact id is
	/// what makes a two thumb layout work at all.
	[Test]
	public static void AStickKeepsItsOwnFingerWhileAnotherIsDown()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let move = runtime.Resolve("Move");
		let fire = runtime.Resolve("Fire");
		let devices = scope FakeDevices();

		devices.FakeTouch.Set(1, 0.20f, 0.5f);
		runtime.Update(devices, cStep);
		devices.FakeTouch.Set(1, 0.30f, 0.5f);
		devices.FakeTouch.Set(2, 0.10f, 0.9f);
		runtime.Update(devices, cStep);

		let deflected = runtime.Value2D(move).X;
		Test.Assert(deflected > 0.0f, "the first finger still owns the stick");

		// And the other thumb drives the button at the same time.
		devices.FakeTouch.Set(2, 0.80f, 0.80f);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(fire));
		Test.Assert(runtime.Value2D(move).X > 0.0f);
	}

	/// No touch device at all: released, and the anchor is dropped rather than kept for a
	/// contact that ended in another session.
	[Test]
	public static void NoTouchDeviceReadsReleased()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let move = runtime.Resolve("Move");
		let fire = runtime.Resolve("Fire");

		let devices = scope ShellInputSource(null);
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(fire));
		Test.Assert(runtime.Value2D(move) == Float2.Zero);
	}

	/// Touch is a POINTER class, so a menu eating the pointer mutes it the same way it
	/// mutes the mouse.
	[Test]
	public static void TouchIsGatedByThePointerConsumption()
	{
		let map = TouchMap();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let fire = runtime.Resolve("Fire");
		let devices = scope FakeDevices();

		devices.FakeTouch.Set(1, 0.8f, 0.8f);
		runtime.Update(devices, cStep);
		Test.Assert(runtime.IsDown(fire));

		runtime.SetConsumptionMask(.() { Pointer = true });
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.IsDown(fire));
	}
}
