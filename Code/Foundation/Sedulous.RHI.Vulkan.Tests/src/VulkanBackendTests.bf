using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// The Vulkan backend against whatever hardware is actually present.
///
/// These SKIP rather than fail when there is no loader or no device: a CI box without a
/// GPU should report the port fine, not broken. Where a device is present they are real.
class VulkanBackendTests
{
	/// The backend, or null when this machine cannot run Vulkan at all.
	private static IBackend TryCreate()
	{
		if (VulkanRhi.CreateBackend(false) case .Ok(let backend))
			return backend;
		return null;
	}

	[Test]
	public static void TheBackendComesUpAndFindsAdapters()
	{
		let backend = TryCreate();
		if (backend == null)
		{
			Console.WriteLine("SKIP: no Vulkan loader or instance on this machine");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		Test.Assert(backend.IsInitialized);

		let adapters = backend.EnumerateAdapters();
		Console.WriteLine(scope $"Vulkan adapters: {adapters.Length}");
		Test.Assert(!adapters.IsEmpty, "a Vulkan loader with no adapter at all is a broken install");

		let info = scope AdapterInfo();
		for (int i < adapters.Length)
		{
			info.Name.Clear();
			adapters[i].GetInfo(info);
			Console.WriteLine(scope $"  [{i}] {info.Name} ({info.Type}) vendor=0x{info.VendorId:X}");
			Test.Assert(!info.Name.IsEmpty, "every adapter names itself");
		}
	}

	/// The adapters come back BEST FIRST, so a caller taking element zero gets the discrete
	/// GPU where there is one. This is the ordering AdapterSelection defines, checked
	/// against whatever mix of hardware this machine actually has.
	[Test]
	public static void AdaptersAreOrderedBestFirst()
	{
		let backend = TryCreate();
		if (backend == null)
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let adapters = backend.EnumerateAdapters();
		let info = scope AdapterInfo();

		int32 previousRank = -1;
		for (int i < adapters.Length)
		{
			info.Name.Clear();
			adapters[i].GetInfo(info);
			let rank = (int32)AdapterSelection.PreferenceRank(info.Type);
			Test.Assert(rank >= previousRank,
				scope $"adapter {i} ({info.Type}) ranks better than the one before it");
			previousRank = rank;
		}

		// Where a discrete GPU exists it must be first, which is the whole point of the
		// ordering.
		bool hasDiscrete = false;
		for (int i < adapters.Length)
		{
			info.Name.Clear();
			adapters[i].GetInfo(info);
			if (info.Type == .DiscreteGpu)
				hasDiscrete = true;
		}
		if (hasDiscrete)
		{
			info.Name.Clear();
			adapters[0].GetInfo(info);
			Test.Assert(info.Type == .DiscreteGpu,
				scope $"element zero is {info.Type} while a discrete GPU is present");
			Console.WriteLine(scope $"best adapter: {info.Name}");
		}
	}

	[Test]
	public static void TheBestAdapterCreatesADeviceWithQueues()
	{
		let backend = TryCreate();
		if (backend == null)
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;

		var desc = DeviceDesc();
		desc.GraphicsQueueCount = 1;
		desc.ComputeQueueCount = 1;
		desc.TransferQueueCount = 1;

		Test.Assert(adapters[0].CreateDevice(desc) case .Ok(let device),
			"the best adapter creates a device");
		defer device.Destroy();

		Test.Assert(device.Type == .Vulkan);
		Test.Assert(device.PreferredShaderFormat == .SpirV);
		Test.Assert(!device.NeedsClipSpaceYFlip, "Vulkan flips Y in the viewport itself");
		Test.Assert(!device.IsLost());

		// The queues asked for are there, and each knows which kind it is.
		Test.Assert(device.GetQueueCount(.Graphics) >= 1);
		let graphics = device.GetQueue(.Graphics);
		Test.Assert(graphics != null);
		Test.Assert(graphics.QueueType == .Graphics);
		Test.Assert(graphics.TimestampPeriod() > 0, "a real device reports a tick period");

		Console.WriteLine(scope $"queues: graphics={device.GetQueueCount(.Graphics)} compute={device.GetQueueCount(.Compute)} transfer={device.GetQueueCount(.Transfer)}");

		device.WaitIdle();
	}

	/// The limits and features come from the DEVICE rather than from the RHI defaults, so a
	/// caller sizing anything against them is reading the hardware.
	[Test]
	public static void TheDeviceReportsRealLimits()
	{
		let backend = TryCreate();
		if (backend == null)
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;
		Test.Assert(adapters[0].CreateDevice(.()) case .Ok(let device));
		defer device.Destroy();

		let features = device.Features;
		Test.Assert(features.MaxTextureDimension2D >= 4096,
			scope $"every Vulkan device guarantees at least 4096, got {features.MaxTextureDimension2D}");
		Test.Assert(features.MaxBindGroups >= 4);
		Test.Assert(features.MaxPushConstantSize >= 128);
		Test.Assert(features.MaxComputeWorkgroupSizeX >= 128);

		Console.WriteLine(scope $"limits: maxTex2D={features.MaxTextureDimension2D} pushConst={features.MaxPushConstantSize} bindGroups={features.MaxBindGroups}");
		Console.WriteLine(scope $"features: bindless={features.BindlessDescriptors} mesh={features.MeshShaders} rt={features.RayTracing}");
	}

	/// Format support is asked of the driver, so it answers differently for a colour format
	/// and a compressed one the hardware may not have.
	[Test]
	public static void FormatSupportComesFromTheDriver()
	{
		let backend = TryCreate();
		if (backend == null)
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;
		Test.Assert(adapters[0].CreateDevice(.()) case .Ok(let device));
		defer device.Destroy();

		// RGBA8 is the format every Vulkan device must support as a sampled colour target.
		let rgba8 = device.GetFormatSupport(.RGBA8Unorm);
		Test.Assert(rgba8.HasFlag(.Texture), "RGBA8Unorm is sampleable everywhere");
		Test.Assert(rgba8.HasFlag(.ColorAttachment));

		// And an undefined format supports nothing, which proves the answer is being read
		// rather than assumed.
		Test.Assert(device.GetFormatSupport(.Undefined) == .Unsupported);

		Console.WriteLine(scope $"RGBA8Unorm support: {rgba8}");
	}
}
