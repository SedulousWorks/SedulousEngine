namespace Sedulous.Model;

/// The pixel format of a decoded texture.
///
/// Distinct from the image module's PixelFormat: this describes what an importer found in
/// a model file, which is a smaller set and is recorded before anything is decoded.
enum TexturePixelFormat : uint32
{
	case Unknown;
	case R8;
	case RG8;
	case RGB8;
	case RGBA8;
	case BGR8;
	case BGRA8;
}
