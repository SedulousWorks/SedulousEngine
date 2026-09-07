namespace Sedulous.Model;

/// How a material's alpha is treated.
enum AlphaMode : uint32
{
	case Opaque;
	/// Cut out at a threshold, with no blending.
	case Mask;
	case Blend;
}
