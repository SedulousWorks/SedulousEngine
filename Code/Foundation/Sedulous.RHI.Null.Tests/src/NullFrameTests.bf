using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.RHI.Null.Tests;

/// The pieces a frame loop actually drives: surface, swap chain, pool, encoder, queue and
/// fence. This is what makes the null backend worth having, so it is walked end to end.
class NullFrameTests
{
	private static IDevice MakeDevice(IBackend backend)
	{
		if (backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device))
			return device;
		return null;
	}

	/// A surface is made from ANY handle, null included: there is no windowing system to
	/// reject it, and refusing would make a headless swap chain untestable.
	[Test]
	public static void ASurfaceComesFromAnyHandle()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;

		Test.Assert(backend.CreateSurface(null) case .Ok(let surface));
		Test.Assert(surface != null);

		Test.Assert(backend.CreateSurface((void*)(int)0x1234, null, .Win32) case .Ok(let other));
		Test.Assert(other !== surface, "each call makes its own");
	}

	[Test]
	public static void TheSwapChainReportsWhatItWasAskedFor()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);
		Test.Assert(backend.CreateSurface(null) case .Ok(let surface));

		var desc = SwapChainDesc();
		desc.Width = 800;
		desc.Height = 600;
		desc.Format = .RGBA8Unorm;
		desc.BufferCount = 3;

		Test.Assert(device.CreateSwapChain(surface, desc) case .Ok(var swapChain));
		Test.Assert(swapChain.Width == 800);
		Test.Assert(swapChain.Height == 600);
		Test.Assert(swapChain.Format == .RGBA8Unorm);
		Test.Assert(swapChain.BufferCount == 3);

		// The back buffer and its view exist and agree with the chain, so a pass can be
		// built against them headlessly.
		Test.Assert(swapChain.CurrentTexture != null);
		Test.Assert(swapChain.CurrentTextureView != null);
		Test.Assert(swapChain.CurrentTextureView.Texture === swapChain.CurrentTexture,
			"the view views the chain's own texture");
		Test.Assert(swapChain.CurrentTexture.Desc.Format == .RGBA8Unorm);
		Test.Assert(swapChain.CurrentTexture.Desc.Width == 800);

		device.DestroySwapChain(ref swapChain);
		Test.Assert(swapChain == null);
	}

	/// The acquired index CYCLES. A caller keying per frame resources on it is exercised
	/// properly, and one that assumed it never moved is caught here rather than on hardware.
	[Test]
	public static void AcquiringCyclesThroughTheBackBuffers()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);
		Test.Assert(backend.CreateSurface(null) case .Ok(let surface));

		var desc = SwapChainDesc();
		desc.Width = 64; desc.Height = 64; desc.BufferCount = 3;
		Test.Assert(device.CreateSwapChain(surface, desc) case .Ok(var swapChain));

		let seen = scope uint32[3];
		for (int i < 3)
		{
			Test.Assert(swapChain.AcquireNextImage() case .Ok);
			seen[i] = swapChain.CurrentImageIndex;
			Test.Assert(seen[i] < 3, "the index stays within the buffer count");
		}
		Test.Assert((seen[0] != seen[1]) && (seen[1] != seen[2]), "it actually advances");

		// And it wraps rather than running away.
		Test.Assert(swapChain.AcquireNextImage() case .Ok);
		Test.Assert(swapChain.CurrentImageIndex == seen[0], "back round to where it began");

		Test.Assert(swapChain.Present(device.GetQueue(.Graphics)) case .Ok);

		Test.Assert(swapChain.Resize(1280, 720) case .Ok);
		Test.Assert((swapChain.Width == 1280) && (swapChain.Height == 720));

		device.DestroySwapChain(ref swapChain);
	}

	/// A descriptor asking for no buffers still yields a usable chain rather than dividing
	/// by zero on the first acquire.
	[Test]
	public static void AZeroBufferCountIsClampedNotDividedBy()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);
		Test.Assert(backend.CreateSurface(null) case .Ok(let surface));

		var desc = SwapChainDesc();
		desc.BufferCount = 0;
		Test.Assert(device.CreateSwapChain(surface, desc) case .Ok(var swapChain));
		Test.Assert(swapChain.BufferCount >= 1);
		Test.Assert(swapChain.AcquireNextImage() case .Ok);
		Test.Assert(swapChain.CurrentImageIndex == 0);
		device.DestroySwapChain(ref swapChain);
	}

	/// A fence STARTS at the value it was created with and only ever moves forward.
	[Test]
	public static void AFenceStartsSignalledAndNeverGoesBackwards()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);

		Test.Assert(device.CreateFence(5) case .Ok(var fence));
		Test.Assert(fence.CompletedValue() == 5, "created at the value asked for");

		// Waiting succeeds at once and carries the counter forward: there is no GPU to be
		// behind, and a fence that never signalled would hang every headless loop.
		Test.Assert(fence.Wait(10));
		Test.Assert(fence.CompletedValue() == 10);

		// Waiting for something already passed does not rewind it.
		Test.Assert(fence.Wait(3));
		Test.Assert(fence.CompletedValue() == 10, "monotonic");

		device.DestroyFence(ref fence);
		Test.Assert(fence == null);
	}

	/// Submitting with a fence completes the work immediately, which is what lets a submit
	/// then wait loop make progress.
	[Test]
	public static void SubmittingSignalsTheFence()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);
		let queue = device.GetQueue(.Graphics);

		Test.Assert(device.CreateFence(0) case .Ok(var fence));
		Test.Assert(fence.CompletedValue() == 0);

		queue.Submit(.(), fence, 7);
		Test.Assert(fence.CompletedValue() == 7, "the work is done by the time Submit returns");

		// The full form signals too, and its waits are moot because nothing runs later.
		queue.Submit(.(), .(), .(), fence, 9);
		Test.Assert(fence.CompletedValue() == 9);

		queue.WaitIdle();
		device.DestroyFence(ref fence);
	}

	/// The pool owns its encoder: every request hands back the same one, and destroying
	/// releases the caller's handle without freeing it.
	[Test]
	public static void ThePoolOwnsItsEncoder()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var first));
		Test.Assert(pool.CreateEncoder() case .Ok(let second));
		Test.Assert(first === second, "a stub keeps no per encoder state to separate");

		pool.DestroyEncoder(ref first);
		Test.Assert(first == null, "the caller's handle is released");

		// The pool is still usable afterwards, which it would not be had it been freed.
		Test.Assert(pool.CreateEncoder() case .Ok(let third));
		Test.Assert(third === second);

		pool.Reset();
		device.DestroyCommandPool(ref pool);
		Test.Assert(pool == null);
	}

	/// A whole recording pass: begin, record into both pass kinds and a bundle, finish, and
	/// submit. Nothing is checked beyond it running, which is the point of a null backend.
	[Test]
	public static void AFullRecordingWalkRunsThrough()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));

		var pass = RenderPassDesc();
		let renderPass = encoder.BeginRenderPass(pass);
		Test.Assert(renderPass != null);
		renderPass.SetViewport(0, 0, 64, 64);
		renderPass.SetScissor(0, 0, 64, 64);
		renderPass.Draw(3);
		renderPass.End();

		let computePass = encoder.BeginComputePass();
		Test.Assert(computePass != null);
		computePass.Dispatch(1);
		computePass.ComputeBarrier();
		computePass.End();

		let bundleEncoder = encoder.CreateRenderBundleEncoder(.());
		Test.Assert(bundleEncoder != null);
		bundleEncoder.Draw(3);
		let bundle = bundleEncoder.Finish();
		Test.Assert(bundle != null, "the bundle belongs to the pool, not to us");

		// The pool's own bundle encoder is the encoder's, since both come from one pool.
		Test.Assert(pool.CreateRenderBundleEncoder(.()) === bundleEncoder);

		encoder.BeginDebugLabel("frame");
		encoder.EndDebugLabel();

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null);

		let buffers = scope ICommandBuffer[](commandBuffer);
		device.GetQueue(.Graphics).Submit(buffers);

		device.DestroyCommandPool(ref pool);
	}

	/// The transfer batch belongs to the QUEUE, and its async submit signals at once so a
	/// caller waiting on an upload is not left hanging.
	[Test]
	public static void TheTransferBatchBelongsToTheQueueAndCompletesAtOnce()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);
		let queue = device.GetQueue(.Transfer);

		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		Test.Assert(queue.CreateTransferBatch() case .Ok(let same));
		Test.Assert(batch === same, "the queue owns one");

		Test.Assert(device.CreateBuffer(.()) case .Ok(var buffer));
		let bytes = scope uint8[4](1, 2, 3, 4);
		batch.WriteBuffer(buffer, 0, bytes);
		Test.Assert(batch.Submit() case .Ok);

		Test.Assert(device.CreateFence(0) case .Ok(var fence));
		Test.Assert(batch.SubmitAsync(fence, 4) case .Ok);
		Test.Assert(fence.CompletedValue() == 4, "the upload is already done");

		batch.Reset();
		queue.DestroyTransferBatch(ref batch);
		Test.Assert(batch == null, "only the caller's handle went");

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref buffer);
	}

	/// The extension seams are reachable by CASTING, and the null backend implements both so
	/// a mesh shader or ray tracing path can be exercised where no hardware does it.
	[Test]
	public static void TheExtensionSeamsAreReachableByCasting()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = MakeDevice(backend);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));

		let rayTracing = encoder as IRayTracingEncoderExt;
		Test.Assert(rayTracing != null, "the null encoder offers ray tracing");
		rayTracing.TraceRays(null, 0, 0, null, 0, 0, null, 0, 0, 8, 8);

		let renderPass = encoder.BeginRenderPass(.());
		let meshShaders = renderPass as IMeshShaderPassExt;
		Test.Assert(meshShaders != null, "and the pass encoder offers mesh shaders");
		meshShaders.DrawMeshTasks(1);
		renderPass.End();

		// And the device creates the matching objects rather than refusing, unlike the
		// interface defaults.
		Test.Assert(device.CreateMeshPipeline(.()) case .Ok(var meshPipeline));
		device.DestroyMeshPipeline(ref meshPipeline);

		var accelDesc = AccelStructDesc();
		accelDesc.Type = .TopLevel;
		Test.Assert(device.CreateAccelStruct(accelDesc) case .Ok(var accelStruct));
		Test.Assert(accelStruct.Type == .TopLevel, "it remembers which level it is");
		Test.Assert(accelStruct.DeviceAddress == 0, "and addresses nothing, having no memory");
		device.DestroyAccelStruct(ref accelStruct);

		Test.Assert(device.CreateRayTracingPipeline(.()) case .Ok(var rtPipeline));
		let handles = scope uint8[64];
		Test.Assert(device.GetShaderGroupHandles(rtPipeline, 0, 2, handles) case .Ok);
		Test.Assert(handles[0] == 0, "zeroed, addressing nothing");
		Test.Assert(device.ShaderGroupHandleSize > 0, "but the sizing arithmetic still works");
		device.DestroyRayTracingPipeline(ref rtPipeline);

		device.DestroyCommandPool(ref pool);
	}
}
