using System;

namespace Sedulous.Core;

/// How content is scaled to fit its region. Its cases are reflected: a settings editor offers
/// them by name.
[Reflect(.StaticFields)]
enum FitMode
{
	/// Fill the region, ignoring aspect. May distort.
	case Stretch;
	/// Preserve aspect and fit inside, leaving bars on the short axis.
	case Letterbox;
	/// Preserve aspect and fill the region, cropping the overflow by slicing the source.
	case Crop;
	/// Letterbox with the scale floored to a whole number, for pixel art.
	case IntegerScale;
}
