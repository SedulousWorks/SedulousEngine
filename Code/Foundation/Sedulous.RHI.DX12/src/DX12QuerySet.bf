namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IQuerySet.
/// Wraps an ID3D12QueryHeap.
class DX12QuerySet : IQuerySet
{
	private ID3D12QueryHeap* mQueryHeap;
	private QueryType mType;
	private uint32 mCount;

	public QueryType Type => mType;
	public uint32 Count => mCount;

	public this() { }

	public Result<void> Init(DX12Device device, QuerySetDesc desc)
	{
		mType = desc.Type;
		mCount = desc.Count;

		D3D12_QUERY_HEAP_DESC heapDesc = .()
		{
			Type = ToQueryHeapType(desc.Type),
			Count = desc.Count,
			NodeMask = 0
		};

		HRESULT hr = device.Handle.CreateQueryHeap(&heapDesc, ID3D12QueryHeap.IID, (void**)&mQueryHeap);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12QuerySet: CreateQueryHeap failed (0x{hr:X})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(DX12Device device)
	{
		if (mQueryHeap != null)
		{
			mQueryHeap.Release();
			mQueryHeap = null;
		}
	}

	private static D3D12_QUERY_HEAP_TYPE ToQueryHeapType(QueryType type)
	{
		switch (type)
		{
		case .Timestamp:          return .D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
		case .Occlusion:          return .D3D12_QUERY_HEAP_TYPE_OCCLUSION;
		case .PipelineStatistics: return .D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS;
		}
	}

	// --- Internal ---
	public ID3D12QueryHeap* Handle => mQueryHeap;

	public static D3D12_QUERY_TYPE ToDx12QueryType(QueryType type)
	{
		switch (type)
		{
		case .Timestamp:          return .D3D12_QUERY_TYPE_TIMESTAMP;
		case .Occlusion:          return .D3D12_QUERY_TYPE_OCCLUSION;
		case .PipelineStatistics: return .D3D12_QUERY_TYPE_PIPELINE_STATISTICS;
		}
	}
}
