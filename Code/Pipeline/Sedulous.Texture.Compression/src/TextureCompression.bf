using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.RHI;
using static Sedulous.RHI.TextureFormats;
using astcenc_Beef;
using bc7enc_Beef;

namespace Sedulous.Texture.Compression;

/// The format POLICY and the encoder dispatch: given what a source is for and what the export
/// target can decode, pick a cooked format, and encode one mip level into it.
///
/// Cook and import time only, and free of any interface, which is the pipeline's rule. The BC
/// formats go through bc7enc block by block, ASTC through astcenc as a whole image, and BC6H
/// through the engine's own encoder, since nothing vendorable writes one.
/// The RHI has a TextureUsage of its own, meaning what a texture is BOUND as, so the semantic
/// one is spelled out here where both are in scope.
typealias SourceUsage = Sedulous.Texture.Compression.TextureUsage;

static class TextureCompression
{
	/// One time global table init for the block encoders, which is idempotent and cheap after
	/// the first call, so every entry point simply asks for it.
	private static void EnsureInit() => bc7encc_init();

	/// Bytes one mip level of a block compressed format occupies, rounded up to whole 4x4
	/// blocks. The cook asserts the encoder produced exactly this.
	public static uint64 BlockCompressedSize(TextureFormat format, uint32 width, uint32 height)
		=> CompressedLevelBytes(format, width, height);

	/// The cooked format for a source, or `uncompressed` when the policy says not to compress:
	/// an authored None, a small or interface texture, or a target with no family this build
	/// can encode.
	///
	/// `sRGB` picks the Srgb variants. `hasAlpha` splits colour into BC1 when opaque and BC7
	/// when not. `multiChannel` is the cook's cheap channel sniff: a packed mask carrying three
	/// meaningful channels cannot go to BC4, which would keep red and silently drop the rest.
	public static TextureFormat ResolveCompressedFormat(SourceUsage usage, bool sRGB,
		bool hasAlpha, bool multiChannel, CompressionChoice choice, uint32 width, uint32 height,
		TargetProfile profile, TextureFormat uncompressed)
	{
		// The escape hatches: an authored None, and anything small enough that interface art
		// and pixel art would visibly suffer.
		if (choice == .None)
			return uncompressed;
		if ((width <= 64) && (height <= 64))
			return uncompressed;

		if (usage == .HDR)
		{
			// BC6H unsigned is part of the same BC feature already required on desktop and in
			// desktop browsers. The mobile ASTC HDR variant is the follow up.
			return profile.Bc ? .BC6HRGBUfloat : uncompressed;
		}

		// BC first where a profile has both, desktop and desktop browsers being the case.
		if (profile.Bc)
		{
			switch (usage)
			{
			case .Color:
				if (hasAlpha || (choice == .Quality))
					return sRGB ? .BC7RGBAUnormSrgb : .BC7RGBAUnorm;
				return sRGB ? .BC1RGBAUnormSrgb : .BC1RGBAUnorm; // opaque, and not forced
			case .Normal:
				// BC7 linear, NOT BC5: the shaders decode rgb * 2 - 1, and BC5 carries no blue,
				// so z decodes to -1 and the surface shades white. Same one byte per texel as
				// BC5 would cost. BC5 with shader side z reconstruction is the deferred step.
				return .BC7RGBAUnorm;
			case .Mask:
				// A packed mask authored as one carries THREE meaningful channels, and BC4
				// would keep only red. The sniff routes those to BC7 linear; a true single
				// channel mask stays on BC4.
				return multiChannel ? .BC7RGBAUnorm : .BC4RUnorm;
			case .HDR:
				return uncompressed; // answered above
			}
		}

		if (profile.Astc)
		{
			// ASTC has no per usage split the way BC does: one 4x4 block encodes RGBA, and the
			// semantic reaches the encoder as a flag rather than as a format. sRGB only
			// meaningfully applies to colour, so a normal map or a mask stays linear.
			return (sRGB && (usage == .Color)) ? .ASTC4x4UnormSrgb : .ASTC4x4Unorm;
		}

		// ETC2, and any other family, stay uncompressed.
		return uncompressed;
	}

	/// Whether any texel's green or blue differs from its red by more than `tolerance`.
	///
	/// The mask guard, and the editor's "cooks to" preview. A packed mask reads true; a grey
	/// roughness, occlusion or height map reads false. The default tolerance absorbs the
	/// chroma noise a JPEG source leaves on a grey image.
	public static bool HasDistinctChannels(uint8* rgba, uint32 width, uint32 height,
		uint8 tolerance = 8)
	{
		if (rgba == null)
			return false;

		let texels = (int)width * (int)height;
		let tol = (int32)tolerance;
		for (int i < texels)
		{
			let r = (int32)rgba[i * 4 + 0];
			let g = (int32)rgba[i * 4 + 1];
			let b = (int32)rgba[i * 4 + 2];
			if ((Math.Abs(g - r) > tol) || (Math.Abs(b - r) > tol))
				return true;
		}
		return false;
	}

	/// Encodes one mip level of tightly packed RGBA8, being width times height times four
	/// bytes, into `format`'s block bytes. The APPENDED bytes are exactly
	/// BlockCompressedSize; nothing is appended when the format is one this build cannot
	/// encode, which the caller sees as an empty result.
	///
	/// Edge blocks on a level that is not a multiple of four are clamp padded from the border
	/// texels. `quality` runs 0 to 255 and maps onto each encoder's own effort scale.
	/// `jobs`, when given, fans the BLOCK ROWS out over the job system. Each row writes its
	/// own slice of the output and every block encodes on its own, the encoders keeping no
	/// state past EnsureInit, so the result is byte identical to the serial loop.
	public static void EncodeBlockCompressed(uint8* rgba, uint32 width, uint32 height,
		TextureFormat format, uint8 quality, List<uint8> outBytes, JobSystem jobs = null)
	{
		if ((rgba == null) || (width == 0) || (height == 0) || !IsCompressed(format))
			return;

		// ASTC is a whole image codec rather than a block one, so it has its own path.
		if ((format == .ASTC4x4Unorm) || (format == .ASTC4x4UnormSrgb))
		{
			EncodeAstc(rgba, width, height, format == .ASTC4x4UnormSrgb, quality, outBytes);
			return;
		}

		let blockBytes = BlockBytesFor(format);
		if (blockBytes == 0)
			return; // BC2, BC6H and anything else this path does not write

		EnsureInit();

		let blocksX = (width + 3) / 4;
		let blocksY = (height + 3) / 4;
		let start = outBytes.Count;
		outBytes.Count = start + (int)BlockCompressedSize(format, width, height);

		// The BC1 and BC3 encoder takes a level up to its own maximum; the BC7 one takes an
		// uber level of 0 to 4, off the same 0 to 255 quality.
		//
		// The DEFAULT maps to uber 0, which is bc7enc's own default: the mid level cost about
		// four times as much for a fraction of a decibel, which on a 4k texture is most of a
		// minute of CPU. Only an explicit top quality asks for the export grade effort.
		let rgbcxLevel = ((uint32)quality * bc7encc_rgbcx_max_level()) / 255;
		let uberLevel = (quality >= 255) ? (uint32)4 : ((quality >= 192) ? (uint32)2 : (uint32)0);

		let rowBytes = (int)blocksX * blockBytes;
		let outPtr = outBytes.Ptr;

		void EncodeRow(int32 y)
		{
			uint8[64] block = .();
			var offset = start + (int)y * rowBytes;
			for (uint32 x < blocksX)
			{
				GatherBlock(rgba, width, height, x, (uint32)y, &block);
				let dst = outPtr + offset;
				switch (format)
				{
				case .BC1RGBAUnorm, .BC1RGBAUnormSrgb:
					bc7encc_encode_bc1(rgbcxLevel, dst, &block, 1, 0);
				case .BC3RGBAUnorm, .BC3RGBAUnormSrgb:
					bc7encc_encode_bc3(rgbcxLevel, dst, &block);
				case .BC4RUnorm, .BC4RSnorm:
					bc7encc_encode_bc4(dst, &block, 4);
				case .BC5RGUnorm, .BC5RGSnorm:
					bc7encc_encode_bc5(dst, &block, 0, 1, 4);
				case .BC7RGBAUnorm, .BC7RGBAUnormSrgb:
					bc7encc_encode_bc7(dst, &block, uberLevel);
				default:
					return; // unreachable: BlockBytesFor already rejected it
				}
				offset += blockBytes;
			}
		}

		if (jobs != null)
			jobs.ParallelFor((int32)blocksY, scope => EncodeRow);
		else
		{
			for (int32 y = 0; y < (int32)blocksY; y++)
				EncodeRow(y);
		}
	}

	/// Encodes one level of tightly packed RGBA32F into BC6H unsigned, which is the HDR row of
	/// the policy above. Kept beside the block dispatch so a caller finds both formats' entry
	/// points in one place; the encoder itself is the engine's own, in Bc6hEncoder.
	public static void EncodeBlockCompressedHdr(float* rgba, uint32 width, uint32 height,
		uint8 quality, List<uint8> outBytes)
		=> Bc6hEncoder.Encode(rgba, width, height, quality, outBytes);

	/// The bytes one 4x4 block of a format this dispatcher can WRITE occupies, or nought for a
	/// format it cannot. Distinct from the RHI's block size, which answers for every format the
	/// device can sample rather than only those this build encodes.
	private static int BlockBytesFor(TextureFormat format)
	{
		switch (format)
		{
		case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm:
			return 8;
		case .BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC5RGUnorm, .BC5RGSnorm, .BC7RGBAUnorm,
			.BC7RGBAUnormSrgb:
			return 16;
		default:
			return 0;
		}
	}

	/// The 4x4 RGBA block at a block coordinate, with source coordinates clamped so an edge
	/// block on a level that is not a multiple of four pads from its border texels.
	private static void GatherBlock(uint8* rgba, uint32 width, uint32 height, uint32 bx,
		uint32 by, uint8* outBlock)
	{
		for (uint32 py < 4)
		{
			let sy = Math.Min(by * 4 + py, height - 1);
			for (uint32 px < 4)
			{
				let sx = Math.Min(bx * 4 + px, width - 1);
				let src = rgba + ((int)sy * (int)width + (int)sx) * 4;
				let dst = outBlock + ((int)py * 4 + (int)px) * 4;
				dst[0] = src[0];
				dst[1] = src[1];
				dst[2] = src[2];
				dst[3] = src[3];
			}
		}
	}

	/// ASTC takes the WHOLE level and writes the packed 4x4 blocks itself. Single threaded,
	/// this being a cook and not a hot path. Nothing is appended on any encoder error.
	private static void EncodeAstc(uint8* rgba, uint32 width, uint32 height, bool srgb,
		uint8 quality, List<uint8> outBytes)
	{
		let profile = srgb ? AstcProfile.LdrSrgb : AstcProfile.Ldr;
		let effort = ASTCENC_PRE_FASTEST
			+ ((float)quality / 255.0f) * (ASTCENC_PRE_THOROUGH - ASTCENC_PRE_FASTEST);

		AstcConfig config = .();
		if (astcenc_config_init(profile, 4, 4, 1, effort, 0, &config) != .Success)
			return;

		void* context = null;
		if (astcenc_context_alloc(&config, 1, &context, null) != .Success)
			return;
		defer astcenc_context_free(context);

		// The codec only READS the image when compressing, so handing it the source is safe
		// even though the parameter is not const.
		void* slice = (void*)rgba;
		AstcImage image = .() { DimX = width, DimY = height, DimZ = 1, DataType = .U8,
			Data = &slice };
		var swizzle = AstcSwizzle.Identity;

		let start = outBytes.Count;
		let size = (int)BlockCompressedSize(.ASTC4x4Unorm, width, height);
		outBytes.Count = start + size;

		if (astcenc_compress_image(context, &image, &swizzle, &outBytes[start], (uint)size, 0)
			!= .Success)
		{
			outBytes.Count = start;
		}
	}
}
