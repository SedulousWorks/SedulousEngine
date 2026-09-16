using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;

namespace Sedulous.RHI.WebGPU;

/// The internal fullscreen blit pass.
///
/// WebGPU has no image blit, so a scaling blit and every mip generation are a RENDER
/// PASS that samples the source into the destination, which is what a DX12 backend does
/// for the same reason.
///
/// The shader is WGSL and this is an INTERNAL pipeline with its own compact layout: no
/// DXC, and none of the register shifts the engine's own layouts carry. Pipelines are
/// cached per destination format, the format being the only thing that varies.
///
/// Colour only. A depth blit would need a depth output variant, which nothing asks for
/// yet, and a 3D texture would need a pass per slice; both fail rather than pretend.
sealed class WebGpuBlitHelper
{
	/// One cached pipeline, keyed by the destination format it writes.
	private struct FormatPipeline
	{
		public WGPUTextureFormat Format;
		public WGPURenderPipeline Pipeline;
	}

	private const String cBlitWgsl = """
		@group(0) @binding(0) var sourceTexture : texture_2d<f32>;
		@group(0) @binding(1) var sourceSampler : sampler;
		struct VertexOutput {
		  @builtin(position) position : vec4f,
		  @location(0) uv : vec2f,
		}
		@vertex fn vertexMain(@builtin(vertex_index) index : u32) -> VertexOutput {
		  var output : VertexOutput;
		  let uv = vec2f(f32((index << 1u) & 2u), f32(index & 2u));
		  output.position = vec4f(uv * 2.0 - 1.0, 0.0, 1.0);
		  output.uv = vec2f(uv.x, 1.0 - uv.y);
		  return output;
		}
		@fragment fn fragmentMain(input : VertexOutput) -> @location(0) vec4f {
		  return textureSampleLevel(sourceTexture, sourceSampler, input.uv, 0.0);
		}
		""";

	private WGPUDevice mDevice;
	private WGPUShaderModule mShaderModule = null;
	private WGPUSampler mSampler = null;
	private WGPUBindGroupLayout mBindGroupLayout = null;
	private WGPUPipelineLayout mPipelineLayout = null;
	private List<FormatPipeline> mPipelines = new .() ~ delete _;

	public void Initialize(WGPUDevice device)
	{
		mDevice = device;
	}

	public ~this()
	{
		Release();
	}

	public void Release()
	{
		for (let cached in mPipelines)
			wgpuRenderPipelineRelease(cached.Pipeline);

		mPipelines.Clear();

		if (mPipelineLayout != null)
		{
			wgpuPipelineLayoutRelease(mPipelineLayout);
			mPipelineLayout = null;
		}

		if (mBindGroupLayout != null)
		{
			wgpuBindGroupLayoutRelease(mBindGroupLayout);
			mBindGroupLayout = null;
		}

		if (mSampler != null)
		{
			wgpuSamplerRelease(mSampler);
			mSampler = null;
		}

		if (mShaderModule != null)
		{
			wgpuShaderModuleRelease(mShaderModule);
			mShaderModule = null;
		}
	}

	/// Records a fullscreen sample of one view into another on the given encoder.
	///
	/// The views are read only here; the CALLER releases them. False when the
	/// destination format has no blit pipeline.
	public bool Blit(WGPUCommandEncoder encoder, WGPUTextureView sourceView,
		WGPUTextureView destinationView, WGPUTextureFormat destinationFormat)
	{
		let pipeline = PipelineForFormat(destinationFormat);
		if (pipeline == null)
			return false;

		// Per element .(), not a bare .(): a Beef fixed array ZERO FILLS rather than
		// running each element's initialisers, and an entry's size defaults to the whole
		// buffer rather than to nothing.
		WGPUBindGroupEntry[2] entries = .(.(), .());
		entries[0].binding = 0;
		entries[0].textureView = sourceView;
		entries[1].binding = 1;
		entries[1].sampler = mSampler;

		WGPUBindGroupDescriptor groupDesc = .();
		groupDesc.layout = mBindGroupLayout;
		groupDesc.entryCount = 2;
		groupDesc.entries = &entries[0];

		let group = wgpuDeviceCreateBindGroup(mDevice, &groupDesc);

		WGPURenderPassColorAttachment color = .();
		color.view = destinationView;
		color.loadOp = .WGPULoadOp_Clear;
		color.storeOp = .WGPUStoreOp_Store;

		WGPURenderPassDescriptor passDesc = .();
		passDesc.colorAttachmentCount = 1;
		passDesc.colorAttachments = &color;

		let pass = wgpuCommandEncoderBeginRenderPass(encoder, &passDesc);
		wgpuRenderPassEncoderSetPipeline(pass, pipeline);
		wgpuRenderPassEncoderSetBindGroup(pass, 0, group, 0, null);
		// Three vertices, no buffers: the vertex shader derives a fullscreen triangle
		// from the index alone.
		wgpuRenderPassEncoderDraw(pass, 3, 1, 0, 0);
		wgpuRenderPassEncoderEnd(pass);
		wgpuRenderPassEncoderRelease(pass);
		wgpuBindGroupRelease(group);
		return true;
	}

	/// The module, sampler and layouts, which every format's pipeline shares.
	private void EnsureCommon()
	{
		if (mShaderModule != null)
			return;

		WGPUShaderSourceWGSL wgsl = .();
		wgsl.chain.sType = .WGPUSType_ShaderSourceWGSL;
		wgsl.code = .() { data = cBlitWgsl.Ptr, length = (uint)cBlitWgsl.Length };

		WGPUShaderModuleDescriptor moduleDesc = .();
		moduleDesc.nextInChain = &wgsl.chain;
		mShaderModule = wgpuDeviceCreateShaderModule(mDevice, &moduleDesc);

		WGPUSamplerDescriptor samplerDesc = .();
		samplerDesc.magFilter = .WGPUFilterMode_Linear;
		samplerDesc.minFilter = .WGPUFilterMode_Linear;
		mSampler = wgpuDeviceCreateSampler(mDevice, &samplerDesc);

		// Per element again, for the same reason: each binding kind's type field defaults
		// to Undefined rather than to the zero that means something else.
		WGPUBindGroupLayoutEntry[2] entries = .(.(), .());
		entries[0].binding = 0;
		entries[0].visibility = WGPUShaderStage_Fragment;
		entries[0].texture.sampleType = .WGPUTextureSampleType_Float;
		entries[0].texture.viewDimension = .WGPUTextureViewDimension_2D;
		entries[1].binding = 1;
		entries[1].visibility = WGPUShaderStage_Fragment;
		entries[1].sampler.type = .WGPUSamplerBindingType_Filtering;

		WGPUBindGroupLayoutDescriptor layoutDesc = .();
		layoutDesc.entryCount = 2;
		layoutDesc.entries = &entries[0];
		mBindGroupLayout = wgpuDeviceCreateBindGroupLayout(mDevice, &layoutDesc);

		WGPUPipelineLayoutDescriptor pipelineLayoutDesc = .();
		pipelineLayoutDesc.bindGroupLayoutCount = 1;
		pipelineLayoutDesc.bindGroupLayouts = &mBindGroupLayout;
		mPipelineLayout = wgpuDeviceCreatePipelineLayout(mDevice, &pipelineLayoutDesc);
	}

	private WGPURenderPipeline PipelineForFormat(WGPUTextureFormat format)
	{
		if (format == .WGPUTextureFormat_Undefined)
			return null;

		for (let cached in mPipelines)
		{
			if (cached.Format == format)
				return cached.Pipeline;
		}

		EnsureCommon();
		if (mShaderModule == null)
			return null;

		WGPURenderPipelineDescriptor pipelineDesc = .();
		pipelineDesc.layout = mPipelineLayout;
		pipelineDesc.vertex.module = mShaderModule;
		pipelineDesc.vertex.entryPoint = WebGpuConversions.ToWgpuStringView("vertexMain");

		WGPUColorTargetState target = .();
		target.format = format;

		WGPUFragmentState fragment = .();
		fragment.module = mShaderModule;
		fragment.entryPoint = WebGpuConversions.ToWgpuStringView("fragmentMain");
		fragment.targetCount = 1;
		fragment.targets = &target;
		pipelineDesc.fragment = &fragment;

		let pipeline = wgpuDeviceCreateRenderPipeline(mDevice, &pipelineDesc);
		if (pipeline == null)
			return null;

		mPipelines.Add(.() { Format = format, Pipeline = pipeline });
		return pipeline;
	}
}
