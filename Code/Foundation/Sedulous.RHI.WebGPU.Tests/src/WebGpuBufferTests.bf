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
