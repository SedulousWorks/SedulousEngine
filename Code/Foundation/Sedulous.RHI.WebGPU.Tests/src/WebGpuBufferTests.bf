using System;
using wgpu_Beef;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The Map emulation, which is what makes WebGPU keep the RHI's Vulkan shaped contract.
///
/// These go straight at the buffer with a device made here, rather than waiting for the
/// RHI device wrapper, because the behaviour they pin is the buffer's own.
class WebGpuBufferTests
{
	/// A backend, its first adapter, and a raw device from it. Null when this machine
	/// has no usable WebGPU, which every case treats as a skip.
	private static WGPUDevice RequestDevice(WebGpuBackend backend)
	{
		if (backend.Initialize() case .Err)
			return null;

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;

		let adapter = (WebGpuAdapter)adapters[0];

		WGPUDevice device = null;
		var done = false;

		WGPURequestDeviceCallbackInfo callback = .();
		callback.mode = WebGpuApi.cCallbackMode;
		callback.callback = (status, got, message, userdata1, userdata2) =>
			{
				*(WGPUDevice*)userdata1 = (status == .WGPURequestDeviceStatus_Success) ? got : null;
				*(bool*)userdata2 = true;
			};
		callback.userdata1 = &device;
		callback.userdata2 = &done;

		WGPUDeviceDescriptor desc = .();
		wgpuAdapterRequestDevice(adapter.Handle, &desc, callback);
		WebGpuApi.PumpUntil(backend.Instance, ref done);

		return device;
	}

	/// A CpuToGpu buffer hands back a CPU shadow, and the pointer STAYS VALID across
	/// frames: that is the persistent half of the contract, and the reason the shadow
	/// exists rather than a real mapping.
	[Test]
	public static void ACpuToGpuMapIsAPersistentShadow()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let queue = wgpuDeviceGetQueue(device);
		defer wgpuQueueRelease(queue);

		let buffer = scope WebGpuBuffer();
		let desc = BufferDesc() { Size = 256, Usage = .Uniform, Memory = .CpuToGpu };
		Test.Assert(buffer.Initialize(backend.Instance, device, queue, desc) case .Ok);

		let first = buffer.Map();
		Test.Assert(first != null, "a CpuToGpu buffer maps");

		let second = buffer.Map();
		Test.Assert(second == first, "and maps to the SAME pointer, being a held shadow");
	}

	/// The upload skip. Flushing a shadow the GPU already holds must not issue a queue
	/// write, because on web every one of those marshals a copy across the wasm to JS
	/// boundary and re-sending unchanged persistent buffers every submit was the
	/// dominant frame cost.
	[Test]
	public static void FlushingAnUnchangedShadowIssuesNoUpload()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let queue = wgpuDeviceGetQueue(device);
		defer wgpuQueueRelease(queue);

		let buffer = scope WebGpuBuffer();
		let desc = BufferDesc() { Size = 256, Usage = .Uniform, Memory = .CpuToGpu };
		Test.Assert(buffer.Initialize(backend.Instance, device, queue, desc) case .Ok);

		let shadow = (uint8*)buffer.Map();
		Test.Assert(shadow != null);

		for (int i = 0; i < 256; i++)
			shadow[i] = (uint8)i;

		buffer.Unmap();
		let afterFirst = buffer.UploadCount;
		Test.Assert(afterFirst == 1, "the first flush uploaded");

		// Nothing changed, so every later flush is skipped outright.
		buffer.Map();
		buffer.Unmap();
		buffer.Map();
		buffer.Unmap();
		Test.Assert(buffer.UploadCount == afterFirst,
			scope $"unchanged flushes uploaded again: {buffer.UploadCount} vs {afterFirst}");

		// One changed byte is enough to send it.
		let again = (uint8*)buffer.Map();
		again[0] = 0xFF;
		buffer.Unmap();
		Test.Assert(buffer.UploadCount == afterFirst + 1, "a changed shadow uploaded");
	}

	/// FlushRange is the RING's shape: a large buffer of which one frame writes a small
	/// window. It uploads THAT window and nothing else, and the Unmap that follows must not
	/// then walk the whole shadow and send it all over again.
	[Test]
	public static void FlushRangeUploadsOnlyItsWindowAndUnmapAddsNothing()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		// A "ring": 1 KB, of which one frame writes 64 bytes at offset 512.
		var ringDesc = BufferDesc();
		ringDesc.Size = 1024;
		ringDesc.Usage = .Uniform | .CopySrc;
		ringDesc.Memory = .CpuToGpu;
		var ring = device.CreateBuffer(ringDesc).GetValueOrDefault();
		Test.Assert(ring != null);
		let webgpuRing = (WebGpuBuffer)ring;

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 1024;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();
		let queue = device.GetQueue(.Graphics, 0);

		void SubmitCopy(uint64 frame)
		{
			var encoder = pool.CreateEncoder().GetValueOrDefault();
			encoder.CopyBufferToBuffer(ring, 0, readback, 0, 1024);
			ICommandBuffer[1] buffers = .(encoder.Finish());
			queue.Submit(.(&buffers[0], 1), fence, frame);
			Test.Assert(fence.Wait(frame, uint64.MaxValue));
			pool.DestroyEncoder(ref encoder);
		}

		// Frame one: map, write the window, flush the window, unmap. Exactly ONE upload, and
		// the Unmap after a ranged flush must not add a whole buffer one.
		var mapped = (uint8*)ring.Map();
		Test.Assert(mapped != null);
		Internal.MemSet(mapped + 512, 0x5A, 64);
		ring.FlushRange(512, 64);
		Test.Assert(webgpuRing.UploadCount == 1, "the window uploaded");
		ring.Unmap();
		Test.Assert(webgpuRing.UploadCount == 1, "and the Unmap added nothing");
		SubmitCopy(1);
		Test.Assert(webgpuRing.UploadCount == 1, "nor did the submit hook");

		var bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[0] == 0x00, "the untouched bytes stayed zero initialised");
		Test.Assert(bytes[511] == 0x00);
		Test.Assert(bytes[512] == 0x5A, "the window landed");
		Test.Assert(bytes[575] == 0x5A);
		Test.Assert(bytes[576] == 0x00);
		readback.Unmap();

		// Frame two: the same bytes flushed again are a SKIPPED upload, by the ranged compare.
		ring.Map();
		ring.FlushRange(512, 64);
		ring.Unmap();
		Test.Assert(webgpuRing.UploadCount == 1, "an unchanged window is not re-sent");

		// Frame three: a different window uploads once more and lands BESIDE the first.
		mapped = (uint8*)ring.Map();
		Internal.MemSet(mapped + 128, 0xA5, 32);
		ring.FlushRange(128, 32);
		ring.Unmap();
		Test.Assert(webgpuRing.UploadCount == 2);
		SubmitCopy(2);

		bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[128] == 0xA5);
		Test.Assert(bytes[159] == 0xA5);
		Test.Assert(bytes[160] == 0x00);
		Test.Assert(bytes[512] == 0x5A, "the earlier window survived a partial upload");
		readback.Unmap();

		// A plain Map and Unmap with no writes costs at most the whole shadow compare and
		// never an upload: the GPU provably holds these exact bytes.
		ring.Map();
		ring.Unmap();
		Test.Assert(webgpuRing.UploadCount == 2);

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyBuffer(ref ring);
		device.Destroy();
	}

	/// The registry is what re-flushes a mapping left OPEN before a submit, which is the
	/// coherent half of the contract. A buffer whose Unmap was paired is not outstanding
	/// and must not be re-sent.
	[Test]
	public static void TheRegistryOnlyReflushesAnOpenMapping()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let queue = wgpuDeviceGetQueue(device);
		defer wgpuQueueRelease(queue);

		let held = scope WebGpuBuffer();
		let paired = scope WebGpuBuffer();
		let desc = BufferDesc() { Size = 64, Usage = .Uniform, Memory = .CpuToGpu };
		Test.Assert(held.Initialize(backend.Instance, device, queue, desc) case .Ok);
		Test.Assert(paired.Initialize(backend.Instance, device, queue, desc) case .Ok);

		let registry = scope WebGpuBufferRegistry();
		registry.Add(held);
		registry.Add(paired);

		// One keeps its mapping open, the way a persistently mapped caller does.
		let heldPtr = (uint8*)held.Map();
		heldPtr[0] = 1;

		// The other pairs its Unmap, so it has already paid its upload.
		let pairedPtr = (uint8*)paired.Map();
		pairedPtr[0] = 1;
		paired.Unmap();

		let pairedBefore = paired.UploadCount;
		Test.Assert(pairedBefore == 1);

		// A submit. The open one flushes; the closed one is not outstanding.
		heldPtr[1] = 2;
		registry.FlushOutstanding();

		Test.Assert(held.UploadCount == 1, "the open mapping flushed on submit");
		Test.Assert(paired.UploadCount == pairedBefore, "the closed one was left alone");

		registry.Remove(held);
		registry.Remove(paired);
	}
}
