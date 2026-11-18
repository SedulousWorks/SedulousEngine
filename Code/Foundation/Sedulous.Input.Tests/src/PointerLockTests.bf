using System;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// A pointer lock is asked of the runtime and reaches the mouse through the next update's
/// devices, as a rumble reaches its pad.
class PointerLockTests
{
	private const float cStep = 1.0f / 60.0f;

	[Test]
	public static void APointerLockWaitsForTheNextUpdateHoldsUntilFreedAndReadsWhatTheHostGrants()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let devices = scope FakeDevices();
		let mouse = devices.FakeMouse;

		// Asked between frames: the mouse is told at the next update, and hides.
		runtime.SetPointerLock(true);
		Test.Assert(!mouse.Relative);
		Test.Assert(!runtime.PointerLocked);
		runtime.Update(devices, cStep);
		Test.Assert(mouse.Relative);
		Test.Assert(!mouse.Visible);
		Test.Assert(runtime.PointerLocked);

		// Held: later updates tell the mouse nothing more.
		runtime.Update(devices, cStep);
		Test.Assert(mouse.RelativeCalls == 1, scope $"{mouse.RelativeCalls} calls");

		// The host ends the lock (a browser's Escape): it reads unlocked while still asked, and the
		// runtime does not fight the host for it.
		mouse.Relative = false;
		runtime.Update(devices, cStep);
		Test.Assert(!runtime.PointerLocked);
		Test.Assert(runtime.PointerLockApplied);
		Test.Assert(!mouse.Relative);

		// Freed: the mouse is told and shows again.
		mouse.Relative = true;
		runtime.SetPointerLock(false);
		runtime.Update(devices, cStep);
		Test.Assert(!mouse.Relative);
		Test.Assert(mouse.Visible);
		Test.Assert(!runtime.PointerLocked);

		// A run's end frees the devices and forgets the ask.
		runtime.SetPointerLock(true);
		runtime.Update(devices, cStep);
		Test.Assert(mouse.Relative);
		ActionRuntime.ReleasePointerLock(devices);
		runtime.ResetPointerLock();
		Test.Assert(!mouse.Relative);
		Test.Assert(mouse.Visible);
		runtime.Update(devices, cStep);
		Test.Assert(!mouse.Relative);
		Test.Assert(!runtime.PointerLockApplied);
	}

	/// A host that swaps its devices while a lock holds (the editor's scripted input for a test
	/// run, in and out): the new mouse is locked as asked, so the lock does not read as ended by
	/// the host.
	[Test]
	public static void APointerLockFollowsTheHostOntoAnotherMouse()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let first = scope FakeDevices();
		let second = scope FakeDevices();

		runtime.SetPointerLock(true);
		runtime.Update(first, cStep);
		Test.Assert(runtime.PointerLocked);

		runtime.Update(second, cStep);
		Test.Assert(second.FakeMouse.Relative);
		Test.Assert(!second.FakeMouse.Visible);
		Test.Assert(runtime.PointerLocked);

		// Freed on the second and back on the first: the first is freed too.
		runtime.SetPointerLock(false);
		runtime.Update(second, cStep);
		Test.Assert(!second.FakeMouse.Relative);
		runtime.Update(first, cStep);
		Test.Assert(!first.FakeMouse.Relative);
		Test.Assert(first.FakeMouse.Visible);

		// A runtime that never locked leaves a new mouse as it is.
		let other = scope ActionRuntime();
		other.SetMap(map);
		let third = scope FakeDevices();
		third.FakeMouse.Relative = true;
		other.Update(first, cStep);
		other.Update(third, cStep);
		Test.Assert(third.FakeMouse.Relative);
	}
}
