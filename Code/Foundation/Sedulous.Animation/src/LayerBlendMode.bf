namespace Sedulous.Animation;

enum LayerBlendMode
{
	/// Replaces what is underneath, weighted.
	case Override;
	/// ADDS its difference from the bind pose, so a lean or a breath rides on top of
	/// whatever is playing rather than replacing it.
	case Additive;
}
