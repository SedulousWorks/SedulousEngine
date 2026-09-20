using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain.Tests;

/// The splatmap thumbnail: the raw payload path, one hue per dominant slot.
class SplatmapThumbnailTests
{
	private static uint32 TexelAt(Image tile, uint32 x, uint32 y)
	{
		let px = tile.PixelData;
		let p = ((int)y * (int)tile.Width + (int)x) * 4;
		return ((uint32)px[p] << 16) | ((uint32)px[p + 1] << 8) | (uint32)px[p + 2];
	}

	[Test]
	public static void GivesEachDominantSlotADistinctHue()
	{
		const uint32 side = 32;
		let payload = scope List<uint8>();
		SplatmapThumbnailGenerator.WriteRawHeader(payload, side, side);
		for (uint32 y < side)
		{
			for (uint32 x < side)
			{
				let slot = ((x < side / 2) ? 0u : 1u) + ((y < side / 2) ? 0u : 2u); // one slot per quadrant
				for (uint32 k < 4)
					payload.Add((k == slot) ? 255 : 0);
			}
		}
		let generator = scope SplatmapThumbnailGenerator();
		let names = scope List<StringView>();
		generator.AssetTypeNames(names);
		Test.Assert((names.Count == 1) && (names[0] == "SplatmapAsset"));
		let tile = scope Image();
		Test.Assert(generator.Generate(payload, tile) case .Ok);
		Test.Assert(tile.Width == ThumbnailService.cThumbnailSize);
		Test.Assert(tile.Height == ThumbnailService.cThumbnailSize);
		uint32[4] quadrant = .(TexelAt(tile, 32, 32), TexelAt(tile, 96, 32), TexelAt(tile, 32, 96), TexelAt(tile, 96, 96));
		for (int i < 4)
		{
			for (int j = i + 1; j < 4; j++)
				Test.Assert(quadrant[i] != quadrant[j]);
		}
	}

	[Test]
	public static void ATruncatedRawPayloadIsRefused()
	{
		let payload = scope List<uint8>();
		SplatmapThumbnailGenerator.WriteRawHeader(payload, 4, 4);
		payload.Add(0); // far short of the sixty four bytes four by four needs
		let tile = scope Image();
		Test.Assert(scope SplatmapThumbnailGenerator().Generate(payload, tile) case .Err);
	}
}
