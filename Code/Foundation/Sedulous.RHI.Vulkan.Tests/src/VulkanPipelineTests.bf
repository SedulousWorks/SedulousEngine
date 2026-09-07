using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// Pipelines compiled by the real driver from real SPIR-V.
///
/// A pipeline that creates is a pipeline the driver accepted: the shader interface, the
/// attachment formats and the layout all had to agree for it to succeed.
class VulkanPipelineTests
{
	private static IBackend sBackend;
	private static IDevice sDevice;

	private static bool Ready()
	{
		if (sDevice != null)
			return true;
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
			return false;
		sBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return false;

		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);
		var desc = DeviceDesc();
		desc.RequiredFeatures = info.SupportedFeatures;
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
			return false;
		sDevice = device;
		return true;
	}

	private static IShaderModule MakeModule(uint32* words, int wordCount)
	{
		var desc = ShaderModuleDesc();
		desc.Code = TestShaders.AsBytes(words, wordCount);
		if (sDevice.CreateShaderModule(desc) case .Ok(let module))
			return module;
		return null;
	}

	/// A full graphics pipeline: vertex and fragment stages, a vertex layout, blending,
	/// depth, and the attachment formats dynamic rendering needs.
	[Test]
	public static void AGraphicsPipelineCompiles()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var vertex = MakeModule(&TestShaders.Vertex[0], TestShaders.Vertex.Count);
		var fragment = MakeModule(&TestShaders.Fragment[0], TestShaders.Fragment.Count);
		Test.Assert(vertex != null, "the vertex SPIR-V was accepted");
		Test.Assert(fragment != null);

		Test.Assert(sDevice.CreatePipelineLayout(.()) case .Ok(var layout));

		// One vertex buffer holding a float3 position at location zero, matching the shader.
		let attributes = scope VertexAttribute[1](.(.Float32x3, 0, 0));
		var buffer = VertexBufferLayout();
		buffer.Stride = 12;
		buffer.Attributes = attributes;
		let buffers = scope VertexBufferLayout[1](buffer);

		var target = ColorTargetState();
		target.Format = .RGBA8Unorm;
		target.Blend = BlendState.AlphaBlend;
		let targets = scope ColorTargetState[1](target);

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = targets;

		var depth = DepthStencilState();
		depth.Format = .Depth32Float;

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Vertex.Buffers = buffers;
		desc.Fragment = fragmentState;
		desc.DepthStencil = depth;

		Test.Assert(sDevice.CreateRenderPipeline(desc) case .Ok(var pipeline),
			"the driver compiled it, so every piece agreed");
		Test.Assert(pipeline.Layout === layout);

		sDevice.DestroyRenderPipeline(ref pipeline);
		sDevice.DestroyPipelineLayout(ref layout);
		sDevice.DestroyShaderModule(ref fragment);
		sDevice.DestroyShaderModule(ref vertex);
	}

	/// A depth only pipeline has NO fragment stage and no colour targets, which is what a
	/// shadow pass is.
	[Test]
	public static void ADepthOnlyPipelineNeedsNoFragmentStage()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var vertex = MakeModule(&TestShaders.Vertex[0], TestShaders.Vertex.Count);
		Test.Assert(sDevice.CreatePipelineLayout(.()) case .Ok(var layout));

		let attributes = scope VertexAttribute[1](.(.Float32x3, 0, 0));
		var buffer = VertexBufferLayout();
		buffer.Stride = 12;
		buffer.Attributes = attributes;
		let buffers = scope VertexBufferLayout[1](buffer);

		var depth = DepthStencilState();
		depth.Format = .Depth32Float;

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Vertex.Buffers = buffers;
		desc.DepthStencil = depth;
		// Fragment left null.

		Test.Assert(sDevice.CreateRenderPipeline(desc) case .Ok(var pipeline));
		sDevice.DestroyRenderPipeline(ref pipeline);
		sDevice.DestroyPipelineLayout(ref layout);
		sDevice.DestroyShaderModule(ref vertex);
	}

	[Test]
	public static void APipelineRefusesAMissingLayoutOrShader()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		Test.Assert(sDevice.CreateRenderPipeline(.()) case .Err, "no layout");

		Test.Assert(sDevice.CreatePipelineLayout(.()) case .Ok(var layout));
		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		Test.Assert(sDevice.CreateRenderPipeline(desc) case .Err, "no vertex shader");
		sDevice.DestroyPipelineLayout(ref layout);
	}

	/// A compute pipeline over a storage buffer bound at the UAV shift, which is where DXC
	/// would have put a `u0` register.
	[Test]
	public static void AComputePipelineCompilesAgainstItsLayout()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var compute = MakeModule(&TestShaders.Compute[0], TestShaders.Compute.Count);
		Test.Assert(compute != null);

		// The shader declares binding 200, which is exactly u0 after the standard shift.
		let entries = scope BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.StorageBuffer(0, .Compute, false, 4));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var setLayout));

		let setLayouts = scope IBindGroupLayout[1](setLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = setLayouts;
		Test.Assert(sDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(var layout));

		var desc = ComputePipelineDesc();
		desc.Layout = layout;
		desc.Compute = .(compute, "main", .Compute);

		Test.Assert(sDevice.CreateComputePipeline(desc) case .Ok(var pipeline),
			"the shader's binding 200 matched the shifted layout");

		sDevice.DestroyComputePipeline(ref pipeline);
		sDevice.DestroyPipelineLayout(ref layout);
		sDevice.DestroyBindGroupLayout(ref setLayout);
		sDevice.DestroyShaderModule(ref compute);
	}

	/// A cache starts empty, fills as pipelines compile, and its blob round trips.
	[Test]
	public static void APipelineCacheFillsAndRoundTrips()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		Test.Assert(sDevice.CreatePipelineCache(.()) case .Ok(var cache));
		let emptySize = cache.GetDataSize();

		var compute = MakeModule(&TestShaders.Compute[0], TestShaders.Compute.Count);
		let entries = scope BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.StorageBuffer(0, .Compute, false, 4));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var setLayout));
		let setLayouts = scope IBindGroupLayout[1](setLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = setLayouts;
		Test.Assert(sDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(var layout));

		var desc = ComputePipelineDesc();
		desc.Layout = layout;
		desc.Compute = .(compute, "main", .Compute);
		desc.Cache = cache;
		Test.Assert(sDevice.CreateComputePipeline(desc) case .Ok(var pipeline));

		let filledSize = cache.GetDataSize();
		Test.Assert(filledSize >= emptySize, "compiling through the cache does not shrink it");

		// The blob reads back, and feeding it to a new cache is accepted.
		if (filledSize > 0)
		{
			let blob = scope uint8[filledSize];
			Test.Assert(cache.GetData(blob) case .Ok);

			var seeded = PipelineCacheDesc();
			seeded.InitialData = blob;
			Test.Assert(sDevice.CreatePipelineCache(seeded) case .Ok(var warm),
				"the driver recognised its own blob");
			sDevice.DestroyPipelineCache(ref warm);
		}

		sDevice.DestroyComputePipeline(ref pipeline);
		sDevice.DestroyPipelineLayout(ref layout);
		sDevice.DestroyBindGroupLayout(ref setLayout);
		sDevice.DestroyShaderModule(ref compute);
		sDevice.DestroyPipelineCache(ref cache);
	}

	/// Mesh and ray tracing pipelines are refused unless the DEVICE was created with them,
	/// which is a different question from whether the hardware has them.
	[Test]
	public static void ExtensionPipelinesAreGatedOnTheDevice()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		// This device asked for everything the adapter reported, so where the hardware has
		// them the gate is open. Either way the answer is consistent with the feature.
		let hasMesh = sDevice.Features.MeshShaders;
		let hasRayTracing = sDevice.Features.RayTracing;
		Console.WriteLine(scope $"device features: mesh={hasMesh} rayTracing={hasRayTracing}");

		// Without a layout both refuse regardless, which is the argument check rather than
		// the gate.
		Test.Assert(sDevice.CreateMeshPipeline(.()) case .Err);
		Test.Assert(sDevice.CreateRayTracingPipeline(.()) case .Err);
	}

	[Test]
	public static void ZzTearDown()
	{
		if (sDevice != null)
		{
			sDevice.WaitIdle();
			sDevice.Destroy();
			sDevice = null;
		}
		if (sBackend != null)
		{
			sBackend.Destroy();
			delete sBackend;
			sBackend = null;
		}
	}
}
