namespace Sedulous.Drawing;

/// Blend modes for compositing drawn elements
public enum BlendMode
{
	/// Standard alpha blending: srcColor * srcAlpha + dstColor * (1 - srcAlpha)
	Normal,
	/// Additive blending: srcColor + dstColor
	Additive,
	/// Multiply blending: srcColor * dstColor
	Multiply,
	/// Screen blending: 1 - (1 - srcColor) * (1 - dstColor)
	Screen
}
