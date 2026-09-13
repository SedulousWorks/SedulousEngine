using System;
using Sedulous.RHI;

namespace Sedulous.Texture.Compression.Tests;

/// The format policy: what a source's semantics plus a target's capabilities cook to, and the
/// exact byte count the chosen format then occupies.
class CompressionPolicyTests
{
	[Test]
	public static void ThePolicyTableOnABcTarget()
	{
		let bc = TargetProfile.Desktop;
		let uncompressed = TextureFormat.RGBA8Unorm;

		// Colour: opaque by default goes to BC1, alpha forces BC7, and an authored Quality
		// forces BC7 even when opaque. The sRGB variants follow the flag.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, false, false,
			.Default, 256, 256, bc, uncompressed) == .BC1RGBAUnorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, false, false,
			.Default, 256, 256, bc, uncompressed) == .BC1RGBAUnormSrgb);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, true, false,
			.Default, 256, 256, bc, uncompressed) == .BC7RGBAUnorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, true, false,
			.Default, 256, 256, bc, uncompressed) == .BC7RGBAUnormSrgb);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, false, false,
			.Quality, 256, 256, bc, uncompressed) == .BC7RGBAUnorm);

		// A normal map goes to BC7 linear rather than BC5, and a single channel mask to BC4.
		// Both ignore the sRGB flag.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Normal, false, false, false,
			.Default, 256, 256, bc, uncompressed) == .BC7RGBAUnorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Mask, false, false, false,
			.Default, 256, 256, bc, uncompressed) == .BC4RUnorm);
		// A packed mask authored as one carries distinct channels, so it goes to BC7 linear
		// and never to channel dropping BC4.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Mask, false, false, true,
			.Default, 256, 256, bc, uncompressed) == .BC7RGBAUnorm);

		// The escape hatches: an authored None, and anything small enough to be interface art.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, true, false, .None,
			256, 256, bc, uncompressed) == uncompressed);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, false, false,
			.Default, 64, 64, bc, uncompressed) == uncompressed);

		// HDR has its own row.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false,
			.Default, 256, 256, bc, uncompressed) == .BC6HRGBUfloat);

		// A target with no family this build can encode stays uncompressed whatever the usage.
		TargetProfile none = .();
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, true, false,
			.Default, 256, 256, none, uncompressed) == uncompressed);
	}

	[Test]
	public static void ThePolicyTableOnAnAstcTarget()
	{
		let astc = TargetProfile.Mobile;
		let uncompressed = TextureFormat.RGBA8Unorm;

		// One 4x4 format covers every low dynamic range usage, and sRGB applies only to colour.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, true, false,
			.Default, 256, 256, astc, uncompressed) == .ASTC4x4UnormSrgb);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, false, false,
			.Default, 256, 256, astc, uncompressed) == .ASTC4x4Unorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Normal, false, false, false,
			.Default, 256, 256, astc, uncompressed) == .ASTC4x4Unorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Mask, true, false, false,
			.Default, 256, 256, astc, uncompressed) == .ASTC4x4Unorm, "a linear map ignores sRGB");

		// The same escape hatches as BC, and ASTC has no HDR row yet.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, false, false, .None,
			256, 256, astc, uncompressed) == uncompressed);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, false, false,
			.Default, 64, 64, astc, uncompressed) == uncompressed);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false,
			.Default, 256, 256, astc, uncompressed) == uncompressed);

		// A target with BOTH families prefers BC, desktop first.
		TargetProfile both = .(true, true, false);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, false, false, false,
			.Default, 256, 256, both, uncompressed) == .BC1RGBAUnorm);
	}

	[Test]
	public static void TheHdrRowIsBc6hOnBcTargetsAndUncompressedElsewhere()
	{
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false,
			.Default, 512, 256, TargetProfile.Desktop, .RGBA32Float) == .BC6HRGBUfloat);
		// Mobile has no BC6H; the ASTC HDR profile is the follow up.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false,
			.Default, 512, 256, TargetProfile.Mobile, .RGBA32Float) == .RGBA32Float);
		// And the authored escape and the small texture escape still apply.
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false, .None,
			512, 256, TargetProfile.Desktop, .RGBA32Float) == .RGBA32Float);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.HDR, false, false, false,
			.Default, 32, 32, TargetProfile.Desktop, .RGBA32Float) == .RGBA32Float);
	}

	[Test]
	public static void BlockCompressedSizeCountsWholeBlocks()
	{
		// 256 by 256 is 64 by 64 blocks, which is 4096 of them. BC1 and BC4 are eight bytes a
		// block; BC3, BC5 and BC7 are sixteen.
		Test.Assert(TextureCompression.BlockCompressedSize(.BC1RGBAUnorm, 256, 256) == 4096 * 8);
		Test.Assert(TextureCompression.BlockCompressedSize(.BC4RUnorm, 256, 256) == 4096 * 8);
		Test.Assert(TextureCompression.BlockCompressedSize(.BC7RGBAUnorm, 256, 256) == 4096 * 16);
		Test.Assert(TextureCompression.BlockCompressedSize(.BC5RGUnorm, 256, 256) == 4096 * 16);
		// A level that is not a multiple of four rounds UP: 65 becomes seventeen blocks.
		Test.Assert(TextureCompression.BlockCompressedSize(.BC7RGBAUnorm, 65, 65) == 17 * 17 * 16);
	}
}
