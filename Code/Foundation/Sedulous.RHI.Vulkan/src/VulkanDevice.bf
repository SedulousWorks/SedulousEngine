namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Configurable HLSL register shifts for Vulkan's flat binding namespace.
/// When compiling HLSL->SPIR-V via DXC, each register class (b/t/u/s) is offset
/// so they don't collide. Set these to match your DXC -fvk-*-shift flags.
/// Default is all zeros (no shifts — user passes pre-shifted bindings or uses GLSL).
///
/// Shifts are applied internally by the Vulkan backend when creating descriptor set
/// layouts and writing descriptor sets. The user always works with unshifted binding
/// numbers at the API level (BindGroupLayoutEntry.Binding, BindGroupEntry.Binding).
/// The backend translates to shifted Vulkan bindings transparently.
struct VulkanBindingShifts
{
	/// Shift for CBV / uniform buffers (HLSL `b` registers).
	public uint32 CbvShift = 0;
	/// Shift for SRV / sampled textures & read-only storage buffers (HLSL `t` registers).
	public uint32 SrvShift = 0;
	/// Shift for UAV / read-write storage buffers & textures (HLSL `u` registers).
	public uint32 UavShift = 0;
	/// Shift for samplers (HLSL `s` registers).
	public uint32 SamplerShift = 0;

	/// Standard convention: b=0, t=1000, u=2000, s=3000.
	public static Self Standard => .() {
		CbvShift = 0,
		SrvShift = 1000,
		UavShift = 2000,
		SamplerShift = 3000
	};

	/// Returns the shifted binding for a given binding type.
	public uint32 Apply(BindingType type, uint32 binding)
	{
		switch (type)
		{
		case .UniformBuffer:
			return binding + CbvShift;
		case .SampledTexture, .BindlessTextures, .AccelerationStructure,
			 .StorageBufferReadOnly:
			return binding + SrvShift;
		case .StorageBufferReadWrite,
			 .StorageTextureReadOnly, .StorageTextureReadWrite,
			 .BindlessStorageBuffers, .BindlessStorageTextures:
			return binding + UavShift;
		case .Sampler, .ComparisonSampler, .BindlessSamplers:
			return binding + SamplerShift;
		}
	}
}

/// Vulkan implementation of IDevice.
class VulkanDevice : IDevice
{
	private VulkanAdapter mAdapter;
	private VkDevice mDevice;
	private DeviceFeatures mFeatures;
	private bool mBindlessEnabled;
	private bool mMeshShadersEnabled;
	private bool mRayTracingEnabled;
	private VulkanDescriptorPoolManager mDescriptorPoolManager;
	public VulkanDescriptorPoolManager DescriptorPoolManager => mDescriptorPoolManager;
	private VulkanMeshShaderExt mMeshShaderExt;
	private VulkanRayTracingExt mRayTracingExt;
	private VulkanBindingShifts mBindingShifts = .Standard;

	// Swapchain synchronization: set by AcquireNextImage, consumed by next Submit
	private VkSemaphore mPendingAcquireSemaphore;
	private VkSemaphore mPendingPresentSemaphore;
	private bool mHasPendingSwapChainSync;

	// Queue tracking
	private struct QueueInfo
	{
		public int32 FamilyIndex;
		public List<VulkanQueue> Queues;
	}

	private QueueInfo[3] mQueueInfos; // Graphics=0, Compute=1, Transfer=2
	private List<VulkanQueue> mAllQueues = new .() ~ DeleteContainerAndItems!(_);

	public this() { }

	public Result<void> Init(VulkanAdapter adapter, DeviceDesc desc)
	{
		mAdapter = adapter;

		// Find queue families
		int32 graphicsFamily = adapter.FindQueueFamily(.Graphics);
		int32 computeFamily = adapter.FindQueueFamily(.Compute);
		int32 transferFamily = adapter.FindQueueFamily(.Transfer);

		if (graphicsFamily < 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanDevice: no graphics queue family found");
			return .Err;
		}

		// Determine queue counts per family
		Dictionary<int32, uint32> familyQueueCounts = scope .();

		uint32 graphicsCount = Math.Min(desc.GraphicsQueueCount, adapter.QueueFamilies[graphicsFamily].queueCount);
		if (graphicsCount < 1) graphicsCount = 1;
		familyQueueCounts[graphicsFamily] = graphicsCount;
		mQueueInfos[0].FamilyIndex = graphicsFamily;

		uint32 computeCount = 0;
		if (computeFamily >= 0 && desc.ComputeQueueCount > 0)
		{
			computeCount = Math.Min(desc.ComputeQueueCount, adapter.QueueFamilies[computeFamily].queueCount);
			if (computeFamily == graphicsFamily)
			{
				// Share the same family, offset the queue indices
				uint32 existing = familyQueueCounts.GetValueOrDefault(computeFamily);
				uint32 max = adapter.QueueFamilies[computeFamily].queueCount;
				computeCount = (uint32)Math.Min((int64)computeCount, (int64)(max - existing));
				familyQueueCounts[computeFamily] = existing + computeCount;
			}
			else
			{
				familyQueueCounts[computeFamily] = computeCount;
			}
		}
		mQueueInfos[1].FamilyIndex = computeFamily;

		uint32 transferCount = 0;
		if (transferFamily >= 0 && desc.TransferQueueCount > 0)
		{
			transferCount = Math.Min(desc.TransferQueueCount, adapter.QueueFamilies[transferFamily].queueCount);
			uint32 existing = familyQueueCounts.GetValueOrDefault(transferFamily);
			uint32 max = adapter.QueueFamilies[transferFamily].queueCount;
			transferCount = (uint32)Math.Min((int64)transferCount, (int64)(max - existing));
			familyQueueCounts[transferFamily] = existing + transferCount;
		}
		mQueueInfos[2].FamilyIndex = transferFamily;

		// Create queue create infos
		List<VkDeviceQueueCreateInfo> queueCreateInfos = scope .();
		List<float[]> priorityArrays = scope .();
		for (let pair in familyQueueCounts)
		{
			if (pair.value == 0) continue;
			float[] priorities = scope:: float[pair.value];
			for (int i = 0; i < (.)pair.value; i++)
				priorities[i] = 1.0f;

			VkDeviceQueueCreateInfo qci = .();
			qci.queueFamilyIndex = (uint32)pair.key;
			qci.queueCount = pair.value;
			qci.pQueuePriorities = priorities.CArray();
			queueCreateInfos.Add(qci);
			priorityArrays.Add(priorities);
		}

		// Device extensions
		List<char8*> extensions = scope .();
		extensions.Add(VulkanNative.VK_KHR_SWAPCHAIN_EXTENSION_NAME);

		// Vulkan 1.3 features are core — but if on 1.2 we need extensions
		if (!adapter.SupportsDynamicRendering) { System.Diagnostics.Debug.WriteLine("VulkanDevice: dynamic rendering not supported (requires Vulkan 1.3)"); return .Err; }
		if (!adapter.SupportsTimelineSemaphore) { System.Diagnostics.Debug.WriteLine("VulkanDevice: timeline semaphores not supported (requires Vulkan 1.2)"); return .Err; }

		// Enable additional extensions based on features
		if (adapter.SupportsDescriptorIndexing && desc.RequiredFeatures.BindlessDescriptors)
		{
			// VK_EXT_descriptor_indexing is core in 1.2
		}
		if (adapter.SupportsMeshShader && desc.RequiredFeatures.MeshShaders)
			extensions.Add("VK_EXT_mesh_shader");
		if (adapter.SupportsRayTracing && desc.RequiredFeatures.RayTracing)
		{
			extensions.Add("VK_KHR_ray_tracing_pipeline");
			extensions.Add("VK_KHR_acceleration_structure");
			extensions.Add("VK_KHR_deferred_host_operations");
			extensions.Add("VK_KHR_ray_query");
		}

		// Build feature chain for Vulkan 1.3
		VkPhysicalDeviceVulkan13Features features13 = .();
		features13.dynamicRendering = VkBool32.True;
		features13.synchronization2 = VkBool32.True;
		features13.shaderDemoteToHelperInvocation = VkBool32.True;

		VkPhysicalDeviceVulkan12Features features12 = .();
		features12.pNext = &features13;
		features12.timelineSemaphore = VkBool32.True;
		if (desc.RequiredFeatures.BindlessDescriptors && adapter.SupportsDescriptorIndexing)
		{
			features12.descriptorIndexing = VkBool32.True;
			features12.descriptorBindingPartiallyBound = VkBool32.True;
			features12.descriptorBindingVariableDescriptorCount = VkBool32.True;
			features12.descriptorBindingSampledImageUpdateAfterBind = VkBool32.True;
			features12.descriptorBindingStorageBufferUpdateAfterBind = VkBool32.True;
			features12.runtimeDescriptorArray = VkBool32.True;
			features12.shaderSampledImageArrayNonUniformIndexing = VkBool32.True;
			features12.shaderStorageBufferArrayNonUniformIndexing = VkBool32.True;
		}

		// Mesh shader features (VK_EXT_mesh_shader)
		VkPhysicalDeviceMeshShaderFeaturesEXT meshFeatures = .();
		if (desc.RequiredFeatures.MeshShaders && adapter.SupportsMeshShader)
		{
			meshFeatures.taskShader = VkBool32.True;
			meshFeatures.meshShader = VkBool32.True;
			meshFeatures.pNext = features12.pNext; // chain after features13
			features12.pNext = &meshFeatures;
		}

		// Ray tracing features (VK_KHR_ray_tracing_pipeline + VK_KHR_acceleration_structure)
		VkPhysicalDeviceRayTracingPipelineFeaturesKHR rtPipelineFeatures = .();
		VkPhysicalDeviceAccelerationStructureFeaturesKHR asFeatures = .();
		VkPhysicalDeviceRayQueryFeaturesKHR rayQueryFeatures = .();
		if (desc.RequiredFeatures.RayTracing && adapter.SupportsRayTracing)
		{
			rtPipelineFeatures.rayTracingPipeline = VkBool32.True;
			asFeatures.accelerationStructure = VkBool32.True;
			rayQueryFeatures.rayQuery = VkBool32.True;

			// Chain into features12.pNext
			rtPipelineFeatures.pNext = features12.pNext;
			features12.pNext = &rtPipelineFeatures;

			asFeatures.pNext = features12.pNext;
			features12.pNext = &asFeatures;

			rayQueryFeatures.pNext = features12.pNext;
			features12.pNext = &rayQueryFeatures;

			// Also need bufferDeviceAddress for RT
			features12.bufferDeviceAddress = VkBool32.True;
		}

		VkPhysicalDeviceFeatures2 features2 = .();
		features2.pNext = &features12;
		features2.features = adapter.Features10;

		// Create device
		VkDeviceCreateInfo deviceCreateInfo = .();
		deviceCreateInfo.pNext = &features2;
		deviceCreateInfo.queueCreateInfoCount = (uint32)queueCreateInfos.Count;
		deviceCreateInfo.pQueueCreateInfos = queueCreateInfos.Ptr;
		deviceCreateInfo.enabledExtensionCount = (uint32)extensions.Count;
		deviceCreateInfo.ppEnabledExtensionNames = extensions.Ptr;

		let result = VulkanNative.vkCreateDevice(adapter.PhysicalDevice, &deviceCreateInfo, null, &mDevice);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanDevice: vkCreateDevice failed ({result})");
			return .Err;
		}

		// Retrieve queues
		RetrieveQueues(graphicsFamily, graphicsCount, .Graphics, 0);
		if (computeCount > 0)
		{
			uint32 offset = (computeFamily == graphicsFamily) ? graphicsCount : 0;
			RetrieveQueues(computeFamily, computeCount, .Compute, offset);
		}
		if (transferCount > 0)
		{
			uint32 offset = familyQueueCounts.GetValueOrDefault(transferFamily) - transferCount;
			// More precise: the transfer queues start after any graphics/compute queues on the same family
			RetrieveQueues(transferFamily, transferCount, .Transfer, offset);
		}

		// Store features
		mFeatures = adapter.BuildFeatures();
		mBindlessEnabled = desc.RequiredFeatures.BindlessDescriptors && adapter.SupportsDescriptorIndexing;
		mMeshShadersEnabled = desc.RequiredFeatures.MeshShaders && adapter.SupportsMeshShader;
		mRayTracingEnabled = desc.RequiredFeatures.RayTracing && adapter.SupportsRayTracing;

		// Create descriptor pool manager (after feature flags so we know which descriptor types to include)
		mDescriptorPoolManager = new VulkanDescriptorPoolManager(mDevice, accelerationStructureEnabled: mRayTracingEnabled);

		// Create extension objects
		if (mMeshShadersEnabled)
			mMeshShaderExt = new VulkanMeshShaderExt(this);
		if (mRayTracingEnabled)
			mRayTracingExt = new VulkanRayTracingExt(this, adapter);

		return .Ok;
	}

	private void RetrieveQueues(int32 familyIndex, uint32 count, QueueType type, uint32 offset)
	{
		int typeIndex = (int)type;
		mQueueInfos[typeIndex].Queues = new List<VulkanQueue>();

		for (uint32 i = 0; i < count; i++)
		{
			VkQueue queue = default;
			VulkanNative.vkGetDeviceQueue(mDevice, (uint32)familyIndex, offset + i, &queue);
			let vkQueue = new VulkanQueue(queue, type, (uint32)familyIndex, mAdapter.Properties.limits.timestampPeriod, this);
			mQueueInfos[typeIndex].Queues.Add(vkQueue);
			mAllQueues.Add(vkQueue);
		}
	}

	// ===== IDevice Implementation =====

	public IQueue GetQueue(QueueType type, uint32 index = 0)
	{
		int typeIndex = (int)type;
		let queues = mQueueInfos[typeIndex].Queues;
		if (queues == null || index >= (uint32)queues.Count)
			return null;
		return queues[(.)index];
	}

	public uint32 GetQueueCount(QueueType type)
	{
		int typeIndex = (int)type;
		let queues = mQueueInfos[typeIndex].Queues;
		return (queues != null) ? (uint32)queues.Count : 0;
	}

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		let buffer = new VulkanBuffer();
		if (buffer.Init(this, mAdapter, desc) case .Err)
		{
			delete buffer;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_BUFFER, (uint64)buffer.Handle.Handle, desc.Label);
		return .Ok(buffer);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		let texture = new VulkanTexture();
		if (texture.Init(this, mAdapter, desc) case .Err)
		{
			delete texture;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_IMAGE, (uint64)texture.Handle.Handle, desc.Label);
		return .Ok(texture);
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		let vkTexture = texture as VulkanTexture;
		if (vkTexture == null) return .Err;

		let view = new VulkanTextureView();
		if (view.Init(this, vkTexture, desc) case .Err)
		{
			delete view;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_IMAGE_VIEW, (uint64)view.Handle.Handle, desc.Label);
		return .Ok(view);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		let sampler = new VulkanSampler();
		if (sampler.Init(this, desc) case .Err)
		{
			delete sampler;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_SAMPLER, (uint64)sampler.Handle.Handle, desc.Label);
		return .Ok(sampler);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		let module = new VulkanShaderModule();
		if (module.Init(this, desc) case .Err)
		{
			delete module;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_SHADER_MODULE, (uint64)module.Handle.Handle, desc.Label);
		return .Ok(module);
	}

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		// Validate: warn if bindless types used without requesting BindlessDescriptors
		if (!mBindlessEnabled)
		{
			for (let entry in desc.Entries)
			{
				switch (entry.Type)
				{
				case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers, .BindlessStorageTextures:
					Console.WriteLine("[Vulkan WARN] Bindless binding type used but BindlessDescriptors was not requested in DeviceDesc.RequiredFeatures. This will likely cause validation errors.");
					break;
				default:
				}
			}
		}

		let layout = new VulkanBindGroupLayout();
		if (layout.Init(this, desc) case .Err)
		{
			delete layout;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT, (uint64)layout.Handle.Handle, desc.Label);
		return .Ok(layout);
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		let group = new VulkanBindGroup();
		if (group.Init(this, mDescriptorPoolManager, desc) case .Err)
		{
			delete group;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_DESCRIPTOR_SET, (uint64)group.Handle.Handle, desc.Label);
		return .Ok(group);
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		let layout = new VulkanPipelineLayout();
		if (layout.Init(this, desc) case .Err)
		{
			delete layout;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_PIPELINE_LAYOUT, (uint64)layout.Handle.Handle, desc.Label);
		return .Ok(layout);
	}

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		let cache = new VulkanPipelineCache();
		if (cache.Init(this, desc) case .Err)
		{
			delete cache;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_PIPELINE_CACHE, (uint64)cache.Handle.Handle, desc.Label);
		return .Ok(cache);
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		let pipeline = new VulkanRenderPipeline();
		if (pipeline.Init(this, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_PIPELINE, (uint64)pipeline.Handle.Handle, desc.Label);
		return .Ok(pipeline);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		let pipeline = new VulkanComputePipeline();
		if (pipeline.Init(this, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_PIPELINE, (uint64)pipeline.Handle.Handle, desc.Label);
		return .Ok(pipeline);
	}

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		let pool = new VulkanCommandPool();
		if (pool.Init(this, queueType) case .Err)
		{
			delete pool;
			return .Err;
		}
		return .Ok(pool);
	}

	public Result<IFence> CreateFence(uint64 initialValue = 0)
	{
		let fence = new VulkanFence();
		if (fence.Init(this, initialValue) case .Err)
		{
			delete fence;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_SEMAPHORE, (uint64)fence.Handle.Handle, "TimelineFence");
		return .Ok(fence);
	}

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		let querySet = new VulkanQuerySet();
		if (querySet.Init(this, desc) case .Err)
		{
			delete querySet;
			return .Err;
		}
		SetDebugName(.VK_OBJECT_TYPE_QUERY_POOL, (uint64)querySet.Handle.Handle, desc.Label);
		return .Ok(querySet);
	}

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		let vkSurface = surface as VulkanSurface;
		if (vkSurface == null) return .Err;

		let swapChain = new VulkanSwapChain();
		if (swapChain.Init(this, vkSurface, desc) case .Err)
		{
			delete swapChain;
			return .Err;
		}
		return .Ok(swapChain);
	}

	// ===== Destroy Methods =====

	public void DestroyBuffer(ref IBuffer buffer)
	{
		if (let vk = buffer as VulkanBuffer)
		{
			vk.Cleanup(this);
			delete vk;
		}
		buffer = null;
	}

	public void DestroyTexture(ref ITexture texture)
	{
		if (let vk = texture as VulkanTexture)
		{
			vk.Cleanup(this);
			delete vk;
		}
		texture = null;
	}

	public void DestroyTextureView(ref ITextureView view)
	{
		if (let vk = view as VulkanTextureView)
		{
			vk.Cleanup(this);
			delete vk;
		}
		view = null;
	}

	public void DestroySampler(ref ISampler sampler)
	{
		if (let vk = sampler as VulkanSampler)
		{
			vk.Cleanup(this);
			delete vk;
		}
		sampler = null;
	}

	public void DestroyShaderModule(ref IShaderModule module)
	{
		if (let vk = module as VulkanShaderModule)
		{
			vk.Cleanup(this);
			delete vk;
		}
		module = null;
	}

	public void DestroyBindGroupLayout(ref IBindGroupLayout layout)
	{
		if (let vk = layout as VulkanBindGroupLayout)
		{
			vk.Cleanup(this);
			delete vk;
		}
		layout = null;
	}

	public void DestroyBindGroup(ref IBindGroup group)
	{
		if (let vk = group as VulkanBindGroup)
		{
			vk.Cleanup(this);
			delete vk;
		}
		group = null;
	}

	public void DestroyPipelineLayout(ref IPipelineLayout layout)
	{
		if (let vk = layout as VulkanPipelineLayout)
		{
			vk.Cleanup(this);
			delete vk;
		}
		layout = null;
	}

	public void DestroyPipelineCache(ref IPipelineCache cache)
	{
		if (let vk = cache as VulkanPipelineCache)
		{
			vk.Cleanup(this);
			delete vk;
		}
		cache = null;
	}

	public void DestroyRenderPipeline(ref IRenderPipeline pipeline)
	{
		if (let vk = pipeline as VulkanRenderPipeline)
		{
			vk.Cleanup(this);
			delete vk;
		}
		pipeline = null;
	}

	public void DestroyComputePipeline(ref IComputePipeline pipeline)
	{
		if (let vk = pipeline as VulkanComputePipeline)
		{
			vk.Cleanup(this);
			delete vk;
		}
		pipeline = null;
	}

	public void DestroyCommandPool(ref ICommandPool pool)
	{
		if (let vk = pool as VulkanCommandPool)
		{
			vk.Cleanup(this);
			delete vk;
		}
		pool = null;
	}

	public void DestroyFence(ref IFence fence)
	{
		if (let vk = fence as VulkanFence)
		{
			vk.Cleanup(this);
			delete vk;
		}
		fence = null;
	}

	public void DestroyQuerySet(ref IQuerySet querySet)
	{
		if (let vk = querySet as VulkanQuerySet)
		{
			vk.Cleanup(this);
			delete vk;
		}
		querySet = null;
	}

	public void DestroySwapChain(ref ISwapChain swapChain)
	{
		if (let vk = swapChain as VulkanSwapChain)
		{
			vk.Cleanup(this);
			delete vk;
		}
		swapChain = null;
	}

	public void DestroySurface(ref ISurface surface)
	{
		if (let vk = surface as VulkanSurface)
		{
			vk.Destroy();
			delete vk;
		}
		surface = null;
	}

	public IMeshShaderExt GetMeshShaderExt()
	{
		return mMeshShaderExt;
	}

	public IRayTracingExt GetRayTracingExt()
	{
		return mRayTracingExt;
	}

	public DeviceFeatures Features => mFeatures;

	public void WaitIdle()
	{
		VulkanNative.vkDeviceWaitIdle(mDevice);
	}

	public void Destroy()
	{
		if (mDevice.Handle != 0)
		{
			WaitIdle();

			// Clean up extensions
			if (mMeshShaderExt != null) { delete mMeshShaderExt; mMeshShaderExt = null; }
			if (mRayTracingExt != null) { delete mRayTracingExt; mRayTracingExt = null; }

			// Clean up descriptor pool manager
			if (mDescriptorPoolManager != null)
			{
				mDescriptorPoolManager.Destroy();
				delete mDescriptorPoolManager;
				mDescriptorPoolManager = null;
			}

			// Clean up queue lists (queue objects are in mAllQueues which auto-deletes)
			for (int i = 0; i < 3; i++)
			{
				if (mQueueInfos[i].Queues != null)
				{
					delete mQueueInfos[i].Queues;
					mQueueInfos[i].Queues = null;
				}
			}

			VulkanNative.vkDestroyDevice(mDevice, null);
			mDevice = .Null;
		}
	}

	// --- Internal ---
	public VkDevice Handle => mDevice;
	public VulkanAdapter Adapter => mAdapter;

	/// Sets a debug name on a Vulkan object (visible in RenderDoc, validation layers, etc.).
	public void SetDebugName(VkObjectType objectType, uint64 objectHandle, StringView name)
	{
		if (name.IsEmpty || mDevice.Handle == 0) return;

		if(VulkanNative.[Friend]vkSetDebugUtilsObjectNameEXT_ptr == null)
			return;

		let nameStr = scope String(name);
		VkDebugUtilsObjectNameInfoEXT nameInfo = .();
		nameInfo.objectType = objectType;
		nameInfo.objectHandle = objectHandle;
		nameInfo.pObjectName = nameStr.CStr();
		VulkanNative.vkSetDebugUtilsObjectNameEXT(mDevice, &nameInfo);
	}
	public VulkanBindingShifts BindingShifts
	{
		get => mBindingShifts;
		set => mBindingShifts = value;
	}

	/// Called by VulkanSwapChain.AcquireNextImage to set pending binary semaphores.
	public void SetPendingSwapChainSync(VkSemaphore acquireSemaphore, VkSemaphore presentSemaphore)
	{
		mPendingAcquireSemaphore = acquireSemaphore;
		mPendingPresentSemaphore = presentSemaphore;
		mHasPendingSwapChainSync = true;
	}

	/// Called by VulkanQueue.Submit to consume pending swapchain semaphores.
	/// Returns true if there were pending semaphores.
	public bool ConsumePendingSwapChainSync(out VkSemaphore acquireSemaphore, out VkSemaphore presentSemaphore)
	{
		if (mHasPendingSwapChainSync)
		{
			acquireSemaphore = mPendingAcquireSemaphore;
			presentSemaphore = mPendingPresentSemaphore;
			mHasPendingSwapChainSync = false;
			return true;
		}
		acquireSemaphore = .Null;
		presentSemaphore = .Null;
		return false;
	}
}
