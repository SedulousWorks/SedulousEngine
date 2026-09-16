using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// Push constants through the UNIFORM BUFFER fallback, verified on a real GPU.
///
/// A browser has no immediates, so push constants there are emulated as a uniform buffer
/// bound at the pipeline's group, binding zero. That path has no runtime to exercise it
/// yet, so it is FORCED on the wgpu-native device here and the readback proves a value
/// set through SetPushConstants actually reaches the shader.
class WebGpuPushConstantTests
{
	/// Reads the emulated block at group 1 and copies it into a storage buffer at the UAV
	/// shifted binding. Binding the wrong buffer or the wrong group shows up in the
	/// readback and nowhere earlier.
	private const String cComputeWgsl = """
		struct PushBlock { data : vec4<u32> };
		@group(1) @binding(0) var<uniform> pc : PushBlock;
		@group(0) @binding(200) var<storage, read_write> outBuf : array<u32>;
		@compute @workgroup_size(1) fn computeMain() {
		    outBuf[0] = pc.data.x; outBuf[1] = pc.data.y;
		    outBuf[2] = pc.data.z; outBuf[3] = pc.data.w;
		}
		""";

	/// No bind groups at all, so the push block lives at GROUP 0 rather than the default 1.
	private const String cRenderWgsl = """
		struct PushBlock { color : vec4f };
		@group(0) @binding(0) var<uniform> pc : PushBlock;
		@vertex fn vertexMain(@builtin(vertex_index) index : u32)
		    -> @builtin(position) vec4f {
		  let uv = vec2f(f32((index << 1u) & 2u), f32(index & 2u));
		  return vec4f(uv * 4.0 - 1.0, 0.0, 1.0);
		}
		@fragment fn fragmentMain() -> @location(0) vec4f { return pc.color; }
		""";

	[Test]
	public static void AComputePushReachesTheShaderThroughTheEmulation()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		// Forced even though this device HAS immediates, which is the whole point: the
		// browser path gets exercised against a real GPU.
		((WebGpuDevice)device).SetForceUniformPushConstants(true);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cComputeWgsl.Ptr, cComputeWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		BindGroupLayoutEntry[1] layoutEntries = .(
			BindGroupLayoutEntry.StorageBuffer(0, .Compute, false));
		var bglDesc = BindGroupLayoutDesc();
		bglDesc.Entries = .(&layoutEntries[0], 1);
		var bgl = device.CreateBindGroupLayout(bglDesc).GetValueOrDefault();
		Test.Assert(bgl != null);

		var storageDesc = BufferDesc();
		storageDesc.Size = 16;
		storageDesc.Usage = .Storage | .CopySrc;
		storageDesc.Memory = .GpuOnly;
		var storage = device.CreateBuffer(storageDesc).GetValueOrDefault();
		Test.Assert(storage != null);

		BindGroupEntry[1] groupEntries = .(BindGroupEntry.BufferEntry(storage, 0, 16));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = bgl;
		groupDesc.Entries = .(&groupEntries[0], 1);
		var bindGroup = device.CreateBindGroup(groupDesc).GetValueOrDefault();
		Test.Assert(bindGroup != null);

		// The range targets group 1, so the layout has to SYNTHESIZE the emulated uniform
		// bind group layout there rather than declaring immediates.
		PushConstantRange pushRange = .();
		pushRange.Stages = .Compute;
		pushRange.Offset = 0;
		pushRange.Size = 16;
		pushRange.BindGroupIndex = 1;

		IBindGroupLayout[1] layouts = .(bgl);
		var plDesc = PipelineLayoutDesc();
		plDesc.BindGroupLayouts = .(&layouts[0], 1);
		plDesc.PushConstantRanges = .(&pushRange, 1);
		var pipelineLayout = device.CreatePipelineLayout(plDesc).GetValueOrDefault();
		Test.Assert(pipelineLayout != null);

		var cpDesc = ComputePipelineDesc();
		cpDesc.Layout = pipelineLayout;
		cpDesc.Compute = .(module, "computeMain", .Compute);
		var pipeline = device.CreateComputePipeline(cpDesc).GetValueOrDefault();
		Test.Assert(pipeline != null);

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 16;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();

		var pool = device.CreateCommandPool(.Compute).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();

		uint32[4] pushValues = .(0xA1A1A1A1, 0xB2B2B2B2, 0xC3C3C3C3, 0xD4D4D4D4);

		let computePass = encoder.BeginComputePass();
		Test.Assert(computePass != null);
		computePass.SetPipeline(pipeline);
		computePass.SetBindGroup(0, bindGroup);
		computePass.SetPushConstants(.Compute, 0, 16, &pushValues[0]);
		computePass.Dispatch(1, 1, 1);
		computePass.End();
		encoder.CopyBufferToBuffer(storage, 0, readback, 0, 16);

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(encoder.Finish());
		device.GetQueue(.Compute, 0).Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		let result = (uint32*)readback.Map();
		Test.Assert(result != null);
		Test.Assert(result[0] == pushValues[0], "the push data reached the shader...");
		Test.Assert(result[1] == pushValues[1], "...through the emulated uniform bind group");
		Test.Assert(result[2] == pushValues[2]);
		Test.Assert(result[3] == pushValues[3]);
		readback.Unmap();

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref readback);
		device.DestroyCommandPool(ref pool);
		device.DestroyComputePipeline(ref pipeline);
		device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyBuffer(ref storage);
		device.DestroyBindGroup(ref bindGroup);
		device.DestroyBindGroupLayout(ref bgl);
		device.DestroyShaderModule(ref module);
		device.Destroy();
	}

	/// The debug geometry shape: a pipeline with NO bind groups and its push block at group
	/// 0, so the emulation has to synthesize the uniform there.
	///
	/// Two draws with different push values into two pixels also prove the FRESH BUFFER PER
	/// DRAW design: the second SetPushConstants must not reach back and clobber what the
	/// first draw has not issued yet.
	[Test]
	public static void TwoDrawsKeepTheirOwnPushValues()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		((WebGpuDevice)device).SetForceUniformPushConstants(true);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cRenderWgsl.Ptr, cRenderWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		PushConstantRange pushRange = .();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = 16;
		pushRange.BindGroupIndex = 0; // no bind groups, so the block lives at group 0

		var plDesc = PipelineLayoutDesc();
		plDesc.PushConstantRanges = .(&pushRange, 1);
		var pipelineLayout = device.CreatePipelineLayout(plDesc).GetValueOrDefault();
		Test.Assert(pipelineLayout != null);

		ColorTargetState target = .();
		target.Format = .RGBA8Unorm;
		FragmentState frag = .();
		frag.Shader = .(module, "fragmentMain", .Fragment);
		frag.Targets = .(&target, 1);

		var rpDesc = RenderPipelineDesc();
		rpDesc.Layout = pipelineLayout;
		rpDesc.Vertex.Shader = .(module, "vertexMain", .Vertex);
		rpDesc.Fragment = frag;
		rpDesc.Primitive.Topology = .TriangleList;
		var pipeline = device.CreateRenderPipeline(rpDesc).GetValueOrDefault();
		Test.Assert(pipeline != null);

		var texDesc = TextureDesc();
		texDesc.Format = .RGBA8Unorm;
		texDesc.Width = 2;
		texDesc.Height = 1;
		texDesc.Usage = .RenderTarget | .CopySrc;
		var tex = device.CreateTexture(texDesc).GetValueOrDefault();
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(tex, viewDesc).GetValueOrDefault();

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 256; // one row, aligned
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();

		RenderPassDesc pass = .();
		ColorAttachment color = .();
		color.View = view;
		color.ClearValue = .(0, 0, 0, 0);
		pass.ColorAttachments.Add(color);

		let rp = encoder.BeginRenderPass(pass);
		Test.Assert(rp != null);
		rp.SetPipeline(pipeline);

		float[4] red = .(1.0f, 0.0f, 0.0f, 1.0f);
		float[4] green = .(0.0f, 1.0f, 0.0f, 1.0f);

		rp.SetPushConstants(.Fragment, 0, 16, &red[0]);
		rp.SetScissor(0, 0, 1, 1); // the left pixel
		rp.Draw(3, 1, 0, 0);
		rp.SetPushConstants(.Fragment, 0, 16, &green[0]);
		rp.SetScissor(1, 0, 1, 1); // the right one
		rp.Draw(3, 1, 0, 0);
		rp.End();

		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 1;
		region.TextureExtent = .(2, 1, 1);
		encoder.CopyTextureToBuffer(tex, readback, region);

		var fence = device.CreateFence(0).GetValueOrDefault();
		ICommandBuffer[1] submitted = .(encoder.Finish());
		device.GetQueue(.Graphics, 0).Submit(.(&submitted[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		let pixels = (uint8*)readback.Map();
		Test.Assert(pixels != null);
		Test.Assert(pixels[0] == 255, "left is red: the first draw's push data survived");
		Test.Assert(pixels[1] == 0);
		Test.Assert(pixels[4] == 0, "and right is green");
		Test.Assert(pixels[5] == 255);
		readback.Unmap();

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref readback);
		device.DestroyCommandPool(ref pool);
		device.DestroyRenderPipeline(ref pipeline);
		device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyShaderModule(ref module);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref tex);
		device.Destroy();
	}
}
