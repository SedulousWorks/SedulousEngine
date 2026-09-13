using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.Shaders;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.VG.Backend.Tests;

/// Renders one recorded vector scene and reads the pixels back.
///
/// Single sampled with a STENCIL attachment, which is what the stencil then cover fills need;
/// above one sample it renders into a multisampled target that resolves into the readback
/// texture, the same arrangement the canvas and window hosts use.
static class VGSceneRenderer
{
	public const uint32 Size = 128;
	private const TextureFormat cTargetFormat = .RGBA8UnormSrgb;
	private const TextureFormat cDepthStencilFormat = .Depth24PlusStencil8;

	public static Color ByteColor(uint8 r, uint8 g, uint8 b) => ToColor(Color32(r, g, b, 255));

	public static CapturedImage RenderScene(VGProbeFixture fixture, delegate void(VGContext) record,
		uint32 sampleCount = 1)
	{
		let device = fixture.Device;
		let shaders = fixture.Host;

		let vertex = shaders.GetVariant("vg", .Vertex, .None);
		let fragment = shaders.GetVariant("vg", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		let distanceField = shaders.GetVariant("vg_df", .Fragment, .None);
		let gradRadial = shaders.GetVariant("vg_grad_radial", .Fragment, .None);
		let gradConic = shaders.GetVariant("vg_grad_conic", .Fragment, .None);

		var targetConfig = VGTargetConfig();
		targetConfig.SampleCount = sampleCount;
		targetConfig.DepthStencilFormat = cDepthStencilFormat;

		let renderer = scope VGRenderer();
		if (renderer.Initialize(device, vertex, fragment, cTargetFormat, 2, distanceField,
			gradRadial, gradConic, targetConfig) case .Err)
			return null;

		defer renderer.Dispose();

		var colorDesc = TextureDesc.RenderTarget(cTargetFormat, Size, Size);
		colorDesc.Usage |= .CopySrc;
		if (!(device.CreateTexture(colorDesc) case .Ok(var target)))
			return null;
		defer device.DestroyTexture(ref target);

		if (!(device.CreateTextureView(target, .()) case .Ok(var targetView)))
			return null;
		defer device.DestroyTextureView(ref targetView);

		ITexture msaa = null;
		ITextureView msaaView = null;
		defer
		{
			if (msaaView != null)
				device.DestroyTextureView(ref msaaView);
			if (msaa != null)
				device.DestroyTexture(ref msaa);
		}

		if (sampleCount > 1)
		{
			var msaaDesc = TextureDesc.RenderTarget(cTargetFormat, Size, Size, sampleCount);
			msaaDesc.Usage = .RenderTarget;
			if (!(device.CreateTexture(msaaDesc) case .Ok(let created)))
				return null;
			msaa = created;

			if (!(device.CreateTextureView(msaa, .()) case .Ok(let createdView)))
				return null;
			msaaView = createdView;
		}

		var depthDesc = TextureDesc();
		depthDesc.Dimension = .Texture2D;
		depthDesc.Format = cDepthStencilFormat;
		depthDesc.Width = Size;
		depthDesc.Height = Size;
		depthDesc.Depth = 1;
		depthDesc.Usage = .DepthStencil;
		depthDesc.SampleCount = sampleCount;
		if (!(device.CreateTexture(depthDesc) case .Ok(var depthStencil)))
			return null;
		defer device.DestroyTexture(ref depthStencil);

		if (!(device.CreateTextureView(depthStencil, .()) case .Ok(var depthStencilView)))
			return null;
		defer device.DestroyTextureView(ref depthStencilView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return null;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return null;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return null;

		let context = scope VGContext();
		context.SetStencilFills(true);
		context.SetPerPixelGradients((gradRadial != null) && (gradConic != null));
		record(context);

		renderer.BeginFrame(0);
		let slice = renderer.Prepare(context.GetBatch(), 0, Size, Size);

		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return null;
		defer pool.DestroyEncoder(ref encoder);

		encoder.TransitionTexture(target, .Undefined, .RenderTarget);
		if (msaa != null)
			encoder.TransitionTexture(msaa, .Undefined, .RenderTarget);
		encoder.TransitionTexture(depthStencil, .Undefined, .DepthStencilWrite);

		var color = ColorAttachment();
		color.View = (msaaView != null) ? msaaView : targetView;
		color.ResolveTarget = (msaaView != null) ? targetView : null;
		color.LoadOp = .Clear;
		// The multisampled samples are not wanted after the resolve.
		color.StoreOp = (msaaView != null) ? .DontCare : .Store;
		color.ClearValue = ClearColor.Black;

		var depth = DepthStencilAttachment();
		depth.View = depthStencilView;
		depth.DepthLoadOp = .Clear;
		depth.DepthStoreOp = .DontCare;
		depth.StencilLoadOp = .Clear;
		depth.StencilStoreOp = .DontCare;
		depth.StencilClearValue = 0;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(color);
		passDesc.DepthStencilAttachment = depth;
		passDesc.Label = "vg.probe";

		let pass = encoder.BeginRenderPass(passDesc);
		if (pass == null)
			return null;

		renderer.Render(pass, Size, Size, 0, slice);
		pass.End();

		encoder.TransitionTexture(target, .RenderTarget, .CopySrc);

		let commandBuffer = encoder.Finish();
		if (commandBuffer == null)
			return null;

		var buffers = ICommandBuffer[1](commandBuffer);
		queue.Submit(.(&buffers[0], 1), fence, 1);
		fence.Wait(1);

		// The target is left in the copy source state; the shared substrate owns the rest.
		let image = RhiTestSupport.Readback(device, target, Size, Size);
		device.WaitIdle();
		return image;
	}
}
