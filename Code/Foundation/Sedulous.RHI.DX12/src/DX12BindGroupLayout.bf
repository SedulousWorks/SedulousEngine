namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// Tracks the offset of each binding entry within the descriptor heap block.
struct DX12BindingRangeInfo
{
	public uint32 Binding;
	public BindingType Type;
	public uint32 Count;
	/// Offset within the contiguous CBV/SRV/UAV or Sampler block.
	/// Unused for dynamic offset bindings (they use root descriptors).
	public uint32 HeapOffset;
	public bool IsSampler;
	/// If true, this binding uses a root descriptor instead of a heap entry.
	public bool HasDynamicOffset;
	/// Structure byte stride for storage buffers. When > 0, creates a
	/// StructuredBuffer SRV/UAV instead of a raw buffer.
	public uint32 StorageBufferStride;
}

/// DX12 implementation of IBindGroupLayout.
/// Stores descriptor range definitions for root signature creation
/// and heap offset info for bind group allocation.
class DX12BindGroupLayout : IBindGroupLayout
{
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;
	private List<DX12BindingRangeInfo> mRanges = new .() ~ delete _;
	private uint32 mCbvSrvUavCount;
	private uint32 mSamplerCount;
	private uint32 mDynamicOffsetCount;
	private bool mHasBindless;

	public this() { }

	public Result<void> Init(BindGroupLayoutDesc desc)
	{
		uint32 cbvSrvUavOffset = 0;
		uint32 samplerOffset = 0;

		for (let entry in desc.Entries)
		{
			mEntries.Add(entry);

			bool isSampler = DX12Conversions.IsSamplerBinding(entry.Type);
			uint32 count = entry.Count;
			if (count == uint32.MaxValue)
			{
				count = 1024 * 16; // Bindless — large but finite
				mHasBindless = true;
			}

			DX12BindingRangeInfo range = .()
			{
				Binding = entry.Binding,
				Type = entry.Type,
				Count = count,
				IsSampler = isSampler,
				HasDynamicOffset = entry.HasDynamicOffset,
				StorageBufferStride = entry.StorageBufferStride
			};

			// Dynamic offset bindings use root descriptors, not heap entries
			if (entry.HasDynamicOffset)
			{
				range.HeapOffset = 0; // Not used
				mDynamicOffsetCount++;
			}
			else if (isSampler)
			{
				range.HeapOffset = samplerOffset;
				samplerOffset += count;
			}
			else
			{
				range.HeapOffset = cbvSrvUavOffset;
				cbvSrvUavOffset += count;
			}

			mRanges.Add(range);
		}

		mCbvSrvUavCount = cbvSrvUavOffset;
		mSamplerCount = samplerOffset;
		return .Ok;
	}

	// --- Internal ---
	public List<BindGroupLayoutEntry> Entries => mEntries;
	public List<DX12BindingRangeInfo> Ranges => mRanges;
	public uint32 CbvSrvUavCount => mCbvSrvUavCount;
	public uint32 SamplerCount => mSamplerCount;
	public uint32 DynamicOffsetCount => mDynamicOffsetCount;
	public bool HasBindless => mHasBindless;
}
