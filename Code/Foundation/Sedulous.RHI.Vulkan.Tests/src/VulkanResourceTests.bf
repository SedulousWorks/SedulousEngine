using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// Resources created on the real device.
///
/// These do not stand in for anything: a buffer here is device memory, and a mapped write
/// that reads back is proof the allocation and the mapping are right.
class VulkanResourceTests
{
	private static IBackend sBackend;
	private static IDevice sDevice;
	/// A failed attempt is NEVER retried: the next test would build another backend that the
	/// first failure already proved useless, and leak it.
	private static bool sTried;

	/// One backend and device for the whole file, since creating a device costs a couple of
	/// hundred milliseconds and none of these mutate it.
	private static bool Ready()
	{
		if (sDevice != null)
			return true;
		if (sTried)
			return false;
		sTried = true;
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
			return false;
		sBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return false;
		if (!(adapters[0].CreateDevice(.()) case .Ok(let device)))
			return false;
		sDevice = device;
		return true;
	}

	/// The device reports the MSAA counts the hardware actually has, for BOTH colour and
	/// depth.
	///
	/// The intersection matters: a device offering 8x colour with 4x depth cannot run an 8x
	/// scene pass, and reporting the colour limit alone would fail later at texture creation
	/// instead of here. A backend that never overrode these inherits the interface default
	/// of one, which silently disables MSAA everywhere.
	[Test]
	public static void SampleCountsComeFromTheHardware()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let maximum = sDevice.MaxColorDepthSampleCount;
		Test.Assert(maximum >= 1, "a device always supports single sampling");
		Test.Assert((maximum == 1) || (maximum == 2) || (maximum == 4),
			"the engine ceiling is 4x, so nothing above it is reported");

		Test.Assert(sDevice.SupportsSampleCount(1), "single sampling always works");
		// Not a power of two, and above the ceiling, are both refused.
		Test.Assert(!sDevice.SupportsSampleCount(3));
		Test.Assert(!sDevice.SupportsSampleCount(8));

		// The maximum has to agree with the per count query, or a caller that snaps to the
		// maximum would then be told the result is unsupported.
		Test.Assert(sDevice.SupportsSampleCount(maximum));

		// Any discrete GPU has 4x on both attachments, so less than that here means the
		// query is wrong rather than the hardware being unusual. This is what fails if the
		// backend stops overriding the queries and falls back to the interface default.
		Test.Assert(maximum == 4, "the hardware's real 4x colour and depth is reported");
		Test.Assert(sDevice.SupportsSampleCount(2), "and 2x with it");
	}

	/// A host visible buffer is PERSISTENTLY mapped, so a write through the pointer is
	/// visible on the next map without any unmapping in between.
	[Test]
	public static void AHostVisibleBufferMapsAndRoundTrips()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var desc = BufferDesc();
		desc.Size = 1024;
		desc.Usage = .CopySrc | .CopyDst;
		desc.Memory = .CpuToGpu;

		Test.Assert(sDevice.CreateBuffer(desc) case .Ok(var buffer));
		Test.Assert(buffer.Size == 1024);
		Test.Assert(buffer.Usage.HasFlag(.CopySrc));

		let mapped = (uint8*)buffer.Map();
		Test.Assert(mapped != null, "CpuToGpu memory is mappable");
		for (int i < 1024)
			mapped[i] = (uint8)(i & 0xFF);
		buffer.Unmap();

		let again = (uint8*)buffer.Map();
		Test.Assert(again == mapped, "the mapping is persistent, so it is the same pointer");
		Test.Assert(again[0] == 0);
		Test.Assert(again[255] == 255);
		Test.Assert(again[1023] == (uint8)(1023 & 0xFF), "the writes reached the memory");

		sDevice.DestroyBuffer(ref buffer);
		Test.Assert(buffer == null);
	}

	/// Device local memory is not mappable, which is the whole reason the location exists.
	[Test]
	public static void ADeviceLocalBufferIsNotMappable()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var desc = BufferDesc();
		desc.Size = 256;
		desc.Usage = .Vertex | .CopyDst;
		desc.Memory = .GpuOnly;

		Test.Assert(sDevice.CreateBuffer(desc) case .Ok(var buffer));
		Test.Assert(buffer.Map() == null, "GpuOnly memory is never mapped");
		sDevice.DestroyBuffer(ref buffer);
	}

	/// A readback buffer is mappable too, and takes CACHED memory rather than coherent
	/// because the CPU reads it.
	[Test]
	public static void AReadbackBufferIsMappable()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var desc = BufferDesc();
		desc.Size = 512;
		desc.Usage = .CopyDst;
		desc.Memory = .GpuToCpu;

		Test.Assert(sDevice.CreateBuffer(desc) case .Ok(var buffer));
		Test.Assert(buffer.Map() != null);
		sDevice.DestroyBuffer(ref buffer);
	}

	[Test]
	public static void TexturesAndViewsAreCreatedOnTheDevice()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let before = VulkanTexture.LiveAllocations;

		var desc = TextureDesc.RenderTarget(.RGBA8Unorm, 256, 128);
		desc.MipLevelCount = 4;
		Test.Assert(sDevice.CreateTexture(desc) case .Ok(var texture));
		Test.Assert(texture.Desc.Width == 256);
		Test.Assert(VulkanTexture.LiveAllocations == before + 1,
			"one allocation per texture, and it is counted");

		// A view of mip zero sees the whole texture.
		Test.Assert(sDevice.CreateTextureView(texture, .()) case .Ok(var full));
		Test.Assert(full.Texture === texture);
		let asVulkan = full as VulkanTextureView;
		Test.Assert(asVulkan.Width == 256);
		Test.Assert(asVulkan.Height == 128);

		// A view of mip two is a QUARTER the size in each axis. The render area comes from
		// these, so a stale mip zero size would overrun the attachment and fault the GPU.
		var mipDesc = TextureViewDesc();
		mipDesc.BaseMipLevel = 2;
		mipDesc.MipLevelCount = 1;
		Test.Assert(sDevice.CreateTextureView(texture, mipDesc) case .Ok(var mip));
		let mipView = mip as VulkanTextureView;
		Test.Assert(mipView.Width == 64, scope $"mip 2 of 256 is 64, got {mipView.Width}");
		Test.Assert(mipView.Height == 32);

		// Ids never repeat, even across views of the same texture.
		Test.Assert(full.UniqueId != mip.UniqueId);

		sDevice.DestroyTextureView(ref mip);
		sDevice.DestroyTextureView(ref full);
		sDevice.DestroyTexture(ref texture);
		Test.Assert(VulkanTexture.LiveAllocations == before, "and the allocation was freed");
	}

	/// A depth texture is created with whatever format the probe settled on, which is the
	/// point of the fallback: an unsupported packed format becomes the 32 bit one rather
	/// than failing.
	[Test]
	public static void ADepthTextureIsCreatedWhicheverFormatTheDeviceHas()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		for (let format in TextureFormat[](.Depth32Float, .Depth24PlusStencil8, .Depth24Plus))
		{
			let desc = TextureDesc.DepthBuffer(format, 128, 128);
			Test.Assert(sDevice.CreateTexture(desc) case .Ok(var texture),
				scope $"{format} creates a depth buffer");

			var viewDesc = TextureViewDesc();
			viewDesc.Aspect = .DepthOnly;
			Test.Assert(sDevice.CreateTextureView(texture, viewDesc) case .Ok(var view),
				scope $"{format} views its depth aspect");

			sDevice.DestroyTextureView(ref view);
			sDevice.DestroyTexture(ref texture);
		}
	}

	/// Six layers on a 2D texture makes it cube compatible, which has to be declared at
	/// creation for the cube view to be possible at all.
	[Test]
	public static void ASixLayerTextureViewsAsACube()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		var desc = TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64);
		desc.ArrayLayerCount = 6;
		Test.Assert(sDevice.CreateTexture(desc) case .Ok(var texture));

		var viewDesc = TextureViewDesc();
		viewDesc.Dimension = .TextureCube;
		viewDesc.ArrayLayerCount = 6;
		Test.Assert(sDevice.CreateTextureView(texture, viewDesc) case .Ok(var cube),
			"the cube compatible flag was set at creation");

		sDevice.DestroyTextureView(ref cube);
		sDevice.DestroyTexture(ref texture);
	}

	[Test]
	public static void SamplersCoverTheOrdinaryAndComparisonCases()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		Test.Assert(sDevice.CreateSampler(.()) case .Ok(var trilinear));
		Test.Assert(trilinear.Desc.MinFilter == .Linear);
		sDevice.DestroySampler(ref trilinear);

		// A comparison sampler, which is what shadow filtering binds.
		var shadow = SamplerDesc();
		shadow.Compare = .LessEqual;
		shadow.AddressU = .ClampToEdge;
		shadow.AddressV = .ClampToEdge;
		Test.Assert(sDevice.CreateSampler(shadow) case .Ok(var comparison));
		Test.Assert(comparison.Desc.Compare.HasValue);
		sDevice.DestroySampler(ref comparison);

		// And an anisotropic one, which the device must report support for.
		var aniso = SamplerDesc();
		aniso.MaxAnisotropy = 4;
		Test.Assert(sDevice.CreateSampler(aniso) case .Ok(var anisotropic));
		sDevice.DestroySampler(ref anisotropic);
	}

	/// The fence is a TIMELINE semaphore, so it starts at the value it was created with and
	/// a wait for something already passed returns at once.
	[Test]
	public static void AFenceIsATimelineThatStartsWhereItWasTold()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		Test.Assert(sDevice.CreateFence(7) case .Ok(var fence));
		Test.Assert(fence.CompletedValue() == 7, "created at the value asked for");

		Test.Assert(fence.Wait(7, 0), "a value already reached returns immediately");

		// Nothing will signal 99, so a wait with no timeout budget reports the timeout
		// rather than blocking.
		Test.Assert(!fence.Wait(99, 0), "and an unreached value times out rather than hanging");
		Test.Assert(fence.CompletedValue() == 7, "a timed out wait changes nothing");

		sDevice.DestroyFence(ref fence);
	}

	[Test]
	public static void QuerySetsAreCreatedForEachKind()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		for (let type in QueryType[](.Timestamp, .Occlusion, .PipelineStatistics))
		{
			var desc = QuerySetDesc();
			desc.Type = type;
			desc.Count = 8;
			Test.Assert(sDevice.CreateQuerySet(desc) case .Ok(var querySet),
				scope $"a {type} pool is created");
			Test.Assert(querySet.Type == type);
			Test.Assert(querySet.Count == 8);
			sDevice.DestroyQuerySet(ref querySet);
		}
	}

	/// SPIR-V is read as 32 bit words, so an empty blob is refused rather than handed to
	/// the driver.
	[Test]
	public static void AnEmptyShaderModuleIsRefused()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }
		Test.Assert(sDevice.CreateShaderModule(.()) case .Err);
	}

	/// Runs last by name, tearing down what the other cases shared.
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
