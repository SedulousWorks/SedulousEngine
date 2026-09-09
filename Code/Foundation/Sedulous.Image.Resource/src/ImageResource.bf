using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Image;

namespace Sedulous.Image.Resource;

/// A cooked CPU image: its shape, and the pixels themselves.
///
/// The RECORD AND THE PRODUCT are one type here, unlike a texture, where the record
/// describes something that lives on the device and the product is that device object. A CPU
/// image is genuinely just its header and its bytes, and splitting them would mean two types
/// that always travel together.
///
/// The header is what serializes; the pixels ride the instance's own "pixels" stream. They
/// are private for that reason: a database browsing a thousand images wants a thousand
/// headers, not a thousand images.
[Serializable]
class ImageResource
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public PixelFormat Format = .RGBA8;
	public ImageColorSpace ColorSpace = .Srgb;

	private List<uint8> mPixels = new .() ~ delete _;

	public Span<uint8> Pixels => mPixels;

	/// TAKES the bytes, replacing whatever was there.
	public void SetPixels(Span<uint8> pixels)
	{
		mPixels.Clear();
		mPixels.AddRange(pixels);
	}

	/// A NON OWNING view for anything that consumes image data. It borrows these pixels, so
	/// the resource has to outlive it.
	///
	/// THE CALLER OWNS what comes back.
	public ImageDataRef View() =>
		new ImageDataRef(Width, Height, Format, mPixels.Ptr, mPixels.Count, ColorSpace);
}
