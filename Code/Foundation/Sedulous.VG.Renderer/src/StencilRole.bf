namespace Sedulous.VG.Renderer;

/// Which part of stencil then cover a pipeline plays.
enum StencilRole : uint8
{
	/// An ordinary colour draw.
	case None;
	/// Colour masked; the front face increments and the back decrements, so the stencil
	/// counts the WINDING.
	case WriteNonZero;
	/// Colour masked; both faces invert, so the stencil holds the PARITY.
	case WriteEvenOdd;
	/// Draw where the stencil says inside, and zero or restore it behind.
	case Cover;
	/// Colour masked; turns accumulated winding into the clip mask bit.
	case ClipApply;
	/// Colour masked; erases the clip mask over its bounds.
	case ClipClear;
}
