using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// The command memory for one queue type. ONE POOL PER THREAD per queue type: a pool is
/// not safe to record from concurrently, and that is the whole reason it is a separate
/// object rather than living on the device.
interface ICommandPool
{
	/// A new encoder to record into.
	///
	/// Every encoder MUST be finished before this pool is reset: DX12 cannot reset a
	/// command allocator while one of its lists is still recording.
	Result<ICommandEncoder> CreateEncoder();

	void DestroyEncoder(ref ICommandEncoder encoder);

	/// Recycles every buffer allocated here, and frees the bundles produced this cycle.
	///
	/// Only safe once the GPU has finished the pool's last submission, which the caller
	/// establishes with a fence. Nothing here checks it.
	void Reset();

	/// Begins a bundle straight from the pool, with no open encoder needed, so a per thread
	/// bundle worker needs only a pool. The encoder and the bundle it finishes are OWNED BY
	/// THE POOL and live until its next reset. Null when the backend has no bundles.
	IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc);
}
