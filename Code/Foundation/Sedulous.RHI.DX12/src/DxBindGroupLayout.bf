using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RHI.DX12;

/// The shape of one bind group, laid out as descriptor table offsets.
///
/// This is where the RHI's flat list of bindings becomes a D3D12 TABLE LAYOUT. Every binding
/// gets an offset within its group, counted separately for CBV/SRV/UAV and for samplers,
/// because those live in different heaps and are bound as different tables.
///
/// A binding with a dynamic offset takes NO table slot: it is bound as a root descriptor
/// instead, which is what makes the offset changeable without rewriting the table.
class DxBindGroupLayout : IBindGroupLayout
{
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;
	private List<DxBindingRangeInfo> mRanges = new .() ~ delete _;
	private uint32 mCbvSrvUavCount = 0;
	private uint32 mSamplerCount = 0;
	private uint32 mDynamicOffsetCount = 0;
	private bool mHasBindless = false;

	public Span<BindGroupLayoutEntry> Entries => mEntries;
	public Span<DxBindingRangeInfo> Ranges => mRanges;
	public uint32 CbvSrvUavCount => mCbvSrvUavCount;
	public uint32 SamplerCount => mSamplerCount;
	public uint32 DynamicOffsetCount => mDynamicOffsetCount;
	public bool HasBindless => mHasBindless;

	public Result<void> Initialize(BindGroupLayoutDesc d)
	{
		uint32 cbvSrvUavOff = 0;
		uint32 sampOff = 0;

		for (let e in d.Entries)
		{
			mEntries.Add(e);

			let sampler = DxConversions.IsSamplerBinding(e.Type);

			// An unbounded count is the bindless marker. D3D12 wants a real number for the
			// table, so it gets a large fixed one and the group is flagged.
			var cnt = e.Count;
			if (cnt == uint32.MaxValue)
			{
				cnt = 1024 * 16;
				mHasBindless = true;
			}

			DxBindingRangeInfo r = .();
			r.Binding = e.Binding;
			r.Type = e.Type;
			r.Count = cnt;
			r.IsSampler = sampler;
			r.HasDynamicOffset = e.HasDynamicOffset;
			r.StorageBufferStride = e.StorageBufferStride;

			if (e.HasDynamicOffset)
			{
				// Bound as a root descriptor, so it occupies no table slot and advances
				// neither offset.
				r.HeapOffset = 0;
				mDynamicOffsetCount++;
			}
			else if (sampler)
			{
				r.HeapOffset = sampOff;
				sampOff += cnt;
			}
			else
			{
				r.HeapOffset = cbvSrvUavOff;
				cbvSrvUavOff += cnt;
			}

			mRanges.Add(r);
		}

		mCbvSrvUavCount = cbvSrvUavOff;
		mSamplerCount = sampOff;
		return .Ok;
	}
}
