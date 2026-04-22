namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IAdapter.
class VulkanAdapter : IAdapter
{
	private VkPhysicalDevice mPhysicalDevice;
	private VkInstance mInstance;
	private VkPhysicalDeviceProperties mProperties;
	private VkPhysicalDeviceFeatures mFeatures10;
	private VkPhysicalDeviceMemoryProperties mMemoryProperties;

	// Queue family info
	private List<VkQueueFamilyProperties> mQueueFamilies = new .() ~ delete _;

	// Cached feature support
	private bool mSupportsDynamicRendering;
	private bool mSupportsTimelineSemaphore;
	private bool mSupportsSynchronization2;
	private bool mSupportsDescriptorIndexing;
	private bool mSupportsMeshShader;
	private bool mSupportsRayTracing;

	public this(VkPhysicalDevice physicalDevice, VkInstance instance)
	{
		mPhysicalDevice = physicalDevice;
		mInstance = instance;

		// Query properties
		VulkanNative.vkGetPhysicalDeviceProperties(mPhysicalDevice, &mProperties);
		VulkanNative.vkGetPhysicalDeviceFeatures(mPhysicalDevice, &mFeatures10);
		VulkanNative.vkGetPhysicalDeviceMemoryProperties(mPhysicalDevice, &mMemoryProperties);

		// Query queue families
		uint32 queueFamilyCount = 0;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(mPhysicalDevice, &queueFamilyCount, null);
		mQueueFamilies.Resize((.)queueFamilyCount);
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(mPhysicalDevice, &queueFamilyCount, mQueueFamilies.Ptr);

		// Query Vulkan 1.2/1.3 feature support
		QueryExtensionSupport();
	}

	private void QueryExtensionSupport()
	{
		// Query available extensions
		uint32 extCount = 0;
		VulkanNative.vkEnumerateDeviceExtensionProperties(mPhysicalDevice, null, &extCount, null);
		VkExtensionProperties[] extensions = scope VkExtensionProperties[(.)extCount];
		VulkanNative.vkEnumerateDeviceExtensionProperties(mPhysicalDevice, null, &extCount, extensions.CArray());

		for (var ext in extensions)
		{
			let name = StringView(&ext.extensionName);
			if (name == "VK_KHR_dynamic_rendering") mSupportsDynamicRendering = true;
			if (name == "VK_KHR_timeline_semaphore") mSupportsTimelineSemaphore = true;
			if (name == "VK_KHR_synchronization2") mSupportsSynchronization2 = true;
			if (name == "VK_EXT_descriptor_indexing") mSupportsDescriptorIndexing = true;
			if (name == "VK_EXT_mesh_shader") mSupportsMeshShader = true;
			if (name == "VK_KHR_ray_tracing_pipeline") mSupportsRayTracing = true;
		}

		// For Vulkan 1.3, these are core
		uint32 apiMajor = VulkanNative.VK_API_VERSION_MAJOR(mProperties.apiVersion);
		uint32 apiMinor = VulkanNative.VK_API_VERSION_MINOR(mProperties.apiVersion);
		if (apiMajor > 1 || (apiMajor == 1 && apiMinor >= 3))
		{
			mSupportsDynamicRendering = true;
			mSupportsTimelineSemaphore = true;
			mSupportsSynchronization2 = true;
			mSupportsDescriptorIndexing = true;
		}
		else if (apiMajor == 1 && apiMinor >= 2)
		{
			mSupportsTimelineSemaphore = true;
			mSupportsDescriptorIndexing = true;
		}
	}

	public AdapterInfo GetInfo()
	{
		let info = new AdapterInfo();
		info.Name.Set(StringView(&mProperties.deviceName));
		info.VendorId = mProperties.vendorID;
		info.DeviceId = mProperties.deviceID;

		switch (mProperties.deviceType)
		{
		case .VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:   info.Type = .DiscreteGpu;
		case .VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: info.Type = .IntegratedGpu;
		case .VK_PHYSICAL_DEVICE_TYPE_CPU:            info.Type = .Cpu;
		default:                                      info.Type = .Unknown;
		}

		info.SupportedFeatures = BuildFeatures();
		return info;
	}

	public DeviceFeatures BuildFeatures()
	{
		DeviceFeatures f = default;

		f.BindlessDescriptors = mSupportsDescriptorIndexing;
		f.TimestampQueries = mProperties.limits.timestampComputeAndGraphics != VkBool32.False;
		f.MultiDrawIndirect = mFeatures10.multiDrawIndirect != VkBool32.False;
		f.DepthClamp = mFeatures10.depthClamp != VkBool32.False;
		f.FillModeWireframe = mFeatures10.fillModeNonSolid != VkBool32.False;
		f.TextureCompressionBC = mFeatures10.textureCompressionBC != VkBool32.False;
		f.TextureCompressionASTC = mFeatures10.textureCompressionASTC_LDR != VkBool32.False;
		f.IndependentBlend = mFeatures10.independentBlend != VkBool32.False;
		f.MultiViewport = mFeatures10.multiViewport != VkBool32.False;
		f.MeshShaders = mSupportsMeshShader;
		f.RayTracing = mSupportsRayTracing;
		f.PipelineStatisticsQueries = mFeatures10.pipelineStatisticsQuery != VkBool32.False;

		// Mesh shader limits
		if (mSupportsMeshShader)
		{
			VkPhysicalDeviceMeshShaderPropertiesEXT meshProps = .();
			VkPhysicalDeviceProperties2 props2 = .();
			props2.pNext = &meshProps;
			VulkanNative.vkGetPhysicalDeviceProperties2(mPhysicalDevice, &props2);
			f.MaxMeshOutputVertices = meshProps.maxMeshOutputVertices;
			f.MaxMeshOutputPrimitives = meshProps.maxMeshOutputPrimitives;
			f.MaxMeshWorkgroupSize = meshProps.maxMeshWorkGroupInvocations;
			f.MaxTaskWorkgroupSize = meshProps.maxTaskWorkGroupInvocations;
		}

		// Limits
		f.MaxBindGroups = mProperties.limits.maxBoundDescriptorSets;
		f.MaxBindingsPerGroup = mProperties.limits.maxDescriptorSetUniformBuffers; // conservative
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

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		let device = new VulkanDevice();
		if (device.Init(this, desc) case .Err)
		{
			Console.WriteLine("VulkanAdapter: device creation failed");
			delete device;
			return .Err;
		}
		return .Ok(device);
	}

	// --- Internal accessors ---

	public VkPhysicalDevice PhysicalDevice => mPhysicalDevice;
	public VkPhysicalDeviceProperties Properties => mProperties;
	public VkPhysicalDeviceFeatures Features10 => mFeatures10;
	public VkPhysicalDeviceMemoryProperties MemoryProperties => mMemoryProperties;
	public List<VkQueueFamilyProperties> QueueFamilies => mQueueFamilies;

	public bool SupportsDynamicRendering => mSupportsDynamicRendering;
	public bool SupportsTimelineSemaphore => mSupportsTimelineSemaphore;
	public bool SupportsSynchronization2 => mSupportsSynchronization2;
	public bool SupportsDescriptorIndexing => mSupportsDescriptorIndexing;
	public bool SupportsMeshShader => mSupportsMeshShader;
	public bool SupportsRayTracing => mSupportsRayTracing;

	/// Finds the best queue family index for the given type.
	/// For Compute: prefers a family without Graphics.
	/// For Transfer: prefers a family without Graphics or Compute.
	public int32 FindQueueFamily(QueueType type)
	{
		switch (type)
		{
		case .Graphics:
			for (int i = 0; i < mQueueFamilies.Count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_GRAPHICS_BIT))
					return (int32)i;
			}
		case .Compute:
			// Prefer dedicated compute (no graphics)
			for (int i = 0; i < mQueueFamilies.Count; i++)
			{
				let flags = mQueueFamilies[i].queueFlags;
				if (flags.HasFlag(.VK_QUEUE_COMPUTE_BIT) && !flags.HasFlag(.VK_QUEUE_GRAPHICS_BIT))
					return (int32)i;
			}
			// Fallback to any compute-capable
			for (int i = 0; i < mQueueFamilies.Count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_COMPUTE_BIT))
					return (int32)i;
			}
		case .Transfer:
			// Prefer dedicated transfer (no graphics or compute)
			for (int i = 0; i < mQueueFamilies.Count; i++)
			{
				let flags = mQueueFamilies[i].queueFlags;
				if (flags.HasFlag(.VK_QUEUE_TRANSFER_BIT) &&
					!flags.HasFlag(.VK_QUEUE_GRAPHICS_BIT) &&
					!flags.HasFlag(.VK_QUEUE_COMPUTE_BIT))
					return (int32)i;
			}
			// Fallback to any transfer-capable
			for (int i = 0; i < mQueueFamilies.Count; i++)
			{
				if (mQueueFamilies[i].queueFlags.HasFlag(.VK_QUEUE_TRANSFER_BIT))
					return (int32)i;
			}
		}
		return -1;
	}

	/// Finds a memory type index matching the requirements.
	public int32 FindMemoryType(uint32 typeFilter, VkMemoryPropertyFlags properties)
	{
		for (uint32 i = 0; i < mMemoryProperties.memoryTypeCount; i++)
		{
			if ((typeFilter & (1 << i)) != 0 &&
				(mMemoryProperties.memoryTypes[i].propertyFlags & properties) == properties)
				return (int32)i;
		}
		return -1;
	}

	/// Gets VkMemoryPropertyFlags for a MemoryLocation.
	public static VkMemoryPropertyFlags GetMemoryFlags(MemoryLocation location)
	{
		switch (location)
		{
		case .GpuOnly:
			return .VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
		case .CpuToGpu:
			return .VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
		case .GpuToCpu:
			return .VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
		case .Auto:
			return .VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
		}
	}
}
