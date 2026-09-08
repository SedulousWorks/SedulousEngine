namespace Sedulous.Texture;

/// The logical shape of a texture ASSET, which is not the same as its GPU storage: a
/// cubemap is stored as a six layer 2D array and only viewed as a cube. This says what the
/// author meant, so a tool can show the right editor and a factory can build the right
/// view.
///
/// Values are stored in cooked textures, so they are appended and never reordered.
enum TextureShape : uint8
{
	case Texture2D;
	/// Layers of the same size.
	case Texture2DArray;
	/// A volume.
	case Texture3D;
	/// Six square faces, in +X, -X, +Y, -Y, +Z, -Z order.
	case Cubemap;
	case CubemapArray;
}
