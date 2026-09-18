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

	// ==================================================================
	// PARTIALLY PORTED. The resource creation and destruction pairs, format support, the
	// indirect command signatures and the internal blit pipeline are still in
	// RaptorCode/Foundation/RHI.DX12/DxDevice.cppm, which says what remains. Everything
	// below answers honestly rather than pretending, so nothing silently half works.
	// ==================================================================

	public FormatSupport GetFormatSupport(TextureFormat format) => .();

	public Result<IBuffer> CreateBuffer(BufferDesc desc) => .Err;
	public Result<ITexture> CreateTexture(TextureDesc desc) => .Err;
	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc) => .Err;
	public Result<ISampler> CreateSampler(SamplerDesc desc) => .Err;
	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc) => .Err;
	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc) => .Err;
	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc) => .Err;
	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc) => .Err;
	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc) => .Err;
	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc) => .Err;
	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc) => .Err;
	public Result<ICommandPool> CreateCommandPool(QueueType queueType) => .Err;
	public Result<IFence> CreateFence(uint64 initialValue) => .Err;
	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc) => .Err;
	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc) => .Err;

	public void DestroyBuffer(ref IBuffer buffer) {}
	public void DestroyTexture(ref ITexture texture) {}
	public void DestroyTextureView(ref ITextureView view) {}
	public void DestroySampler(ref ISampler sampler) {}
	public void DestroyShaderModule(ref IShaderModule module) {}
	public void DestroyBindGroupLayout(ref IBindGroupLayout layout) {}
	public void DestroyBindGroup(ref IBindGroup group) {}
	public void DestroyPipelineLayout(ref IPipelineLayout layout) {}
	public void DestroyPipelineCache(ref IPipelineCache cache) {}
	public void DestroyRenderPipeline(ref IRenderPipeline pipeline) {}
	public void DestroyComputePipeline(ref IComputePipeline pipeline) {}
	public void DestroyCommandPool(ref ICommandPool pool) {}
	public void DestroyFence(ref IFence fence) {}
	public void DestroyQuerySet(ref IQuerySet querySet) {}
	public void DestroySwapChain(ref ISwapChain swapChain) {}
	public void DestroySurface(ref ISurface surface) {}
}
