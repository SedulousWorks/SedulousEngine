using System;
using System.Collections;

namespace Sedulous.Image;

/// Owns a CPU side pixel buffer, and nothing else.
///
/// Distinct from Image, which owns pixels too but carries the whole manipulation and
/// procedural surface with it. This is what a producer hands back when it has pixels and
/// no opinion about them: a baked font atlas, a decoded texture, a packed sheet. A
/// consumer that only uploads or samples takes ImageData and never knows which it got.
class OwnedImageData : ImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat = .RGBA8;
	private ImageColorSpace mColorSpace = .Srgb;
	private List<uint8> mPixels = new .() ~ delete _;

	public this() {}

	/// Takes a COPY of the source.
	public this(uint32 width, uint32 height, PixelFormat format, Span<uint8> source,
		ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width; mHeight = height; mFormat = format; mColorSpace = colorSpace;
		mPixels.Resize(source.Length);
		if (source.Length > 0)
			Internal.MemCpy(mPixels.Ptr, source.Ptr, source.Length);
	}

	/// Takes the list ITSELF, which the caller must not touch afterwards.
	///
	/// A move, in effect: a producer that already built the buffer hands it over rather
	/// than paying to copy a whole image it is about to drop.
	public this(uint32 width, uint32 height, PixelFormat format, List<uint8> pixels,
		ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width; mHeight = height; mFormat = format; mColorSpace = colorSpace;
		delete mPixels;
		mPixels = pixels;
	}

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override PixelFormat Format => mFormat;
	public override ImageColorSpace ColorSpace => mColorSpace;
	public override Span<uint8> PixelData => .(mPixels.Ptr, mPixels.Count);

	public void SetColorSpace(ImageColorSpace colorSpace) => mColorSpace = colorSpace;

	/// What the dimensions and format say the buffer should be, which is NOT necessarily
	/// what it holds: a buffer handed in short stays short.
	public uint32 DataSize => mWidth * mHeight * PixelFormats.BytesPerPixel(mFormat);
}
