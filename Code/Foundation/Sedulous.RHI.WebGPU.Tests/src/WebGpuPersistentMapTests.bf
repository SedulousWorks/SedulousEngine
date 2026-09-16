using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// Persistent mapping proven ON THE GPU rather than through the shadow.
///
/// The RHI's Map contract is Vulkan's: map once, hold the pointer, write per frame, never
/// Unmap. WebGPU has no such mapping, so the shadow flushes OPEN mappings before every
/// submit - and the only way to know that works is to read the bytes back.
class WebGpuPersistentMapTests
{
	[Test]
	public static void WritesThroughAHeldPointerReachTheGpu()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		var uboDesc = BufferDesc();
		uboDesc.Size = 64;
		uboDesc.Usage = .Uniform | .CopySrc;
		uboDesc.Memory = .CpuToGpu;
		var ubo = device.CreateBuffer(uboDesc).GetValueOrDefault();
		Test.Assert(ubo != null);

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 64;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		let persistent = (uint8*)ubo.Map(); // NEVER unmapped
		Test.Assert(persistent != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();

		for (uint64 frame = 1; frame <= 3; frame++)
		{
			let value = (uint8)(frame * 17);
			Internal.MemSet(persistent, value, 64); // through the HELD pointer

			var encoder = pool.CreateEncoder().GetValueOrDefault();
			encoder.CopyBufferToBuffer(ubo, 0, readback, 0, 64);
			ICommandBuffer[1] submitted = .(encoder.Finish());
			queue.Submit(.(&submitted[0], 1), fence, frame);
			Test.Assert(fence.Wait(frame, uint64.MaxValue));

			let bytes = (uint8*)readback.Map();
			Test.Assert(bytes != null);
			Test.Assert(bytes[0] == value, "this frame's write arrived");
			Test.Assert(bytes[63] == value);
			readback.Unmap();

			pool.DestroyEncoder(ref encoder);
		}

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyBuffer(ref ubo);
		device.Destroy();
	}

	/// The coherence flush SKIPS a re upload when the shadow is byte identical to the last
	/// one. On web every write crosses the wasm to JS boundary, so re uploading every open
	/// shadow on every submit would dominate the frame.
	///
	/// WebGpuBufferTests pins the skip itself. This pins that the GPU still holds the right
	/// bytes ACROSS the skipped flushes, which is the half a counter cannot show.
	[Test]
	public static void ASkippedFlushLeavesTheGpuHoldingTheRightBytes()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		var uboDesc = BufferDesc();
		uboDesc.Size = 64;
		uboDesc.Usage = .Uniform | .CopySrc;
		uboDesc.Memory = .CpuToGpu;
		var ubo = device.CreateBuffer(uboDesc).GetValueOrDefault();
		Test.Assert(ubo != null);
		let wgpuUbo = (WebGpuBuffer)ubo;

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 64;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		let persistent = (uint8*)ubo.Map(); // held open, never unmapped
		Test.Assert(persistent != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();

		// Frame 1: the first write reaches the GPU, so exactly one upload.
		Internal.MemSet(persistent, 0x11, 64);
		SubmitCopy(queue, pool, fence, ubo, readback, 1);
		Test.Assert(wgpuUbo.UploadCount == 1);

		// Frames 2 to 4: the shadow is untouched, so the flush skips every time.
		SubmitCopy(queue, pool, fence, ubo, readback, 2);
		SubmitCopy(queue, pool, fence, ubo, readback, 3);
		SubmitCopy(queue, pool, fence, ubo, readback, 4);
		Test.Assert(wgpuUbo.UploadCount == 1, "three redundant re uploads elided");

		// And the GPU still holds frame 1's bytes despite those skipped flushes.
		var bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[0] == 0x11);
		Test.Assert(bytes[63] == 0x11);
		readback.Unmap();

		// Frame 5: a real change uploads again, and the new data lands.
		Internal.MemSet(persistent, 0x22, 64);
		SubmitCopy(queue, pool, fence, ubo, readback, 5);
		Test.Assert(wgpuUbo.UploadCount == 2);

		bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[0] == 0x22);
		Test.Assert(bytes[63] == 0x22);
		readback.Unmap();

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyBuffer(ref ubo);
		device.Destroy();
	}

	/// One submit that copies the ubo into the readback AND triggers the shadow flush.
	/// A free method rather than a local one, Beef local methods not closing over locals.
	private static void SubmitCopy(IQueue queue, ICommandPool pool, IFence fence, IBuffer ubo,
		IBuffer readback, uint64 frame)
	{
		var encoder = pool.CreateEncoder().GetValueOrDefault();
		encoder.CopyBufferToBuffer(ubo, 0, readback, 0, 64);
		ICommandBuffer[1] submitted = .(encoder.Finish());
		queue.Submit(.(&submitted[0], 1), fence, frame);
		Test.Assert(fence.Wait(frame, uint64.MaxValue));
		pool.DestroyEncoder(ref encoder);
	}
}
