namespace Sedulous.Model;

/// How a texture is sampled when minified, including how mip levels are chosen.
enum TextureMinFilter : uint32
{
	case Nearest;
	case Linear;
	case NearestMipmapNearest;
	case LinearMipmapNearest;
	case NearestMipmapLinear;
	case LinearMipmapLinear;
}
