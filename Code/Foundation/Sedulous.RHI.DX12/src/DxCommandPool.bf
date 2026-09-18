using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One command allocator, the encoders recording into it, and the descriptor staging they
/// share.
///
/// OWNERSHIP is the job here. The pool owns its allocator, the command buffers its encoders
/// finished, the bundle encoders minted from it, and the staging. Everything it owns is given
/// up on Reset, which is only ever called once the pool's fence has been waited on, so nothing
/// the GPU is still reading is freed.
class DxCommandPool : ICommandPool
{
	private DxDevice mDevice = null; // NOT owned
	private ID3D12Device* mD3dDevice = null; // NOT owned
	private ID3D12CommandAllocator* mAllocator = null; // owned
	private D3D12_COMMAND_LIST_TYPE mType = .D3D12_COMMAND_LIST_TYPE_DIRECT;

	private List<DxCommandBuffer> mTrackedBuffers = new .() ~ delete _; // owned, freed on Reset
	private List<DxRenderBundleEncoder> mTrackedBundleEncoders = new .() ~ delete _; // likewise
	/// Encoders created whose Finish has not run. Reset cannot be safe while any is open.
	private int32 mUnfinishedEncoders = 0;

	private DxDescriptorStaging mSrvStaging = new .() ~ delete _;

	public ID3D12CommandAllocator* Handle => mAllocator;
	public DxDevice OwnerDevice => mDevice;
	public DxDescriptorStaging SrvStaging => mSrvStaging;

	public Result<void> Initialize(DxDevice device, ID3D12Device* d3dDevice, QueueType queueType)
	{
		mDevice = device;
		mD3dDevice = d3dDevice;
		mType = DxConversions.ToCommandListType(queueType);

		if (FAILED(d3dDevice.CreateCommandAllocator(mType, ID3D12CommandAllocator.IID,
			(void**)&mAllocator)))
			return .Err;

		// Only the SRV heap is staged. The shader visible SAMPLER heap is capped at 2048 by
		// D3D12, which cannot fit per pool staging blocks, so sampler tables are baked into it
		// once at bind group creation instead.
		mSrvStaging.Initialize(device.CpuSrvHeap, device.GpuSrvHeap, d3dDevice,
			.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 1024);

		return .Ok;
	}

	public Result<ICommandEncoder> CreateEncoder()
	{
		ID3D12GraphicsCommandList* cmdList = null;
		if (FAILED(mD3dDevice.CreateCommandList(0, mType, mAllocator, null,
			ID3D12GraphicsCommandList.IID, (void**)&cmdList)))
			return .Err;

		DxRenderPassContext rpeCtx = .();
		rpeCtx.CmdList = cmdList;
		rpeCtx.SrvStaging = mSrvStaging;
		rpeCtx.GpuSrvHeap = mDevice.GpuSrvHeap;
		rpeCtx.GpuSamplerHeap = mDevice.GpuSamplerHeap;
		rpeCtx.DrawSig = mDevice.DrawSignature;
		rpeCtx.DrawIndexedSig = mDevice.DrawIndexedSignature;
		rpeCtx.DispatchMeshSig = mDevice.DispatchMeshSignature;

		DxComputePassContext cpeCtx = .();
		cpeCtx.CmdList = cmdList;
		cpeCtx.SrvStaging = mSrvStaging;
		cpeCtx.GpuSrvHeap = mDevice.GpuSrvHeap;
		cpeCtx.GpuSamplerHeap = mDevice.GpuSamplerHeap;
		cpeCtx.DispatchSig = mDevice.DispatchSignature;

		let enc = new DxCommandEncoder(mDevice, cmdList, this, rpeCtx, cpeCtx);
		mUnfinishedEncoders++; // balanced by Finish closing the list
		return .Ok(enc);
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (let e = encoder as DxCommandEncoder)
			delete e;
		encoder = null;
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		// A bundle records into its OWN bundle type allocator and list, so the pool's primary
		// allocator is untouched and no open encoder is needed.
		ID3D12CommandAllocator* alloc = null;
		if (FAILED(mD3dDevice.CreateCommandAllocator(.D3D12_COMMAND_LIST_TYPE_BUNDLE,
			ID3D12CommandAllocator.IID, (void**)&alloc)))
			return null;

		ID3D12GraphicsCommandList* list = null;
		if (FAILED(mD3dDevice.CreateCommandList(0, .D3D12_COMMAND_LIST_TYPE_BUNDLE, alloc, null,
			ID3D12GraphicsCommandList.IID, (void**)&list)))
		{
			alloc.Release();
			return null;
		}

		// A bundle's descriptor heaps must MATCH the executing list's at ExecuteBundle time,
		// and both use the device's two shader visible heaps.
		ID3D12DescriptorHeap*[2] heaps = .(mDevice.GpuSrvHeap.Heap, mDevice.GpuSamplerHeap.Heap);
		list.SetDescriptorHeaps(2, &heaps[0]);

		DxRenderPassContext ctx = .();
		ctx.CmdList = list;
		ctx.SrvStaging = mSrvStaging;
		ctx.GpuSrvHeap = mDevice.GpuSrvHeap;
		ctx.GpuSamplerHeap = mDevice.GpuSamplerHeap;
		ctx.DrawSig = mDevice.DrawSignature;
		ctx.DrawIndexedSig = mDevice.DrawIndexedSignature;
		ctx.DispatchMeshSig = mDevice.DispatchMeshSignature;

		let enc = new DxRenderBundleEncoder(ctx, list, alloc);
		mTrackedBundleEncoders.Add(enc); // pool owned, freed on Reset behind the fence
		return enc;
	}

	public void Reset()
	{
		// The contract is that every encoder has Finished, closing its list, before Reset.
		// D3D12 cannot reset an allocator while one of its lists is recording, so say so here
		// rather than leave a cryptic driver error.
		if (mUnfinishedEncoders != 0)
		{
			GlobalLog(.Error,
				"DxCommandPool.Reset: {0} encoder(s) still recording, so the allocator reset will fail",
				mUnfinishedEncoders);
		}

		ReleaseCommandBuffers();
		// Bundles minted this cycle die at the frame boundary, which the fence guards.
		ReleaseBundleEncoders();
		// The GPU is done, so the staging bump pointers can go back to the start.
		mSrvStaging.Reset();
		mAllocator.Reset();
	}

	public void Cleanup()
	{
		ReleaseCommandBuffers();
		ReleaseBundleEncoders();
		mSrvStaging.Destroy();

		if (mAllocator != null)
		{
			mAllocator.Release();
			mAllocator = null;
		}
	}

	/// Called by an encoder's Finish, which hands its command buffer to the pool to own.
	public void TrackCommandBuffer(DxCommandBuffer cb) => mTrackedBuffers.Add(cb);

	/// Called by an encoder's Finish: its list is now closed.
	public void MarkEncoderFinished()
	{
		if (mUnfinishedEncoders > 0)
			mUnfinishedEncoders--;
	}

	private void ReleaseCommandBuffers()
	{
		for (let cb in mTrackedBuffers)
		{
			cb.Release();
			delete cb;
		}
		mTrackedBuffers.Clear();
	}

	private void ReleaseBundleEncoders()
	{
		for (let e in mTrackedBundleEncoders)
		{
			e.Cleanup();
			delete e;
		}
		mTrackedBundleEncoders.Clear();
	}
}
