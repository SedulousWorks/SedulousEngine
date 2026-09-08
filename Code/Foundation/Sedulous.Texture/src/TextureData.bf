using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;

namespace Sedulous.Texture;

/// A CPU side description of pixel data staged for upload.
///
/// It owns NO GPU handle and no pixels: the consumer creates the RHI texture from this and
/// keeps the bytes alive until the upload has been submitted. That is what lets the layer
/// between images and the GPU stay device free, which the cooking tools and the headless
/// tests both depend on.
struct TextureData
{
	/// NOT OWNED. The span is a view of somebody else's buffer, and its length is the
	/// total byte count.
	public Span<uint8> Pixels = .();

	public uint32 Width = 0;
	public uint32 Height = 0;
	/// The depth of a volume, or the layer count of an array. Six for a cubemap.
	public uint32 DepthOrArrayLayers = 1;
	/// Above one, the data must contain EVERY mip, packed largest first.
	public uint32 MipLevels = 1;

	public TextureFormat Format = .RGBA8Unorm;
	public TextureDimension Dimension = .Texture2D;

	/// Zero means derive it from the format and the width.
	public uint32 BytesPerRow = 0;
	/// Zero means derive it from the height.
	public uint32 RowsPerImage = 0;

	public this() {}

	public uint64 Size => (uint64)Pixels.Length;

	public static TextureData Create2D(Span<uint8> pixels, uint32 width, uint32 height,
		TextureFormat format)
	{
		var data = TextureData();
		data.Pixels = pixels;
		data.Width = width;
		data.Height = height;
		data.Format = format;
		return data;
	}

	public static TextureData Create2DWithMips(Span<uint8> pixels, uint32 width, uint32 height,
		uint32 mipLevels, TextureFormat format)
	{
		var data = Create2D(pixels, width, height, format);
		data.MipLevels = mipLevels;
		return data;
	}

	/// Six SQUARE faces, packed as a 2D array of six layers, which is how the GPU stores
	/// one: the cube is a view over that storage, not a storage shape of its own.
	public static TextureData CreateCube(Span<uint8> pixels, uint32 faceSize, TextureFormat format)
	{
		var data = Create2D(pixels, faceSize, faceSize, format);
		data.DepthOrArrayLayers = 6;
		return data;
	}

	public static TextureData Create2DArray(Span<uint8> pixels, uint32 width, uint32 height,
		uint32 layers, TextureFormat format)
	{
		var data = Create2D(pixels, width, height, format);
		data.DepthOrArrayLayers = layers;
		return data;
	}

	/// Stages an image, reading its bytes as `colorSpace`.
	///
	/// Stated explicitly rather than taken from the image, because the colour space is an
	/// authoring decision: a loader that guessed sRGB would corrupt every normal map that
	/// happens to be stored as eight bit RGBA.
	public static TextureData FromImage(ImageData image, ImageColorSpace colorSpace)
	{
		return Create2D(image.PixelData, image.Width, image.Height,
			TextureFormatUtils.Convert(image.Format, colorSpace));
	}

	/// The same, taking the image at its word. For a source that carried its colour space
	/// through the load rather than one that has yet to be told.
	public static TextureData FromImage(ImageData image) => FromImage(image, image.ColorSpace);

	/// Bytes one texel occupies, or ZERO for a block compressed format, which has no per
	/// texel size at all: CalculateMipSize sizes those by block.
	///
	/// One table, the RHI's. Raptor carried a second copy here that defaulted unknown
	/// formats to four, which was wrong for RGBA16Unorm and Stencil8.
	public static uint32 GetBytesPerPixel(TextureFormat format)
		=> TextureFormats.BytesPerPixel(format);

	/// The bytes one mip level of this texture occupies.
	public uint64 CalculateMipSize(uint32 mipLevel)
	{
		// Every dimension floors at one: a 8x1 texture still has mips, and they are all
		// one texel tall.
		let mipWidth = Math.Max((uint32)1, Width >> mipLevel);
		let mipHeight = Math.Max((uint32)1, Height >> mipLevel);

		if (TextureFormats.IsCompressed(Format))
			return TextureFormats.CompressedLevelBytes(Format, mipWidth, mipHeight)
				* DepthOrArrayLayers;

		return (uint64)mipWidth * mipHeight * DepthOrArrayLayers * GetBytesPerPixel(Format);
	}
}
