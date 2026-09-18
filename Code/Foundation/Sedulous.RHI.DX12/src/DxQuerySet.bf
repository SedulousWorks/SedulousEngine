#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One query heap.
///
/// D3D12 splits what the RHI calls a query type across TWO enumerations: the heap is created
/// for a family, and each Begin or End names the query within it. Both mappings live here
/// because they have to agree.
class DxQuerySet : IQuerySet
{
	private QueryType mType = .Timestamp;
	private uint32 mCount = 0;
	private ID3D12QueryHeap* mHeap = null; // owned, released in Cleanup

	public QueryType Type => mType;
	public uint32 Count => mCount;
	public ID3D12QueryHeap* Handle => mHeap;

	public Result<void> Initialize(ID3D12Device* device, QuerySetDesc d)
	{
		mType = d.Type;
		mCount = d.Count;

		D3D12_QUERY_HEAP_DESC hd = .();
		hd.Type = ToQueryHeapType(d.Type);
		hd.Count = d.Count;

		let hr = device.CreateQueryHeap(&hd, ID3D12QueryHeap.IID, (void**)&mHeap);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxQuerySet: CreateQueryHeap failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup()
	{
		if (mHeap != null)
		{
			mHeap.Release();
			mHeap = null;
		}
	}

	/// The FAMILY the heap is created for.
	public static D3D12_QUERY_HEAP_TYPE ToQueryHeapType(QueryType t)
	{
		switch (t)
		{
		case .Timestamp:
			return .D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
		case .Occlusion:
			return .D3D12_QUERY_HEAP_TYPE_OCCLUSION;
		case .PipelineStatistics:
			return .D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS;
		}
	}

	/// The query itself, named at Begin and End.
	public static D3D12_QUERY_TYPE ToDxQueryType(QueryType t)
	{
		switch (t)
		{
		case .Timestamp:
			return .D3D12_QUERY_TYPE_TIMESTAMP;
		case .Occlusion:
			return .D3D12_QUERY_TYPE_OCCLUSION;
		case .PipelineStatistics:
			return .D3D12_QUERY_TYPE_PIPELINE_STATISTICS;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
