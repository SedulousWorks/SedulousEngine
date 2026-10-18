using System;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;
#if BF_PLATFORM_WINDOWS
using Sedulous.RHI.DX12;
#endif

namespace Sedulous.Render.Backend.Tests;

/// The VIEW FORMAT probe on real devices: an sRGB render target that declares its UNORM twin
/// (TextureDesc.AlternateViewFormat) is cleared to half grey through each view and read back.
///
/// The UNORM view stores the value as given (128), the sRGB view encodes it (188): the same
/// texture, written with or without the sRGB transfer, which is what lets VG blend encoded
/// values into the targets everything else draws linear light into.
class ViewFormatProbeTests
{
	const uint32 cSize = 4;

	[Test]
	public static void AnSrgbTargetWrittenThroughItsUnormViewStoresTheValueAsGiven()
	{
		if (VulkanRhi.CreateBackend(false) case .Ok(let vulkan))
		{
			Probe(vulkan, "vulkan");
			vulkan.Destroy();
			delete vulkan;
		}
		if (WebGpuRhi.CreateBackend() case .Ok(let webgpu))
		{
			Probe(webgpu, "webgpu");
			webgpu.Destroy();
			delete webgpu;
		}
#if BF_PLATFORM_WINDOWS
		if (DxRhi.CreateBackend() case .Ok(let dx12))
		{
			Probe(dx12, "dx12");
			dx12.Destroy();
			delete dx12;
		}
#endif
	}

	static void Probe(IBackend backend, StringView name)
	{
		let device = RhiTestSupport.MakeTestDevice(backend);
		if (device == null)
			return; // no device for this backend here: nothing to answer
		defer device.Destroy();

		let unorm = ClearThrough(device, .RGBA8Unorm);
		let srgb = ClearThrough(device, .RGBA8UnormSrgb);
		Test.Assert((unorm >= 127) && (unorm <= 128), scope $"{name}: the UNORM view stored {unorm}, the value as given");
		// Encoded: 0.5 linear is 0.735 sRGB.
		Test.Assert((srgb >= 187) && (srgb <= 189), scope $"{name}: the sRGB view stored {srgb}, encoded");
	}

	/// The red the target holds after a half grey clear through a view in `viewFormat`.
	static int ClearThrough(IDevice device, TextureFormat viewFormat)
	{
		var textureDesc = TextureDesc.RenderTarget(.RGBA8UnormSrgb, cSize, cSize, 1, "viewformat.target");
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.AlternateViewFormat = .RGBA8Unorm;
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var target));
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = viewFormat;
		Test.Assert(device.CreateTextureView(target, viewDesc) case .Ok(var view));
		defer device.DestroyTextureView(ref view);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);

		encoder.TransitionTexture(target, .Undefined, .RenderTarget);
		var attachment = ColorAttachment();
		attachment.View = view;
		attachment.LoadOp = .Clear;
		attachment.StoreOp = .Store;
		attachment.ClearValue = .(0.5f, 0.5f, 0.5f, 1.0f);
		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(attachment);
		let pass = encoder.BeginRenderPass(passDesc);
		Test.Assert(pass != null);
		pass.End();
		// Readback expects the target already in the copy source state.
		encoder.TransitionTexture(target, .RenderTarget, .CopySrc);

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null);
		var buffers = ICommandBuffer[1](commandBuffer);
		device.GetQueue(.Graphics).Submit(.(&buffers[0], 1));
		device.WaitIdle();

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		Test.Assert(image.Valid);
		return image.At(1, 1)[0];
	}
}
