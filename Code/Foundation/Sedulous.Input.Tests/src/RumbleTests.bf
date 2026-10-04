using System;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// A rumble is asked of the runtime and reaches a pad through the next update's devices.
class RumbleTests
{
	private const float cStep = 1.0f / 60.0f;

	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.001f;

	[Test]
	public static void ARumbleWaitsForTheNextUpdateAndReachesItsPadThroughThatFramesDevices()
	{
		let map = InputTestMaps.Gameplay();
		defer delete map;
		let runtime = scope ActionRuntime();
		runtime.SetMap(map);
		let devices = scope FakeDevices();
		let pad0 = devices.AddPad();
		let pad1 = devices.AddPad();

		// Asked between frames: nothing reaches a pad until the update that has the devices.
		runtime.Rumble(1, 0.8f, 0.4f, 0.25f);
		Test.Assert(pad1.RumbleCalls == 0);
		runtime.Update(devices, cStep);
		Test.Assert(pad1.RumbleCalls == 1);
		Test.Assert(Near(pad1.RumbleLow, 0.8f));
		Test.Assert(Near(pad1.RumbleHigh, 0.4f));
		Test.Assert(pad1.RumbleMs == 250);
		Test.Assert(pad0.RumbleCalls == 0, "only the pad asked for");

		// Applied once: the next update asks nothing more.
		runtime.Update(devices, cStep);
		Test.Assert(pad1.RumbleCalls == 1);

		// A later request for the same pad replaces the waiting one; the motors clamp to 0..1.
		runtime.Rumble(0, 0.2f, 0.2f, 1.0f);
		runtime.Rumble(0, 2.0f, -1.0f, 0.1f);
		runtime.Update(devices, cStep);
		Test.Assert(pad0.RumbleCalls == 1);
		Test.Assert(Near(pad0.RumbleLow, 1.0f));
		Test.Assert(Near(pad0.RumbleHigh, 0.0f));
		Test.Assert(pad0.RumbleMs == 100);

		// A pad that is not there is skipped; StopRumble stops every pad and drops what was
		// waiting.
		runtime.Rumble(5, 1.0f, 1.0f, 1.0f);
		runtime.Rumble(0, 1.0f, 1.0f, 1.0f);
		runtime.StopRumble();
		runtime.Update(devices, cStep);
		Test.Assert(Near(pad0.RumbleLow, 0.0f));
		Test.Assert(pad0.RumbleMs == 0);
		Test.Assert(Near(pad1.RumbleLow, 0.0f));

		// The run's end has no update to wait for: the helper stops every pad of its source at
		// once.
		pad0.RumbleLow = 0.5f;
		ActionRuntime.StopAllRumble(devices);
		Test.Assert(Near(pad0.RumbleLow, 0.0f));
	}
}
