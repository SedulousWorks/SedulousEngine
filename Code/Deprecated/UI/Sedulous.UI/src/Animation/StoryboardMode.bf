namespace Sedulous.UI;

/// How a storyboard plays the animations it holds.
enum StoryboardMode
{
	/// One after another: each starts when the one before it finishes.
	case Sequential;
	/// All at once.
	case Parallel;
}
