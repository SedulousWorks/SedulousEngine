using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Owns ONE encoder and hands it back to every caller.
///
/// Which mirrors the real contract in the way that matters: an encoder belongs to its pool,
/// not to whoever asked for it, so DestroyEncoder releases the caller's handle without
/// freeing anything.
class NullCommandPool : ICommandPool
{
	private NullCommandEncoder mEncoder = new .() ~ delete _;

	public Result<ICommandEncoder> CreateEncoder() => .Ok(mEncoder);

	/// Drops the caller's handle. The pool keeps the encoder alive until the pool itself
	/// goes, which is what the real backends do.
	public void DestroyEncoder(ref ICommandEncoder encoder) => encoder = null;

	public void Reset() {}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
		=> mEncoder.BundleEncoder;
}
