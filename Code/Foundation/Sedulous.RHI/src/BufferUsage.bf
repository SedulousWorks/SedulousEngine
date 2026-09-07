namespace Sedulous.RHI;

/// What a buffer may be used for. Every use must be declared at creation: a backend bakes
/// these into the allocation, and a use that was not asked for is not available later.
enum BufferUsage : uint32
{
	case None = 0;
	case CopySrc = 1;
	case CopyDst = 2;
	case Vertex = 4;
	case Index = 8;
	case Uniform = 16;
	/// Read write storage, an SSBO or a UAV. NOT compatible with CpuToGpu memory on DX12,
	/// where an upload heap cannot allow unordered access: use StorageRead for a buffer
	/// that is only read by shaders and still needs to be mapped.
	case Storage = 32;
	case StorageRead = 64;
	case Indirect = 128;
	case AccelStructInput = 256;
	case ShaderBindingTable = 512;
	case AccelStructScratch = 1024;
}
