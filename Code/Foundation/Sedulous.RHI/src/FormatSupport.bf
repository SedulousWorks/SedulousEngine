namespace Sedulous.RHI;

/// What a device can do with one texture format.
///
/// Asked through GetFormatSupport. This is how a caller finds out whether a format works
/// BEFORE creating something with it, which is why creation does not return a "not
/// supported" reason: the question has its own answer.
enum FormatSupport : uint32
{
	case Unsupported = 0;
	case Texture = 1;
	case StorageTexture = 2;
	case ColorAttachment = 4;
	case DepthStencil = 8;
	case Buffer = 16;
	case StorageBuffer = 32;
	case VertexBuffer = 64;
	/// Usable as a blendable colour target. Separate from ColorAttachment because integer
	/// formats can be attachments but cannot blend.
	case BlendableColor = 128;
	/// Filterable by a Linear sampler. Separate for the same reason: a format can be
	/// sampled and still only support Nearest.
	case LinearFilter = 256;
}
