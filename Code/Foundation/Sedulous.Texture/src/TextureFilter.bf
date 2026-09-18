using Sedulous.Core;

namespace Sedulous.Texture;

/// How an asset asks to be sampled between texels, and between mips.
///
/// Stored in cooked textures: appended, never reordered.
[Scriptable(.AllPublic)]
enum TextureFilter : uint8
{
	case Nearest;
	case Linear;
	case MipmapNearest;
	case MipmapLinear;
}
