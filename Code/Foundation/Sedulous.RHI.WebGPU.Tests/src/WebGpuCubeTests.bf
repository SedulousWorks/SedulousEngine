using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The IBL and sky shape: render INTO per face 2D views of a cube, then sample the CUBE
/// view and prove through a readback that the right face came back.
///
/// Two view dimensions over one texture is the part that goes wrong quietly. A layer view
/// that ignored its base array layer, or a cube view built with the wrong layer count,
/// still creates and still draws; only the pixel says which face was fetched.
class WebGpuCubeTests
{
	private const String cCubeWgsl = """
		@group(0) @binding(100) var environmentCube : texture_cube<f32>;
		@group(0) @binding(300) var environmentSampler : sampler;
		@vertex fn vertexMain(@builtin(vertex_index) index : u32)
		    -> @builtin(position) vec4f {
		  let uv = vec2f(f32((index << 1u) & 2u), f32(index & 2u));
		  return vec4f(uv * 2.0 - 1.0, 0.0, 1.0);
		}
		@fragment fn fragmentMain() -> @location(0) vec4f {
		  return textureSampleLevel(environmentCube, environmentSampler,
		                            vec3f(1.0, 0.0, 0.0), 0.0);
		}
		""";

	[Test]
	public static void ACubeViewSamplesTheFaceThatWasRenderedIntoIt()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		var cubeDesc = TextureDesc();
		cubeDesc.Format = .RGBA8Unorm;
		cubeDesc.Width = 4;
		cubeDesc.Height = 4;
		cubeDesc.ArrayLayerCount = 6;
		cubeDesc.Usage = .RenderTarget | .Sampled;
		var cube = device.CreateTexture(cubeDesc).GetValueOrDefault();
		Test.Assert(cube != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();

		// Each face is cleared to its OWN red level through its own 2D layer view, so a
		// view that ignored baseArrayLayer would leave five faces at whatever face 0 got.
		ITextureView[6] faceViews = .();
		for (uint32 face = 0; face < 6; face++)
		{
			var faceDesc = TextureViewDesc();
			faceDesc.Format = .RGBA8Unorm;
			faceDesc.Dimension = .Texture2D;
			faceDesc.BaseArrayLayer = face;
			faceDesc.ArrayLayerCount = 1;
			faceViews[face] = device.CreateTextureView(cube, faceDesc).GetValueOrDefault();
			Test.Assert(faceViews[face] != null);

			RenderPassDesc pass = .();
			ColorAttachment color = .();
			color.View = faceViews[face];
			color.ClearValue = .((float)(face + 1) / 8.0f, 0, 0, 1);
			pass.ColorAttachments.Add(color);
			encoder.BeginRenderPass(pass).End();
		}

		var cubeViewDesc = TextureViewDesc();
		cubeViewDesc.Format = .RGBA8Unorm;
		cubeViewDesc.Dimension = .TextureCube;
		cubeViewDesc.ArrayLayerCount = 6;
		var cubeView = device.CreateTextureView(cube, cubeViewDesc).GetValueOrDefault();
		Test.Assert(cubeView != null);

		var sampler = device.CreateSampler(.()).GetValueOrDefault();

		BindGroupLayoutEntry[2] layoutEntries = .(
			BindGroupLayoutEntry.SampledTexture(0, .Fragment, .TextureCube),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&layoutEntries[0], 2);
		var layout = device.CreateBindGroupLayout(layoutDesc).GetValueOrDefault();
		Test.Assert(layout != null);

		BindGroupEntry[2] groupEntries = .(
			BindGroupEntry.TextureEntry(cubeView),
			BindGroupEntry.SamplerEntry(sampler));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = layout;
		groupDesc.Entries = .(&groupEntries[0], 2);
		var group = device.CreateBindGroup(groupDesc).GetValueOrDefault();
		Test.Assert(group != null);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cCubeWgsl.Ptr, cCubeWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		IBindGroupLayout[1] layouts = .(layout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		var pipelineLayout = device.CreatePipelineLayout(pipelineLayoutDesc).GetValueOrDefault();

		ColorTargetState target = .();
		target.Format = .RGBA8Unorm;
		FragmentState fragment = .();
		fragment.Shader = .(module, "fragmentMain", .Fragment);
		fragment.Targets = .(&target, 1);

		var pipelineDesc = RenderPipelineDesc();
		pipelineDesc.Layout = pipelineLayout;
		pipelineDesc.Vertex.Shader = .(module, "vertexMain", .Vertex);
		pipelineDesc.Fragment = fragment;
		var pipeline = device.CreateRenderPipeline(pipelineDesc).GetValueOrDefault();
		Test.Assert(pipeline != null);

		var outDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 1, 1);
		outDesc.Usage = .RenderTarget | .CopySrc;
		var outTexture = device.CreateTexture(outDesc).GetValueOrDefault();
		var outViewDesc = TextureViewDesc();
		outViewDesc.Format = .RGBA8Unorm;
		var outView = device.CreateTextureView(outTexture, outViewDesc).GetValueOrDefault();

		RenderPassDesc samplePass = .();
		ColorAttachment sampleColor = .();
		sampleColor.View = outView;
		samplePass.ColorAttachments.Add(sampleColor);

		let pass = encoder.BeginRenderPass(samplePass);
		pass.SetPipeline(pipeline);
		pass.SetBindGroup(0, group);
		pass.Draw(3, 1, 0, 0);
		pass.End();

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 256;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();

		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 1;
		region.TextureExtent = .(1, 1, 1);
		encoder.CopyTextureToBuffer(outTexture, readback, region);

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(encoder.Finish());
		queue.Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		let pixel = (uint8*)readback.Map();
		Test.Assert(pixel != null);
		// Direction +X is face 0, whose red is 1/8, which quantises to 32.
		Test.Assert(pixel[0] == 32, "the +X face came back, not another one");
		readback.Unmap();

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref readback);
		device.DestroyTextureView(ref outView);
		device.DestroyTexture(ref outTexture);
		device.DestroyRenderPipeline(ref pipeline);
		device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyShaderModule(ref module);
		device.DestroyBindGroup(ref group);
		device.DestroyBindGroupLayout(ref layout);
		device.DestroySampler(ref sampler);
		device.DestroyTextureView(ref cubeView);

		for (int face = 0; face < 6; face++)
			device.DestroyTextureView(ref faceViews[face]);

		device.DestroyTexture(ref cube);
		device.DestroyCommandPool(ref pool);
		device.Destroy();
	}
}
