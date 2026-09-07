namespace Sedulous.Model;

/// Which property of a bone an animation channel drives.
enum AnimationPath : uint32
{
	case Translation;
	case Rotation;
	case Scale;
	/// Morph target weights.
	case Weights;
}
