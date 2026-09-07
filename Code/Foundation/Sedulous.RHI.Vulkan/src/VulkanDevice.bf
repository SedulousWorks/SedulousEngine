using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// The logical device: queues, enabled features, and everything created from it.
///
/// NOT YET COMPLETE. Initialization is ported in full; the resource creation entry points
/// are filled in as each resource type lands, and until then they refuse loudly rather
/// than returning something half built.
class VulkanDevice : IDevice
{
	private VulkanAdapter mAdapter;
	private VkDevice mDevice;
	private DeviceFeatures mFeatures = .();

	private List<VulkanQueue> mGraphicsQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<VulkanQueue> mComputeQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<VulkanQueue> mTransferQueues = new .() ~ DeleteContainerAndItems!(_);

	private BindingShifts mBindingShifts = BindingShifts.Standard;

	private bool mBindlessEnabled = false;
	private bool mMeshEnabled = false;
	private bool mRayTracingEnabled = false;
	private bool mDestroyed = false;

	private uint32 mShaderGroupHandleSize = 0;
	private uint32 mShaderGroupHandleAlignment = 0;
	private uint32 mShaderGroupBaseAlignment = 0;

	public VkDevice Handle => mDevice;
	public VulkanAdapter Adapter => mAdapter;
	public BindingShifts Shifts => mBindingShifts;
	public bool BindlessEnabled => mBindlessEnabled;
	public bool MeshShadersEnabled => mMeshEnabled;
	public bool RayTracingEnabled => mRayTracingEnabled;

	public Result<void> Initialize(VulkanAdapter adapter, DeviceDesc desc)
	{
		mAdapter = adapter;
		mFeatures = adapter.BuildFeatures();

		// A feature is enabled only where it was BOTH asked for and is available, so a
		// descriptor asking for everything on a device that has little still creates.
		mBindlessEnabled = desc.RequiredFeatures.BindlessDescriptors && adapter.SupportsDescriptorIndexing;
		mMeshEnabled = desc.RequiredFeatures.MeshShaders && adapter.SupportsMeshShader;
		mRayTracingEnabled = desc.RequiredFeatures.RayTracing && adapter.SupportsRayTracing;

		let graphicsFamily = adapter.FindQueueFamily(.Graphics);
		let computeFamily = adapter.FindQueueFamily(.Compute);
		let transferFamily = adapter.FindQueueFamily(.Transfer);
		if (graphicsFamily < 0)
			return .Err;

		// One create info per FAMILY, not per requested queue: two kinds that resolve to
		// the same family must be asked for together, and Vulkan rejects a duplicate family.
		let families = scope List<(uint32 family, uint32 count)>();
		AddFamily(adapter, families, graphicsFamily, desc.GraphicsQueueCount);
		AddFamily(adapter, families, computeFamily, desc.ComputeQueueCount);
		AddFamily(adapter, families, transferFamily, desc.TransferQueueCount);

		let queueInfos = scope List<VkDeviceQueueCreateInfo>();
		let priorities = scope List<float[]>();
		defer { for (let p in priorities) delete p; }

		for (let request in families)
		{
			let entry = new float[request.count];
			for (int i < entry.Count)
				entry[i] = 1.0f;
			priorities.Add(entry);

			VkDeviceQueueCreateInfo info = .();
			info.queueFamilyIndex = request.family;
			info.queueCount = request.count;
			info.pQueuePriorities = &entry[0];
			queueInfos.Add(info);
		}

		let extensions = scope List<char8*>();
		extensions.Add(VulkanNative.VK_KHR_SWAPCHAIN_EXTENSION_NAME);
		if (mMeshEnabled)
			extensions.Add("VK_EXT_mesh_shader");
		if (mRayTracingEnabled)
		{
			extensions.Add("VK_KHR_ray_tracing_pipeline");
			extensions.Add("VK_KHR_acceleration_structure");
			extensions.Add("VK_KHR_deferred_host_operations");
			extensions.Add("VK_KHR_ray_query");
		}

		// The feature chain, built from the tail backwards. Dynamic rendering and
		// synchronization2 are what the encoders are written against, so they are required
		// rather than optional.
		VkPhysicalDeviceVulkan13Features features13 = .();
		features13.dynamicRendering = true;
		features13.synchronization2 = true;
		features13.shaderDemoteToHelperInvocation = true;

		VkPhysicalDeviceVulkan12Features features12 = .();
		features12.pNext = &features13;
		features12.timelineSemaphore = true;

		if (mBindlessEnabled)
		{
			features12.descriptorIndexing = true;
			features12.descriptorBindingPartiallyBound = true;
			features12.descriptorBindingVariableDescriptorCount = true;
			features12.descriptorBindingSampledImageUpdateAfterBind = true;
			features12.descriptorBindingStorageBufferUpdateAfterBind = true;
			features12.runtimeDescriptorArray = true;
			features12.shaderSampledImageArrayNonUniformIndexing = true;
			features12.shaderStorageBufferArrayNonUniformIndexing = true;
		}
		if (mRayTracingEnabled)
			features12.bufferDeviceAddress = true;

		void* chainTail = &features12;

		VkPhysicalDeviceMeshShaderFeaturesEXT meshFeatures = .();
		if (mMeshEnabled)
		{
			meshFeatures.taskShader = true;
			meshFeatures.meshShader = true;
			meshFeatures.pNext = chainTail;
			chainTail = &meshFeatures;
		}

		VkPhysicalDeviceRayTracingPipelineFeaturesKHR rayTracingFeatures = .();
		VkPhysicalDeviceAccelerationStructureFeaturesKHR accelStructFeatures = .();
		VkPhysicalDeviceRayQueryFeaturesKHR rayQueryFeatures = .();
		if (mRayTracingEnabled)
		{
			rayTracingFeatures.rayTracingPipeline = true;
			accelStructFeatures.accelerationStructure = true;
			rayQueryFeatures.rayQuery = true;

			rayTracingFeatures.pNext = chainTail;
			chainTail = &rayTracingFeatures;
			accelStructFeatures.pNext = chainTail;
			chainTail = &accelStructFeatures;
			rayQueryFeatures.pNext = chainTail;
			chainTail = &rayQueryFeatures;
		}

		VkPhysicalDeviceFeatures2 features2 = .();
		features2.pNext = chainTail;
		features2.features = adapter.Features10;

		VkDeviceCreateInfo createInfo = .();
		createInfo.pNext = &features2;
		createInfo.queueCreateInfoCount = (uint32)queueInfos.Count;
		createInfo.pQueueCreateInfos = queueInfos.Ptr;
		createInfo.enabledExtensionCount = (uint32)extensions.Count;
		createInfo.ppEnabledExtensionNames = extensions.Ptr;

		if (VulkanNative.vkCreateDevice(adapter.PhysicalDevice, &createInfo, null, &mDevice)
			!= .VK_SUCCESS)
			return .Err;

		RetrieveQueues(adapter, desc, graphicsFamily, computeFamily, transferFamily);
		ProbeDepthFormats(adapter);

		if (mRayTracingEnabled)
		{
			VkPhysicalDeviceRayTracingPipelinePropertiesKHR properties = .();
			VkPhysicalDeviceProperties2 properties2 = .();
			properties2.pNext = &properties;
			VulkanNative.vkGetPhysicalDeviceProperties2(adapter.PhysicalDevice, &properties2);

			mShaderGroupHandleSize = properties.shaderGroupHandleSize;
			mShaderGroupHandleAlignment = properties.shaderGroupHandleAlignment;
			mShaderGroupBaseAlignment = properties.shaderGroupBaseAlignment;
		}

		return .Ok;
	}

	/// Merges a request into the family list, clamped to what the family actually offers.
	private static void AddFamily(VulkanAdapter adapter,
		List<(uint32 family, uint32 count)> families, int32 family, uint32 requested)
	{
		if ((family < 0) || (requested == 0))
			return;

		let available = adapter.QueueFamilies[family].queueCount;
		for (int i < families.Count)
		{
			if (families[i].family == (uint32)family)
			{
				families[i].count = Math.Min(families[i].count + requested, available);
				return;
			}
		}
		families.Add(((uint32)family, Math.Min(requested, available)));
	}

	/// Takes the queues back out of the device.
	///
	/// The OFFSETS matter: where two kinds share a family, the second kind's queues start
	/// after the first kind's, or both would hand out the same queue.
	private void RetrieveQueues(VulkanAdapter adapter, DeviceDesc desc, int32 graphicsFamily,
		int32 computeFamily, int32 transferFamily)
	{
		let timestampPeriod = adapter.Properties.limits.timestampPeriod;

		void Retrieve(int32 family, uint32 count, QueueType type, uint32 offset,
			List<VulkanQueue> into)
		{
			if ((family < 0) || (count == 0))
				return;
			for (uint32 i = 0; i < count; i++)
			{
				VkQueue queue = .Null;
				VulkanNative.vkGetDeviceQueue(mDevice, (uint32)family, offset + i, &queue);
				into.Add(new VulkanQueue(queue, type, (uint32)family, timestampPeriod, this));
			}
		}

		let graphicsCount = (uint32)Math.Min(desc.GraphicsQueueCount,
			adapter.QueueFamilies[graphicsFamily].queueCount);
		Retrieve(graphicsFamily, graphicsCount, .Graphics, 0, mGraphicsQueues);

		if (computeFamily >= 0)
		{
			uint32 offset = (computeFamily == graphicsFamily) ? graphicsCount : 0;
			let available = adapter.QueueFamilies[computeFamily].queueCount - offset;
			Retrieve(computeFamily, (uint32)Math.Min(desc.ComputeQueueCount, available), .Compute,
				offset, mComputeQueues);
		}

		if (transferFamily >= 0)
		{
			uint32 offset = 0;
			if (transferFamily == graphicsFamily)
				offset = graphicsCount + (uint32)mComputeQueues.Count;
			else if (transferFamily == computeFamily)
				offset = (uint32)mComputeQueues.Count;

			let available = adapter.QueueFamilies[transferFamily].queueCount - offset;
			Retrieve(transferFamily, (uint32)Math.Min(desc.TransferQueueCount, available), .Transfer,
				offset, mTransferQueues);
		}
	}

	/// Asks whether the packed 24 bit depth formats are actually usable as attachments.
	///
	/// D24_S8 is optional and absent on AMD's driver, and X8_D24 is absent on more. The
	/// conversion table falls back to the 32 bit float forms where they are missing, so a
	/// depth buffer is created rather than refused.
	private void ProbeDepthFormats(VulkanAdapter adapter)
	{
		VkFormatProperties properties = default;

		VulkanNative.vkGetPhysicalDeviceFormatProperties(adapter.PhysicalDevice,
			.VK_FORMAT_D24_UNORM_S8_UINT, &properties);
		let depth24Stencil8 = properties.optimalTilingFeatures
			.HasFlag(.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

		VulkanNative.vkGetPhysicalDeviceFormatProperties(adapter.PhysicalDevice,
			.VK_FORMAT_X8_D24_UNORM_PACK32, &properties);
		let depth24 = properties.optimalTilingFeatures
			.HasFlag(.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

		VulkanConversions.SetDepthFormatSupport(depth24Stencil8, depth24);
	}

	// ---- IDevice: what is ported ----

	public DeviceType Type => .Vulkan;
	public DeviceFeatures Features => mFeatures;
	public ShaderFormat PreferredShaderFormat => .SpirV;

	/// False: Vulkan flips clip space Y with a negative height viewport, so a screen space
	/// pass needs no further negation.
	public bool NeedsClipSpaceYFlip => false;

	public uint32 ShaderGroupHandleSize => mShaderGroupHandleSize;
	public uint32 ShaderGroupHandleAlignment => mShaderGroupHandleAlignment;
	public uint32 ShaderGroupBaseAlignment => mShaderGroupBaseAlignment;

	public IQueue GetQueue(QueueType type, uint32 index)
	{
		let list = (type == .Graphics) ? mGraphicsQueues
			: (type == .Compute) ? mComputeQueues : mTransferQueues;

		if (index < (uint32)list.Count)
			return list[(int)index];

		// A device asked for no dedicated compute or transfer queue still has to answer:
		// the work runs on graphics.
		return mGraphicsQueues.IsEmpty ? null : mGraphicsQueues[0];
	}

	public uint32 GetQueueCount(QueueType type)
	{
		switch (type)
		{
		case .Graphics: return (uint32)mGraphicsQueues.Count;
		case .Compute: return (uint32)mComputeQueues.Count;
		case .Transfer: return (uint32)mTransferQueues.Count;
		}
	}

	public FormatSupport GetFormatSupport(TextureFormat format)
	{
		VkFormatProperties properties = default;
		VulkanNative.vkGetPhysicalDeviceFormatProperties(mAdapter.PhysicalDevice,
			VulkanConversions.ToVkFormat(format), &properties);

		var support = FormatSupport.Unsupported;
		let optimal = properties.optimalTilingFeatures;
		let buffer = properties.bufferFeatures;

		if (optimal.HasFlag(.VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT))
			support |= .Texture;
		if (optimal.HasFlag(.VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT))
			support |= .StorageTexture;
		if (optimal.HasFlag(.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT))
			support |= .ColorAttachment;
		if (optimal.HasFlag(.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT))
			support |= .BlendableColor;
		if (optimal.HasFlag(.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))
			support |= .DepthStencil;
		if (optimal.HasFlag(.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT))
			support |= .LinearFilter;
		if (buffer.HasFlag(.VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT))
			support |= .Buffer;
		if (buffer.HasFlag(.VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT))
			support |= .StorageBuffer;
		if (buffer.HasFlag(.VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT))
			support |= .VertexBuffer;

		return support;
	}

	public bool IsLost() => false;

	public void WaitIdle()
	{
		if (mDevice != .Null)
			VulkanNative.vkDeviceWaitIdle(mDevice);
	}

	public void Destroy()
	{
		if (mDestroyed)
			return;
		mDestroyed = true;

		ClearAndDeleteItems!(mGraphicsQueues);
		ClearAndDeleteItems!(mComputeQueues);
		ClearAndDeleteItems!(mTransferQueues);

		if (mDevice != .Null)
		{
			VulkanNative.vkDestroyDevice(mDevice, null);
			mDevice = .Null;
		}
	}

	// ---- IDevice: not yet ported ----
	//
	// Each resource type is filled in as it lands. Refusing loudly rather than quietly is
	// deliberate: a silent .Err here would look like a driver failure rather than an
	// unfinished port.

	private static Result<T> NotYetPorted<T>(StringView what)
	{
		Console.Error.WriteLine(scope $"Sedulous.RHI.Vulkan: {what} is not ported yet");
		return .Err;
	}

	public Result<IBuffer> CreateBuffer(BufferDesc desc) => NotYetPorted<IBuffer>("CreateBuffer");
	public Result<ITexture> CreateTexture(TextureDesc desc) => NotYetPorted<ITexture>("CreateTexture");
	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc) => NotYetPorted<ITextureView>("CreateTextureView");
	public Result<ISampler> CreateSampler(SamplerDesc desc) => NotYetPorted<ISampler>("CreateSampler");
	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc) => NotYetPorted<IShaderModule>("CreateShaderModule");
	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc) => NotYetPorted<IBindGroupLayout>("CreateBindGroupLayout");
	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc) => NotYetPorted<IBindGroup>("CreateBindGroup");
	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc) => NotYetPorted<IPipelineLayout>("CreatePipelineLayout");
	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc) => NotYetPorted<IPipelineCache>("CreatePipelineCache");
	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc) => NotYetPorted<IRenderPipeline>("CreateRenderPipeline");
	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc) => NotYetPorted<IComputePipeline>("CreateComputePipeline");
	public Result<ICommandPool> CreateCommandPool(QueueType queueType) => NotYetPorted<ICommandPool>("CreateCommandPool");
	public Result<IFence> CreateFence(uint64 initialValue) => NotYetPorted<IFence>("CreateFence");
	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc) => NotYetPorted<IQuerySet>("CreateQuerySet");
	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc) => NotYetPorted<ISwapChain>("CreateSwapChain");

	public void DestroyBuffer(ref IBuffer x) {}
	public void DestroyTexture(ref ITexture x) {}
	public void DestroyTextureView(ref ITextureView x) {}
	public void DestroySampler(ref ISampler x) {}
	public void DestroyShaderModule(ref IShaderModule x) {}
	public void DestroyBindGroupLayout(ref IBindGroupLayout x) {}
	public void DestroyBindGroup(ref IBindGroup x) {}
	public void DestroyPipelineLayout(ref IPipelineLayout x) {}
	public void DestroyPipelineCache(ref IPipelineCache x) {}
	public void DestroyRenderPipeline(ref IRenderPipeline x) {}
	public void DestroyComputePipeline(ref IComputePipeline x) {}
	public void DestroyCommandPool(ref ICommandPool x) {}
	public void DestroyFence(ref IFence x) {}
	public void DestroyQuerySet(ref IQuerySet x) {}
	public void DestroySwapChain(ref ISwapChain x) {}
	public void DestroySurface(ref ISurface x) {}
}
