using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The resources a device makes, and the things it refuses.
///
/// A refusal here is the point of the case as much as a success is: where WebGPU has no
/// shape for something, the backend fails rather than quietly handing back a stand in.
class WebGpuResourceTests
{
	[Test]
	public static void ACpuToGpuBufferMapsThroughItsShadow()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var desc = BufferDesc();
		desc.Size = 256;
		desc.Usage = .Uniform | .CopyDst;
		desc.Memory = .CpuToGpu;
		var buffer = device.CreateBuffer(desc).GetValueOrDefault();
		Test.Assert(buffer != null);

		let mapped = buffer.Map();
		Test.Assert(mapped != null, "Map hands out the CPU shadow");
		Internal.MemSet(mapped, 0xAB, 256);
		buffer.Unmap(); // a queue ordered upload; a bad one would log GPU validation

		device.WaitIdle();
		Test.Assert(!device.IsLost());

		// GpuOnly has no host view, by contract.
		var gpuOnly = BufferDesc();
		gpuOnly.Size = 64;
		gpuOnly.Usage = .Storage;
		gpuOnly.Memory = .GpuOnly;
		var deviceLocal = device.CreateBuffer(gpuOnly).GetValueOrDefault();
		Test.Assert(deviceLocal != null);
		Test.Assert(deviceLocal.Map() == null, "a GpuOnly buffer has no host view");

		device.DestroyBuffer(ref deviceLocal);
		device.DestroyBuffer(ref buffer);
		device.Destroy();
	}

	[Test]
	public static void ATextureTakesAViewAndAnUnknownFormatIsRefused()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var texture = device
			.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64)).GetValueOrDefault();
		Test.Assert(texture != null);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(texture, viewDesc).GetValueOrDefault();
		Test.Assert(view != null);
		Test.Assert(view.Texture == texture, "a view names the texture it came from");

		// 16 bit norms have no core WebGPU equivalent, so creation FAILS rather than
		// quietly substituting a format that would render wrong.
		Test.Assert(device.CreateTexture(TextureDesc.RenderTarget(.RGBA16Unorm, 4, 4))
			case .Err, "a format WebGPU does not have is refused");

		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref texture);
		device.Destroy();
	}

	/// Anisotropy is only legal with linear filtering in WebGPU, so a nearest sampler
	/// asking for 8x has to be CLAMPED rather than passed through to abort the device.
	[Test]
	public static void ANearestSamplerWithAnisotropyIsClamped()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var desc = SamplerDesc();
		desc.MinFilter = .Nearest;
		desc.MaxAnisotropy = 8;
		var sampler = device.CreateSampler(desc).GetValueOrDefault();
		Test.Assert(sampler != null, "the backend clamps rather than failing validation");

		device.WaitIdle();
		Test.Assert(!device.IsLost(), "and the device survived it");

		device.DestroySampler(ref sampler);
		device.Destroy();
	}

	/// The non SPIR-V ingestion branch: which path a module takes is decided by LOOKING
	/// at the code for the SPIR-V magic, so plain WGSL text has to land as WGSL.
	[Test]
	public static void AWgslModuleCompiles()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let wgsl = "@vertex fn main() -> @builtin(position) vec4f { return vec4f(0.0); }";
		var desc = ShaderModuleDesc();
		desc.Code = .((uint8*)wgsl.Ptr, wgsl.Length);
		var module = device.CreateShaderModule(desc).GetValueOrDefault();
		Test.Assert(module != null);

		device.DestroyShaderModule(ref module);
		device.Destroy();
	}

	/// Where WebGPU has no shape for something, the answer is a failure rather than an
	/// object that does not work. These are the three the RHI can ask for and WebGPU
	/// cannot serve.
	[Test]
	public static void WhatWebGpuCannotDoFailsHonestly()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		// An EMPTY desc is a zero sized buffer, which is a validation error rather than
		// wgpu's "invalid object" handed back as if it worked.
		Test.Assert(device.CreateBuffer(.()) case .Err, "a zero sized buffer is refused");

		// Pipeline statistics are not in core WebGPU.
		var statistics = QuerySetDesc();
		statistics.Type = .PipelineStatistics;
		statistics.Count = 1;
		Test.Assert(device.CreateQuerySet(statistics) case .Err,
			"pipeline statistics have no WebGPU shape");

		// And neither are mesh shaders, which take IDevice's refusing default.
		Test.Assert(device.CreateMeshPipeline(.()) case .Err);

		device.Destroy();
	}
}
