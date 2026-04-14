namespace Sedulous.RHI.Validation;

using System;
using System.Collections;
using Sedulous.RHI;

/// Validation wrapper for IDevice.
/// Tracks resource lifecycle for use-after-destroy detection.
class ValidatedDevice : IDevice
{
	public DeviceType Type => mInner.Type;

	private IDevice mInner;
	private bool mDestroyed;

	// Resource tracking — tracks all live resources created through this device
	private List<IBuffer> mLiveBuffers = new .() ~ delete _;
	private List<ITexture> mLiveTextures = new .() ~ delete _;
	private List<ITextureView> mLiveTextureViews = new .() ~ delete _;
	private List<ISampler> mLiveSamplers = new .() ~ delete _;
	private List<IShaderModule> mLiveShaderModules = new .() ~ delete _;
	private List<IBindGroupLayout> mLiveBindGroupLayouts = new .() ~ delete _;
	private List<IBindGroup> mLiveBindGroups = new .() ~ delete _;
	private List<IPipelineLayout> mLivePipelineLayouts = new .() ~ delete _;
	private List<IPipelineCache> mLivePipelineCaches = new .() ~ delete _;
	private List<IRenderPipeline> mLiveRenderPipelines = new .() ~ delete _;
	private List<IComputePipeline> mLiveComputePipelines = new .() ~ delete _;
	private List<ICommandPool> mLiveCommandPools = new .() ~ delete _;
	private List<IFence> mLiveFences = new .() ~ delete _;
	private List<IQuerySet> mLiveQuerySets = new .() ~ delete _;
	private List<ISwapChain> mLiveSwapChains = new .() ~ delete _;

	// Wrapped queues
	private List<ValidatedQueue> mQueues = new .() ~ DeleteContainerAndItems!(_);

	public this(IDevice inner)
	{
		mInner = inner;
	}

	private bool CheckNotDestroyed(StringView method)
	{
		if (mDestroyed)
		{
			let msg = scope String();
			msg.AppendF("{}: device has been destroyed", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	// ===== Queues =====

	public IQueue GetQueue(QueueType type, uint32 index = 0)
	{
		if (!CheckNotDestroyed("GetQueue")) return null;

		let inner = mInner.GetQueue(type, index);
		if (inner == null) return null;

		// Return cached wrapper
		for (let q in mQueues)
			if (q.Inner === inner) return q;

		let wrapped = new ValidatedQueue(inner, this);
		mQueues.Add(wrapped);
		return wrapped;
	}

	public uint32 GetQueueCount(QueueType type)
	{
		if (!CheckNotDestroyed("GetQueueCount")) return 0;
		return mInner.GetQueueCount(type);
	}

	// ===== Resource Creation =====

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		if (!CheckNotDestroyed("CreateBuffer")) return .Err;

		if (desc.Size == 0)
		{
			ValidationLogger.Error("CreateBuffer: size is 0");
			return .Err;
		}

		// DX12 portability: UPLOAD/READBACK heaps cannot have UAV (Storage) usage.
		// Vulkan allows this but DX12 does not. Use a staging + GPU copy pattern instead.
		if (desc.Memory == .CpuToGpu && desc.Usage.HasFlag(.Storage))
		{
			ValidationLogger.Error(
				"""
				CreateBuffer: Storage usage is not compatible with CpuToGpu memory.
				DX12 UPLOAD heaps cannot have ALLOW_UNORDERED_ACCESS.
				Use a staging buffer (CpuToGpu, CopySrc) + GPU buffer (GpuOnly, Storage | CopyDst) instead.
				""");
			return .Err;
		}

		if (desc.Memory == .GpuToCpu && desc.Usage.HasFlag(.Storage))
		{
			ValidationLogger.Error(
				"""
				CreateBuffer: Storage usage is not compatible with GpuToCpu memory.
				"DX12 READBACK heaps cannot have ALLOW_UNORDERED_ACCESS.
				""");
			return .Err;
		}

		let result = mInner.CreateBuffer(desc);
		if (result case .Ok(let buffer))
		{
			mLiveBuffers.Add(buffer);
			return .Ok(buffer);
		}
		return .Err;
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		if (!CheckNotDestroyed("CreateTexture")) return .Err;

		if (desc.Width == 0 || desc.Height == 0)
		{
			ValidationLogger.Error("CreateTexture: width or height is 0");
			return .Err;
		}

		let result = mInner.CreateTexture(desc);
		if (result case .Ok(let texture))
		{
			mLiveTextures.Add(texture);
			return .Ok(texture);
		}
		return .Err;
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		if (!CheckNotDestroyed("CreateTextureView")) return .Err;

		if (texture == null)
		{
			ValidationLogger.Error("CreateTextureView: texture is null");
			return .Err;
		}

		if (!mLiveTextures.Contains(texture))
		{
			ValidationLogger.Error("CreateTextureView: texture has been destroyed or was not created by this device");
		}

		let result = mInner.CreateTextureView(texture, desc);
		if (result case .Ok(let view))
		{
			mLiveTextureViews.Add(view);
			return .Ok(view);
		}
		return .Err;
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		if (!CheckNotDestroyed("CreateSampler")) return .Err;

		let result = mInner.CreateSampler(desc);
		if (result case .Ok(let sampler))
		{
			mLiveSamplers.Add(sampler);
			return .Ok(sampler);
		}
		return .Err;
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		if (!CheckNotDestroyed("CreateShaderModule")) return .Err;

		if (desc.Code.IsEmpty)
		{
			ValidationLogger.Error("CreateShaderModule: code is empty");
			return .Err;
		}

		let result = mInner.CreateShaderModule(desc);
		if (result case .Ok(let module))
		{
			mLiveShaderModules.Add(module);
			return .Ok(module);
		}
		return .Err;
	}

	// ===== Binding =====

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		if (!CheckNotDestroyed("CreateBindGroupLayout")) return .Err;

		let result = mInner.CreateBindGroupLayout(desc);
		if (result case .Ok(let layout))
		{
			mLiveBindGroupLayouts.Add(layout);
			return .Ok(layout);
		}
		return .Err;
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		if (!CheckNotDestroyed("CreateBindGroup")) return .Err;

		if (desc.Layout == null)
		{
			ValidationLogger.Error("CreateBindGroup: layout is null");
			return .Err;
		}

		// Count non-bindless layout entries — only those need positional BindGroupEntry
		let layoutEntries = desc.Layout.Entries;
		if (layoutEntries != null)
		{
			int regularCount = 0;
			for (let le in layoutEntries)
			{
				switch (le.Type)
				{
				case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers, .BindlessStorageTextures:
					break; // Bindless entries are populated via UpdateBindless, not positional
				default:
					regularCount++;
				}
			}

			if (desc.Entries.Length != regularCount)
			{
				let msg = scope String();
				msg.AppendF("CreateBindGroup: entry count ({}) does not match non-bindless layout entry count ({})",
					desc.Entries.Length, regularCount);
				ValidationLogger.Error(msg);
				return .Err;
			}

			// Validate each positional entry provides the correct resource type
			int entryIdx = 0;
			for (int i = 0; i < layoutEntries.Count; i++)
			{
				let layoutEntry = layoutEntries[i];

				// Skip bindless layout entries — they don't consume a positional entry
				switch (layoutEntry.Type)
				{
				case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers, .BindlessStorageTextures:
					continue;
				default:
				}

				if (entryIdx >= desc.Entries.Length) break;
				let entry = desc.Entries[entryIdx];

				switch (layoutEntry.Type)
				{
				case .UniformBuffer, .StorageBufferReadOnly, .StorageBufferReadWrite:
					if (entry.Buffer == null)
					{
						let msg = scope String();
						msg.AppendF("CreateBindGroup: entry [{}] expects a buffer (layout type {}) but Buffer is null", entryIdx, layoutEntry.Type);
						ValidationLogger.Error(msg);
					}

				case .SampledTexture, .StorageTextureReadOnly, .StorageTextureReadWrite:
					if (entry.TextureView == null)
					{
						let msg = scope String();
						msg.AppendF("CreateBindGroup: entry [{}] expects a texture view (layout type {}) but TextureView is null", entryIdx, layoutEntry.Type);
						ValidationLogger.Error(msg);
					}

				case .Sampler, .ComparisonSampler:
					if (entry.Sampler == null)
					{
						let msg = scope String();
						msg.AppendF("CreateBindGroup: entry [{}] expects a sampler (layout type {}) but Sampler is null", entryIdx, layoutEntry.Type);
						ValidationLogger.Error(msg);
					}

				case .AccelerationStructure:
					if (entry.AccelStruct == null)
					{
						let msg = scope String();
						msg.AppendF("CreateBindGroup: entry [{}] expects an acceleration structure (layout type {}) but AccelStruct is null", entryIdx, layoutEntry.Type);
						ValidationLogger.Error(msg);
					}

				default:
				}

				entryIdx++;
			}
		}

		let result = mInner.CreateBindGroup(desc);
		if (result case .Ok(let group))
		{
			mLiveBindGroups.Add(group);
			return .Ok(group);
		}
		return .Err;
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		if (!CheckNotDestroyed("CreatePipelineLayout")) return .Err;

		let result = mInner.CreatePipelineLayout(desc);
		if (result case .Ok(let layout))
		{
			mLivePipelineLayouts.Add(layout);
			return .Ok(layout);
		}
		return .Err;
	}

	// ===== Pipelines =====

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		if (!CheckNotDestroyed("CreatePipelineCache")) return .Err;

		let result = mInner.CreatePipelineCache(desc);
		if (result case .Ok(let cache))
		{
			mLivePipelineCaches.Add(cache);
			return .Ok(cache);
		}
		return .Err;
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		if (!CheckNotDestroyed("CreateRenderPipeline")) return .Err;

		if (desc.Layout == null)
		{
			ValidationLogger.Error("CreateRenderPipeline: layout is null");
			return .Err;
		}

		if (desc.Vertex.Shader.Module == null)
		{
			ValidationLogger.Error("CreateRenderPipeline: vertex shader module is null");
			return .Err;
		}

		let result = mInner.CreateRenderPipeline(desc);
		if (result case .Ok(let pipeline))
		{
			mLiveRenderPipelines.Add(pipeline);
			return .Ok(pipeline);
		}
		return .Err;
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		if (!CheckNotDestroyed("CreateComputePipeline")) return .Err;

		if (desc.Layout == null)
		{
			ValidationLogger.Error("CreateComputePipeline: layout is null");
			return .Err;
		}

		if (desc.Compute.Module == null)
		{
			ValidationLogger.Error("CreateComputePipeline: compute shader module is null");
			return .Err;
		}

		let result = mInner.CreateComputePipeline(desc);
		if (result case .Ok(let pipeline))
		{
			mLiveComputePipelines.Add(pipeline);
			return .Ok(pipeline);
		}
		return .Err;
	}

	// ===== Commands =====

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		if (!CheckNotDestroyed("CreateCommandPool")) return .Err;

		let result = mInner.CreateCommandPool(queueType);
		if (result case .Ok(let pool))
		{
			let wrapped = new ValidatedCommandPool(pool);
			mLiveCommandPools.Add(wrapped);
			return .Ok(wrapped);
		}
		return .Err;
	}

	// ===== Synchronization =====

	public Result<IFence> CreateFence(uint64 initialValue = 0)
	{
		if (!CheckNotDestroyed("CreateFence")) return .Err;

		let result = mInner.CreateFence(initialValue);
		if (result case .Ok(let fence))
		{
			let wrapped = new ValidatedFence(fence, initialValue);
			mLiveFences.Add(wrapped);
			return .Ok(wrapped);
		}
		return .Err;
	}

	// ===== Queries =====

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		if (!CheckNotDestroyed("CreateQuerySet")) return .Err;

		if (desc.Count == 0)
		{
			ValidationLogger.Error("CreateQuerySet: count is 0");
			return .Err;
		}

		let result = mInner.CreateQuerySet(desc);
		if (result case .Ok(let querySet))
		{
			mLiveQuerySets.Add(querySet);
			return .Ok(querySet);
		}
		return .Err;
	}

	// ===== Presentation =====

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		if (!CheckNotDestroyed("CreateSwapChain")) return .Err;

		if (surface == null)
		{
			ValidationLogger.Error("CreateSwapChain: surface is null");
			return .Err;
		}

		if (desc.Width == 0 || desc.Height == 0)
		{
			ValidationLogger.Error("CreateSwapChain: width or height is 0");
			return .Err;
		}

		let result = mInner.CreateSwapChain(surface, desc);
		if (result case .Ok(let swapChain))
		{
			let wrapped = new ValidatedSwapChain(swapChain);
			mLiveSwapChains.Add(wrapped);
			return .Ok(wrapped);
		}
		return .Err;
	}

	// ===== Resource Destruction =====

	public void DestroyBuffer(ref IBuffer buffer)
	{
		if (buffer == null) return;
		if (!mLiveBuffers.Remove(buffer))
			ValidationLogger.Warn("DestroyBuffer: buffer was not tracked (double-destroy or wrong device?)");
		mInner.DestroyBuffer(ref buffer);
	}

	public void DestroyTexture(ref ITexture texture)
	{
		if (texture == null) return;
		if (!mLiveTextures.Remove(texture))
			ValidationLogger.Warn("DestroyTexture: texture was not tracked");
		mInner.DestroyTexture(ref texture);
	}

	public void DestroyTextureView(ref ITextureView view)
	{
		if (view == null) return;
		if (!mLiveTextureViews.Remove(view))
			ValidationLogger.Warn("DestroyTextureView: view was not tracked");
		mInner.DestroyTextureView(ref view);
	}

	public void DestroySampler(ref ISampler sampler)
	{
		if (sampler == null) return;
		if (!mLiveSamplers.Remove(sampler))
			ValidationLogger.Warn("DestroySampler: sampler was not tracked");
		mInner.DestroySampler(ref sampler);
	}

	public void DestroyShaderModule(ref IShaderModule module)
	{
		if (module == null) return;
		if (!mLiveShaderModules.Remove(module))
			ValidationLogger.Warn("DestroyShaderModule: module was not tracked");
		mInner.DestroyShaderModule(ref module);
	}

	public void DestroyBindGroupLayout(ref IBindGroupLayout layout)
	{
		if (layout == null) return;
		if (!mLiveBindGroupLayouts.Remove(layout))
			ValidationLogger.Warn("DestroyBindGroupLayout: layout was not tracked");
		mInner.DestroyBindGroupLayout(ref layout);
	}

	public void DestroyBindGroup(ref IBindGroup group)
	{
		if (group == null) return;
		if (!mLiveBindGroups.Remove(group))
			ValidationLogger.Warn("DestroyBindGroup: group was not tracked");
		mInner.DestroyBindGroup(ref group);
	}

	public void DestroyPipelineLayout(ref IPipelineLayout layout)
	{
		if (layout == null) return;
		if (!mLivePipelineLayouts.Remove(layout))
			ValidationLogger.Warn("DestroyPipelineLayout: layout was not tracked");
		mInner.DestroyPipelineLayout(ref layout);
	}

	public void DestroyPipelineCache(ref IPipelineCache cache)
	{
		if (cache == null) return;
		if (!mLivePipelineCaches.Remove(cache))
			ValidationLogger.Warn("DestroyPipelineCache: cache was not tracked");
		mInner.DestroyPipelineCache(ref cache);
	}

	public void DestroyRenderPipeline(ref IRenderPipeline pipeline)
	{
		if (pipeline == null) return;
		if (!mLiveRenderPipelines.Remove(pipeline))
			ValidationLogger.Warn("DestroyRenderPipeline: pipeline was not tracked");
		mInner.DestroyRenderPipeline(ref pipeline);
	}

	public void DestroyComputePipeline(ref IComputePipeline pipeline)
	{
		if (pipeline == null) return;
		if (!mLiveComputePipelines.Remove(pipeline))
			ValidationLogger.Warn("DestroyComputePipeline: pipeline was not tracked");
		mInner.DestroyComputePipeline(ref pipeline);
	}

	public void DestroyCommandPool(ref ICommandPool pool)
	{
		if (pool == null) return;
		if (!mLiveCommandPools.Remove(pool))
			ValidationLogger.Warn("DestroyCommandPool: pool was not tracked");

		// Unwrap if validated
		if (let validated = pool as ValidatedCommandPool)
		{
			var inner = validated.Inner;
			delete validated;
			mInner.DestroyCommandPool(ref inner);
			pool = null;
		}
		else
		{
			mInner.DestroyCommandPool(ref pool);
		}
	}

	public void DestroyFence(ref IFence fence)
	{
		if (fence == null) return;
		if (!mLiveFences.Remove(fence))
			ValidationLogger.Warn("DestroyFence: fence was not tracked");

		if (let validated = fence as ValidatedFence)
		{
			var inner = validated.Inner;
			delete validated;
			mInner.DestroyFence(ref inner);
			fence = null;
		}
		else
		{
			mInner.DestroyFence(ref fence);
		}
	}

	public void DestroyQuerySet(ref IQuerySet querySet)
	{
		if (querySet == null) return;
		if (!mLiveQuerySets.Remove(querySet))
			ValidationLogger.Warn("DestroyQuerySet: querySet was not tracked");
		mInner.DestroyQuerySet(ref querySet);
	}

	public void DestroySwapChain(ref ISwapChain swapChain)
	{
		if (swapChain == null) return;
		if (!mLiveSwapChains.Remove(swapChain))
			ValidationLogger.Warn("DestroySwapChain: swapChain was not tracked");

		if (let validated = swapChain as ValidatedSwapChain)
		{
			var inner = validated.Inner;
			delete validated;
			mInner.DestroySwapChain(ref inner);
			swapChain = null;
		}
		else
		{
			mInner.DestroySwapChain(ref swapChain);
		}
	}

	public void DestroySurface(ref ISurface surface)
	{
		mInner.DestroySurface(ref surface);
	}

	// ===== Extensions =====

	public IMeshShaderExt GetMeshShaderExt()
	{
		if (!CheckNotDestroyed("GetMeshShaderExt")) return null;
		return mInner.GetMeshShaderExt();
	}

	public IRayTracingExt GetRayTracingExt()
	{
		if (!CheckNotDestroyed("GetRayTracingExt")) return null;
		return mInner.GetRayTracingExt();
	}

	// ===== Info =====

	public DeviceFeatures Features
	{
		get
		{
			if (!CheckNotDestroyed("Features")) return default;
			return mInner.Features;
		}
	}

	public void WaitIdle()
	{
		if (!CheckNotDestroyed("WaitIdle")) return;
		mInner.WaitIdle();
	}

	public void Destroy()
	{
		if (mDestroyed)
		{
			ValidationLogger.Error("Device.Destroy: device already destroyed");
			return;
		}

		// Warn about leaked resources
		WarnLeaks("Buffer", mLiveBuffers.Count);
		WarnLeaks("Texture", mLiveTextures.Count);
		WarnLeaks("TextureView", mLiveTextureViews.Count);
		WarnLeaks("Sampler", mLiveSamplers.Count);
		WarnLeaks("ShaderModule", mLiveShaderModules.Count);
		WarnLeaks("BindGroupLayout", mLiveBindGroupLayouts.Count);
		WarnLeaks("BindGroup", mLiveBindGroups.Count);
		WarnLeaks("PipelineLayout", mLivePipelineLayouts.Count);
		WarnLeaks("PipelineCache", mLivePipelineCaches.Count);
		WarnLeaks("RenderPipeline", mLiveRenderPipelines.Count);
		WarnLeaks("ComputePipeline", mLiveComputePipelines.Count);
		WarnLeaks("CommandPool", mLiveCommandPools.Count);
		WarnLeaks("Fence", mLiveFences.Count);
		WarnLeaks("QuerySet", mLiveQuerySets.Count);
		WarnLeaks("SwapChain", mLiveSwapChains.Count);

		mDestroyed = true;
		mInner.Destroy();
	}

	private void WarnLeaks(StringView typeName, int count)
	{
		if (count > 0)
		{
			let msg = scope String();
			msg.AppendF("Device.Destroy: {} live {}(s) not destroyed (resource leak)", count, typeName);
			ValidationLogger.Warn(msg);
		}
	}

	public IDevice Inner => mInner;
}
