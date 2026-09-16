using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A pipeline cache that holds nothing.
///
/// WebGPU has no cache object, the browser or driver caching internally, and the RHI
/// treats caches as best effort. So creating one SUCCEEDS with an empty cache rather
/// than failing: pipelines ignore it and there is never any data to serve.
sealed class WebGpuPipelineCache : IPipelineCache
{
	public uint32 GetDataSize()
	{
		return 0;
	}

	public Result<void> GetData(Span<uint8> outData)
	{
		return .Ok;
	}
}
