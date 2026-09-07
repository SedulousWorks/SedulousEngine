using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// Acceleration structures put through the real driver.
///
/// KNOWN GAP, inherited from Raptor: AccelStructDesc carries no geometry and no size, so
/// CreateAccelStruct cannot ask the driver how large the structure needs to be and falls
/// back to a 1024 byte floor. One indexed triangle already needs 2048, and one instance
/// 2560, so the builds below are REJECTED by the driver for want of space. Validation says
/// so plainly; nothing in the RHI reports it, and the encoder has no way to.
///
/// What these tests do prove is everything up to that point: the geometry is described in a
/// form the driver accepts, the device addresses resolve, the commands record and submit,
/// and the device survives. What they cannot prove is that a structure was actually built,
/// and they must not be read as saying so. Closing that needs a sizing query on the RHI,
/// which is a change to the shared surface rather than to this backend.
class VulkanRayTracingTests
{
	private static IBackend sBackend;
	private static IDevice sDevice;
	private static bool sRayTracing = false;

	private static bool Ready()
	{
		if (sDevice != null)
			return sRayTracing;
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
		sRayTracing = info.SupportedFeatures.RayTracing;
		return sRayTracing;
	}

	/// A buffer holding `data`, created for the address-taking a build needs.
	private static IBuffer MakeInputBuffer(void* data, uint64 size)
	{
		var desc = BufferDesc();
		desc.Size = size;
		desc.Usage = .AccelStructInput | .CopyDst;
		// Host visible, so the test can fill it without a transfer and the build reads
		// exactly what was written.
		desc.Memory = .CpuToGpu;
		if (!(sDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return null;
		if (data != null)
			Internal.MemCpy(buffer.Map(), data, (int)size);
		return buffer;
	}

	private static IBuffer MakeScratchBuffer(uint64 size)
	{
		var desc = BufferDesc();
		desc.Size = size;
		desc.Usage = .AccelStructScratch;
		desc.Memory = .GpuOnly;
		if (!(sDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return null;
		return buffer;
	}

	/// One triangle into a bottom level structure, and that structure into a top level one
	/// through a single instance.
	///
	/// Both levels in one test because a top level build is only meaningful over a bottom
	/// level that exists, and the instance record carries the bottom level's device address,
	/// which is the piece most likely to be wrong.
	///
	/// See the type's note: the builds themselves do not fit the structures the RHI can
	/// size, so this covers the recording path, not the result.
	[Test]
	public static void ABottomAndTopLevelStructureBuild()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan with ray tracing"); return; }

		float[9] vertices = .(
			0.0f, 0.5f, 0.0f,
			-0.5f, -0.5f, 0.0f,
			0.5f, -0.5f, 0.0f);
		uint32[3] indices = .(0, 1, 2);

		let vertexBuffer = MakeInputBuffer(&vertices[0], sizeof(float) * 9);
		let indexBuffer = MakeInputBuffer(&indices[0], sizeof(uint32) * 3);
		Test.Assert(vertexBuffer != null && indexBuffer != null, "the geometry buffers were made");

		var bottomDesc = AccelStructDesc();
		bottomDesc.Type = .BottomLevel;
		Test.Assert(sDevice.CreateAccelStruct(bottomDesc) case .Ok(var bottom));
		Test.Assert(bottom.DeviceAddress != 0, "a built structure is reachable by address");

		var topDesc = AccelStructDesc();
		topDesc.Type = .TopLevel;
		Test.Assert(sDevice.CreateAccelStruct(topDesc) case .Ok(var top));
		Test.Assert(top.DeviceAddress != 0);

		let scratch = MakeScratchBuffer(1 << 20);
		Test.Assert(scratch != null);

		// VkAccelerationStructureInstanceKHR laid out by hand: the RHI has no type for it,
		// since the record is a Vulkan and DXR ABI rather than an RHI concept.
		// A row-major 3x4 transform, then packed index/mask/offset/flags, then the bottom
		// level's device address.
		uint8[64] instance = default;
		float[12] transform = .(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0);
		Internal.MemCpy(&instance[0], &transform[0], sizeof(float) * 12);
		// instanceCustomIndex in the low 24 bits, mask 0xFF in the high 8: a zero mask
		// would make the instance invisible to every ray.
		*(uint32*)&instance[48] = 0xFF000000;
		// instanceShaderBindingTableRecordOffset in the low 24 bits and flags in the high 8,
		// both zero here.
		*(uint32*)&instance[52] = 0;
		// The bottom level structure this instance refers to, by ADDRESS: the field the
		// build actually follows, and the one a wrong build gets wrong.
		*(uint64*)&instance[56] = bottom.DeviceAddress;

		let instanceBuffer = MakeInputBuffer(&instance[0], 64);
		Test.Assert(instanceBuffer != null);

		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

		let rayTracing = encoder as IRayTracingEncoderExt;
		Test.Assert(rayTracing != null, "the Vulkan encoder offers the ray tracing extension");

		var triangles = AccelStructGeometryTriangles();
		triangles.VertexBuffer = vertexBuffer;
		triangles.VertexCount = 3;
		triangles.VertexStride = sizeof(float) * 3;
		triangles.VertexFormat = .Float32x3;
		triangles.IndexBuffer = indexBuffer;
		triangles.IndexCount = 3;
		triangles.IndexFormat = .UInt32;

		rayTracing.BuildBottomLevelAccelStruct(bottom, scratch, 0, .(&triangles, 1), .());
		// The top level build READS the bottom level, so it has to wait for it.
		encoder.TransitionBuffer(scratch, .ShaderWrite, .ShaderRead);
		rayTracing.BuildTopLevelAccelStruct(top, scratch, 0, instanceBuffer, 0, 1);

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));
		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers, fence, 1);
		Test.Assert(fence.Wait(1), "the submission with both builds completed");
		Test.Assert(!sDevice.IsLost(), "and the device survived them");

		sDevice.DestroyFence(ref fence);
		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyAccelStruct(ref top);
		sDevice.DestroyAccelStruct(ref bottom);
		var toDelete = instanceBuffer;
		sDevice.DestroyBuffer(ref toDelete);
		toDelete = scratch;
		sDevice.DestroyBuffer(ref toDelete);
		toDelete = indexBuffer;
		sDevice.DestroyBuffer(ref toDelete);
		toDelete = vertexBuffer;
		sDevice.DestroyBuffer(ref toDelete);
	}

	/// Named to sort last so the device outlives the tests above.
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
			sBackend = null;
		}
	}
}
