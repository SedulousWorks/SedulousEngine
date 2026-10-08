using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// A scissor reaching past the target, before it, or wholly outside it is clipped to the
/// render area, without an error.
///
/// In the browser the scene went black now and then: world space UI over a character half off
/// screen set a scissor past the target's right edge ("Scissor rect (x: 1933, ...) is not
/// contained in the render area"), WebGPU refused the whole command encoder for it, and the
/// frame never drew.
class WebGpuScissorTests
{
	[Test]
	public static void AScissorReachingOutsideTheRenderAreaIsClippedToItWithoutAnError()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let errorsBefore = WebGpuDiagnostics.UncapturedErrorCount;
		let queue = device.GetQueue(.Graphics, 0);

		var target = device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 48)).GetValueOrDefault();
		Test.Assert(target != null);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(target, viewDesc).GetValueOrDefault();
		Test.Assert(view != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();

		RenderPassDesc pass = .();
		ColorAttachment color = .();
		color.View = view;
		color.ClearValue = ClearColor.Black;
		pass.ColorAttachments.Add(color);
		let renderPass = encoder.BeginRenderPass(pass);
		Test.Assert(renderPass != null);
		renderPass.SetScissor(70, 10, 0, 10);   // past the right edge (the browser's case)
		renderPass.SetScissor(50, 40, 30, 20);  // reaching over the bottom right corner
		renderPass.SetScissor(-8, -4, 16, 16);  // starting before the top left
		renderPass.SetScissor(100, 100, 5, 5);  // wholly outside
		renderPass.End();

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(encoder.Finish());
		Test.Assert(submitted[0] != null);
		queue.Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));
		device.WaitIdle(); // the error callbacks arrive through the event pump

		Test.Assert(WebGpuDiagnostics.UncapturedErrorCount == errorsBefore,
			scope $"{WebGpuDiagnostics.UncapturedErrorCount - errorsBefore} WebGPU errors");
		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref target);
		device.Destroy();
	}
}
