namespace Sedulous.VG;

/// The values a target's blending works on.
enum VGBlendSpace
{
	/// Linear light: authored colours are decoded and the target encodes on write, so half
	/// black over white is 73% grey. Right for panels that sit in a lit scene.
	case Linear;
	/// sRGB-encoded values, as browsers and design tools blend: half black over white is 50%
	/// grey, and gradients and fades go as authored. The renderer draws into a UNORM view of the
	/// target (its sRGB twin's), and colours stay as entered.
	case Encoded;
}
