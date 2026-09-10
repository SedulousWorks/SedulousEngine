namespace Sedulous.UI;

/// How a WRAPPING container packs its lines on the cross axis.
///
/// No effect on a single line, which by definition is the container: that is CSS's rule and
/// this follows it.
enum AlignContent
{
	case Start;
	case End;
	case Center;
	case SpaceBetween;
	case SpaceAround;
	/// The lines share out the free cross space, which is CSS's `normal`.
	case Stretch;
}
