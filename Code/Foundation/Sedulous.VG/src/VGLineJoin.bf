namespace Sedulous.VG;

/// Line join style for stroke corners
public enum VGLineJoin
{
	/// Sharp corner (clamped by miter limit)
	Miter,
	/// Rounded corner
	Round,
	/// Beveled (flat cut) corner
	Bevel
}
