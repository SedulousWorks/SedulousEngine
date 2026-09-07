namespace Sedulous.RHI;

/// Which shader stages a binding or a push constant range is visible to.
///
/// Naming only the stages that actually read a binding matters on DX12, where visibility
/// is part of the root signature and a narrower one costs less.
enum ShaderStage : uint32
{
	case None = 0;
	case Vertex = 1;
	case Fragment = 2;
	case Compute = 4;
	case Mesh = 8;
	case Task = 16;
	case RayGen = 32;
	case ClosestHit = 64;
	case Miss = 128;
	case AnyHit = 256;
	case Intersection = 512;
	case Callable = 1024;

	case AllGraphics = Vertex | Fragment;
	/// Every stage above, which is the eleven bits and not a full word.
	case All = 0x7FF;
}
