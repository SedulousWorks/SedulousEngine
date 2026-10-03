using System;
using System.Collections;
using Sedulous.Image;
using Sedulous.Editor.Core;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene.Tests;

/// The thumbnail stage renders into a float target, which holds LINEAR values since the
/// tonemap encodes for display once. Its downscale averages in linear light and then encodes,
/// so a thumbnail is neither too dark (linear written as bytes) nor averaged in the wrong space.
class ThumbnailDownscaleTests
{
	private const uint16 cHalfOne = 0x3C00;
	private const uint16 cHalfHalf = 0x3800;

	/// A source the size the stage renders at, every texel set by a function of its column.
	private static void Source(List<uint16> outTexels, uint32 size, delegate uint16(uint32 x, int channel) value)
	{
		outTexels.Clear();
		for (uint32 y < size)
			for (uint32 x < size)
				for (int c < 4)
					outTexels.Add(value(x, c));
	}

	[Test]
	public static void ALinearSourceIsEncodedAndAveragedInLinearLight()
	{
		let size = ThumbnailService.cThumbnailSize * ThumbnailStage.cSupersample;
		let texels = scope List<uint16>();
		let tile = scope Image(ThumbnailService.cThumbnailSize, ThumbnailService.cThumbnailSize, .RGBA8);

		// Linear half grey, half alpha: the colour encodes (0.5 is 188), the coverage does not.
		Source(texels, size, scope (x, c) => cHalfHalf);
		ThumbnailStage.Downscale((uint8*)texels.Ptr, size * 8, tile);
		let p = tile.PixelData.Ptr;
		Test.Assert((p[0] == 188) && (p[1] == 188) && (p[2] == 188), scope $"grey encoded ({p[0]})");
		Test.Assert(p[3] == 128, scope $"alpha linear ({p[3]})");

		// Alternating black and white columns average to linear 0.5 before encoding: 188, where
		// averaging encoded values would give 128.
		Source(texels, size, scope (x, c) => (c == 3) ? cHalfOne : (((x % 2) == 0) ? cHalfOne : 0));
		ThumbnailStage.Downscale((uint8*)texels.Ptr, size * 8, tile);
		Test.Assert(tile.PixelData.Ptr[0] == 188, scope $"averaged in linear light ({tile.PixelData.Ptr[0]})");
	}
}
