using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Integration.Tests;

/// The readback substrate against a REAL device.
///
/// A pixel probe is only worth anything if the pixels it reads are the ones the GPU wrote, so
/// this clears a target to a colour nothing else would produce and checks that exact colour
/// comes back. Everything above it, the whole structural probe idea, rests on this one fact.
///
/// SKIPS rather than fails where there is no Vulkan device: a machine that cannot answer the
/// question has not answered it wrongly.
class ReadbackSmokeTests
{
	[Test]
	public static void AClearedTargetReadsBackAsTheColourItWasCleared()
	{
		if (!(VulkanRhi.CreateBackend(false) case .Ok(var backend)))
			return;

		defer { backend.Destroy(); delete backend; }

		let device = RhiTestSupport.MakeTestDevice(backend);
		if (device == null)
			return;

		defer device.Destroy();

		const uint32 cSize = 64;

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, cSize, cSize, 1, "readback.smoke");
		textureDesc.Usage |= .CopySrc;
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return;

		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return;

		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return;

		defer device.DestroyCommandPool(ref pool);

		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return;

		defer pool.DestroyEncoder(ref encoder);

		// A colour no default clear would land on, so a target that was never written cannot
		// pass by accident.
		let expected = ClearColor(0.25f, 0.5f, 0.75f, 1.0f);

		encoder.TransitionTexture(target, .Undefined, .RenderTarget);

		var attachment = ColorAttachment();
		attachment.View = targetView;
		attachment.LoadOp = .Clear;
		attachment.StoreOp = .Store;
		attachment.ClearValue = expected;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(attachment);
		passDesc.Label = "readback.smoke";

		let pass = encoder.BeginRenderPass(passDesc);
		if (pass == null)
			return;
		pass.End();

		// Readback expects the target already in the copy source state.
		encoder.TransitionTexture(target, .RenderTarget, .CopySrc);

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null);

		let queue = device.GetQueue(.Graphics);
		Test.Assert(queue != null);

		var buffers = ICommandBuffer[1](commandBuffer);
		queue.Submit(.(&buffers[0], 1));
		device.WaitIdle();

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;

		Test.Assert(image.Valid, "the readback completed");
		Test.Assert(image.Width == cSize);
		Test.Assert(image.Height == cSize);

		// Unorm rounding, so within a count or so of the encoded value rather than exact.
		let centre = image.At(cSize / 2, cSize / 2);
		Test.Assert(Math.Abs((int)centre[0] - 64) <= 2, "red");
		Test.Assert(Math.Abs((int)centre[1] - 128) <= 2, "green");
		Test.Assert(Math.Abs((int)centre[2] - 191) <= 2, "blue");
		Test.Assert(centre[3] == 255, "alpha");

		// And the WHOLE target carries it, so this is a real clear rather than one stray texel.
		let matching = image.CountWhere(scope (rgba) =>
			{
				return (Math.Abs((int)rgba[0] - 64) <= 2) && (Math.Abs((int)rgba[1] - 128) <= 2)
					&& (Math.Abs((int)rgba[2] - 191) <= 2);
			});
		Test.Assert(matching == cSize * cSize, "every pixel");
	}
}
