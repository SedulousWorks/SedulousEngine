namespace Sedulous.VG;

/// Clipping mode for draw commands
public enum VGClipMode
{
	/// No clipping
	None,
	/// Scissor rectangle clipping
	Scissor,
	/// Stencil-based path clipping
	Stencil
}
