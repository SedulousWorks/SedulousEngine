using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// One physical device: what it is, what it supports, and how to pick queues and memory
/// on it.
class VulkanAdapter : IAdapter
{
	private VkPhysicalDevice mPhysicalDevice;
	private VkInstance mInstance;

	private VkPhysicalDeviceProperties mProperties;
	private VkPhysicalDeviceFeatures mFeatures10;
	private VkPhysicalDeviceMemoryProperties mMemoryProperties;
	private List<VkQueueFamilyProperties> mQueueFamilies = new .() ~ delete _;
	private List<VulkanDevice> mDevices = new List<VulkanDevice>() ~ DeleteContainerAndItems!(_);

	private bool mSupportsDynamicRendering = false;
	private bool mSupportsTimelineSemaphore = false;
	private bool mSupportsSynchronization2 = false;
	private bool mSupportsDescriptorIndexing = false;
	private bool mSupportsMeshShader = false;
	private bool mSupportsRayTracing = false;

	public this(VkPhysicalDevice physicalDevice, VkInstance instance)
	{
		mPhysicalDevice = physicalDevice;
		mInstance = instance;

		VulkanNative.vkGetPhysicalDeviceProperties(mPhysicalDevice, &mProperties);
		VulkanNative.vkGetPhysicalDeviceFeatures(mPhysicalDevice, &mFeatures10);
		VulkanNative.vkGetPhysicalDeviceMemoryProperties(mPhysicalDevice, &mMemoryProperties);

		uint32 familyCount = 0;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(mPhysicalDevice, &familyCount, null);
		mQueueFamilies.Resize((int)familyCount);
		if (familyCount > 0)
		{
			VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(mPhysicalDevice, &familyCount,
				mQueueFamilies.Ptr);
		}

		QueryExtensionSupport();
	}

	public VkPhysicalDevice PhysicalDevice => mPhysicalDevice;
	public VkInstance Instance => mInstance;
	public VkPhysicalDeviceProperties Properties => mProperties;
	public VkPhysicalDeviceFeatures Features10 => mFeatures10;
	public List<VkQueueFamilyProperties> QueueFamilies => mQueueFamilies;

	public bool SupportsDynamicRendering => mSupportsDynamicRendering;
	public bool SupportsTimelineSemaphore => mSupportsTimelineSemaphore;
	public bool SupportsSynchronization2 => mSupportsSynchronization2;
	public bool SupportsDescriptorIndexing => mSupportsDescriptorIndexing;
	public bool SupportsMeshShader => mSupportsMeshShader;
	public bool SupportsRayTracing => mSupportsRayTracing;

	public void GetInfo(AdapterInfo outInfo)
	{
		// deviceName is a fixed char array in the properties, so it is read up to its
		// terminator rather than by its full length.
		outInfo.Name.Clear();
		outInfo.Name.Append(StringView(&mProperties.deviceName[0]));

		outInfo.VendorId = mProperties.vendorID;
		outInfo.DeviceId = mProperties.deviceID;

		switch (mProperties.deviceType)
		{
		case .VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: outInfo.Type = .DiscreteGpu;
		case .VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: outInfo.Type = .IntegratedGpu;
		case .VK_PHYSICAL_DEVICE_TYPE_CPU: outInfo.Type = .Cpu;
		default: outInfo.Type = .Unknown;
		}

		outInfo.SupportedFeatures = BuildFeatures();
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		let device = new VulkanDevice();
		if (device.Initialize(this, desc) case .Err)
		{
			delete device;
			return .Err;
		}
		mDevices.Add(device);
		return .Ok(device);
	}

	/// What this adapter can do, read from its properties, features and extensions.
	public DeviceFeatures BuildFeatures()
	{
		var f = DeviceFeatures();

		f.BindlessDescriptors = mSupportsDescriptorIndexing;
		f.TimestampQueries = mProperties.limits.timestampComputeAndGraphics;
		// True unconditionally: vkCmdBeginQuery works anywhere inside a pass on Vulkan,
		// which is the shape the RHI's occlusion queries assume. WebGPU is the backend that
		// cannot honour it.
		f.OcclusionQueries = true;
		f.BorderSampling = true;
		f.MultiDrawIndirect = mFeatures10.multiDrawIndirect;
		f.DepthClamp = mFeatures10.depthClamp;
		f.FillModeWireframe = mFeatures10.fillModeNonSolid;
		f.TextureCompressionBC = mFeatures10.textureCompressionBC;
		f.TextureCompressionASTC = mFeatures10.textureCompressionASTC_LDR;
		f.IndependentBlend = mFeatures10.independentBlend;
		f.MultiViewport = mFeatures10.multiViewport;
		f.MeshShaders = mSupportsMeshShader;
		f.RayTracing = mSupportsRayTracing;
		f.PipelineStatisticsQueries = mFeatures10.pipelineStatisticsQuery;

		// Mesh limits come from a second properties query, and are only asked for when the
		// extension is there: chaining the struct otherwise reads a field the driver never
		// filled in.
		if (mSupportsMeshShader)
		{
			VkPhysicalDeviceMeshShaderPropertiesEXT meshProperties = .();
			VkPhysicalDeviceProperties2 properties2 = .();
			properties2.pNext = &meshProperties;
			VulkanNative.vkGetPhysicalDeviceProperties2(mPhysicalDevice, &properties2);

			f.MaxMeshOutputVertices = meshProperties.maxMeshOutputVertices;
			f.MaxMeshOutputPrimitives = meshProperties.maxMeshOutputPrimitives;
			f.MaxMeshWorkgroupSize = meshProperties.maxMeshWorkGroupInvocations;
			f.MaxTaskWorkgroupSize = meshProperties.maxTaskWorkGroupInvocations;
		}

		f.MaxBindGroups = mProperties.limits.maxBoundDescriptorSets;
		f.MaxBindingsPerGroup = mProperties.limits.maxDescriptorSetUniformBuffers;
		f.MaxPushConstantSize = mProperties.limits.maxPushConstantsSize;
		f.MaxTextureDimension2D = mProperties.limits.maxImageDimension2D;
		f.MaxTextureArrayLayers = mProperties.limits.maxImageArrayLayers;
		f.MaxComputeWorkgroupSizeX = mProperties.limits.maxComputeWorkGroupSize[0];
		f.MaxComputeWorkgroupSizeY = mProperties.limits.maxComputeWorkGroupSize[1];
		f.MaxComputeWorkgroupSizeZ = mProperties.limits.maxComputeWorkGroupSize[2];
		f.MaxComputeWorkgroupsPerDimension = mProperties.limits.maxComputeWorkGroupCount[0];
		f.MaxBufferSize = (uint64)mProperties.limits.maxStorageBufferRange;
		f.MinUniformBufferOffsetAlignment = (uint32)mProperties.limits.minUniformBufferOffsetAlignment;
		f.MinStorageBufferOffsetAlignment = (uint32)mProperties.limits.minStorageBufferOffsetAlignment;
		f.TimestampPeriodNs = (uint32)mProperties.limits.timestampPeriod;

		return f;
	}

	/// The best queue family for a kind of work, or -1 when there is none.
	///
	/// A DEDICATED family is preferred for compute and transfer: hardware that has one runs
	/// that work in parallel with graphics, and falling back to a shared family only when
	/// there is no dedicated one is what makes the difference available where it exists.
	public int32 FindQueueFamily(QueueType type)
	{
		let count = (int32)mQueueFamilies.Count;

		switch (type)
		{
		case .Graphics:
			for (int32 i = 0; i < count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_GRAPHICS_BIT))
					return i;
			}

		case .Compute:
			for (int32 i = 0; i < count; i++)
			{
				let flags = mQueueFamilies[i].queueFlags;
				if (flags.HasFlag(.VK_QUEUE_COMPUTE_BIT) && !flags.HasFlag(.VK_QUEUE_GRAPHICS_BIT))
					return i;
			}
			for (int32 i = 0; i < count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_COMPUTE_BIT))
					return i;
			}

		case .Transfer:
			for (int32 i = 0; i < count; i++)
			{
				let flags = mQueueFamilies[i].queueFlags;
				if (flags.HasFlag(.VK_QUEUE_TRANSFER_BIT)
					&& !flags.HasFlag(.VK_QUEUE_GRAPHICS_BIT)
					&& !flags.HasFlag(.VK_QUEUE_COMPUTE_BIT))
					return i;
			}
			for (int32 i = 0; i < count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_TRANSFER_BIT))
					return i;
			}
		}

		return -1;
	}

	/// A memory type satisfying both the resource's allowed types and the properties asked
	/// for, or -1 when the device has none.
	public int32 FindMemoryType(uint32 typeFilter, VkMemoryPropertyFlags properties)
	{
		for (uint32 i = 0; i < mMemoryProperties.memoryTypeCount; i++)
		{
			if ((typeFilter & (1 << i)) == 0)
				continue;
			if ((mMemoryProperties.memoryTypes[i].propertyFlags & properties) == properties)
				return (int32)i;
		}
		return -1;
	}

	/// The memory properties a location asks for.
	public static VkMemoryPropertyFlags GetMemoryFlags(MemoryLocation location)
	{
		switch (location)
		{
		case .GpuOnly:
			return .VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
		case .CpuToGpu:
			return .VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
		case .GpuToCpu:
			// Cached rather than coherent: the CPU READS this, and an uncached read from
			// device memory is punishingly slow.
			return .VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
		case .Auto:
			return .VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
		}
	}

	/// What the device offers, from its extension list and its core version.
	private void QueryExtensionSupport()
	{
		uint32 extensionCount = 0;
		VulkanNative.vkEnumerateDeviceExtensionProperties(mPhysicalDevice, null,
			&extensionCount, null);
		let extensions = scope VkExtensionProperties[extensionCount == 0 ? 1 : extensionCount];
		if (extensionCount > 0)
		{
			VulkanNative.vkEnumerateDeviceExtensionProperties(mPhysicalDevice, null,
				&extensionCount, &extensions[0]);
		}

		for (uint32 i = 0; i < extensionCount; i++)
		{
			let name = StringView(&extensions[(int)i].extensionName[0]);
			switch (name)
			{
			case "VK_KHR_dynamic_rendering": mSupportsDynamicRendering = true;
			case "VK_KHR_timeline_semaphore": mSupportsTimelineSemaphore = true;
			case "VK_KHR_synchronization2": mSupportsSynchronization2 = true;
			case "VK_EXT_descriptor_indexing": mSupportsDescriptorIndexing = true;
			case "VK_EXT_mesh_shader": mSupportsMeshShader = true;
			case "VK_KHR_ray_tracing_pipeline": mSupportsRayTracing = true;
			}
		}

		// From 1.3 these are CORE, so a device that supports the version supports them
		// whether or not it still advertises the extension.
		let major = mProperties.apiVersion >> 22;
		let minor = (mProperties.apiVersion >> 12) & 0x3FF;

		if ((major > 1) || ((major == 1) && (minor >= 3)))
		{
			mSupportsDynamicRendering = true;
			mSupportsTimelineSemaphore = true;
			mSupportsSynchronization2 = true;
			mSupportsDescriptorIndexing = true;
		}
		else if ((major == 1) && (minor >= 2))
		{
			mSupportsTimelineSemaphore = true;
			mSupportsDescriptorIndexing = true;
		}
	}
}
