namespace Sedulous.UI.Toolkit;

/// How a Hermite key's two tangent handles relate to one another.
enum TangentMode
{
	/// Dragging one handle moves the other to match, so the curve passes through smoothly.
	/// The default, and what a key is nearly always wanted to be.
	Mirrored,
	/// The handles move independently, for a corner or an asymmetric ease. Some tools call
	/// this "broken".
	Free,
	/// Both tangents pinned at zero, so the curve flattens through the key. The handles are
	/// still drawn but ignore dragging, which is what says the key is deliberately flat rather
	/// than merely level at this moment.
	Flat
}
