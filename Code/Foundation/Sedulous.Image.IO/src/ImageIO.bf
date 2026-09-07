using System;
using Sedulous.Core;
using Sedulous.Image;
using stb_image;

namespace Sedulous.Image.IO;

/// Reading images, through stb_image.
///
/// A direct dependency rather than an abstract loader interface: there is one decoder, the
/// formats it handles are the formats the engine handles, and an interface with a single
/// implementation is a layer that only ever costs.
static class ImageIO
{
	/// Every load asks for four channels, so the caller always gets RGBA and never has to
	/// branch on what the file happened to contain.
	private const int32 cDesiredChannels = 4;

	/// Loads an image from a file: RGBA8 normally, RGBA32F for a high dynamic range source.
	///
	/// The colour space follows from that: an LDR file is sRGB encoded, an HDR one carries
	/// linear values. Getting it wrong makes everything either washed out or too dark, and
	/// the file itself is what says which.
	public static Result<void, ErrorCode> LoadImage(StringView path, Image image)
	{
		let terminated = scope String(path);
		let isHdr = stbi_is_hdr(terminated) != 0;

		int32 width = 0, height = 0, channels = 0;
		void* data = isHdr
			? (void*)stbi_loadf(terminated, &width, &height, &channels, cDesiredChannels)
			: (void*)stbi_load(terminated, &width, &height, &channels, cDesiredChannels);

		return Adopt(data, width, height, isHdr, image);
	}

	/// The same, from bytes already in memory, which is the path an archive or an embedded
	/// texture takes.
	public static Result<void, ErrorCode> LoadImageFromMemory(Span<uint8> buffer, Image image)
	{
		if (buffer.IsEmpty)
			return .Err(.InvalidArgument);

		let isHdr = stbi_is_hdr_from_memory(buffer.Ptr, (int32)buffer.Length) != 0;

		int32 width = 0, height = 0, channels = 0;
		void* data = isHdr
			? (void*)stbi_loadf_from_memory(buffer.Ptr, (int32)buffer.Length, &width, &height, &channels, cDesiredChannels)
			: (void*)stbi_load_from_memory(buffer.Ptr, (int32)buffer.Length, &width, &height, &channels, cDesiredChannels);

		return Adopt(data, width, height, isHdr, image);
	}

	/// Loads a single channel image at FULL 16 bit precision, which is the heightmap path.
	///
	/// The ordinary load would take a 16 bit source down to 8 bits, and 256 height steps
	/// across a terrain is visible as terracing. An 8 bit source is promoted rather than
	/// refused, and a multi channel one collapses to luminance.
	public static Result<void, ErrorCode> LoadImage16(StringView path, Image image)
	{
		let terminated = scope String(path);
		int32 width = 0, height = 0, channels = 0;
		let data = stbi_load_16(terminated, &width, &height, &channels, 1);
		return Adopt16(data, width, height, image);
	}

	public static Result<void, ErrorCode> LoadImage16FromMemory(Span<uint8> buffer, Image image)
	{
		if (buffer.IsEmpty)
			return .Err(.InvalidArgument);

		int32 width = 0, height = 0, channels = 0;
		let data = stbi_load_16_from_memory(buffer.Ptr, (int32)buffer.Length, &width, &height, &channels, 1);
		return Adopt16(data, width, height, image);
	}

	/// Why the last load failed, as stb reports it. Worth surfacing: "unknown image type"
	/// and "corrupt JPEG" are the same ErrorCode and very different problems.
	public static void LastFailureReason(String outReason)
	{
		let reason = stbi_failure_reason();
		if (reason != null)
			outReason.Append(reason);
	}

	/// Copies a decoded buffer into the image and frees stb's, or reports the failure.
	private static Result<void, ErrorCode> Adopt(void* data, int32 width, int32 height, bool isHdr,
		Image image)
	{
		if (data == null)
			return .Err(.Unknown);
		defer stbi_image_free(data);

		if ((width <= 0) || (height <= 0))
			return .Err(.InvalidArgument);

		let format = isHdr ? PixelFormat.RGBA32F : PixelFormat.RGBA8;
		let size = (int)width * (int)height * (int)PixelFormats.BytesPerPixel(format);

		image.ReplaceData((uint32)width, (uint32)height, format, .((uint8*)data, size));
		image.SetColorSpace(isHdr ? .Linear : .Srgb);
		return .Ok;
	}

	private static Result<void, ErrorCode> Adopt16(uint16* data, int32 width, int32 height, Image image)
	{
		if (data == null)
			return .Err(.Unknown);
		defer stbi_image_free(data);

		if ((width <= 0) || (height <= 0))
			return .Err(.InvalidArgument);

		let size = (int)width * (int)height * 2;
		image.ReplaceData((uint32)width, (uint32)height, .R16, .((uint8*)data, size));
		// Heights are DATA, not colour: an sRGB curve applied to them would bend the
		// terrain.
		image.SetColorSpace(.Linear);
		return .Ok;
	}
}
