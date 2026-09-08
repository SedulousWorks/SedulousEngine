namespace Sedulous.VG;

/// How a draw command is clipped.
enum VGClipMode
{
	case None;
	/// A rectangle, which the hardware applies for free.
	case Scissor;
	/// An arbitrary path, accumulated into the stencil.
	case Stencil;
}
