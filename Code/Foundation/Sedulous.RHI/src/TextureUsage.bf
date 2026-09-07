namespace Sedulous.RHI;

/// What a texture may be used for, declared at creation for the same reason as BufferUsage.
enum TextureUsage : uint32
{
	case None = 0;
	case CopySrc = 1;
	case CopyDst = 2;
	case Sampled = 4;
	case Storage = 8;
	case RenderTarget = 16;
	case DepthStencil = 32;
	/// Read within a render pass at the same pixel, which is what a tiler can keep in tile
	/// memory instead of writing out and reading back.
	case InputAttachment = 64;
}
