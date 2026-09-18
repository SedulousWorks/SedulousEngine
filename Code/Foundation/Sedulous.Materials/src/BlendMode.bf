using Sedulous.Core;

namespace Sedulous.Materials;

/// A blend PRESET, resolved to a concrete blend state when the pipeline is built.
///
/// A preset rather than the state itself, because the state is a dozen fields that almost
/// always take one of these handful of shapes, and naming the shape is what an artist
/// actually chooses.
[Scriptable(.AllPublic)]
enum BlendMode : uint8
{
	case Opaque;
	/// Opaque, with the shader discarding below a threshold.
	case Masked;
	case AlphaBlend;
	case Additive;
	case Multiply;
	case PremultipliedAlpha;
}
