namespace Sedulous.Drawing;

/// Pixel format for CPU-side texture data.
/// This is a simplified format enum for the Drawing layer.
/// The renderer maps these to GPU-specific formats.
public enum PixelFormat
{
	/// Single channel, 8-bit unsigned normalized (grayscale/alpha)
	R8,

	/// Four channels, 8-bit unsigned normalized (red, green, blue, alpha)
	RGBA8,

	/// Four channels, 8-bit unsigned normalized, BGR order (blue, green, red, alpha)
	BGRA8
}
