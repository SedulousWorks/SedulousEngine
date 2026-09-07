namespace Sedulous.Model;

/// How an animation channel interpolates between its keyframes.
enum AnimationInterpolation : uint32
{
	case Linear;
	/// Holds each keyframe's value until the next one, with no blending.
	case Step;
	case CubicSpline;
}
