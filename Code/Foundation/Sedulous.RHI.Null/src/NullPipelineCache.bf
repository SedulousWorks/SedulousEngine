using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A cache that stores nothing and reports nothing, which is a legitimate cache: a driver
/// that does not recognise the blob is expected to ignore it.
class NullPipelineCache : IPipelineCache
{
	public uint32 GetDataSize() => 0;

	/// Succeeds writing nothing, matching the zero size reported above.
	public Result<void> GetData(Span<uint8> outData) => .Ok;
}
