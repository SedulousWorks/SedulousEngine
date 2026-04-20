namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of ICommandPool.
/// Wraps an ID3D12CommandAllocator.
class DX12CommandPool : ICommandPool
{
	private ID3D12CommandAllocator* mAllocator;
	private DX12Device mDevice;
	private D3D12_COMMAND_LIST_TYPE mType;
	private List<DX12CommandBuffer> mCommandBuffers = new .() ~ delete _;

	// Descriptor staging owned by the pool - lifetime matches GPU execution.
	// Reset after fence wait (pool.Reset), safe from use-after-free.
	private DX12DescriptorStaging mSrvStaging;
	private DX12DescriptorStaging mSamplerStaging;

	public this() { }

	public Result<void> Init(DX12Device device, QueueType queueType)
	{
		mDevice = device;
		mType = DX12Conversions.ToCommandListType(queueType);

		HRESULT hr = device.Handle.CreateCommandAllocator(mType,
			ID3D12CommandAllocator.IID, (void**)&mAllocator);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12CommandPool: CreateCommandAllocator failed (0x{hr:X})");
			return .Err;
		}

		// Create descriptor staging (shared by all encoders from this pool)
		mSrvStaging = new DX12DescriptorStaging(device.CpuSrvHeap, device.GpuSrvHeap,
			device.Handle, .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, 1024);
		mSamplerStaging = new DX12DescriptorStaging(device.CpuSamplerHeap, device.GpuSamplerHeap,
			device.Handle, .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 64);

		return .Ok;
	}

	public Result<ICommandEncoder> CreateEncoder()
	{
		ID3D12GraphicsCommandList* cmdList = null;
		HRESULT hr = mDevice.Handle.CreateCommandList(0, mType, mAllocator, null,
			ID3D12GraphicsCommandList.IID, (void**)&cmdList);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12CommandPool: CreateCommandList failed (0x{hr:X})");
			return .Err;
		}

		let encoder = new DX12CommandEncoder(mDevice, cmdList, this);
		return .Ok(encoder);
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (encoder != null)
		{
			delete encoder;
			encoder = null;
		}
	}

	public void Reset()
	{
		ReleaseCommandBuffers();
		// Reset descriptor staging - GPU is done (fence waited), so staging
		// bump pointers can safely return to start.
		if (mSrvStaging != null) mSrvStaging.Reset();
		if (mSamplerStaging != null) mSamplerStaging.Reset();
		mAllocator.Reset();
	}

	public void Cleanup(DX12Device device)
	{
		ReleaseCommandBuffers();
		if (mSrvStaging != null) { mSrvStaging.Destroy(); delete mSrvStaging; mSrvStaging = null; }
		if (mSamplerStaging != null) { mSamplerStaging.Destroy(); delete mSamplerStaging; mSamplerStaging = null; }
		if (mAllocator != null)
		{
			mAllocator.Release();
			mAllocator = null;
		}
	}

	private void ReleaseCommandBuffers()
	{
		for (let cb in mCommandBuffers)
		{
			cb.ReleaseCommandList();
			delete cb;
		}
		mCommandBuffers.Clear();
	}

	// --- Internal ---
	public ID3D12CommandAllocator* Handle => mAllocator;
	public DX12DescriptorStaging SrvStaging => mSrvStaging;
	public DX12DescriptorStaging SamplerStaging => mSamplerStaging;

	/// Called by DX12CommandEncoder.Finish() to register a command buffer with this pool.
	public void TrackCommandBuffer(DX12CommandBuffer cb)
	{
		mCommandBuffers.Add(cb);
	}
}
