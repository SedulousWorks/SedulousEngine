namespace Sedulous.VG;

/// The gradient family a fill belongs to.
///
/// The context maps this to a draw mode and an emit mode when per pixel gradients are on.
/// Solid and linear stay on the default pipeline, because neither needs one: a solid has
/// nothing to interpolate and a linear parameter is affine.
enum VGGradientKind
{
	case Solid;
	case Linear;
	case Radial;
	case Conic;
}
