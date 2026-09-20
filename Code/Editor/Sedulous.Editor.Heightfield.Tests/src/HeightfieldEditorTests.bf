using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Heightfield.Tests;

/// The heightfield editor's registration, its undo snapshot and its thumbnail.
class HeightfieldEditorTests
{
	[Test]
	public static void TheFactoryReportsTheHeightfieldAssetPrimaryType()
	{
		let factory = scope HeightfieldEditorPageFactory();
		Test.Assert(factory.PrimaryType == typeof(HeightfieldAsset));
	}

	[Test]
	public static void RegisteringRoutesHeightfieldAssetToTheFactory()
	{
		let context = scope EditorContext();
		HeightfieldEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(HeightfieldAsset));
		Test.Assert(found != null);
		Test.Assert(found.PrimaryType == typeof(HeightfieldAsset));
	}

	[Test]
	public static void TheSnapshotRoundTripsTheAuthoredFields()
	{
		HeightfieldPipeline.RegisterAll();
		let a = scope HeightfieldAsset();
		a.FileName.Set("Terrain/island.png");
		a.Size = 513;
		a.WorldSize = .(512.0f, 512.0f);
		a.MinY = -8.0f;
		a.MaxY = 96.0f;
		let blob = scope List<uint8>();
		HeightfieldAssetEdit.Snapshot(a, blob);
		let b = scope HeightfieldAsset();
		Test.Assert(HeightfieldAssetEdit.Apply(b, blob));
		Test.Assert(b.FileName.Value == "Terrain/island.png");
		Test.Assert(b.Size == 513);
		Test.Assert(b.WorldSize.X == 512.0f);
		Test.Assert((b.MinY == -8.0f) && (b.MaxY == 96.0f));
		Test.Assert(!HeightfieldAssetEdit.Apply(b, blob));
	}

	[Test]
	public static void TheThumbnailNormalizesALowReliefGradientToTheFullRamp()
	{
		const uint32 side = 64;
		let payload = scope List<uint8>();
		HeightfieldThumbnailGenerator.WriteRawHeader(payload, side);
		for (uint32 y < side)
		{
			for (uint32 x < side)
			{
				let sample = (uint16)(1000 + y * 8);
				payload.Add((uint8)(sample & 0xff));
				payload.Add((uint8)(sample >> 8));
			}
		}
		let generator = scope HeightfieldThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(payload, tile) case .Ok);
		Test.Assert(tile.Width == ThumbnailService.cThumbnailSize);
		let px = tile.PixelData;
		let lastRow = (int)(tile.Height - 1) * (int)tile.Width * 4;
		Test.Assert(px[0] <= 8); // the top of the ramp normalises to black
		Test.Assert(px[lastRow] >= 247); // the bottom to white
		Test.Assert(px[3] == 255);
	}

	[Test]
	public static void TheThumbnailRejectsATruncatedPayload()
	{
		let payload = scope List<uint8>();
		HeightfieldThumbnailGenerator.WriteRawHeader(payload, 64);
		payload.Add(0); // far too few samples
		let generator = scope HeightfieldThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(payload, tile) case .Err);
	}
}
