using Sedulous.Core;

namespace Sedulous.Engine.UI;

/// How a canvas maps its own pixels onto the target's.
[Scriptable(.AllPublic)]
enum CanvasScalerMode : uint8
{
	/// One UI pixel is one target pixel.
	case ConstantPixel = 0;
	/// Scaled uniformly so the reference resolution fits the target.
	case ReferenceResolution;
}
