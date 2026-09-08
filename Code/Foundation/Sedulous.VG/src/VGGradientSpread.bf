namespace Sedulous.VG;

/// What a gradient does with a parameter outside zero to one.
///
/// Applied as the ramp sampler's address mode: pad clamps, repeat wraps, reflect mirrors.
/// A conic gradient wraps inherently and ignores this.
enum VGGradientSpread : uint8
{
	case Pad;
	case Repeat;
	case Reflect;
}
