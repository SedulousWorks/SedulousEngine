using Sedulous.Core;

namespace Sedulous.Engine.GUI;

/// How a canvas maps its document's pixels onto its view's.
enum GuiScalerMode : uint8
{
	/// One GUI pixel is one target pixel.
	case ConstantPixel = 0;
	/// Laid out at the reference resolution, scaled uniformly to fit, centred.
	case ReferenceResolution;
}
