namespace Sedulous.Drawing;

/// Clipping mode for draw commands
public enum ClipMode
{
	/// No clipping
	None,
	/// Scissor rectangle clipping (axis-aligned)
	Scissor,
	/// Stencil-based clipping (arbitrary shapes)
	Stencil
}
