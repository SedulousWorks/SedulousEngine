namespace Sedulous.RHI;

/// How a resource is being used right now, which is what a barrier transitions between.
///
/// A flag set rather than a single value because a resource can legitimately be in several
/// read states at once, and a barrier into a combined read state is cheaper than several
/// separate ones. WRITE states must stand alone: two writers, or a writer beside a reader,
/// is the race a barrier exists to prevent.
enum ResourceState : uint32
{
	case Undefined = 0;
	case VertexBuffer = 1;
	case IndexBuffer = 2;
	case UniformBuffer = 4;
	case ShaderRead = 8;
	case ShaderWrite = 16;
	case RenderTarget = 32;
	case DepthStencilWrite = 64;
	case DepthStencilRead = 128;
	case IndirectArgument = 256;
	case CopySrc = 512;
	case CopyDst = 1024;
	case Present = 2048;
	case InputAttachment = 4096;
	/// Every use at once. Correct but pessimistic: it forces the widest barrier there is.
	case General = 8192;
	case AccelStructRead = 16384;
	case AccelStructWrite = 32768;
}
