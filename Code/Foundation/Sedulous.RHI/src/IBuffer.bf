namespace Sedulous.RHI;

/// A GPU buffer: vertices, indices, uniforms, storage, whatever its usage declared.
interface IBuffer
{
	/// What it was created with, so a caller need not keep the descriptor alongside the
	/// handle.
	BufferDesc Desc { get; }

	uint64 Size => Desc.Size;
	BufferUsage Usage => Desc.Usage;

	/// Maps for CPU access, or returns NULL when the buffer is not mappable.
	///
	/// Null rather than a failure result because mappability is a property of the memory
	/// location the caller already chose: asking a GpuOnly buffer to map is a question with
	/// a known answer, not an error to report.
	void* Map();

	void Unmap();
}
