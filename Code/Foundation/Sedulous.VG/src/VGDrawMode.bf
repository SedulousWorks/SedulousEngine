namespace Sedulous.VG;

/// How a command's texels are shaded. The renderer switches pipelines on this.
enum VGDrawMode
{
	/// Sample the texture, or the vertex colour, directly.
	case Default;
	/// Decode a multi channel distance field atlas, which is what keeps text crisp at any
	/// scale rather than blurring with the glyph's baked size.
	case DistanceField;
	/// A radial gradient computed PER PIXEL: the parameter is the length of the texture
	/// coordinate, and the ramp is sampled from a lookup table.
	case GradientRadial;
	/// A conic gradient computed per pixel: the parameter is the angle.
	case GradientConic;
}
