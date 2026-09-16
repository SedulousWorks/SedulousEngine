using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The DXC register shift scheme end to end, against a real WGSL pipeline.
///
/// WebGpuBindingShiftTests pins the ARITHMETIC. This pins that the shifted layout and a
/// shader written against the shifted numbers actually agree: if they did not, pipeline
/// creation is where it would show, and nowhere earlier.
class WebGpuPipelineTests
{
	/// The compact WebGPU profile: a CBV stays at its register, an SRV shifts by 100 and
	/// a sampler by 300, which is what the WGSL below is written against.
	private const String cShiftedWgsl = """
		@group(0) @binding(0) var<uniform> tintUniform : vec4f;
		@group(0) @binding(100) var sceneTexture : texture_2d<f32>;
		@group(0) @binding(300) var sceneSampler : sampler;
		@vertex fn vertexMain(@builtin(vertex_index) i : u32) -> @builtin(position) vec4f
		{ return vec4f(f32(i), 0.0, 0.0, 1.0); }
		@fragment fn fragmentMain() -> @location(0) vec4f
		{ return textureSampleLevel(sceneTexture, sceneSampler, vec2f(0.5), 0.0)
		    * tintUniform; }
		""";

	private const String cComputeWgsl = "@compute @workgroup_size(1) fn computeMain() { }";

	[Test]
	public static void AShiftedLayoutAndItsShaderAgree()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		// One layout carrying all three shift classes.
		BindGroupLayoutEntry[3] entries = .(
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 3);
		var layout = device.CreateBindGroupLayout(layoutDesc).GetValueOrDefault();
		Test.Assert(layout != null);

		// The resources the group binds.
		var uboDesc = BufferDesc();
		uboDesc.Size = 16;
		uboDesc.Usage = .Uniform;
		uboDesc.Memory = .CpuToGpu;
		var ubo = device.CreateBuffer(uboDesc).GetValueOrDefault();
		Test.Assert(ubo != null);

		var texDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		texDesc.Usage = .Sampled | .CopyDst;
		var texture = device.CreateTexture(texDesc).GetValueOrDefault();
		Test.Assert(texture != null);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(texture, viewDesc).GetValueOrDefault();
		Test.Assert(view != null);

		var sampler = device.CreateSampler(.()).GetValueOrDefault();
		Test.Assert(sampler != null);

		BindGroupEntry[3] groupEntries = .(
			BindGroupEntry.BufferEntry(ubo, 0, 16),
			BindGroupEntry.TextureEntry(view),
			BindGroupEntry.SamplerEntry(sampler));

		var groupDesc = BindGroupDesc();
		groupDesc.Layout = layout;
		groupDesc.Entries = .(&groupEntries[0], 3);
		var group = device.CreateBindGroup(groupDesc).GetValueOrDefault();
		Test.Assert(group != null);

		IBindGroupLayout[1] layouts = .(layout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		var pipelineLayout = device.CreatePipelineLayout(pipelineLayoutDesc).GetValueOrDefault();
		Test.Assert(pipelineLayout != null);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cShiftedWgsl.Ptr, cShiftedWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		ColorTargetState target = .();
		target.Format = .RGBA8Unorm;
		target.Blend = BlendState.AlphaBlend;

		FragmentState fragment = .();
		fragment.Shader = .(module, "fragmentMain", .Fragment);
		fragment.Targets = .(&target, 1);

		var rpDesc = RenderPipelineDesc();
		rpDesc.Layout = pipelineLayout;
		rpDesc.Vertex.Shader = .(module, "vertexMain", .Vertex);
		rpDesc.Fragment = fragment;

		var renderPipeline = device.CreateRenderPipeline(rpDesc).GetValueOrDefault();
		Test.Assert(renderPipeline != null,
			"the shifted shader and the shifted layout agree");

		// Wireframe has no WebGPU shape at all, polygon mode not being in the API.
		var wireframeDesc = rpDesc;
		wireframeDesc.Primitive.FillMode = .Wireframe;
		Test.Assert(device.CreateRenderPipeline(wireframeDesc) case .Err,
			"a wireframe fill is refused rather than silently filled");

		device.DestroyRenderPipeline(ref renderPipeline);
		device.DestroyShaderModule(ref module);
		device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyBindGroup(ref group);
		device.DestroyBindGroupLayout(ref layout);
		device.DestroySampler(ref sampler);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref texture);
		device.DestroyBuffer(ref ubo);

		device.WaitIdle();
		Test.Assert(!device.IsLost());
		device.Destroy();
	}

	[Test]
	public static void AComputePipelineBuildsOnAnEmptyLayout()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)cComputeWgsl.Ptr, cComputeWgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Test.Assert(module != null);

		var emptyLayout = device.CreatePipelineLayout(.()).GetValueOrDefault();
		Test.Assert(emptyLayout != null, "a layout binding nothing is still a layout");

		var cpDesc = ComputePipelineDesc();
		cpDesc.Layout = emptyLayout;
		cpDesc.Compute = .(module, "computeMain", .Compute);
		var pipeline = device.CreateComputePipeline(cpDesc).GetValueOrDefault();
		Test.Assert(pipeline != null);

		device.DestroyComputePipeline(ref pipeline);
		device.DestroyPipelineLayout(ref emptyLayout);
		device.DestroyShaderModule(ref module);

		device.WaitIdle();
		Test.Assert(!device.IsLost());
		device.Destroy();
	}
}
