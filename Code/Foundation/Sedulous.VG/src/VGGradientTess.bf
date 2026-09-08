namespace Sedulous.VG;

/// What a gradient fill writes per vertex, paired with the draw mode that reads it.
///
/// A linear gradient's parameter is AFFINE, so interpolating it across a triangle is exact.
/// Radial and conic are not, so those emit per pixel coordinates and let a shader compute
/// the parameter, rather than approximating a curve with a Gouraud interpolation that
/// visibly bands.
enum VGGradientTess
{
	/// The colour itself, per vertex, interpolated across the triangle. Kept for fills that
	/// have no dedicated shader path.
	case Gouraud;
	/// A lookup table coordinate from the affine linear parameter; the ramp is sampled per
	/// pixel.
	case LinearLut;
	/// The gradient coordinate; the shader derives the radial parameter per pixel.
	case RadialCoord;
	/// The gradient coordinate; the shader derives the conic parameter per pixel.
	case ConicCoord;
}
