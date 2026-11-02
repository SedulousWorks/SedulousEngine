namespace Sedulous.Texture;

/// What sampling outside zero to one does.
///
/// Stored in cooked textures: appended, never reordered.
[System.Reflect(.StaticFields)] // its cases by name: an import setting is offered and set by them
enum TextureWrap : uint8
{
	case Repeat;
	case ClampToEdge;
	case ClampToBorder;
	case MirroredRepeat;
}
