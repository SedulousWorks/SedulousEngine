using System;

namespace Sedulous.Drawing;

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
}

/// A texture that owns its pixel data.
public class OwnedImageData : IImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat;
	private uint8[] mPixelData ~ delete _;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => mFormat;
	public Span<uint8> PixelData => mPixelData != null ? Span<uint8>(mPixelData) : .();

	/// Creates a texture that owns a copy of the provided pixel data.
	public this(uint32 width, uint32 height, PixelFormat format, Span<uint8> pixelData)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		if (pixelData.Length > 0)
		{
			mPixelData = new uint8[pixelData.Length];
			pixelData.CopyTo(mPixelData);
		}
	}

	/// Creates a texture that takes ownership of the provided pixel data array.
	public this(uint32 width, uint32 height, PixelFormat format, uint8[] pixelData)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mPixelData = pixelData;
	}
}

/// A texture that references external pixel data (does not own it).
public class ImageDataRef : IImageData
{
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat;
	private uint8* mPixelDataPtr;
	private int mPixelDataLength;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => mFormat;
	public Span<uint8> PixelData => mPixelDataPtr != null ? Span<uint8>(mPixelDataPtr, mPixelDataLength) : .();

	/// Creates a texture reference with no pixel data (for external/GPU-managed textures).
	public this(uint32 width, uint32 height, PixelFormat format = .RGBA8)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mPixelDataPtr = null;
		mPixelDataLength = 0;
	}

	/// Creates a texture reference pointing to external pixel data.
	/// The caller must ensure the data remains valid for the lifetime of this reference.
	public this(uint32 width, uint32 height, PixelFormat format, uint8* pixelData, int pixelDataLength)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mPixelDataPtr = pixelData;
		mPixelDataLength = pixelDataLength;
	}
}
