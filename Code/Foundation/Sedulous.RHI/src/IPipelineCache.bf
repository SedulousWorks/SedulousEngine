using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// Compiled pipeline state kept so the next creation is cheap.
///
/// The data is opaque and driver specific: it is written out and fed back to a later run,
/// and a driver that does not recognise it simply ignores it and compiles again.
interface IPipelineCache
{
	/// How many bytes GetData will write. Asked first, so a caller can size its buffer.
	uint32 GetDataSize();

	/// Writes the cache into `outData`. Fails when the buffer is too small for what
	/// GetDataSize reported.
	Result<void> GetData(Span<uint8> outData);
}
