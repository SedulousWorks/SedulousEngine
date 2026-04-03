namespace Sedulous.RHI;

using System;

/// A GPU buffer resource.
/// Destroyed via IDevice.DestroyBuffer().
interface IBuffer
{
	/// The descriptor this buffer was created with.
	BufferDesc Desc { get; }

	/// Size of the buffer in bytes.
	uint64 Size { get; }

	/// Usage flags.
	BufferUsage Usage { get; }

	/// Maps the buffer for CPU access.
	/// Only valid for CpuToGpu or GpuToCpu memory locations.
	/// Returns null if mapping fails or the buffer is not mappable.
	void* Map();

	/// Unmaps a previously mapped buffer.
	void Unmap();
}
