namespace Sedulous.Drawing;

/// Style for joining line segments
public enum LineJoin
{
	/// Sharp corner (may be limited by miter limit)
	Miter,
	/// Rounded corner
	Round,
	/// Beveled corner (flat cut)
	Bevel
}
