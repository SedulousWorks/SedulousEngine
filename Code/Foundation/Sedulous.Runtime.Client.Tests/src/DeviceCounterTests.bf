using System;
using Sedulous.Profiler;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Runtime.Client;

namespace Sedulous.Runtime.Client.Tests;

/// The device's counts to the profiler once a frame, on the Null device (which counts what it
/// is asked to do): a frame's counters are what that frame recorded (the differences of the
/// device's totals), memory is what is held now, and a device without a driver budget publishes
/// none.
class DeviceCounterTests
{
	/// The value a frame's record holds for the counter named `name`, or -1 when it holds none.
	private static double CounterIn(Profiler p, FrameRecord frame, StringView name)
	{
		for (let value in frame.Counters)
		{
			if (p.Counters[value.Counter].Name == name)
				return value.Value;
		}
		return -1.0;
	}

	private static void DrawFrame(IDevice device, uint32 draws)
	{
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var encoder = pool.CreateEncoder().Value;
		defer pool.DestroyEncoder(ref encoder);
		let pass = encoder.BeginRenderPass(.());
		for (uint32 i < draws)
			pass.Draw(3, 1, 0, 0);
		pass.End();
	}

	[Test]
	public static void AFramesCountersAreWhatItRecordedMemoryWhatIsHeld()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		let p = scope Profiler();
		let publisher = scope DeviceCounterPublisher();
		p.Arm();

		DrawFrame(device, 5); // before the first publish: not any frame's
		p.BeginFrame();
		publisher.Publish(device, p);
		p.EndFrame();
		Test.Assert(CounterIn(p, p.LatestFrame, "Draws") == -1.0, "no earlier totals yet");
		Test.Assert(CounterIn(p, p.LatestFrame, "Buffer memory") == 0.0);

		p.BeginFrame();
		DrawFrame(device, 3);
		var bufferDesc = BufferDesc();
		bufferDesc.Size = 2048;
		var buffer = device.CreateBuffer(bufferDesc).Value;
		defer device.DestroyBuffer(ref buffer);
		publisher.Publish(device, p);
		p.EndFrame();
		Test.Assert(CounterIn(p, p.LatestFrame, "Draws") == 3.0);
		Test.Assert(CounterIn(p, p.LatestFrame, "Render passes") == 1.0);
		Test.Assert(CounterIn(p, p.LatestFrame, "Buffer memory") == 2048.0);

		p.BeginFrame();
		publisher.Publish(device, p);
		p.EndFrame();
		Test.Assert(CounterIn(p, p.LatestFrame, "Draws") == 0.0);
		Test.Assert(CounterIn(p, p.LatestFrame, "Buffer memory") == 2048.0, "still held");
		Test.Assert(CounterIn(p, p.LatestFrame, "GPU memory budget") == -1.0, "Null has no driver");
	}
}
