namespace Sedulous.RHI;

using System;

/// Manages command buffer memory. One pool per thread per queue type.
/// Destroyed via IDevice.DestroyCommandPool().
interface ICommandPool
{
	/// Creates a command encoder for recording commands.
	Result<ICommandEncoder> CreateEncoder();

	/// Destroys a command encoder created by this pool.
	/// Call after Finish() and submission when the encoder is no longer needed.
	void DestroyEncoder(ref ICommandEncoder encoder);

	/// Resets the pool, releasing all command buffers allocated from it.
	/// Only safe to call when all submitted command buffers from this pool have completed.
	void Reset();
}
