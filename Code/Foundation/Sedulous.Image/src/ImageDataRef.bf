using System;

namespace Sedulous.Image;

/// Points at pixel data someone else owns.
///
/// THE CALLER guarantees the data outlives this. Also used with no data at all, to
/// describe a texture whose pixels live only on the GPU.
class ImageDataRef : ImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat = .RGBA8;
	private ImageColorSpace mColorSpace = .Srgb;
	private uint8* mPixels;
	private int mLength;

	public this() {}

	/// No pixel data, for a GPU managed texture.
	public this(uint32 width, uint32 height, PixelFormat format = .RGBA8,
		ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width; mHeight = height; mFormat = format; mColorSpace = colorSpace;
	}

	public this(uint32 width, uint32 height, PixelFormat format, uint8* pixels, int length,
		ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width; mHeight = height; mFormat = format; mColorSpace = colorSpace;
		mPixels = pixels; mLength = length;
	}

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override PixelFormat Format => mFormat;
	public override ImageColorSpace ColorSpace => mColorSpace;
	public override Span<uint8> PixelData => (mPixels != null) ? .(mPixels, mLength) : .();
}
