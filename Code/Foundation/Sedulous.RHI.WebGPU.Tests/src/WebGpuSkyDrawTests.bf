using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The sky pass shape, which is three awkward things at once: a fullscreen draw AT the far
/// plane against depth already cleared to 1.0, a READ ONLY depth attachment, and two colour
/// targets.
///
/// Each of them fails quietly on its own. A LessEqual compare read as Less drops the sky
/// entirely; a read only plane that still declares load and store ops is rejected; a second
/// target the pipeline does not describe writes nothing.
class WebGpuSkyDrawTests
{
	private const String cSkyWgsl = """
		struct FragmentOutput {
		  @location(0) color : vec4f,
		  @location(1) velocity : vec2f,
		}
		@vertex fn vertexMain(@builtin(vertex_index) index : u32)
		    -> @builtin(position) vec4f {
		  let uv = vec2f(f32((index << 1u) & 2u), f32(index & 2u));
		  return vec4f(uv * 2.0 - 1.0, 0.0, 1.0); // z = 0: the far plane (reverse-Z, Depth)
		}
		@fragment fn fragmentMain() -> FragmentOutput {
		  var output : FragmentOutput;
		  output.color = vec4f(0.0, 0.0, 1.0, 1.0);
		  output.velocity = vec2f(0.0);
		  return output;
		}
		""";

	[Test]
	public static void AFarPlaneDrawSurvivesAReadOnlyDepthPassIntoTwoTargets()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		var depthDesc = TextureDesc.DepthBuffer(.Depth32Float, 4, 4);
		// Sampled ON TOP of DepthStencil is REQUIRED for the read only pass below rather
		// than decoration: wgpu treats a depthReadOnly attachment as a readable resource
		// and validates the texture for texture binding. Without it the pass is rejected,
		// and the diagnostic arrives much later and misattributed - "Parent device is
		// lost" out of Finish, then a panic in submit. A real prepass depth reader
		// declares Sampled anyway.
		depthDesc.Usage = .DepthStencil | .Sampled;
		var depthTexture = device.CreateTexture(depthDesc).GetValueOrDefault();
		Test.Assert(depthTexture != null);

		var depthViewDesc = TextureViewDesc();
		depthViewDesc.Format = .Depth32Float;
		var depthView = device.CreateTextureView(depthTexture, depthViewDesc).GetValueOrDefault();

		var colorDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		colorDesc.Usage = .RenderTarget | .CopySrc;
		var colorTexture = device.CreateTexture(colorDesc).GetValueOrDefault();
		var colorViewDesc = TextureViewDesc();
		colorViewDesc.Format = .RGBA8Unorm;
		var colorView = device.CreateTextureView(colorTexture, colorViewDesc).GetValueOrDefault();

		var velocityDesc = TextureDesc.RenderTarget(.RG16Float, 4, 4);
		var velocityTexture = device.CreateTexture(velocityDesc).GetValueOrDefault();
		var velocityViewDesc = TextureViewDesc();
		velocityViewDesc.Format = .RG16Float;
		velocityViewDesc.Dimension = .Texture2D;
		var velocityView = device
			.CreateTextureView(velocityTexture, velocityViewDesc).GetValueOrDefault();
		Test.Assert(velocityView != null);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cSkyWgsl.Ptr, cSkyWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		var pipelineLayout = device.CreatePipelineLayout(.()).GetValueOrDefault();

		ColorTargetState[2] targets = .(.(), .());
		targets[0].Format = .RGBA8Unorm;
		targets[1].Format = .RG16Float;

		FragmentState fragment = .();
		fragment.Shader = .(module, "fragmentMain", .Fragment);
		fragment.Targets = .(&targets[0], 2);

		DepthStencilState depthState = .();
		depthState.Format = .Depth32Float;
		depthState.DepthTestEnabled = true;
		depthState.DepthWriteEnabled = false;
		depthState.DepthCompare = Depth.NearerOrEqual; // at the far plane: only a cleared pixel

		var pipelineDesc = RenderPipelineDesc();
		pipelineDesc.Layout = pipelineLayout;
		pipelineDesc.Vertex.Shader = .(module, "vertexMain", .Vertex);
		pipelineDesc.Fragment = fragment;
		pipelineDesc.DepthStencil = depthState;
		var pipeline = device.CreateRenderPipeline(pipelineDesc).GetValueOrDefault();
		Test.Assert(pipeline != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();

		// Pass 1 stands in for the prepass: clear depth to 1.0, and colour to black.
		{
			RenderPassDesc pass = .();
			ColorAttachment color = .();
			color.View = colorView;
			color.ClearValue = ClearColor.Black;
			pass.ColorAttachments.Add(color);

			DepthStencilAttachment depth = .();
			depth.View = depthView;
			depth.DepthLoadOp = .Clear;
			depth.DepthClearValue = Depth.ClearValue;
			pass.DepthStencilAttachment = depth;

			encoder.BeginRenderPass(pass).End();
		}

		// Pass 2 is the sky itself: load the colour, read only depth, fullscreen at the far plane.
		{
			RenderPassDesc pass = .();
			ColorAttachment color = .();
			color.View = colorView;
			color.LoadOp = .Load;
			pass.ColorAttachments.Add(color);

			ColorAttachment velocity = .();
			velocity.View = velocityView;
			velocity.LoadOp = .Clear;
			pass.ColorAttachments.Add(velocity);

			DepthStencilAttachment depth = .();
			depth.View = depthView;
			depth.DepthReadOnly = true;
			pass.DepthStencilAttachment = depth;

			let sky = encoder.BeginRenderPass(pass);
			sky.SetPipeline(pipeline);
			sky.Draw(3, 1, 0, 0);
			sky.End();
		}

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 4 * 256;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();

		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 4;
		region.TextureExtent = .(4, 4, 1);
		encoder.CopyTextureToBuffer(colorTexture, readback, region);

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(encoder.Finish());
		queue.Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		let pixel = (uint8*)readback.Map();
		Test.Assert(pixel != null);
		Test.Assert(pixel[2] == 255, "the sky blue fragment survived the far plane test");
		readback.Unmap();

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref readback);
		device.DestroyCommandPool(ref pool);
		device.DestroyRenderPipeline(ref pipeline);
		device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyShaderModule(ref module);
		device.DestroyTextureView(ref velocityView);
		device.DestroyTexture(ref velocityTexture);
		device.DestroyTextureView(ref colorView);
		device.DestroyTexture(ref colorTexture);
		device.DestroyTextureView(ref depthView);
		device.DestroyTexture(ref depthTexture);
		device.Destroy();
	}
}
