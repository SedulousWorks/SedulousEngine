namespace Sedulous.Texture;

/// What sampling outside zero to one does.
///
/// Stored in cooked textures: appended, never reordered.
enum TextureWrap : uint8
{
	case Repeat;
	case ClampToEdge;
	case ClampToBorder;
	case MirroredRepeat;
}
