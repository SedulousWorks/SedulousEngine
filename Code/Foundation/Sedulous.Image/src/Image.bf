using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Image;

/// An image that owns its pixel buffer, with the manipulation and the procedural
/// factories.
///
/// The factories are here rather than in a tool because a placeholder is needed at runtime
/// too: a missing texture, a normal map an author has not made yet, a checkerboard to make
/// UV problems visible.
class Image : ImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat = .RGBA8;
	private ImageColorSpace mColorSpace = .Srgb;
	private List<uint8> mPixels = new .() ~ delete _;

	public this() {}

	public this(uint32 width, uint32 height, PixelFormat format)
	{
		mWidth = width; mHeight = height; mFormat = format;
		mPixels.Resize(DataSize);
		Clear();
	}

	/// Takes a COPY of the source. Anything shorter than the image needs leaves the
	/// remainder cleared rather than holding whatever was in the buffer.
	public this(uint32 width, uint32 height, PixelFormat format, Span<uint8> source)
	{
		mWidth = width; mHeight = height; mFormat = format;
		ReplaceData(width, height, format, source);
	}

	public override uint32 Width => mWidth;
	public override uint32 Height => mHeight;
	public override PixelFormat Format => mFormat;
	public override ImageColorSpace ColorSpace => mColorSpace;
	public override Span<uint8> PixelData => .(mPixels.Ptr, mPixels.Count);

	public void SetColorSpace(ImageColorSpace colorSpace) => mColorSpace = colorSpace;

	public uint32 PixelCount => mWidth * mHeight;
	public int DataSize => (int)PixelCount * (int)PixelFormats.BytesPerPixel(mFormat);
	public bool HasAlpha => PixelFormats.HasAlpha(mFormat);
	public int32 ChannelCount => (int32)PixelFormats.ChannelCount(mFormat);

	public static int32 GetBytesPerPixel(PixelFormat format) => (int32)PixelFormats.BytesPerPixel(format);

	/// Replaces size, format and pixels in place, so a hot reload keeps the same object and
	/// every reference to it stays valid.
	///
	/// A short source fills what it can and CLEARS the rest: the alternative is an image
	/// whose tail is whatever the buffer happened to contain.
	public void ReplaceData(uint32 width, uint32 height, PixelFormat format, Span<uint8> source)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;

		let needed = DataSize;
		mPixels.Resize(needed);

		let copy = (source.Length < needed) ? source.Length : needed;
		if (copy > 0)
			Internal.MemCpy(mPixels.Ptr, source.Ptr, copy);
		if (copy < needed)
			Internal.MemSet(mPixels.Ptr + copy, 0, needed - copy);
	}

	/// Clears every byte to zero.
	///
	/// Zero for every format, with no branch filling transparent where the format has
	/// alpha. That would be the same bytes for every 8 bit format, and WRONG for a float
	/// one: RGBA16F and RGBA32F report alpha, so they would take the fill path, and a byte
	/// fill has no meaning for a half or a float. Zero is transparent in all of them.
	public void Clear()
	{
		if (!mPixels.IsEmpty)
			Internal.MemSet(mPixels.Ptr, 0, mPixels.Count);
	}

	public void Clear(Color32 color) => FillColor(color);

	public void FillColor(Color32 color)
	{
		let stride = (int)PixelFormats.BytesPerPixel(mFormat);
		for (int i = 0; i < mPixels.Count; i += stride)
			WritePixel(i, color);
	}

	/// Out of bounds reads answer black rather than trapping. A sampler asking about a
	/// pixel outside the image is ordinary, and the alternative is every caller bounds
	/// checking first.
	public Color32 GetPixel(uint32 x, uint32 y)
	{
		if ((x >= mWidth) || (y >= mHeight))
			return Color32.Black;

		let offset = PixelOffset(x, y);
		switch (mFormat)
		{
		case .R8:
			let grey = mPixels[offset];
			return .(grey, grey, grey, 255);
		case .RGB8:
			return .(mPixels[offset], mPixels[offset + 1], mPixels[offset + 2], 255);
		case .RGBA8:
			return .(mPixels[offset], mPixels[offset + 1], mPixels[offset + 2], mPixels[offset + 3]);
		case .BGR8:
			return .(mPixels[offset + 2], mPixels[offset + 1], mPixels[offset], 255);
		case .BGRA8:
			return .(mPixels[offset + 2], mPixels[offset + 1], mPixels[offset], mPixels[offset + 3]);
		default:
			return Color32.Black;
		}
	}

	/// Out of bounds writes are dropped, for the same reason reads answer black.
	public void SetPixel(uint32 x, uint32 y, Color32 color)
	{
		if ((x >= mWidth) || (y >= mHeight))
			return;
		WritePixel(PixelOffset(x, y), color);
	}

	public void FlipVertical()
	{
		let rowSize = (int)mWidth * (int)PixelFormats.BytesPerPixel(mFormat);
		if (rowSize == 0)
			return;

		let row = scope List<uint8>();
		row.Resize(rowSize);
		for (uint32 y < mHeight / 2)
		{
			let top = mPixels.Ptr + (int)y * rowSize;
			let bottom = mPixels.Ptr + (int)(mHeight - 1 - y) * rowSize;
			Internal.MemCpy(row.Ptr, top, rowSize);
			Internal.MemCpy(top, bottom, rowSize);
			Internal.MemCpy(bottom, row.Ptr, rowSize);
		}
	}

	public void FlipHorizontal()
	{
		let stride = (int)PixelFormats.BytesPerPixel(mFormat);
		if (stride == 0)
			return;

		let pixel = scope List<uint8>();
		pixel.Resize(stride);
		for (uint32 y < mHeight)
		{
			for (uint32 x < mWidth / 2)
			{
				let left = mPixels.Ptr + PixelOffset(x, y);
				let right = mPixels.Ptr + PixelOffset(mWidth - 1 - x, y);
				Internal.MemCpy(pixel.Ptr, left, stride);
				Internal.MemCpy(left, right, stride);
				Internal.MemCpy(right, pixel.Ptr, stride);
			}
		}
	}

	/// A NEW image in the requested format. The caller owns it.
	public Image ConvertFormat(PixelFormat format)
	{
		let result = new Image(mWidth, mHeight, format);
		for (uint32 y < mHeight)
		{
			for (uint32 x < mWidth)
				result.SetPixel(x, y, GetPixel(x, y));
		}
		return result;
	}

	// ---- procedural factories, all of which the CALLER owns ----

	public static Image CreateSolidColor(uint32 width, uint32 height, Color32 color,
		PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		image.FillColor(color);
		return image;
	}

	public static Image CreateCheckerboard(uint32 size = 256, Color32 first = Color32.White,
		Color32 second = Color32.Black, uint32 checkSize = 32, PixelFormat format = .RGBA8)
	{
		let image = new Image(size, size, format);
		let check = (checkSize == 0) ? 1 : checkSize;
		for (uint32 y < size)
		{
			for (uint32 x < size)
				image.SetPixel(x, y, (((x / check + y / check) % 2) == 0) ? first : second);
		}
		return image;
	}

	public static Image CreateGradient(uint32 width, uint32 height, Color32 top, Color32 bottom,
		PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		for (uint32 y < height)
		{
			let t = (float)y / (float)((height > 1) ? (height - 1) : 1);
			let color = Color32(
				(uint8)((float)top.R + t * ((float)bottom.R - (float)top.R)),
				(uint8)((float)top.G + t * ((float)bottom.G - (float)top.G)),
				(uint8)((float)top.B + t * ((float)bottom.B - (float)top.B)),
				(uint8)((float)top.A + t * ((float)bottom.A - (float)top.A)));
			for (uint32 x < width)
				image.SetPixel(x, y, color);
		}
		return image;
	}

	private int PixelOffset(uint32 x, uint32 y)
		=> (int)(y * mWidth + x) * (int)PixelFormats.BytesPerPixel(mFormat);

	/// Writes one pixel at a byte offset, channel order following the format.
	///
	/// A single channel format stores the average of the three colour channels rather than
	/// just red, so a grey written through a colour ends up the grey it looks like.
	private void WritePixel(int offset, Color32 color)
	{
		switch (mFormat)
		{
		case .R8:
			mPixels[offset] = (uint8)(((uint32)color.R + (uint32)color.G + (uint32)color.B) / 3);
		case .RG8:
			mPixels[offset] = color.R;
			mPixels[offset + 1] = color.G;
		case .RGB8:
			mPixels[offset] = color.R;
			mPixels[offset + 1] = color.G;
			mPixels[offset + 2] = color.B;
		case .RGBA8:
			mPixels[offset] = color.R;
			mPixels[offset + 1] = color.G;
			mPixels[offset + 2] = color.B;
			mPixels[offset + 3] = color.A;
		case .BGR8:
			mPixels[offset] = color.B;
			mPixels[offset + 1] = color.G;
			mPixels[offset + 2] = color.R;
		case .BGRA8:
			mPixels[offset] = color.B;
			mPixels[offset + 1] = color.G;
			mPixels[offset + 2] = color.R;
			mPixels[offset + 3] = color.A;
		default:
			// A float or 16 bit format has no 8 bit colour meaning; leaving it alone is
			// better than writing a byte pattern into a half float.
		}
	}
}
