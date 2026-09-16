using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A set of queries.
///
/// A timestamp set needs the TimestampQuery feature, which the device requests when its
/// adapter has it. Occlusion is core. Pipeline statistics has no WebGPU shape at all, so
/// asking for one fails honestly rather than returning something that never fills in.
class WebGpuQuerySet : IQuerySet
{
	private WGPUQuerySet mHandle;
	private QueryType mType;
	private uint32 mCount;

	public QueryType Type => mType;
	public uint32 Count => mCount;
	public WGPUQuerySet Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuQuerySetRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, QuerySetDesc desc)
	{
		mType = desc.Type;
		mCount = desc.Count;

		WGPUQuerySetDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.count = desc.Count;

		switch (desc.Type)
		{
		case .Timestamp: wgpu.type = .WGPUQueryType_Timestamp;
		case .Occlusion: wgpu.type = .WGPUQueryType_Occlusion;
		default: return .Err; // pipeline statistics
		}

		mHandle = wgpuDeviceCreateQuerySet(device, &wgpu);
		return (mHandle != null) ? .Ok : .Err;
	}
}
