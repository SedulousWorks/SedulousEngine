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

	/// Makes a WINDOW of a mapped CpuToGpu buffer visible to the GPU.
	///
	/// A real coherent mapping needs nothing, which is this default. A backend that EMULATES
	/// mapping with a CPU shadow, WebGPU, uploads exactly that range instead of comparing and
	/// re-sending the whole shadow on Unmap.
	///
	/// The contract is that a caller using this flushes EVERY range it wrote during the
	/// mapping, and Unmap then only closes the mapping. A writer touching a small window of a
	/// large buffer, the per frame rings, wants this.
	void FlushRange(uint64 offset, uint64 size) {}
}
