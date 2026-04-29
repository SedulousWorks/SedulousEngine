using System;

namespace Sedulous.Images;

/// Color space of the texture's pixel data.
public enum ImageColorSpace
{
	/// Pixel data is sRGB-encoded color content (UI icons, photos). Default for
	/// 8-bit color textures - when uploaded as a sampled texture, the GPU should
	/// decode sRGB->linear on sample.
	Srgb,

	/// Pixel data is linear (data textures: normal maps, masks, HDR, single-channel
	/// coverage). The GPU samples the values as-is.
	Linear
}

/// Interface for textures used in 2D drawing.
/// Textures carry CPU pixel data that the renderer uploads to the GPU.
/// The renderer manages GPU resources and identifies textures by reference.
public interface IImageData
{
	/// Width of the texture in pixels
	uint32 Width { get; }

	/// Height of the texture in pixels
	uint32 Height { get; }

	/// Pixel format of the texture data
	PixelFormat Format { get; }

	/// CPU pixel data for upload to GPU.
	/// Returns empty span if data is not available (e.g., GPU-only texture).
	Span<uint8> PixelData { get; }

	/// Color space of the pixel data. Tells the renderer whether to use an
	/// sRGB GPU format (so hardware decodes on sample) or a linear format.
	ImageColorSpace ColorSpace { get; }
}

/// A texture that owns its pixel data.
public class OwnedImageData : IImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat;
	private ImageColorSpace mColorSpace;
	private uint8[] mPixelData ~ delete _;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => mFormat;
	public ImageColorSpace ColorSpace => mColorSpace;
	public Span<uint8> PixelData => mPixelData != null ? Span<uint8>(mPixelData) : .();

	/// Creates a texture that owns a copy of the provided pixel data.
	public this(uint32 width, uint32 height, PixelFormat format, Span<uint8> pixelData, ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mColorSpace = colorSpace;
		if (pixelData.Length > 0)
		{
			mPixelData = new uint8[pixelData.Length];
			pixelData.CopyTo(mPixelData);
		}
	}

	/// Creates a texture that takes ownership of the provided pixel data array.
	public this(uint32 width, uint32 height, PixelFormat format, uint8[] pixelData, ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mColorSpace = colorSpace;
		mPixelData = pixelData;
	}
}

/// A texture that references external pixel data (does not own it).
public class ImageDataRef : IImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat;
	private ImageColorSpace mColorSpace;
	private uint8* mPixelDataPtr;
	private int mPixelDataLength;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => mFormat;
	public ImageColorSpace ColorSpace => mColorSpace;
	public Span<uint8> PixelData => mPixelDataPtr != null ? Span<uint8>(mPixelDataPtr, mPixelDataLength) : .();

	/// Creates a texture reference with no pixel data (for external/GPU-managed textures).
	public this(uint32 width, uint32 height, PixelFormat format = .RGBA8, ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mColorSpace = colorSpace;
		mPixelDataPtr = null;
		mPixelDataLength = 0;
	}

	/// Creates a texture reference pointing to external pixel data.
	/// The caller must ensure the data remains valid for the lifetime of this reference.
	public this(uint32 width, uint32 height, PixelFormat format, uint8* pixelData, int pixelDataLength, ImageColorSpace colorSpace = .Srgb)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mColorSpace = colorSpace;
		mPixelDataPtr = pixelData;
		mPixelDataLength = pixelDataLength;
	}
}
