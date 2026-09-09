using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Terrain.Resource;

namespace Sedulous.Terrain.Resource.Tests;

/// The top four splat model and the brushes over it.
class SplatWeightsTests
{
	/// What the slots hold at a texel, which with the base always comes to 255.
	private static int SlotSum(SplatWeights weights, int32 x, int32 y)
	{
		var sum = 0;
		for (uint32 k < SplatWeights.SlotCount)
			sum += (int)weights.SlotWeight(x, y, k);
		return sum;
	}

	/// Authors a texel directly as one layer at full weight.
	private static void SetOneHot(SplatWeights weights, int32 x, int32 y, uint8 layer)
	{
		let at = weights.TexelOffset(x, y);
		weights.Indices[at] = layer;
		weights.Weights[at] = 255;
	}

	/// Convexity: nothing the brush touched can hold more than a whole texel's worth.
	private static void AssertConvex(SplatWeights weights, SplatRegion region)
	{
		for (int32 y = region.MinY; y <= region.MaxY; y++)
		{
			for (int32 x = region.MinX; x <= region.MaxX; x++)
				Test.Assert(SlotSum(weights, x, y) <= 255, scope $"texel {x},{y} exceeds one");
		}
	}

	/// An ALL ZERO raster is a valid pure base surface, so a fresh one needs no seeding.
	[Test]
	public static void AFreshRasterIsPureBase()
	{
		let weights = scope SplatWeights(8, 8);

		Test.Assert(!weights.IsEmpty);
		Test.Assert(weights.Version == 1);
		Test.Assert(weights.BaseWeight(4, 4) == 255);
		Test.Assert(SlotSum(weights, 4, 4) == 0);
	}

	[Test]
	public static void AnEmptyRasterIsInert()
	{
		let weights = scope SplatWeights();

		Test.Assert(weights.IsEmpty);
		Test.Assert(SplatBrush.Paint(weights, 0.5f, 0.5f, 0.5f, 0.5f, 1, 1.0f).IsEmpty);
		Test.Assert(SplatBrush.Erase(weights, 0.5f, 0.5f, 0.5f, 0.5f, 1.0f).IsEmpty);
		Test.Assert(SplatBrush.Smooth(weights, 0.5f, 0.5f, 0.5f, 0.5f, 1.0f).IsEmpty);
		Test.Assert(!SplatBrush.RemapOnPaletteRemove(weights, 0));
		Test.Assert(weights.Version == 1);
	}

	/// Every raster has its OWN identity, which is what the GPU cache keys on beside the
	/// version.
	[Test]
	public static void EveryRasterHasItsOwnIdentity()
	{
		let first = scope SplatWeights(4, 4);
		let second = scope SplatWeights(4, 4);
		Test.Assert(first.Uid != second.Uid);
	}

	[Test]
	public static void PaintingRaisesTheLayerAndStaysConvex()
	{
		let weights = scope SplatWeights(32, 32);
		let version = weights.Version;

		let region = SplatBrush.Paint(weights, 0.5f, 0.5f, 0.25f, 0.25f, 7, 0.6f);

		Test.Assert(!region.IsEmpty);
		Test.Assert(weights.Version > version);
		Test.Assert(weights.WeightOfLayer(16, 16, 7) > 100);
		// The base is exactly what the slots left over.
		Test.Assert(weights.BaseWeight(16, 16) == 255 - SlotSum(weights, 16, 16));
		AssertConvex(weights, region);
		Test.Assert(SlotSum(weights, 0, 0) == 0, "outside the rectangle, untouched");
	}

	/// Repeated full strength painting drives a texel to the ONE layer, which is what a
	/// stamp brush has to be able to reach.
	[Test]
	public static void RepeatedFullStrengthPaintingConverges()
	{
		let weights = scope SplatWeights(8, 8);
		for (int i < 24)
			SplatBrush.Paint(weights, 0.5f, 0.5f, 0.9f, 0.9f, 3, 1.0f);

		Test.Assert(weights.WeightOfLayer(4, 4, 3) == 255);
		Test.Assert(weights.BaseWeight(4, 4) == 0);
	}

	[Test]
	public static void PaintingASecondLayerFadesTheFirst()
	{
		let weights = scope SplatWeights(8, 8);
		for (int i < 24)
			SplatBrush.Paint(weights, 0.5f, 0.5f, 0.9f, 0.9f, 1, 1.0f);

		let before = weights.WeightOfLayer(4, 4, 1);
		Test.Assert(before == 255);

		SplatBrush.Paint(weights, 0.5f, 0.5f, 0.9f, 0.9f, 2, 0.5f);

		Test.Assert(weights.WeightOfLayer(4, 4, 1) < before);
		Test.Assert(weights.WeightOfLayer(4, 4, 2) > 0);
		Test.Assert(SlotSum(weights, 4, 4) <= 255);
	}

	/// A FIFTH layer evicts the smallest slot, since the error that costs is bounded by the
	/// weight that was least visible anyway.
	[Test]
	public static void AFifthLayerEvictsTheSmallestSlot()
	{
		let weights = scope SplatWeights(4, 4);

		// Four distinct layers at descending strengths.
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 10, 0.50f);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 11, 0.40f);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 12, 0.30f);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 13, 0.20f);
		Test.Assert(weights.WeightOfLayer(2, 2, 13) > 0);

		var smallestLayer = (uint32)10;
		var smallest = (uint8)255;
		for (uint32 layer = 10; layer <= 13; layer++)
		{
			let weight = weights.WeightOfLayer(2, 2, layer);
			if (weight < smallest)
			{
				smallest = weight;
				smallestLayer = layer;
			}
		}

		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 42, 0.6f);

		Test.Assert(weights.WeightOfLayer(2, 2, 42) > 0, "the new layer took a slot");
		Test.Assert(weights.WeightOfLayer(2, 2, smallestLayer) == 0, "the weakest one lost its");
		Test.Assert(SlotSum(weights, 2, 2) <= 255);
	}

	[Test]
	public static void ErasingFadesEverythingBackToBase()
	{
		let weights = scope SplatWeights(8, 8);
		for (int i < 10)
			SplatBrush.Paint(weights, 0.5f, 0.5f, 0.9f, 0.9f, 5, 1.0f);
		Test.Assert(weights.BaseWeight(4, 4) < 40);

		for (int i < 24)
			SplatBrush.Erase(weights, 0.5f, 0.5f, 0.9f, 0.9f, 1.0f);

		Test.Assert(weights.BaseWeight(4, 4) == 255);
		Test.Assert(SlotSum(weights, 4, 4) == 0);

		// A freed slot clears its index, so the top four keeps meaning the four largest.
		for (uint32 k < SplatWeights.SlotCount)
			Test.Assert(weights.SlotIndex(4, 4, k) == 0);
	}

	/// A brush that changes nothing does NOT bump the version: a re-upload for an edit that
	/// never happened is wasted bandwidth.
	[Test]
	public static void ABrushThatChangesNothingLeavesTheVersion()
	{
		let weights = scope SplatWeights(8, 8);
		let version = weights.Version;

		Test.Assert(SplatBrush.Erase(weights, 0.5f, 0.5f, 0.9f, 0.9f, 1.0f).IsEmpty,
			"erasing pure base changes nothing");
		Test.Assert(weights.Version == version);

		Test.Assert(SplatBrush.Paint(weights, 100.0f, 100.0f, 0.1f, 0.1f, 1, 1.0f).IsEmpty,
			"and a brush off the raster touches nothing");
		Test.Assert(weights.Version == version);
	}

	/// The brush core SCALES: at a low strength the tool shrinks the flat core, so coverage
	/// grades across the radius rather than converging a flat half against a thin skirt.
	[Test]
	public static void TheBrushCoreScales()
	{
		let hard = scope SplatWeights(32, 32);
		SplatBrush.Paint(hard, 0.5f, 0.5f, 0.25f, 0.25f, 1, 1.0f);

		let soft = scope SplatWeights(32, 32);
		SplatBrush.Paint(soft, 0.5f, 0.5f, 0.25f, 0.25f, 1, 1.0f, 0.0f);

		Test.Assert(hard.WeightOfLayer(16, 16, 1) == 255);
		Test.Assert(soft.WeightOfLayer(16, 16, 1) >= 250, "the cosine is about one at the centre");

		// A third of the way out, inside the default core.
		let hardMid = hard.WeightOfLayer(19, 16, 1);
		let softMid = soft.WeightOfLayer(19, 16, 1);
		Test.Assert(hardMid == 255, "flat inside the core");
		Test.Assert(softMid < 220, "and already grading without one");
		Test.Assert(softMid > 60, "graded, not cut off");
	}

	/// Removing a palette layer FREES the slots naming it and shifts the rest down, so every
	/// surviving slot still names the layer it meant.
	[Test]
	public static void RemovingAPaletteLayerRemapsTheRest()
	{
		let weights = scope SplatWeights(4, 4);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 0, 0.4f);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 1, 0.4f);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 2, 0.4f);

		let beforeTwo = weights.WeightOfLayer(2, 2, 2);
		let version = weights.Version;
		Test.Assert(beforeTwo > 0);

		Test.Assert(SplatBrush.RemapOnPaletteRemove(weights, 1));
		Test.Assert(weights.Version > version);

		Test.Assert(weights.WeightOfLayer(2, 2, 1) == beforeTwo, "layer two became layer one");
		Test.Assert(SlotSum(weights, 2, 2) <= 255);
		Test.Assert(weights.BaseWeight(2, 2) == 255 - SlotSum(weights, 2, 2),
			"the removed layer's weight fell to the base");
	}

	/// Removing a layer nothing paints changes nothing.
	[Test]
	public static void RemovingAnUnusedLayerChangesNothing()
	{
		let weights = scope SplatWeights(4, 4);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 0, 0.5f);
		let version = weights.Version;

		Test.Assert(!SplatBrush.RemapOnPaletteRemove(weights, 9));
		Test.Assert(weights.Version == version);
	}

	/// An imported raster whose channels drifted from a full 255 is RENORMALISED by the
	/// texel's own sum, so the shares are exact rather than dim.
	[Test]
	public static void TheImportRenormalisesByTheTexelSum()
	{
		// Sum 200, so the shares are a half to the base, three tenths and a fifth.
		let raster = scope List<uint8>();
		raster.Resize(4 * 4 * 4);
		for (int t < 16)
		{
			raster[t * 4 + 0] = 100;
			raster[t * 4 + 1] = 60;
			raster[t * 4 + 2] = 40;
			raster[t * 4 + 3] = 0;
		}

		let weights = SplatBrush.FromFixedLayerRaster(.(raster.Ptr, raster.Count), 4, 4);
		defer delete weights;

		Test.Assert(!weights.IsEmpty);
		Test.Assert(weights.WeightOfLayer(1, 1, 0) == 77, "three tenths of 255");
		Test.Assert(weights.WeightOfLayer(1, 1, 1) == 51, "and a fifth");
		Test.Assert(weights.WeightOfLayer(1, 1, 2) == 0);

		let base0 = weights.BaseWeight(1, 1);
		Test.Assert((base0 >= 126) && (base0 <= 128), scope $"half of 255, got {base0}");
	}

	[Test]
	public static void AnImportOfPureBaseStaysPureBase()
	{
		let raster = scope List<uint8>();
		raster.Resize(4 * 4 * 4);
		for (int t < 16)
			raster[t * 4 + 0] = 255;

		let weights = SplatBrush.FromFixedLayerRaster(.(raster.Ptr, raster.Count), 4, 4);
		defer delete weights;

		Test.Assert(weights.BaseWeight(2, 2) == 255);
		Test.Assert(SlotSum(weights, 2, 2) == 0);
	}

	/// A raster whose bytes do not match its stated size imports as EMPTY rather than as
	/// whatever the mismatch happened to leave.
	[Test]
	public static void AMismatchedImportIsEmpty()
	{
		let raster = scope List<uint8>();
		raster.Resize(10);

		let weights = SplatBrush.FromFixedLayerRaster(.(raster.Ptr, raster.Count), 4, 4);
		defer delete weights;
		Test.Assert(weights.IsEmpty);

		let zeroSized = SplatBrush.FromFixedLayerRaster(.(), 0, 0);
		defer delete zeroSized;
		Test.Assert(zeroSized.IsEmpty);
	}

	// ---- smoothing ----

	/// Smoothing an already uniform region is a NO OP, which is what says the average really
	/// is the average and not a drift.
	[Test]
	public static void SmoothingAUniformRegionChangesNothing()
	{
		let weights = scope SplatWeights(16, 16);
		for (int32 y < 16)
		{
			for (int32 x < 16)
				SetOneHot(weights, x, y, 3);
		}
		let version = weights.Version;

		let region = SplatBrush.Smooth(weights, 0.5f, 0.5f, 0.4f, 0.4f, 1.0f);

		Test.Assert(region.IsEmpty);
		Test.Assert(weights.Version == version);
		Test.Assert(weights.WeightOfLayer(8, 8, 3) == 255);
	}

	[Test]
	public static void SmoothingFeathersAHardEdgeBothWays()
	{
		let weights = scope SplatWeights(16, 16);
		// The left half one layer, the right half pure base.
		for (int32 y < 16)
		{
			for (int32 x < 8)
				SetOneHot(weights, x, y, 2);
		}
		let version = weights.Version;

		let region = SplatBrush.Smooth(weights, 0.5f, 0.5f, 0.45f, 0.45f, 1.0f);

		Test.Assert(!region.IsEmpty);
		Test.Assert(weights.Version > version);

		let atEdge = weights.WeightOfLayer(7, 8, 2);
		let bled = weights.WeightOfLayer(8, 8, 2);
		Test.Assert((atEdge < 255) && (atEdge > 0), "the painted edge faded");
		Test.Assert(bled > 0, "and the base beside it gained some");
		Test.Assert(bled < atEdge);

		Test.Assert(weights.WeightOfLayer(5, 8, 2) == 255, "deep inside, all painted");
		Test.Assert(weights.WeightOfLayer(11, 8, 2) == 0, "and deep outside, all base");
		AssertConvex(weights, region);
	}

	/// Where a neighbourhood holds MORE than four layers, the four largest win and the tail
	/// falls to the base: the same least visible error rule the paint eviction follows.
	[Test]
	public static void SmoothingAcrossManyLayersKeepsTheTopFour()
	{
		let weights = scope SplatWeights(8, 8);

		// Nine distinct one hot layers, so every neighbourhood union exceeds four.
		var layer = (uint8)10;
		for (int32 y = 3; y <= 5; y++)
		{
			for (int32 x = 3; x <= 5; x++)
				SetOneHot(weights, x, y, layer++);
		}

		let region = SplatBrush.Smooth(weights, 0.5625f, 0.5625f, 0.3f, 0.3f, 1.0f);
		Test.Assert(!region.IsEmpty);

		for (int32 y = region.MinY; y <= region.MaxY; y++)
		{
			for (int32 x = region.MinX; x <= region.MaxX; x++)
			{
				Test.Assert(SlotSum(weights, x, y) <= 255);
				for (uint32 k < SplatWeights.SlotCount)
				{
					if (weights.SlotWeight(x, y, k) == 0)
						Test.Assert(weights.SlotIndex(x, y, k) == 0, "a freed slot is cleared");
				}
			}
		}

		Test.Assert(SlotSum(weights, 4, 4) < 255, "the dropped tail fell to the base");
		Test.Assert(SlotSum(weights, 4, 4) > 0);
	}

	[Test]
	public static void SmoothingLeavesTexelsOutsideTheBrushAlone()
	{
		let weights = scope SplatWeights(32, 32);
		for (int32 y < 32)
		{
			for (int32 x < 16)
				SetOneHot(weights, x, y, 1);
		}

		let region = SplatBrush.Smooth(weights, 0.5f, 0.5f, 0.15f, 0.15f, 1.0f);

		Test.Assert(!region.IsEmpty);
		Test.Assert(region.MinX >= 10);
		Test.Assert(region.MaxX <= 21);
		Test.Assert(weights.WeightOfLayer(15, 2, 1) == 255, "the same edge, far up the raster");
		Test.Assert(weights.WeightOfLayer(16, 2, 1) == 0);
	}

	/// Smoothing reads a SNAPSHOT, so the pass is order independent: smoothing an edge and
	/// then its mirror image gives mirrored results rather than a smear in the scan's
	/// direction.
	[Test]
	public static void SmoothingIsOrderIndependent()
	{
		let leftPainted = scope SplatWeights(16, 16);
		let rightPainted = scope SplatWeights(16, 16);
		for (int32 y < 16)
		{
			for (int32 x < 8)
			{
				SetOneHot(leftPainted, x, y, 2);
				SetOneHot(rightPainted, (int32)15 - x, y, 2);
			}
		}

		SplatBrush.Smooth(leftPainted, 0.5f, 0.5f, 0.45f, 0.45f, 1.0f);
		SplatBrush.Smooth(rightPainted, 0.5f, 0.5f, 0.45f, 0.45f, 1.0f);

		for (int32 x < 16)
		{
			Test.Assert(leftPainted.WeightOfLayer(x, 8, 2)
				== rightPainted.WeightOfLayer((int32)15 - x, 8, 2),
				scope $"column {x} does not mirror");
		}
	}
}
