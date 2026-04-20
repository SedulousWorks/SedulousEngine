namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Sedulous.RHI;
using Win32.System.Com;
using Win32.Graphics.Direct3D.Fxc;
using Win32.Graphics.Dxgi.Common;

/// DX12 implementation of IDevice.
class DX12Device : IDevice
{
	public DeviceType Type => .DX12;

	private DX12Adapter mAdapter;
	private ID3D12Device* mDevice;
	private DeviceFeatures mFeatures;

	// Queues
	private List<DX12Queue> mGraphicsQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<DX12Queue> mComputeQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<DX12Queue> mTransferQueues = new .() ~ DeleteContainerAndItems!(_);

	// Descriptor heap allocators (CPU-side for staging)
	private DX12DescriptorHeapAllocator mRtvHeap;
	private DX12DescriptorHeapAllocator mDsvHeap;
	private DX12DescriptorHeapAllocator mSrvHeap;
	private DX12DescriptorHeapAllocator mSamplerHeap;

	// GPU-visible descriptor heaps (shader-visible for binding)
	private DX12GpuDescriptorHeap mGpuSrvHeap;
	private DX12GpuDescriptorHeap mGpuSamplerHeap;

	// CPU-visible descriptor heaps for bind groups (non-shader-visible, readable for copy source)
	private DX12GpuDescriptorHeap mCpuSrvHeap;
	private DX12GpuDescriptorHeap mCpuSamplerHeap;

	// Cached command signatures for indirect execution
	private ID3D12CommandSignature* mDrawSignature;
	private ID3D12CommandSignature* mDrawIndexedSignature;
	private ID3D12CommandSignature* mDispatchSignature;
	private ID3D12CommandSignature* mDispatchMeshSignature;

	// Internal blit pipeline (for Blit and GenerateMipmaps)
	private ID3D12RootSignature* mBlitRootSignature;
	private D3D12_SHADER_BYTECODE mBlitVsBytecode;
	private D3D12_SHADER_BYTECODE mBlitPsBytecode;
	private ID3DBlob* mBlitVsBlob;
	private ID3DBlob* mBlitPsBlob;
	private Dictionary<DXGI_FORMAT, ID3D12PipelineState*> mBlitPsoCache = new .() ~ {
		for (let pso in _.Values) pso.Release();
		delete _;
	};

	// Extensions
	private DX12MeshShaderExt mMeshShaderExt;
	private DX12RayTracingExt mRayTracingExt;

	public this() { }

	public Result<void> Init(DX12Adapter adapter, DeviceDesc desc)
	{
		mAdapter = adapter;

		// Create device
		HRESULT hr = D3D12CreateDevice((IUnknown*)adapter.Handle, .D3D_FEATURE_LEVEL_12_0,
			ID3D12Device.IID, (void**)&mDevice);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Device: D3D12CreateDevice failed (0x{hr:X})");
			return .Err;
		}

		// Suppress noisy debug layer warnings
		{
			ID3D12InfoQueue* infoQueue = null;
			if (SUCCEEDED(mDevice.QueryInterface(ID3D12InfoQueue.IID, (void**)&infoQueue)))
			{
				D3D12_MESSAGE_ID[2] suppressIds = .(
					.D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
					.D3D12_MESSAGE_ID_CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE
				);
				D3D12_INFO_QUEUE_FILTER filter = .();
				filter.DenyList.NumIDs = (uint32)suppressIds.Count;
				filter.DenyList.pIDList = &suppressIds[0];
				infoQueue.AddStorageFilterEntries(&filter);
				infoQueue.Release();
			}
		}

		// Create descriptor heap allocators
		mRtvHeap = new DX12DescriptorHeapAllocator(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_RTV, 256);
		mDsvHeap = new DX12DescriptorHeapAllocator(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_DSV, 64);
		mSrvHeap = new DX12DescriptorHeapAllocator(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 4096);
		mSamplerHeap = new DX12DescriptorHeapAllocator(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 256);

		// Create GPU-visible descriptor heaps (shader-visible, for staging regions)
		mGpuSrvHeap = new DX12GpuDescriptorHeap(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 65536);
		mGpuSamplerHeap = new DX12GpuDescriptorHeap(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 2048);

		// Create CPU-visible descriptor heaps (non-shader-visible, bind groups write here)
		mCpuSrvHeap = new DX12GpuDescriptorHeap(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 65536, false);
		mCpuSamplerHeap = new DX12GpuDescriptorHeap(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 2048, false);

		// Create queues
		uint32 graphicsCount = Math.Max(desc.GraphicsQueueCount, 1);
		for (uint32 i = 0; i < graphicsCount; i++)
		{
			let queue = new DX12Queue();
			if (queue.Init(this, .Graphics) case .Err) { delete queue; break; }
			mGraphicsQueues.Add(queue);
		}

		for (uint32 i = 0; i < desc.ComputeQueueCount; i++)
		{
			let queue = new DX12Queue();
			if (queue.Init(this, .Compute) case .Err) { delete queue; break; }
			mComputeQueues.Add(queue);
		}

		for (uint32 i = 0; i < desc.TransferQueueCount; i++)
		{
			let queue = new DX12Queue();
			if (queue.Init(this, .Transfer) case .Err) { delete queue; break; }
			mTransferQueues.Add(queue);
		}

		// Create cached command signatures for indirect execution
		CreateIndirectCommandSignatures();

		// Create internal blit pipeline
		CreateBlitPipeline();

		// Create extensions based on device capabilities
		CreateExtensions();

		mFeatures = adapter.BuildFeatures();
		return .Ok;
	}

	private void CreateIndirectCommandSignatures()
	{
		D3D12_INDIRECT_ARGUMENT_DESC argDesc = default;

		// Draw indirect
		argDesc.Type = .D3D12_INDIRECT_ARGUMENT_TYPE_DRAW;
		D3D12_COMMAND_SIGNATURE_DESC sigDesc = .()
		{
			ByteStride = 16, // sizeof(D3D12_DRAW_ARGUMENTS): 4 x uint32
			NumArgumentDescs = 1,
			pArgumentDescs = &argDesc,
			NodeMask = 0
		};
		mDevice.CreateCommandSignature(&sigDesc, null, ID3D12CommandSignature.IID, (void**)&mDrawSignature);

		// DrawIndexed indirect
		argDesc.Type = .D3D12_INDIRECT_ARGUMENT_TYPE_DRAW_INDEXED;
		sigDesc.ByteStride = 20; // sizeof(D3D12_DRAW_INDEXED_ARGUMENTS): 5 x uint32
		mDevice.CreateCommandSignature(&sigDesc, null, ID3D12CommandSignature.IID, (void**)&mDrawIndexedSignature);

		// Dispatch indirect
		argDesc.Type = .D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH;
		sigDesc.ByteStride = 12; // sizeof(D3D12_DISPATCH_ARGUMENTS): 3 x uint32
		mDevice.CreateCommandSignature(&sigDesc, null, ID3D12CommandSignature.IID, (void**)&mDispatchSignature);
	}

	private void CreateExtensions()
	{
		// Mesh shaders - requires ID3D12Device2 (which we already require for mesh pipeline creation)
		// Check for mesh shader support via feature options7
		D3D12_FEATURE_DATA_D3D12_OPTIONS7 options7 = default;
		HRESULT hr = mDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS7, &options7, (uint32)sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS7));
		if (SUCCEEDED(hr) && options7.MeshShaderTier != .D3D12_MESH_SHADER_TIER_NOT_SUPPORTED)
		{
			mMeshShaderExt = new DX12MeshShaderExt(this);

			// Create DispatchMesh command signature
			D3D12_INDIRECT_ARGUMENT_DESC argDesc = default;
			argDesc.Type = .D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH_MESH;
			D3D12_COMMAND_SIGNATURE_DESC sigDesc = .()
			{
				ByteStride = 12, // sizeof(D3D12_DISPATCH_MESH_ARGUMENTS): 3 x uint32
				NumArgumentDescs = 1,
				pArgumentDescs = &argDesc,
				NodeMask = 0
			};
			mDevice.CreateCommandSignature(&sigDesc, null, ID3D12CommandSignature.IID, (void**)&mDispatchMeshSignature);
		}

		// Ray tracing - requires ID3D12Device5 and DXR support
		D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5 = default;
		hr = mDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS5, &options5, (uint32)sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS5));
		if (SUCCEEDED(hr) && options5.RaytracingTier != .D3D12_RAYTRACING_TIER_NOT_SUPPORTED)
		{
			mRayTracingExt = new DX12RayTracingExt(this);
		}
	}

	// ===== IDevice: Queues =====

	public IQueue GetQueue(QueueType type, uint32 index = 0)
	{
		switch (type)
		{
		case .Graphics: return (index < (uint32)mGraphicsQueues.Count) ? mGraphicsQueues[(.)index] : null;
		case .Compute:  return (index < (uint32)mComputeQueues.Count) ? mComputeQueues[(.)index] : null;
		case .Transfer: return (index < (uint32)mTransferQueues.Count) ? mTransferQueues[(.)index] : null;
		}
	}

	public uint32 GetQueueCount(QueueType type)
	{
		switch (type)
		{
		case .Graphics: return (uint32)mGraphicsQueues.Count;
		case .Compute:  return (uint32)mComputeQueues.Count;
		case .Transfer: return (uint32)mTransferQueues.Count;
		}
	}

	// ===== IDevice: Resource Creation =====

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		let buffer = new DX12Buffer();
		if (buffer.Init(this, desc) case .Err) { delete buffer; return .Err; }
		SetDebugName((ID3D12Object*)buffer.Handle, desc.Label);
		return .Ok(buffer);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		let texture = new DX12Texture();
		if (texture.Init(this, desc) case .Err) { delete texture; return .Err; }
		SetDebugName((ID3D12Object*)texture.Handle, desc.Label);
		return .Ok(texture);
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		let dxTex = texture as DX12Texture;
		if (dxTex == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12Device: cast to DX12Texture failed");
			return .Err;
		}

		let view = new DX12TextureView();
		if (view.Init(this, dxTex, desc) case .Err) { delete view; return .Err; }
		return .Ok(view);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		let sampler = new DX12Sampler();
		if (sampler.Init(this, desc) case .Err) { delete sampler; return .Err; }
		return .Ok(sampler);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		let module = new DX12ShaderModule();
		if (module.Init(desc) case .Err) { delete module; return .Err; }
		return .Ok(module);
	}

	// ===== Binding & Pipelines =====

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		let layout = new DX12BindGroupLayout();
		if (layout.Init(desc) case .Err) { delete layout; return .Err; }
		return .Ok(layout);
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		let group = new DX12BindGroup();
		if (group.Init(this, desc) case .Err) { delete group; return .Err; }
		return .Ok(group);
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		let layout = new DX12PipelineLayout();
		if (layout.Init(this, desc) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12Device: CreatePipelineLayout failed");
			delete layout;
			return .Err;
		}
		SetDebugName((ID3D12Object*)layout.Handle, desc.Label);
		return .Ok(layout);
	}

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		let cache = new DX12PipelineCache();
		if (cache.Init(this, desc) case .Err) { delete cache; return .Err; }
		if (cache.Handle != null) SetDebugName((ID3D12Object*)cache.Handle, desc.Label);
		return .Ok(cache);
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		let pipeline = new DX12RenderPipeline();
		if (pipeline.Init(this, desc) case .Err) { delete pipeline; return .Err; }
		SetDebugName((ID3D12Object*)pipeline.Handle, desc.Label);
		return .Ok(pipeline);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		let pipeline = new DX12ComputePipeline();
		if (pipeline.Init(this, desc) case .Err) { delete pipeline; return .Err; }
		SetDebugName((ID3D12Object*)pipeline.Handle, desc.Label);
		return .Ok(pipeline);
	}

	// ===== Commands =====

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		let pool = new DX12CommandPool();
		if (pool.Init(this, queueType) case .Err) { delete pool; return .Err; }
		return .Ok(pool);
	}

	// ===== Synchronization =====

	public Result<IFence> CreateFence(uint64 initialValue = 0)
	{
		let fence = new DX12Fence();
		if (fence.Init(this, initialValue) case .Err) { delete fence; return .Err; }
		return .Ok(fence);
	}

	// ===== Queries =====

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		let querySet = new DX12QuerySet();
		if (querySet.Init(this, desc) case .Err) { delete querySet; return .Err; }
		SetDebugName((ID3D12Object*)querySet.Handle, desc.Label);
		return .Ok(querySet);
	}

	// ===== Presentation =====

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		let dxSurface = surface as DX12Surface;
		if (dxSurface == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12Device: cast to DX12Surface failed");
			return .Err;
		}

		let swapChain = new DX12SwapChain();
		if (swapChain.Init(this, dxSurface, desc) case .Err) { delete swapChain; return .Err; }
		return .Ok(swapChain);
	}

	// ===== Destroy Methods =====

	public void DestroyBuffer(ref IBuffer buffer)
	{
		if (let dx = buffer as DX12Buffer) { dx.Cleanup(this); delete dx; }
		buffer = null;
	}

	public void DestroyTexture(ref ITexture texture)
	{
		if (let dx = texture as DX12Texture) { dx.Cleanup(this); delete dx; }
		texture = null;
	}

	public void DestroyTextureView(ref ITextureView view)
	{
		if (let dx = view as DX12TextureView) { dx.Cleanup(this); delete dx; }
		view = null;
	}

	public void DestroySampler(ref ISampler sampler)
	{
		if (let dx = sampler as DX12Sampler) { dx.Cleanup(this); delete dx; }
		sampler = null;
	}

	public void DestroyShaderModule(ref IShaderModule module)
	{
		if (let dx = module as DX12ShaderModule) { dx.Cleanup(); delete dx; }
		module = null;
	}

	public void DestroyBindGroupLayout(ref IBindGroupLayout layout)
	{
		if (let dx = layout as DX12BindGroupLayout) delete dx;
		layout = null;
	}

	public void DestroyBindGroup(ref IBindGroup group)
	{
		if (let dx = group as DX12BindGroup) { dx.Cleanup(this); delete dx; }
		group = null;
	}

	public void DestroyPipelineLayout(ref IPipelineLayout layout)
	{
		if (let dx = layout as DX12PipelineLayout) { dx.Cleanup(this); delete dx; }
		layout = null;
	}

	public void DestroyPipelineCache(ref IPipelineCache cache)
	{
		if (let dx = cache as DX12PipelineCache) { dx.Cleanup(this); delete dx; }
		cache = null;
	}

	public void DestroyRenderPipeline(ref IRenderPipeline pipeline)
	{
		if (let dx = pipeline as DX12RenderPipeline) { dx.Cleanup(this); delete dx; }
		pipeline = null;
	}

	public void DestroyComputePipeline(ref IComputePipeline pipeline)
	{
		if (let dx = pipeline as DX12ComputePipeline) { dx.Cleanup(this); delete dx; }
		pipeline = null;
	}

	public void DestroyCommandPool(ref ICommandPool pool)
	{
		if (let dx = pool as DX12CommandPool) { dx.Cleanup(this); delete dx; }
		pool = null;
	}

	public void DestroyFence(ref IFence fence)
	{
		if (let dx = fence as DX12Fence) { dx.Cleanup(this); delete dx; }
		fence = null;
	}

	public void DestroyQuerySet(ref IQuerySet querySet)
	{
		if (let dx = querySet as DX12QuerySet) { dx.Cleanup(this); delete dx; }
		querySet = null;
	}

	public void DestroySwapChain(ref ISwapChain swapChain)
	{
		if (let dx = swapChain as DX12SwapChain) { dx.Cleanup(this); delete dx; }
		swapChain = null;
	}

	public void DestroySurface(ref ISurface surface)
	{
		if (surface != null) delete surface;
		surface = null;
	}

	// ===== Extensions =====

	public IMeshShaderExt GetMeshShaderExt()
	{
		return mMeshShaderExt;
	}

	public IRayTracingExt GetRayTracingExt()
	{
		return mRayTracingExt;
	}

	// ===== Info =====

	public DeviceFeatures Features => mFeatures;

	public void WaitIdle()
	{
		for (let q in mGraphicsQueues) q.WaitIdle();
		for (let q in mComputeQueues)  q.WaitIdle();
		for (let q in mTransferQueues) q.WaitIdle();
	}

	public void Destroy()
	{
		WaitIdle();

		// Queues are deleted via DeleteContainerAndItems in destructor
		for (let q in mGraphicsQueues) q.Cleanup();
		for (let q in mComputeQueues) q.Cleanup();
		for (let q in mTransferQueues) q.Cleanup();

		if (mMeshShaderExt != null) { delete mMeshShaderExt; mMeshShaderExt = null; }
		if (mRayTracingExt != null) { delete mRayTracingExt; mRayTracingExt = null; }

		if (mBlitVsBlob != null) { mBlitVsBlob.Release(); mBlitVsBlob = null; }
		if (mBlitPsBlob != null) { mBlitPsBlob.Release(); mBlitPsBlob = null; }
		if (mBlitRootSignature != null) { mBlitRootSignature.Release(); mBlitRootSignature = null; }

		if (mDrawSignature != null) { mDrawSignature.Release(); mDrawSignature = null; }
		if (mDrawIndexedSignature != null) { mDrawIndexedSignature.Release(); mDrawIndexedSignature = null; }
		if (mDispatchSignature != null) { mDispatchSignature.Release(); mDispatchSignature = null; }
		if (mDispatchMeshSignature != null) { mDispatchMeshSignature.Release(); mDispatchMeshSignature = null; }

		if (mCpuSrvHeap != null) { mCpuSrvHeap.Destroy(); delete mCpuSrvHeap; mCpuSrvHeap = null; }
		if (mCpuSamplerHeap != null) { mCpuSamplerHeap.Destroy(); delete mCpuSamplerHeap; mCpuSamplerHeap = null; }
		if (mGpuSrvHeap != null) { mGpuSrvHeap.Destroy(); delete mGpuSrvHeap; mGpuSrvHeap = null; }
		if (mGpuSamplerHeap != null) { mGpuSamplerHeap.Destroy(); delete mGpuSamplerHeap; mGpuSamplerHeap = null; }

		if (mRtvHeap != null) { mRtvHeap.Destroy(); delete mRtvHeap; mRtvHeap = null; }
		if (mDsvHeap != null) { mDsvHeap.Destroy(); delete mDsvHeap; mDsvHeap = null; }
		if (mSrvHeap != null) { mSrvHeap.Destroy(); delete mSrvHeap; mSrvHeap = null; }
		if (mSamplerHeap != null) { mSamplerHeap.Destroy(); delete mSamplerHeap; mSamplerHeap = null; }

		if (mDevice != null)
		{
#if DEBUG
			ID3D12DebugDevice* debugDevice = null;
			if (SUCCEEDED(mDevice.QueryInterface(ID3D12DebugDevice.IID, (void**)&debugDevice)))
			{
				debugDevice.ReportLiveDeviceObjects(.D3D12_RLDO_DETAIL | .D3D12_RLDO_IGNORE_INTERNAL);
				debugDevice.Release();
			}
#endif
			mDevice.Release();
			mDevice = null;
		}
	}

	// --- Internal ---
	public ID3D12Device* Handle => mDevice;
	public DX12Adapter Adapter => mAdapter;

	/// Sets a debug name on a DX12 object (visible in PIX, VS Graphics Debugger, etc.).
	public static void SetDebugName(ID3D12Object* obj, StringView name)
	{
		if (name.IsEmpty || obj == null) return;
		let wideName = name.ToScopedNativeWChar!();
		obj.SetName(wideName);
	}
	public DX12DescriptorHeapAllocator RtvHeap => mRtvHeap;
	public DX12DescriptorHeapAllocator DsvHeap => mDsvHeap;
	public DX12DescriptorHeapAllocator SrvHeap => mSrvHeap;
	public DX12DescriptorHeapAllocator SamplerHeap => mSamplerHeap;
	public DX12GpuDescriptorHeap GpuSrvHeap => mGpuSrvHeap;
	public DX12GpuDescriptorHeap GpuSamplerHeap => mGpuSamplerHeap;
	public DX12GpuDescriptorHeap CpuSrvHeap => mCpuSrvHeap;
	public DX12GpuDescriptorHeap CpuSamplerHeap => mCpuSamplerHeap;
	public ID3D12CommandSignature* DrawSignature => mDrawSignature;
	public ID3D12CommandSignature* DrawIndexedSignature => mDrawIndexedSignature;
	public ID3D12CommandSignature* DispatchSignature => mDispatchSignature;
	public ID3D12CommandSignature* DispatchMeshSignature => mDispatchMeshSignature;
	public ID3D12RootSignature* BlitRootSignature => mBlitRootSignature;

	/// Gets or creates a blit PSO for the given render target format.
	public ID3D12PipelineState* GetOrCreateBlitPSO(DXGI_FORMAT format)
	{
		if (mBlitRootSignature == null) return null;
		if (mBlitPsoCache.TryGetValue(format, let pso)) return pso;

		D3D12_GRAPHICS_PIPELINE_STATE_DESC desc = .();
		desc.pRootSignature = mBlitRootSignature;
		desc.VS = mBlitVsBytecode;
		desc.PS = mBlitPsBytecode;
		desc.InputLayout.pInputElementDescs = null;
		desc.InputLayout.NumElements = 0;
		desc.PrimitiveTopologyType = .D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		desc.RasterizerState.FillMode = .D3D12_FILL_MODE_SOLID;
		desc.RasterizerState.CullMode = .D3D12_CULL_MODE_NONE;
		desc.RasterizerState.DepthClipEnable = FALSE;
		desc.BlendState.RenderTarget[0].BlendEnable = FALSE;
		desc.BlendState.RenderTarget[0].RenderTargetWriteMask = 0x0F;
		desc.DepthStencilState.DepthEnable = FALSE;
		desc.DepthStencilState.StencilEnable = FALSE;
		desc.DSVFormat = .DXGI_FORMAT_UNKNOWN;
		desc.NumRenderTargets = 1;
		desc.RTVFormats[0] = format;
		desc.SampleDesc.Count = 1;
		desc.SampleMask = uint32.MaxValue;

		ID3D12PipelineState* newPso = null;
		if (SUCCEEDED(mDevice.CreateGraphicsPipelineState(&desc, ID3D12PipelineState.IID, (void**)&newPso)))
		{
			mBlitPsoCache[format] = newPso;
			return newPso;
		}
		return null;
	}

	private void CreateBlitPipeline()
	{
		StringView vsSource = """
			struct VSOutput {
			    float4 Position : SV_Position;
			    float2 UV : TEXCOORD0;
			};
			VSOutput main(uint vertexId : SV_VertexID) {
			    VSOutput output;
			    output.UV = float2((vertexId << 1) & 2, vertexId & 2);
			    output.Position = float4(output.UV * float2(2, -2) + float2(-1, 1), 0, 1);
			    return output;
			}
			""";

		StringView psSource = """
			Texture2D srcTexture : register(t0);
			SamplerState srcSampler : register(s0);
			float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
			    return srcTexture.Sample(srcSampler, uv);
			}
			""";

		ID3DBlob* errorBlob = null;

		HRESULT hr = D3DCompile(vsSource.Ptr, (uint)vsSource.Length, null, null, null,
			(uint8*)"main", (uint8*)"vs_5_0", 0, 0, &mBlitVsBlob, &errorBlob);
		if (!SUCCEEDED(hr))
		{
			if (errorBlob != null) errorBlob.Release();
			return;
		}
		if (errorBlob != null) { errorBlob.Release(); errorBlob = null; }

		hr = D3DCompile(psSource.Ptr, (uint)psSource.Length, null, null, null,
			(uint8*)"main", (uint8*)"ps_5_0", 0, 0, &mBlitPsBlob, &errorBlob);
		if (!SUCCEEDED(hr))
		{
			if (errorBlob != null) errorBlob.Release();
			mBlitVsBlob.Release(); mBlitVsBlob = null;
			return;
		}
		if (errorBlob != null) { errorBlob.Release(); errorBlob = null; }

		mBlitVsBytecode.pShaderBytecode = mBlitVsBlob.GetBufferPointer();
		mBlitVsBytecode.BytecodeLength = mBlitVsBlob.GetBufferSize();
		mBlitPsBytecode.pShaderBytecode = mBlitPsBlob.GetBufferPointer();
		mBlitPsBytecode.BytecodeLength = mBlitPsBlob.GetBufferSize();

		// Root signature: 1 SRV descriptor table (t0) + 1 static linear sampler (s0)
		D3D12_DESCRIPTOR_RANGE srvRange = .();
		srvRange.RangeType = .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		srvRange.NumDescriptors = 1;
		srvRange.BaseShaderRegister = 0;
		srvRange.RegisterSpace = 0;
		srvRange.OffsetInDescriptorsFromTableStart = 0;

		D3D12_ROOT_PARAMETER rootParam = .();
		rootParam.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
		rootParam.ShaderVisibility = .D3D12_SHADER_VISIBILITY_PIXEL;
		rootParam.DescriptorTable.NumDescriptorRanges = 1;
		rootParam.DescriptorTable.pDescriptorRanges = &srvRange;

		D3D12_STATIC_SAMPLER_DESC staticSampler = .();
		staticSampler.Filter = .D3D12_FILTER_MIN_MAG_MIP_LINEAR;
		staticSampler.AddressU = .D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
		staticSampler.AddressV = .D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
		staticSampler.AddressW = .D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
		staticSampler.MaxAnisotropy = 1;
		staticSampler.ComparisonFunc = .D3D12_COMPARISON_FUNC_NEVER;
		staticSampler.MinLOD = 0;
		staticSampler.MaxLOD = float.MaxValue;
		staticSampler.ShaderVisibility = .D3D12_SHADER_VISIBILITY_PIXEL;

		D3D12_ROOT_SIGNATURE_DESC rsDesc = .();
		rsDesc.NumParameters = 1;
		rsDesc.pParameters = &rootParam;
		rsDesc.NumStaticSamplers = 1;
		rsDesc.pStaticSamplers = &staticSampler;

		ID3DBlob* signatureBlob = null;
		hr = D3D12SerializeRootSignature(&rsDesc, .D3D_ROOT_SIGNATURE_VERSION_1, &signatureBlob, &errorBlob);
		if (!SUCCEEDED(hr))
		{
			if (errorBlob != null) errorBlob.Release();
			if (signatureBlob != null) signatureBlob.Release();
			return;
		}
		if (errorBlob != null) { errorBlob.Release(); errorBlob = null; }

		mDevice.CreateRootSignature(0, signatureBlob.GetBufferPointer(), signatureBlob.GetBufferSize(),
			ID3D12RootSignature.IID, (void**)&mBlitRootSignature);
		signatureBlob.Release();
	}
}
