namespace Sedulous.Textures;

using System;
using Sedulous.RHI;
using Sedulous.Imaging;

/// Raw texture data for upload to GPU.
/// The caller is responsible for providing correctly formatted pixel data.
public struct TextureData
{
	/// Pointer to pixel data.
	public uint8* Pixels;

	/// Total size in bytes.
	public uint64 Size;

	/// Texture width.
	public uint32 Width;

	/// Texture height.
	public uint32 Height;

	/// Depth (for 3D textures) or array layers.
	public uint32 DepthOrArrayLayers;

	/// Number of mip levels (data must contain all mips if > 1).
	public uint32 MipLevels;

	/// Pixel format.
	public TextureFormat Format;

	/// Texture dimension.
	public TextureDimension Dimension;

	/// Bytes per row (for upload alignment, 0 = auto-calculate).
	public uint32 BytesPerRow;

	/// Rows per image (for 3D/array textures, 0 = auto-calculate).
	public uint32 RowsPerImage;

	/// Creates texture data for a simple 2D texture.
	public static Self Create2D(uint8* pixels, uint64 size, uint32 width, uint32 height, TextureFormat format)
	{
		return .()
		{
			Pixels = pixels,
			Size = size,
			Width = width,
			Height = height,
			DepthOrArrayLayers = 1,
			MipLevels = 1,
			Format = format,
			Dimension = .Texture2D,
			BytesPerRow = 0,
			RowsPerImage = 0
		};
	}

	/// Creates texture data for a 2D texture with mips.
	public static Self Create2DWithMips(uint8* pixels, uint64 size, uint32 width, uint32 height, uint32 mipLevels, TextureFormat format)
	{
		return .()
		{
			Pixels = pixels,
			Size = size,
			Width = width,
			Height = height,
			DepthOrArrayLayers = 1,
			MipLevels = mipLevels,
			Format = format,
			Dimension = .Texture2D,
			BytesPerRow = 0,
			RowsPerImage = 0
		};
	}

	/// Creates texture data for a cubemap.
	public static Self CreateCube(uint8* pixels, uint64 size, uint32 faceSize, TextureFormat format)
	{
		return .()
		{
			Pixels = pixels,
			Size = size,
			Width = faceSize,
			Height = faceSize,
			DepthOrArrayLayers = 6,
			MipLevels = 1,
			Format = format,
			Dimension = .Texture2D, // Cube is 2D array with 6 layers
			BytesPerRow = 0,
			RowsPerImage = 0
		};
	}

	/// Creates texture data for a 2D array.
	public static Self Create2DArray(uint8* pixels, uint64 size, uint32 width, uint32 height, uint32 layers, TextureFormat format)
	{
		return .()
		{
			Pixels = pixels,
			Size = size,
			Width = width,
			Height = height,
			DepthOrArrayLayers = layers,
			MipLevels = 1,
			Format = format,
			Dimension = .Texture2D,
			BytesPerRow = 0,
			RowsPerImage = 0
		};
	}

	/// Creates texture data from an Image.
	public static Self FromImage(Image image)
	{
		return Create2D(image.Data.Ptr, (uint64)image.Data.Length,
			image.Width, image.Height, TextureFormatUtils.Convert(image.Format));
	}

	/// Gets bytes per pixel for a format.
	public static uint32 GetBytesPerPixel(TextureFormat format)
	{
		switch (format)
		{
		case .R8Unorm, .R8Snorm, .R8Uint, .R8Sint:
			return 1;
		case .R16Uint, .R16Sint, .R16Float, .RG8Unorm, .RG8Snorm, .RG8Uint, .RG8Sint:
			return 2;
		case .R32Uint, .R32Sint, .R32Float, .RG16Uint, .RG16Sint, .RG16Float,
			 .RGBA8Unorm, .RGBA8UnormSrgb, .RGBA8Snorm, .RGBA8Uint, .RGBA8Sint,
			 .BGRA8Unorm, .BGRA8UnormSrgb:
			return 4;
		case .RG32Uint, .RG32Sint, .RG32Float, .RGBA16Uint, .RGBA16Sint, .RGBA16Float:
			return 8;
		case .RGBA32Uint, .RGBA32Sint, .RGBA32Float:
			return 16;
		case .Depth16Unorm:
			return 2;
		case .Depth24Plus, .Depth24PlusStencil8, .Depth32Float:
			return 4;
		case .Depth32FloatStencil8:
			return 5;
		default:
			return 4; // Default assumption
		}
	}

	/// Calculates expected size for a mip level.
	public uint64 CalculateMipSize(uint32 mipLevel)
	{
		let mipWidth = Math.Max(1, Width >> mipLevel);
		let mipHeight = Math.Max(1, Height >> mipLevel);
		let bpp = GetBytesPerPixel(Format);
		return (uint64)(mipWidth * mipHeight * DepthOrArrayLayers * bpp);
	}
}
