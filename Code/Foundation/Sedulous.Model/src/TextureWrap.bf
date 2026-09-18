using Sedulous.Core;

namespace Sedulous.Model;

/// What a sampler does outside the zero to one range.
[Scriptable(.AllPublic)]
enum TextureWrap : uint32
{
	case Repeat;
	case ClampToEdge;
	case MirroredRepeat;
}
