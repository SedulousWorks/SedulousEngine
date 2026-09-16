using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The whole path through the backend on a real GPU: encode, submit, wait, read back.
///
/// This is the case that proves the emulations actually work rather than merely compile -
/// the fence has no WebGPU object behind it, and the readback map is a real one.
class WebGpuRoundTripTests
{
	/// WebGPU has no fence, so the RHI's timeline is a CPU one: a fenced submit registers
	/// a work done callback that records its value when the GPU passes that submission.
	/// An EMPTY submission still has to carry the signal through, which is the case that
	/// catches a fence wired only to the command path.
	[Test]
	public static void AFenceSignalsThroughAnEmptySubmission()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var fence = device.CreateFence(0).GetValueOrDefault();
		Test.Assert(fence != null);
		Test.Assert(fence.CompletedValue() == 0);

		let queue = device.GetQueue(.Graphics, 0);
		queue.Submit(.(), fence, 7);

		Test.Assert(fence.Wait(7, 0), "the signal arrives with nothing submitted behind it");
		Test.Assert(fence.CompletedValue() == 7);

		device.DestroyFence(ref fence);
		device.Destroy();
	}

	/// A render pass clears an offscreen target to a known colour, the target is copied
	/// into a readback buffer, and the pixels are checked on the CPU. Everything between
	/// the encoder and the map has to be right for this to come back red.
	[Test]
	public static void AClearSurvivesTheRoundTripToTheCpu()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var targetDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		targetDesc.Usage = .RenderTarget | .CopySrc;
		var target = device.CreateTexture(targetDesc).GetValueOrDefault();
		Test.Assert(target != null);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(target, viewDesc).GetValueOrDefault();
		Test.Assert(view != null);

		// Four rows of 256 bytes: WebGPU aligns a texture to buffer copy's bytesPerRow to
		// 256, so the rows are PADDED and the readback is not 4x4x4 bytes packed.
		var readbackDesc = BufferDesc();
		readbackDesc.Size = 4 * 256;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		Test.Assert(pool != null);
		var encoder = pool.CreateEncoder().GetValueOrDefault();
		Test.Assert(encoder != null);

		RenderPassDesc pass = .();
		ColorAttachment color = .();
		color.View = view;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		color.ClearValue = .(1.0f, 0.0f, 0.0f, 1.0f); // pure red
		pass.ColorAttachments.Add(color);

		let renderPass = encoder.BeginRenderPass(pass);
		Test.Assert(renderPass != null);
		renderPass.End();

		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 4;
		region.TextureExtent = .(4, 4, 1);
		encoder.CopyTextureToBuffer(target, readback, region);

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null);

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(commandBuffer);
		device.GetQueue(.Graphics, 0).Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue), "the submission retires");

		let pixels = (uint8*)readback.Map();
		Test.Assert(pixels != null, "a GpuToCpu buffer maps for real");
		Test.Assert(pixels[0] == 255, "R");
		Test.Assert(pixels[1] == 0, "G");
		Test.Assert(pixels[2] == 0, "B");
		Test.Assert(pixels[3] == 255, "A");
		// The last row, reached through the PADDED stride rather than through 4 * 4.
		Test.Assert(pixels[256 * 3 + 0] == 255, "the last row cleared too");
		readback.Unmap();

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref target);
		device.Destroy();
	}

	/// A queued work done callback may be delivered AFTER the fence it signals is gone.
	/// The detach and orphan handshake has to keep that delivery writing into live memory,
	/// and teardown has to survive signals still queued behind it.
	[Test]
	public static void DestroyingAFenceWithAPendingSignalIsSafe()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		// The fast path: submit, wait, which resolves the signal, destroy, then keep
		// pumping. A late callback must hit the detached record rather than the fence.
		var fence = device.CreateFence(0).GetValueOrDefault();
		queue.Submit(.(), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));
		device.DestroyFence(ref fence);
		queue.WaitIdle();

		// And without waiting at all: the callback may still be queued when the fence
		// goes, and more work follows it into a full teardown.
		var abandoned = device.CreateFence(0).GetValueOrDefault();
		queue.Submit(.(), abandoned, 1);
		device.DestroyFence(ref abandoned); // no Wait: the signal may still be queued
		queue.Submit(.());
		queue.WaitIdle();

		Test.Assert(!device.IsLost());
		device.Destroy();
	}
}
