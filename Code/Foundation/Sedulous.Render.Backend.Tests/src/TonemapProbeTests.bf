using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RenderGraph;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The tone map's bind groups on a real device: a group is kept only while every input is the
/// same view of the same texture. Auto exposure hands the tone map one of two ping pong textures
/// each frame; the group was once kept on the transients' views and one generation folded from
/// all the inputs, so two exposure textures whose numbers folded alike shared a group, and every
/// other frame showed the other texture's exposure. Here two exposure textures carry the SAME
/// generation and different levels: the second frame must show its own.
class TonemapProbeTests
{
	private const uint32 cSize = 4;

	private static bool MakeTarget(IDevice device, TextureFormat format, uint32 size, TextureUsage usage,
		out ITexture texture, out ITextureView view)
	{
		texture = null;
		view = null;
		var textureDesc = TextureDesc();
		textureDesc.Format = format;
		textureDesc.Width = size;
		textureDesc.Height = size;
		textureDesc.Usage = usage;
		textureDesc.Label = "tonemap.probe";
		if (!(device.CreateTexture(textureDesc) case .Ok(let made)))
			return false;
		texture = made;
		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		if (!(device.CreateTextureView(texture, viewDesc) case .Ok(let madeView)))
			return false;
		view = madeView;
		return true;
	}

	[Test]
	public static void AnExposureTextureWithAnothersGenerationStillGetsItsOwnBindGroup()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;

		let tonemap = scope TonemapPass(device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let graph = scope RenderGraph(device);

		// Two adapted luminance textures (the exposure pass's format): a dim scene and a bright one.
		let madeDim = MakeTarget(device, .R16Float, 1, .RenderTarget | .Sampled, var dim, var dimView);
		defer { device.DestroyTextureView(ref dimView); device.DestroyTexture(ref dim); }
		let madeBright = MakeTarget(device, .R16Float, 1, .RenderTarget | .Sampled, var bright, var brightView);
		defer { device.DestroyTextureView(ref brightView); device.DestroyTexture(ref bright); }
		let madeLdr = MakeTarget(device, .RGBA8Unorm, cSize, .RenderTarget | .CopySrc, var ldr, var ldrView);
		defer { device.DestroyTextureView(ref ldrView); device.DestroyTexture(ref ldr); }
		Test.Assert(madeDim && madeBright && madeLdr);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
		{
			Test.FatalError("no command pool");
			return;
		}
		defer device.DestroyCommandPool(ref pool);
		if (!(device.CreateFence(0) case .Ok(var fence)))
		{
			Test.FatalError("no fence");
			return;
		}
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);
		Test.Assert(queue != null);

		// One frame: a grey scene tone mapped under `exposureTexture` (holding `level`), read back.
		// Every frame uses the same frame slot, the same transients and the same exposure
		// generation.
		uint64 submitted = 0;
		uint32 Frame(ITexture exposureTexture, ITextureView exposureView, float level)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
			{
				Test.FatalError("no encoder");
				return 0;
			}
			graph.SetOutputSize(cSize, cSize);
			graph.BeginFrame(0);
			let hdr = graph.CreateTransient("hdr", .(.RGBA16Float, cSize, cSize));
			let bloom = graph.CreateTransient("bloom", .(.RGBA16Float, cSize, cSize));
			let ao = graph.CreateTransient("ao", .(.RGBA8Unorm, cSize, cSize));
			let lum = graph.ImportTarget("lum", exposureTexture, exposureView, ResourceState.ShaderRead);
			let output = graph.ImportTarget("ldr", ldr, ldrView, ResourceState.CopySrc);
			void Fill(StringView name, RGHandle target, ClearColor colour)
			{
				graph.AddRenderPass(name, scope [&] (builder) =>
					{
						builder.SetColorTarget(0, target, .Clear, .Store, colour);
						builder.NeverCull();
						builder.SetExecute(new (pass) => {});
					});
			}
			Fill("fill.hdr", hdr, .(0.18f, 0.18f, 0.18f, 1.0f));
			Fill("fill.bloom", bloom, .Black);
			Fill("fill.ao", ao, .White);
			Fill("fill.lum", lum, .(level, level, level, 1.0f));
			var autoExposure = TonemapAutoExposure();
			autoExposure.Enabled = true;
			autoExposure.Handle = lum;
			autoExposure.View = exposureView;
			autoExposure.Generation = 7; // the same for both textures
			tonemap.DeclareTonemap(graph, hdr, bloom, ao, output, true, .Black, .RGBA8Unorm, 0, 0, cSize, cSize,
				0, 0, 1.0f, 0.0f, .(1, 1), .(0, 0), 0.0f, false, false, false, autoExposure);
			Test.Assert(graph.Execute(encoder) case .Ok);
			graph.EndFrame();
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null);
			var buffers = ICommandBuffer[1](commandBuffer);
			submitted++;
			queue.Submit(.(&buffers[0], 1), fence, submitted);
			fence.Wait(submitted);
			pool.DestroyEncoder(ref encoder);
			let image = RhiTestSupport.Readback(device, ldr, cSize, cSize);
			defer delete image;
			Test.Assert(image.Valid);
			return image.At(cSize / 2, cSize / 2)[1];
		}

		// A dim average makes the grey bright; a bright average, dark. The second frame must not
		// keep the first frame's group, which binds the dim texture.
		let underDim = Frame(dim, dimView, 0.05f);
		let underBright = Frame(bright, brightView, 0.8f);
		Test.Assert(underDim > underBright + 40, scope $"under the dim level {underDim}, under the bright level {underBright}");
		// And back: the first texture's level again.
		Test.Assert(Frame(dim, dimView, 0.05f) == underDim);

		device.WaitIdle();
	}
}
