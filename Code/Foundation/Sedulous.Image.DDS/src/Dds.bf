using System;
using System.Collections;
using System.IO;
using Sedulous.Core;

namespace Sedulous.Image.DDS;

/// The DDS container: the format GPU ready textures ship in, block compressed or not, with a
/// full mip chain, two dimensional or cubemap or array, under either the legacy FourCC header
/// or the DX10 extension header that NAMES the DXGI format and so the colour space.
///
/// This reads the container as it stands, keeping the payload bytes, decodes any level to an
/// Image, and writes the DX10 form.
///
/// The POLICY lives elsewhere: the texture pipeline decides whether a payload passes through
/// to the cooked texture untouched or is decoded and re-encoded, and the image loaders sniff
/// the magic so every image consumer reads a DDS as its level nought.
static class Dds
{
	/// "DDS ".
	private const uint32 cMagic = 0x20534444;
	private const int cHeaderSize = 124;
	private const int cPixelFormatSize = 32;
	private const int cDx10HeaderSize = 20;
	private const int cFileHeaderBytes = 4 + cHeaderSize;

	// DDS_HEADER.dwFlags
	private const uint32 cFlagCaps = 0x1;
	private const uint32 cFlagHeight = 0x2;
	private const uint32 cFlagWidth = 0x4;
	private const uint32 cFlagPitch = 0x8;
	private const uint32 cFlagPixelFormat = 0x1000;
	private const uint32 cFlagMipMapCount = 0x20000;
	private const uint32 cFlagLinearSize = 0x80000;
	// DDS_PIXELFORMAT.dwFlags
	private const uint32 cPfAlphaPixels = 0x1;
	private const uint32 cPfFourCC = 0x4;
	private const uint32 cPfRgb = 0x40;
	private const uint32 cPfLuminance = 0x20000;
	// dwCaps and dwCaps2
	private const uint32 cCapsComplex = 0x8;
	private const uint32 cCapsTexture = 0x1000;
	private const uint32 cCapsMipMap = 0x400000;
	private const uint32 cCaps2Cubemap = 0x200;
	private const uint32 cCaps2CubemapAllFaces = 0xFE00;
	private const uint32 cCaps2Volume = 0x200000;
	// The DX10 header
	private const uint32 cDimensionTexture2D = 3;
	private const uint32 cDimensionTexture3D = 4;
	private const uint32 cMiscTextureCube = 0x4;

	private static uint32 FourCC(char8 a, char8 b, char8 c, char8 d)
		=> (uint32)(uint8)a | ((uint32)(uint8)b << 8) | ((uint32)(uint8)c << 16)
			| ((uint32)(uint8)d << 24);

	/// The DXGI format values the reader understands.
	private const uint32 cDxgiR32G32B32A32Float = 2;
	private const uint32 cDxgiR16G16B16A16Float = 10;
	private const uint32 cDxgiR8G8B8A8Unorm = 28;
	private const uint32 cDxgiR8G8B8A8UnormSrgb = 29;
	private const uint32 cDxgiR8G8Unorm = 49;
	private const uint32 cDxgiR8Unorm = 61;
	private const uint32 cDxgiBc1Unorm = 71;
	private const uint32 cDxgiBc1UnormSrgb = 72;
	private const uint32 cDxgiBc2Unorm = 74;
	private const uint32 cDxgiBc2UnormSrgb = 75;
	private const uint32 cDxgiBc3Unorm = 77;
	private const uint32 cDxgiBc3UnormSrgb = 78;
	private const uint32 cDxgiBc4Unorm = 80;
	private const uint32 cDxgiBc4Snorm = 81;
	private const uint32 cDxgiBc5Unorm = 83;
	private const uint32 cDxgiBc5Snorm = 84;
	private const uint32 cDxgiB8G8R8A8Unorm = 87;
	private const uint32 cDxgiB8G8R8A8UnormSrgb = 91;
	private const uint32 cDxgiBc6HUf16 = 95;
	private const uint32 cDxgiBc6HSf16 = 96;
	private const uint32 cDxgiBc7Unorm = 98;
	private const uint32 cDxgiBc7UnormSrgb = 99;

	private static DdsFormat FromDxgi(uint32 dxgi)
	{
		switch (dxgi)
		{
		case cDxgiR32G32B32A32Float: return .RGBA32F;
		case cDxgiR16G16B16A16Float: return .RGBA16F;
		case cDxgiR8G8B8A8Unorm: return .RGBA8;
		case cDxgiR8G8B8A8UnormSrgb: return .RGBA8Srgb;
		case cDxgiR8G8Unorm: return .RG8;
		case cDxgiR8Unorm: return .R8;
		case cDxgiBc1Unorm: return .BC1;
		case cDxgiBc1UnormSrgb: return .BC1Srgb;
		case cDxgiBc2Unorm: return .BC2;
		case cDxgiBc2UnormSrgb: return .BC2Srgb;
		case cDxgiBc3Unorm: return .BC3;
		case cDxgiBc3UnormSrgb: return .BC3Srgb;
		case cDxgiBc4Unorm: return .BC4;
		case cDxgiBc4Snorm: return .BC4Snorm;
		case cDxgiBc5Unorm: return .BC5;
		case cDxgiBc5Snorm: return .BC5Snorm;
		case cDxgiB8G8R8A8Unorm: return .BGRA8;
		case cDxgiB8G8R8A8UnormSrgb: return .BGRA8Srgb;
		case cDxgiBc6HUf16: return .BC6HUf;
		case cDxgiBc6HSf16: return .BC6HSf;
		case cDxgiBc7Unorm: return .BC7;
		case cDxgiBc7UnormSrgb: return .BC7Srgb;
		default: return .Unknown;
		}
	}

	private static uint32 ToDxgi(DdsFormat format)
	{
		switch (format)
		{
		case .RGBA32F: return cDxgiR32G32B32A32Float;
		case .RGBA16F: return cDxgiR16G16B16A16Float;
		case .RGBA8: return cDxgiR8G8B8A8Unorm;
		case .RGBA8Srgb: return cDxgiR8G8B8A8UnormSrgb;
		case .RG8: return cDxgiR8G8Unorm;
		case .R8: return cDxgiR8Unorm;
		case .BC1: return cDxgiBc1Unorm;
		case .BC1Srgb: return cDxgiBc1UnormSrgb;
		case .BC2: return cDxgiBc2Unorm;
		case .BC2Srgb: return cDxgiBc2UnormSrgb;
		case .BC3: return cDxgiBc3Unorm;
		case .BC3Srgb: return cDxgiBc3UnormSrgb;
		case .BC4: return cDxgiBc4Unorm;
		case .BC4Snorm: return cDxgiBc4Snorm;
		case .BC5: return cDxgiBc5Unorm;
		case .BC5Snorm: return cDxgiBc5Snorm;
		case .BGRA8: return cDxgiB8G8R8A8Unorm;
		case .BGRA8Srgb: return cDxgiB8G8R8A8UnormSrgb;
		case .BC6HUf: return cDxgiBc6HUf16;
		case .BC6HSf: return cDxgiBc6HSf16;
		case .BC7: return cDxgiBc7Unorm;
		case .BC7Srgb: return cDxgiBc7UnormSrgb;
		default: return 0;
		}
	}

	/// The legacy pixel format block: a FourCC, or the bit masks describing one uncompressed
	/// texel. Only the layouts the engine reads map; anything else is unknown.
	private static DdsFormat FromLegacy(uint32 pfFlags, uint32 fourCC, uint32 bitCount,
		uint32 rMask, uint32 gMask, uint32 bMask, uint32 aMask)
	{
		if ((pfFlags & cPfFourCC) != 0)
		{
			if (fourCC == FourCC('D', 'X', 'T', '1')) return .BC1;
			if ((fourCC == FourCC('D', 'X', 'T', '2')) || (fourCC == FourCC('D', 'X', 'T', '3')))
				return .BC2;
			if ((fourCC == FourCC('D', 'X', 'T', '4')) || (fourCC == FourCC('D', 'X', 'T', '5')))
				return .BC3;
			if ((fourCC == FourCC('A', 'T', 'I', '1')) || (fourCC == FourCC('B', 'C', '4', 'U')))
				return .BC4;
			if (fourCC == FourCC('B', 'C', '4', 'S')) return .BC4Snorm;
			if ((fourCC == FourCC('A', 'T', 'I', '2')) || (fourCC == FourCC('B', 'C', '5', 'U')))
				return .BC5;
			if (fourCC == FourCC('B', 'C', '5', 'S')) return .BC5Snorm;
			if (fourCC == 113) return .RGBA16F; // D3DFMT_A16B16G16R16F
			if (fourCC == 116) return .RGBA32F; // D3DFMT_A32B32G32R32F
			return .Unknown;
		}
		if (((pfFlags & cPfRgb) != 0) && (bitCount == 32))
		{
			let alpha = ((pfFlags & cPfAlphaPixels) != 0) && (aMask == 0xFF000000);
			if ((rMask == 0x000000FF) && (gMask == 0x0000FF00) && (bMask == 0x00FF0000)
				&& (alpha || (aMask == 0)))
				return .RGBA8;
			// A8R8G8B8 and X8R8G8B8 are BGRA in memory.
			if ((rMask == 0x00FF0000) && (gMask == 0x0000FF00) && (bMask == 0x000000FF)
				&& (alpha || (aMask == 0)))
				return .BGRA8;
			return .Unknown;
		}
		if (((pfFlags & cPfLuminance) != 0) && (bitCount == 8) && (rMask == 0xFF))
			return .R8;
		if (((pfFlags & cPfRgb) != 0) && (bitCount == 16) && (rMask == 0x00FF) && (gMask == 0xFF00))
			return .RG8;
		return .Unknown;
	}

	private static uint32 ReadU32(uint8* p)
		=> (uint32)p[0] | ((uint32)p[1] << 8) | ((uint32)p[2] << 16) | ((uint32)p[3] << 24);

	private static void WriteU32(List<uint8> outBytes, uint32 value)
	{
		outBytes.Add((uint8)(value & 0xFF));
		outBytes.Add((uint8)((value >> 8) & 0xFF));
		outBytes.Add((uint8)((value >> 16) & 0xFF));
		outBytes.Add((uint8)((value >> 24) & 0xFF));
	}

	/// True when the bytes start with the DDS magic.
	public static bool IsDds(Span<uint8> bytes)
		=> (bytes.Length >= 4) && (ReadU32(bytes.Ptr) == cMagic);

	/// True when the file starts with the DDS magic, read as a FOUR BYTE probe rather than a
	/// read of the file: how a loader tells a GPU ready container from an image to decode.
	public static bool IsDdsFile(StringView path)
	{
		let stream = scope FileStream();
		if (stream.Open(path, .Read, .Read) case .Err)
			return false;

		uint8[4] magic = .();
		if (!(stream.TryRead(.(&magic[0], 4)) case .Ok(let got)) || (got != 4))
			return false;
		return IsDds(.(&magic[0], 4));
	}

	/// Parses a DDS, under either header form, copying the payload.
	///
	/// A volume, or a format outside the table, is not supported; a truncated payload is an
	/// invalid argument.
	public static Result<void, ErrorCode> LoadDds(Span<uint8> bytes, DdsImage outImage)
	{
		if ((bytes.Length < cFileHeaderBytes) || !IsDds(bytes))
			return .Err(.InvalidArgument);

		let h = bytes.Ptr + 4;
		if ((ReadU32(h) != cHeaderSize) || (ReadU32(h + 72) != cPixelFormatSize))
			return .Err(.InvalidArgument);

		let flags = ReadU32(h + 4);
		let height = ReadU32(h + 8);
		let width = ReadU32(h + 12);
		let mipCount = ReadU32(h + 24);
		let pfFlags = ReadU32(h + 76);
		let fourCC = ReadU32(h + 80);
		let bitCount = ReadU32(h + 84);
		let rMask = ReadU32(h + 88);
		let gMask = ReadU32(h + 92);
		let bMask = ReadU32(h + 96);
		let aMask = ReadU32(h + 100);
		let caps2 = ReadU32(h + 108);

		outImage.Data.Clear();
		outImage.Width = width;
		outImage.Height = height;
		outImage.MipLevels = (((flags & cFlagMipMapCount) != 0) && (mipCount > 0)) ? mipCount : 1;

		var payloadStart = cFileHeaderBytes;
		var cube = (caps2 & cCaps2Cubemap) != 0;
		var volume = (caps2 & cCaps2Volume) != 0;
		var arraySize = (uint32)1;

		if (((pfFlags & cPfFourCC) != 0) && (fourCC == FourCC('D', 'X', '1', '0')))
		{
			if (bytes.Length < (cFileHeaderBytes + cDx10HeaderSize))
				return .Err(.InvalidArgument);

			let x = bytes.Ptr + cFileHeaderBytes;
			let dxgi = ReadU32(x);
			let dimension = ReadU32(x + 4);
			let misc = ReadU32(x + 8);
			arraySize = ReadU32(x + 12);
			outImage.Format = FromDxgi(dxgi);
			outImage.ColorSpaceKnown = true;
			cube = cube || ((misc & cMiscTextureCube) != 0);
			volume = volume || (dimension == cDimensionTexture3D);
			// Nothing in the engine wants a one dimensional texture.
			if ((dimension != cDimensionTexture2D) && (dimension != cDimensionTexture3D))
				return .Err(.NotSupported);
			payloadStart += cDx10HeaderSize;
		}
		else
		{
			outImage.Format = FromLegacy(pfFlags, fourCC, bitCount, rMask, gMask, bMask, aMask);
			outImage.ColorSpaceKnown = false;
		}

		if (volume)
			return .Err(.NotSupported);
		if ((outImage.Format == .Unknown) || (width == 0) || (height == 0) || (arraySize == 0))
			return .Err(.NotSupported);
		// A partial cubemap has no fixed layout.
		if (cube && ((caps2 & cCaps2Cubemap) != 0)
			&& ((caps2 & cCaps2CubemapAllFaces) != cCaps2CubemapAllFaces))
			return .Err(.NotSupported);

		outImage.Cubemap = cube;
		outImage.ArrayLayers = cube ? (arraySize * 6) : arraySize;

		let payload = outImage.LayerSize() * (int)outImage.ArrayLayers;
		if (bytes.Length < (payloadStart + payload))
			return .Err(.InvalidArgument); // truncated

		outImage.Data.Resize(payload);
		if (payload > 0)
			Internal.MemCpy(outImage.Data.Ptr, bytes.Ptr + payloadStart, payload);
		return .Ok;
	}

	/// Writes the image with a DX10 header, always: the form that names the format.
	public static Result<void, ErrorCode> WriteDds(DdsImage dds, List<uint8> outBytes)
	{
		if ((dds.Format == .Unknown) || (dds.Width == 0) || (dds.Height == 0)
			|| (dds.ArrayLayers == 0) || (dds.Cubemap && ((dds.ArrayLayers % 6) != 0)))
			return .Err(.InvalidArgument);

		let payload = dds.LayerSize() * (int)dds.ArrayLayers;
		if (dds.Data.Count < payload)
			return .Err(.InvalidArgument);

		outBytes.Clear();
		outBytes.Reserve(cFileHeaderBytes + cDx10HeaderSize + payload);
		WriteU32(outBytes, cMagic);

		var flags = cFlagCaps | cFlagHeight | cFlagWidth | cFlagPixelFormat;
		flags |= DdsFormats.IsBlockCompressed(dds.Format) ? cFlagLinearSize : cFlagPitch;
		if (dds.MipLevels > 1)
			flags |= cFlagMipMapCount;

		WriteU32(outBytes, (uint32)cHeaderSize);
		WriteU32(outBytes, flags);
		WriteU32(outBytes, dds.Height);
		WriteU32(outBytes, dds.Width);
		// The level nought bytes for a compressed format, the row pitch otherwise.
		WriteU32(outBytes, DdsFormats.IsBlockCompressed(dds.Format)
			? (uint32)dds.LevelSize(0)
			: (dds.Width * DdsFormats.BytesPerPixel(dds.Format)));
		WriteU32(outBytes, 1); // depth
		WriteU32(outBytes, dds.MipLevels);
		for (int i < 11)
			WriteU32(outBytes, 0); // reserved1

		// DDS_PIXELFORMAT, carrying the FourCC "DX10".
		WriteU32(outBytes, (uint32)cPixelFormatSize);
		WriteU32(outBytes, cPfFourCC);
		WriteU32(outBytes, FourCC('D', 'X', '1', '0'));
		for (int i < 5)
			WriteU32(outBytes, 0);

		var caps = cCapsTexture;
		if (dds.MipLevels > 1)
			caps |= cCapsMipMap | cCapsComplex;
		if (dds.Cubemap)
			caps |= cCapsComplex;
		WriteU32(outBytes, caps);
		WriteU32(outBytes, dds.Cubemap ? (cCaps2Cubemap | cCaps2CubemapAllFaces) : 0);
		WriteU32(outBytes, 0); // caps3
		WriteU32(outBytes, 0); // caps4
		WriteU32(outBytes, 0); // reserved2

		// DDS_HEADER_DXT10.
		WriteU32(outBytes, ToDxgi(dds.Format));
		WriteU32(outBytes, cDimensionTexture2D);
		WriteU32(outBytes, dds.Cubemap ? cMiscTextureCube : 0);
		WriteU32(outBytes, dds.Cubemap ? (dds.ArrayLayers / 6) : dds.ArrayLayers);
		WriteU32(outBytes, 0); // miscFlags2: the alpha mode is unknown

		let at = outBytes.Count;
		outBytes.Resize(at + payload);
		if (payload > 0)
			Internal.MemCpy(outBytes.Ptr + at, dds.Data.Ptr, payload);
		return .Ok;
	}

	/// Level nought of layer nought as an Image, which is what a generic image loader hands
	/// back for a DDS.
	public static Result<void, ErrorCode> LoadDdsAsImage(Span<uint8> bytes, Image outImage)
	{
		let dds = scope DdsImage();
		if (LoadDds(bytes, dds) case .Err(let error))
			return .Err(error);
		return DdsDecode.DecodeLevel(dds, 0, 0, outImage);
	}
}
