using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

namespace Sedulous.Drawing;

/// Describes how to draw a texture into a rectangular region.
/// Supports both simple stretched images and 9-slice (9-patch) scaling.
public struct ImageBrush
{
	/// The image data to draw. Non-owning reference.
	public IImageData Texture;

	/// 9-slice border insets. If valid (non-zero), uses 9-slice rendering;
	/// otherwise the image is stretched to fill the destination rectangle.
	public NineSlice Slices;

	/// Color modulation applied when drawing. White = no tint.
	public Color Tint;

	/// Creates an ImageBrush with 9-slice borders.
	public this(IImageData texture, NineSlice slices, Color tint = .White)
	{
		Texture = texture;
		Slices = slices;
		Tint = tint;
	}

	/// Creates an ImageBrush that stretches the full image (no 9-slice).
	public this(IImageData texture, Color tint = .White)
	{
		Texture = texture;
		Slices = default;
		Tint = tint;
	}

	/// Whether this brush has a valid texture to draw.
	public bool IsValid => Texture != null;
}
