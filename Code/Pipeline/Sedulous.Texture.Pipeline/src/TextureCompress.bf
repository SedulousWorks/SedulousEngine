using System;
using System.Collections;
using Sedulous.Pipeline.Core;
using Sedulous.RHI;
using static Sedulous.RHI.TextureFormats;
using Sedulous.Texture.Compression;

namespace Sedulous.Texture.Pipeline;

/// Turning a cooked texture's pixels into block bytes when the policy says to.
///
/// Every entry point here DECLINES quietly: an encoder that refuses, or a policy that picks no
/// compressed format, leaves the uncompressed pixels and the uncompressed format exactly as
/// they were. A cook that produced nothing would be worse than one that produced a larger
/// texture.
static class TextureCompress
{
	/// The compressed family profile for a cook: the target's own capabilities, or the always
	/// warm desktop host when there is no target, which is the editor's development loop.
	public static TargetProfile ProfileFor(AssetBuildContext context)
		=> .(context.Target.Bc, context.Target.Astc, context.Target.Etc2);

	/// Encodes an RGBA8 mip chain in place when the policy picks a block format, and updates
	/// the format to match. The chain is levels nought to N tightly concatenated, and the
	/// compressed one replaces it one for one.
	public static void MaybeCompress(List<uint8> pixels, uint32 width, uint32 height,
		uint32 mipLevels, bool srgb, SourceUsage usage, CompressionChoice choice,
		TargetProfile profile, ref TextureFormat format)
	{
		if (choice == .None)
			return;

		// Whether there is alpha decides colour between the small opaque format and the large
		// one, so level nought is scanned for a texel that is not fully opaque.
		var hasAlpha = false;
		let texels = (int)width * (int)height;
		for (int i < texels)
		{
			if (pixels[i * 4 + 3] != 255)
			{
				hasAlpha = true;
				break;
			}
		}

		// The channel sniff for the mask guard: a packed mask must not cook to the single
		// channel format, which would keep red and drop the rest. A grey one still does.
		let multiChannel = TextureCompression.HasDistinctChannels(pixels.Ptr, width, height);

		let chosen = TextureCompression.ResolveCompressedFormat(usage, srgb, hasAlpha,
			multiChannel, choice, width, height, profile, format);
		if (!IsCompressed(chosen))
			return; // the policy declined, so the chain and the format stand

		let quality = (choice == .Quality) ? (uint8)255 : (uint8)128;

		let encoded = scope List<uint8>();
		var sourceOffset = 0;
		var levelWidth = width;
		var levelHeight = height;
		for (uint32 level < mipLevels)
		{
			let levelBytes = (int)levelWidth * (int)levelHeight * 4;
			let before = encoded.Count;
			TextureCompression.EncodeBlockCompressed(pixels.Ptr + sourceOffset, levelWidth,
				levelHeight, chosen, quality, encoded);
			if (encoded.Count == before)
				return; // the encode failed, so the uncompressed chain stands

			sourceOffset += levelBytes;
			levelWidth = (levelWidth > 1) ? levelWidth / 2 : 1;
			levelHeight = (levelHeight > 1) ? levelHeight / 2 : 1;
		}

		pixels.Clear();
		pixels.AddRange(encoded);
		format = chosen;
	}

	/// The high dynamic range counterpart, over ONE level: a sky carries no mip chain.
	public static void MaybeCompressHdr(List<uint8> pixels, uint32 width, uint32 height,
		SourceUsage usage, CompressionChoice choice, TargetProfile profile,
		ref TextureFormat format)
	{
		if (choice == .None)
			return;

		let chosen = TextureCompression.ResolveCompressedFormat(usage, false, false, true, choice,
			width, height, profile, format);
		if (chosen != .BC6HRGBUfloat)
			return; // the policy declined, or a mis-tagged usage picked a low range format

		let quality = (choice == .Quality) ? (uint8)255 : (uint8)128;
		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr((float*)pixels.Ptr, width, height, quality,
			encoded);
		if ((uint64)encoded.Count != CompressedLevelBytes(chosen, width, height))
			return; // the encoder refused, so the uncompressed level stands

		pixels.Clear();
		pixels.AddRange(encoded);
		format = chosen;
	}
}
