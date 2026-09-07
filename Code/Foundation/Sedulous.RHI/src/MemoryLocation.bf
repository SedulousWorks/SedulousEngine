namespace Sedulous.RHI;

/// Where an allocation lives, and therefore who can touch it cheaply.
enum MemoryLocation : uint32
{
	/// Device local. Fastest for the GPU and not mappable.
	GpuOnly,
	/// Written by the CPU and read by the GPU: staging and per frame uniforms.
	CpuToGpu,
	/// Written by the GPU and read back by the CPU.
	GpuToCpu,
	/// Let the backend choose from the usage flags.
	Auto
}
