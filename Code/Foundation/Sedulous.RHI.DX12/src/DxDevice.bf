using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Win32.System.Com;

namespace Sedulous.RHI.DX12;

/// The D3D12 device: its queues, its descriptor heaps, and everything created on it.
///
/// OWNERSHIP, which is the bulk of what this type does. It owns the D3D12 device, every
/// queue, and eight descriptor heaps. Everything it creates is handed to the caller, who
/// gives it back through the matching Destroy, exactly as the Vulkan device does.
///
/// The heaps are sized for their Tier 1 guarantees rather than guessed. The shader visible
/// SRV heap is a million descriptors because per pool staging blocks, frames in flight times
/// job slots times a thousand each, exhausted a 64K heap under multi view loads: allocation
/// then fails, SetBindGroup goes stale, and draws sample garbage. The sampler heap is capped
/// at 2048 BY D3D12, which is why sampler tables are baked rather than staged.
class DxDevice : IDevice
{
	private ID3D12Device* mDevice = null; // owned, released in Destroy
	private ID3D12InfoQueue* mInfoQueue = null; // owned, released in Destroy
	private DxAdapter mAdapter = null; // NOT owned, the adapter outlives its devices

	private DeviceFeatures mFeatures = .();
	private uint32 mShaderGroupHandleSize = 0;
	private uint32 mShaderGroupHandleAlignment = 0;
	private uint32 mShaderGroupBaseAlignment = 0;

	private List<DxQueue> mGraphicsQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<DxQueue> mComputeQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<DxQueue> mTransferQueues = new .() ~ DeleteContainerAndItems!(_);

	// CPU side staging heaps, single slot at a time.
	private DxDescriptorHeapAllocator mRtvHeap = new .() ~ delete _;
	private DxDescriptorHeapAllocator mDsvHeap = new .() ~ delete _;
	private DxDescriptorHeapAllocator mSrvHeap = new .() ~ delete _;
	private DxDescriptorHeapAllocator mSamplerHeap = new .() ~ delete _;

	// Shader visible, which is what a command list can actually bind.
	private DxGpuDescriptorHeap mGpuSrvHeap = new .() ~ delete _;
	private DxGpuDescriptorHeap mGpuSamplerHeap = new .() ~ delete _;

	// Not shader visible; bind groups write their descriptors here and they are staged in.
	private DxGpuDescriptorHeap mCpuSrvHeap = new .() ~ delete _;
	private DxGpuDescriptorHeap mCpuSamplerHeap = new .() ~ delete _;

	private bool mMeshEnabled = false;
	private bool mRtEnabled = false;

	// ---- what the rest of the backend reaches for ----
	public ID3D12Device* Handle => mDevice;
	public DxAdapter Adapter => mAdapter;
	public DxDescriptorHeapAllocator RtvHeap => mRtvHeap;
	public DxDescriptorHeapAllocator DsvHeap => mDsvHeap;
	public DxDescriptorHeapAllocator SrvHeap => mSrvHeap;
	public DxDescriptorHeapAllocator SamplerHeap => mSamplerHeap;
	public DxGpuDescriptorHeap GpuSrvHeap => mGpuSrvHeap;
	public DxGpuDescriptorHeap GpuSamplerHeap => mGpuSamplerHeap;
	public DxGpuDescriptorHeap CpuSrvHeap => mCpuSrvHeap;
	public DxGpuDescriptorHeap CpuSamplerHeap => mCpuSamplerHeap;
	public bool MeshEnabled => mMeshEnabled;
	public bool RtEnabled => mRtEnabled;

	// ---- IDevice ----
	public DeviceType Type => .DX12;
	public DeviceFeatures Features => mFeatures;
	/// DXIL, always: there is no other cook D3D12 accepts.
	public ShaderFormat PreferredShaderFormat => .DXIL;
	/// D3D12 and the RHI agree on clip space, so nothing has to be flipped.
	public bool NeedsClipSpaceYFlip => false;
	public uint32 ShaderGroupHandleSize => mShaderGroupHandleSize;
	public uint32 ShaderGroupHandleAlignment => mShaderGroupHandleAlignment;
	public uint32 ShaderGroupBaseAlignment => mShaderGroupBaseAlignment;

	public Result<void> Initialize(DxAdapter adapter, DeviceDesc desc)
	{
		mAdapter = adapter;

		let hr = D3D12CreateDevice((IUnknown*)adapter.Handle, .D3D_FEATURE_LEVEL_12_0,
			ID3D12Device.IID, (void**)&mDevice);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxDevice: D3D12CreateDevice failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		// Two debug layer warnings fire on every clear that does not match the optimised
		// clear value, which is most of them, so they are filtered rather than read past.
		if (SUCCEEDED(mDevice.QueryInterface(ID3D12InfoQueue.IID, (void**)&mInfoQueue)))
		{
			D3D12_MESSAGE_ID[2] suppressIds = .(
				.D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
				.D3D12_MESSAGE_ID_CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE);

			D3D12_INFO_QUEUE_FILTER filter = .();
			filter.DenyList.NumIDs = 2;
			filter.DenyList.pIDList = &suppressIds[0];
			mInfoQueue.AddStorageFilterEntries(&filter);
		}

		mRtvHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_RTV, 256).IgnoreError();
		mDsvHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_DSV, 64).IgnoreError();
		mSrvHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 4096).IgnoreError();
		mSamplerHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 256).IgnoreError();

		mGpuSrvHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 1000000, true)
			.IgnoreError();
		mGpuSamplerHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 2048, true)
			.IgnoreError();

		mCpuSrvHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 65536, false)
			.IgnoreError();
		mCpuSamplerHeap.Initialize(mDevice, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 2048, false)
			.IgnoreError();

		// At least one graphics queue, whatever was asked for. A queue that fails to open
		// stops the run for its type rather than leaving a hole in the list.
		CreateQueues(mGraphicsQueues, .Graphics, Math.Max(desc.GraphicsQueueCount, 1));
		CreateQueues(mComputeQueues, .Compute, desc.ComputeQueueCount);
		CreateQueues(mTransferQueues, .Transfer, desc.TransferQueueCount);

		mFeatures = adapter.BuildFeatures();
		return .Ok;
	}

	private void CreateQueues(List<DxQueue> into, QueueType type, uint32 count)
	{
		for (uint32 i = 0; i < count; i++)
		{
			let q = new DxQueue();
			if (q.Initialize(mDevice, type, this) case .Err)
			{
				delete q;
				break;
			}
			into.Add(q);
		}
	}

	private List<DxQueue> QueuesFor(QueueType t)
	{
		switch (t)
		{
		case .Graphics: return mGraphicsQueues;
		case .Compute: return mComputeQueues;
		case .Transfer: return mTransferQueues;
		}
	}

	public IQueue GetQueue(QueueType type, uint32 index = 0)
	{
		let list = QueuesFor(type);
		if ((int)index < list.Count)
			return list[(int)index];

		// A compute or transfer queue that was never opened falls back to graphics, which can
		// do the work: the alternative is handing back nothing and failing the frame.
		if ((type != .Graphics) && !mGraphicsQueues.IsEmpty)
			return mGraphicsQueues[0];

		return null;
	}

	public uint32 GetQueueCount(QueueType type) => (uint32)QueuesFor(type).Count;

	public bool IsLost()
	{
		return FAILED(mDevice.GetDeviceRemovedReason());
	}

	public void WaitIdle()
	{
		for (let q in mGraphicsQueues) q.WaitIdle();
		for (let q in mComputeQueues) q.WaitIdle();
		for (let q in mTransferQueues) q.WaitIdle();
	}

	public void Destroy()
	{
		WaitIdle();

		for (let q in mGraphicsQueues) q.Cleanup();
		for (let q in mComputeQueues) q.Cleanup();
		for (let q in mTransferQueues) q.Cleanup();
		ClearAndDeleteItems!(mGraphicsQueues);
		ClearAndDeleteItems!(mComputeQueues);
		ClearAndDeleteItems!(mTransferQueues);

		mCpuSrvHeap.Destroy();
		mCpuSamplerHeap.Destroy();
		mGpuSrvHeap.Destroy();
		mGpuSamplerHeap.Destroy();
		mRtvHeap.Destroy();
		mDsvHeap.Destroy();
		mSrvHeap.Destroy();
		mSamplerHeap.Destroy();

		if (mInfoQueue != null)
		{
			mInfoQueue.Release();
			mInfoQueue = null;
		}

		if (mDevice != null)
		{
			mDevice.Release();
			mDevice = null;
		}
	}

	/// A debug name, visible in PIX and the graphics debuggers. Any ID3D12Object takes one.
	/// Names are ASCII, so widening is a cast per character.
	private static void SetDebugName(ID3D12Object* obj, StringView name)
	{
		if ((obj == null) || name.IsEmpty)
			return;

		let wide = scope List<char16>();
		for (int i = 0; i < name.Length; i++)
			wide.Add((char16)(uint8)name[i]);
		wide.Add(0);

		obj.SetName(wide.Ptr);
	}

	// ==================================================================
	// Resource creation. Everything made here is handed to the CALLER, who gives it back
	// through the matching Destroy, which is what the Vulkan device does too.
	// ==================================================================

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		let b = new DxBuffer();
		if (b.Initialize(mDevice, desc) case .Err)
		{
			delete b;
			return .Err;
		}
		SetDebugName((ID3D12Object*)b.Handle, desc.Label);
		return .Ok(b);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		let t = new DxTexture();
		if (t.Initialize(mDevice, desc) case .Err)
		{
			delete t;
			return .Err;
		}
		SetDebugName((ID3D12Object*)t.Handle, desc.Label);
		return .Ok(t);
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		let dxTex = texture as DxTexture;
		if (dxTex == null)
		{
			GlobalLog(.Error, "DxDevice: the texture is not a DxTexture");
			return .Err;
		}

		let v = new DxTextureView();
		if (v.Initialize(mDevice, dxTex, desc, mSrvHeap, mRtvHeap, mDsvHeap) case .Err)
		{
			delete v;
			return .Err;
		}
		return .Ok(v);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		let s = new DxSampler();
		if (s.Initialize(mDevice, desc, mSamplerHeap) case .Err)
		{
			delete s;
			return .Err;
		}
		return .Ok(s);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		let m = new DxShaderModule();
		if (m.Initialize(desc) case .Err)
		{
			delete m;
			return .Err;
		}
		return .Ok(m);
	}

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		let l = new DxBindGroupLayout();
		if (l.Initialize(desc) case .Err)
		{
			delete l;
			return .Err;
		}
		return .Ok(l);
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		let g = new DxBindGroup();
		if (g.Initialize(mDevice, desc, mCpuSrvHeap, mCpuSamplerHeap, mGpuSamplerHeap) case .Err)
		{
			delete g;
			return .Err;
		}
		return .Ok(g);
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		let l = new DxPipelineLayout();
		if (l.Initialize(mDevice, desc) case .Err)
		{
			GlobalLog(.Error, "DxDevice: CreatePipelineLayout failed");
			delete l;
			return .Err;
		}
		SetDebugName((ID3D12Object*)l.Handle, desc.Label);
		return .Ok(l);
	}

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		let c = new DxPipelineCache();
		if (c.Initialize(mDevice, desc) case .Err)
		{
			delete c;
			return .Err;
		}
		if (c.Handle != null)
			SetDebugName((ID3D12Object*)c.Handle, desc.Label);
		return .Ok(c);
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		let p = new DxRenderPipeline();
		if (p.Initialize(mDevice, desc) case .Err)
		{
			delete p;
			return .Err;
		}
		SetDebugName((ID3D12Object*)p.Handle, desc.Label);
		return .Ok(p);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		let p = new DxComputePipeline();
		if (p.Initialize(mDevice, desc) case .Err)
		{
			delete p;
			return .Err;
		}
		SetDebugName((ID3D12Object*)p.Handle, desc.Label);
		return .Ok(p);
	}

	public Result<IFence> CreateFence(uint64 initialValue)
	{
		let f = new DxFence();
		if (f.Initialize(mDevice, initialValue) case .Err)
		{
			delete f;
			return .Err;
		}
		return .Ok(f);
	}

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		let q = new DxQuerySet();
		if (q.Initialize(mDevice, desc) case .Err)
		{
			delete q;
			return .Err;
		}
		SetDebugName((ID3D12Object*)q.Handle, desc.Label);
		return .Ok(q);
	}

	// ---- mesh shaders, refused outright when the device has none ----

	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		if (!mMeshEnabled)
			return .Err;

		let p = new DxMeshPipeline();
		if (p.Initialize(mDevice, desc) case .Err)
		{
			delete p;
			return .Err;
		}
		SetDebugName((ID3D12Object*)p.Handle, desc.Label);
		return .Ok(p);
	}

	public void DestroyMeshPipeline(ref IMeshPipeline pipeline)
	{
		if (let p = pipeline as DxMeshPipeline)
		{
			p.Cleanup();
			delete p;
		}
		pipeline = null;
	}

	// ---- ray tracing, likewise ----

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		if (!mRtEnabled)
			return .Err;

		let a = new DxAccelStruct();
		if (a.Initialize(mDevice, desc) case .Err)
		{
			delete a;
			return .Err;
		}
		return .Ok(a);
	}

	public void DestroyAccelStruct(ref IAccelStruct accelStruct)
	{
		if (let a = accelStruct as DxAccelStruct)
		{
			a.Cleanup();
			delete a;
		}
		accelStruct = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		if (!mRtEnabled)
			return .Err;

		let p = new DxRayTracingPipeline();
		if (p.Initialize(mDevice, desc) case .Err)
		{
			delete p;
			return .Err;
		}
		return .Ok(p);
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline)
	{
		if (let p = pipeline as DxRayTracingPipeline)
		{
			p.Cleanup();
			delete p;
		}
		pipeline = null;
	}

	/// The shader identifiers for a run of groups, packed back to back into outData.
	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline, uint32 firstGroup,
		uint32 groupCount, Span<uint8> outData)
	{
		let dxPipeline = pipeline as DxRayTracingPipeline;
		if (dxPipeline == null)
			return .Err;

		const uint32 cHandleSize = 32; // D3D12_SHADER_IDENTIFIER_SIZE_IN_BYTES
		if ((uint32)outData.Length < groupCount * cHandleSize)
		{
			GlobalLog(.Error, "DxDevice: the output buffer is too small for the group handles");
			return .Err;
		}

		let exportNames = dxPipeline.GroupExportNames;
		for (uint32 i = 0; i < groupCount; i++)
		{
			let groupIdx = (int)(firstGroup + i);
			if (groupIdx >= exportNames.Length)
			{
				GlobalLog(.Error, "DxDevice: the shader group index is out of range");
				return .Err;
			}

			let identifier = dxPipeline.GetShaderIdentifier(exportNames[groupIdx]);
			if (identifier == null)
			{
				GlobalLog(.Error, "DxDevice: GetShaderIdentifier answered null");
				return .Err;
			}

			Internal.MemCpy(&outData[(int)(i * cHandleSize)], identifier, cHandleSize);
		}

		return .Ok;
	}

	// ==================================================================
	// Resource destruction. Cleanup gives up the native handles, then the object goes.
	// ==================================================================

	public void DestroyBuffer(ref IBuffer buffer)
	{
		if (let r = buffer as DxBuffer) { r.Cleanup(); delete r; }
		buffer = null;
	}

	public void DestroyTexture(ref ITexture texture)
	{
		if (let r = texture as DxTexture) { r.Cleanup(); delete r; }
		texture = null;
	}

	public void DestroyTextureView(ref ITextureView view)
	{
		if (let r = view as DxTextureView) { r.Cleanup(); delete r; }
		view = null;
	}

	public void DestroySampler(ref ISampler sampler)
	{
		if (let r = sampler as DxSampler) { r.Cleanup(); delete r; }
		sampler = null;
	}

	public void DestroyShaderModule(ref IShaderModule module)
	{
		if (let r = module as DxShaderModule) { r.Cleanup(); delete r; }
		module = null;
	}

	public void DestroyBindGroupLayout(ref IBindGroupLayout layout)
	{
		if (let r = layout as DxBindGroupLayout) { delete r; }
		layout = null;
	}

	public void DestroyBindGroup(ref IBindGroup group)
	{
		if (let r = group as DxBindGroup) { r.Cleanup(); delete r; }
		group = null;
	}

	public void DestroyPipelineLayout(ref IPipelineLayout layout)
	{
		if (let r = layout as DxPipelineLayout) { r.Cleanup(); delete r; }
		layout = null;
	}

	public void DestroyPipelineCache(ref IPipelineCache cache)
	{
		if (let r = cache as DxPipelineCache) { r.Cleanup(); delete r; }
		cache = null;
	}

	public void DestroyRenderPipeline(ref IRenderPipeline pipeline)
	{
		if (let r = pipeline as DxRenderPipeline) { r.Cleanup(); delete r; }
		pipeline = null;
	}

	public void DestroyComputePipeline(ref IComputePipeline pipeline)
	{
		if (let r = pipeline as DxComputePipeline) { r.Cleanup(); delete r; }
		pipeline = null;
	}

	public void DestroyFence(ref IFence fence)
	{
		if (let r = fence as DxFence) { r.Cleanup(); delete r; }
		fence = null;
	}

	public void DestroyQuerySet(ref IQuerySet querySet)
	{
		if (let r = querySet as DxQuerySet) { r.Cleanup(); delete r; }
		querySet = null;
	}

	public void DestroySurface(ref ISurface surface)
	{
		// The backend owns surfaces, so nothing is freed here.
		surface = null;
	}

	// ==================================================================
	// PARTIALLY PORTED. Format support, the indirect command signatures, the internal blit
	// pipeline and extension detection are still in RaptorCode, which says what remains.
	// The command pool and the swap chain wait on their own types.
	// ==================================================================

	public FormatSupport GetFormatSupport(TextureFormat format) => .();

	public Result<ICommandPool> CreateCommandPool(QueueType queueType) => .Err;
	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc) => .Err;

	public void DestroyCommandPool(ref ICommandPool pool) {}
	public void DestroySwapChain(ref ISwapChain swapChain) {}
}
