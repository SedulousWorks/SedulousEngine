namespace Sedulous.VG;

/// How a stroke turns a corner.
enum VGLineJoin
{
	/// Sharp, clamped by the miter limit: a very shallow angle produces an arbitrarily
	/// long spike otherwise.
	case Miter;
	case Round;
	/// Cut flat across the corner.
	case Bevel;
}
