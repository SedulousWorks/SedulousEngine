using System;
using Sedulous.Core;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Vegetation.Resource.Tests;

/// The painted mask: its planes and bounds, the brush operations, and the cooked round trip.
class VegetationMaskTests
{
	private static bool Near(float a, float b, float epsilon = 0.005f) => Math.Abs(a - b) <= epsilon;

	[Test]
	public static void AFreshMaskIsEmptyEverywhereAndBoundsChecked()
	{
		let mask = scope VegetationMask(16, 8, 3);
		Test.Assert(!mask.IsEmpty);
		Test.Assert(mask.Width == 16);
		Test.Assert(mask.Height == 8);
		Test.Assert(mask.PlaneCount == 3);
		Test.Assert(mask.Densities.Length == 16 * 8 * 3);
		Test.Assert(mask.Plane(2).Length == 128);
		Test.Assert(mask.Plane(3).IsEmpty); // out of range

		for (uint32 p = 0; p < 3; p++)
		{
			Test.Assert(mask.DensityAt(p, 5, 5) == 0);
			Test.Assert(mask.ShareAt(p, 0.3f, 0.7f) == 0.0f);
		}
		Test.Assert(mask.DensityAt(9, 0, 0) == 0);
		Test.Assert(mask.DensityAt(0, -1, 0) == 0);
		Test.Assert(mask.DensityAt(0, 16, 0) == 0);

		mask.SetDensity(1, 3, 2, 200);
		Test.Assert(mask.DensityAt(1, 3, 2) == 200);
		Test.Assert(mask.DensityAt(0, 3, 2) == 0); // another plane is untouched
		mask.SetDensity(7, 0, 0, 9); // out of range: ignored
		Test.Assert(Near(mask.ShareAt(1, 3.0f / 15.0f, 2.0f / 7.0f), 200.0f / 255.0f));

		let none = scope VegetationMask();
		Test.Assert(none.IsEmpty);
		Test.Assert(none.Plane(0).IsEmpty);

		// The plane count is clamped to the cap, and nought means one.
		Test.Assert(scope VegetationMask(2, 2, 0).PlaneCount == 1);
		Test.Assert(scope VegetationMask(2, 2, 99).PlaneCount == VegetationMask.cMaxPlanes);
	}

	[Test]
	public static void PaintingRaisesThePlaneConvergesAndReportsTheRegion()
	{
		let mask = scope VegetationMask(32, 32, 2);
		let v0 = mask.Version;
		let r = MaskBrush.Paint(mask, 0, 0.5f, 0.5f, 0.25f, 0.25f, 0.5f);
		Test.Assert(!r.IsEmpty);
		Test.Assert(mask.Version == v0 + 1);
		Test.Assert(r.MinX >= 7);
		Test.Assert(r.MaxX <= 24);
		Test.Assert(r.MinY >= 7);
		Test.Assert(r.MaxY <= 24);

		let centre = mask.DensityAt(0, 16, 16);
		// Half strength over the flat core.
		Test.Assert((centre >= 127) && (centre <= 129));
		Test.Assert(mask.DensityAt(0, 2, 2) == 0); // outside the disc
		Test.Assert(mask.DensityAt(0, 16, 16) != 0);
		Test.Assert(mask.DensityAt(1, 16, 16) == 0); // the other plane
		// The cosine skirt grades toward the rim.
		Test.Assert(mask.DensityAt(0, 16, 9) < centre);
		Test.Assert(mask.DensityAt(0, 16, 9) > 0);

		// Repeated full strength painting converges at the core.
		for (int i < 4)
			MaskBrush.Paint(mask, 0, 0.5f, 0.5f, 0.25f, 0.25f, 1.0f);
		Test.Assert(mask.DensityAt(0, 16, 16) == 255);

		// A saturated stamp changes nothing: an empty region and no version bump.
		let v1 = mask.Version;
		let again = MaskBrush.Paint(mask, 0, 0.5f, 0.5f, 0.02f, 0.02f, 1.0f);
		Test.Assert(again.IsEmpty);
		Test.Assert(mask.Version == v1);

		// A plane out of range, no amount or no radius are all no ops.
		Test.Assert(MaskBrush.Paint(mask, 5, 0.5f, 0.5f, 0.25f, 0.25f, 1.0f).IsEmpty);
		Test.Assert(MaskBrush.Paint(mask, 1, 0.5f, 0.5f, 0.25f, 0.25f, 0.0f).IsEmpty);
		Test.Assert(MaskBrush.Paint(mask, 1, 0.5f, 0.5f, 0.0f, 0.25f, 1.0f).IsEmpty);
		Test.Assert(mask.DensityAt(1, 16, 16) == 0);
	}

	[Test]
	public static void TheEraserFadesToZeroAndSmoothingFeathersAHardEdge()
	{
		let mask = scope VegetationMask(32, 32, 1);
		// A hard half: the left sixteen columns at full.
		for (int32 y = 0; y < 32; y++)
			for (int32 x = 0; x < 16; x++)
				mask.SetDensity(0, x, y, 255);

		let v0 = mask.Version;
		let s = MaskBrush.Smooth(mask, 0, 0.5f, 0.5f, 0.2f, 0.2f, 1.0f, 0.95f);
		Test.Assert(!s.IsEmpty);
		Test.Assert(mask.Version == v0 + 1);
		Test.Assert(mask.DensityAt(0, 15, 16) < 255); // the painted side softened
		Test.Assert(mask.DensityAt(0, 16, 16) > 0); // the empty side gained
		// Still ordered across the seam.
		Test.Assert(mask.DensityAt(0, 15, 16) > mask.DensityAt(0, 16, 16));
		Test.Assert(mask.DensityAt(0, 2, 16) == 255); // far from the brush: untouched
		Test.Assert(mask.DensityAt(0, 30, 16) == 0);

		// Smoothing a uniform region is a no op.
		Test.Assert(MaskBrush.Smooth(mask, 0, 0.1f, 0.1f, 0.05f, 0.05f, 1.0f).IsEmpty);

		// Erasing: half strength halves, and full strength reaches exactly nought.
		MaskBrush.Erase(mask, 0, 0.25f, 0.5f, 0.1f, 0.1f, 0.5f, 0.95f);
		Test.Assert(mask.DensityAt(0, 8, 16) == 128);
		for (int i < 3)
			MaskBrush.Erase(mask, 0, 0.25f, 0.5f, 0.1f, 0.1f, 1.0f, 0.95f);
		Test.Assert(mask.DensityAt(0, 8, 16) == 0);

		Test.Assert(MaskBrush.Erase(mask, 3, 0.25f, 0.5f, 0.1f, 0.1f, 1.0f).IsEmpty);
	}

	[Test]
	public static void TheCookedSourceRoundTripsEveryPlaneAndABadBlobIsEmpty()
	{
		let authored = scope VegetationMask(8, 4, 3);
		MaskBrush.Paint(authored, 1, 0.5f, 0.5f, 0.4f, 0.4f, 1.0f);
		MaskBrush.Paint(authored, 2, 0.2f, 0.5f, 0.2f, 0.4f, 0.5f);

		let src = scope VegetationMaskSource();
		VegetationMaskSource.FromMask(authored, src);
		Test.Assert(src.Width == 8);
		Test.Assert(src.Height == 4);
		Test.Assert(src.PlaneCount == 3);

		let blob = VegetationMaskSource.DensityBlob(authored);
		Test.Assert(blob.Length == 8 * 4 * 3);

		let loaded = src.Build(blob);
		defer delete loaded;
		Test.Assert(loaded != null);
		Test.Assert(loaded.PlaneCount == 3);
		for (uint32 p = 0; p < 3; p++)
			for (int32 y = 0; y < 4; y++)
				for (int32 x = 0; x < 8; x++)
					Test.Assert(loaded.DensityAt(p, x, y) == authored.DensityAt(p, x, y));
		Test.Assert(loaded.Uid != authored.Uid); // a fresh object

		// A size mismatch or bad dimensions give an EMPTY mask, never a malformed one.
		let short = src.Build(.(blob.Ptr, blob.Length - 1));
		defer delete short;
		Test.Assert(short.IsEmpty);

		let bad = scope VegetationMaskSource();
		VegetationMaskSource.FromMask(authored, bad);
		bad.PlaneCount = 0;
		let noPlanes = bad.Build(blob);
		defer delete noPlanes;
		Test.Assert(noPlanes.IsEmpty);

		VegetationMaskSource.FromMask(authored, bad);
		bad.Width = -1;
		let noDims = bad.Build(blob);
		defer delete noDims;
		Test.Assert(noDims.IsEmpty);

		// The stream name is the sidecar contract the builder and the editor persist share.
		Test.Assert(VegetationMaskSource.DensityStream == "densities");
	}
}
