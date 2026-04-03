namespace Sedulous.Animation.Tests;

using System;

class BoneMaskTests
{
	[Test]
	public static void Constructor_DefaultWeight_AllBonesSet()
	{
		let mask = scope BoneMask(4, 1.0f);
		Test.Assert(mask.BoneCount == 4);
		Test.Assert(mask.GetWeight(0) == 1.0f);
		Test.Assert(mask.GetWeight(1) == 1.0f);
		Test.Assert(mask.GetWeight(2) == 1.0f);
		Test.Assert(mask.GetWeight(3) == 1.0f);
	}

	[Test]
	public static void Constructor_ZeroWeight_AllBonesZero()
	{
		let mask = scope BoneMask(3, 0.0f);
		Test.Assert(mask.GetWeight(0) == 0.0f);
		Test.Assert(mask.GetWeight(1) == 0.0f);
		Test.Assert(mask.GetWeight(2) == 0.0f);
	}

	[Test]
	public static void SetWeight_UpdatesSingleBone()
	{
		let mask = scope BoneMask(4, 0.0f);
		mask.SetWeight(2, 0.75f);

		Test.Assert(mask.GetWeight(0) == 0.0f);
		Test.Assert(mask.GetWeight(1) == 0.0f);
		Test.Assert(mask.GetWeight(2) == 0.75f);
		Test.Assert(mask.GetWeight(3) == 0.0f);
	}

	[Test]
	public static void SetWeight_Clamps_ToRange()
	{
		let mask = scope BoneMask(2, 0.5f);
		mask.SetWeight(0, 2.0f);  // above max
		mask.SetWeight(1, -1.0f); // below min

		Test.Assert(mask.GetWeight(0) == 1.0f);
		Test.Assert(mask.GetWeight(1) == 0.0f);
	}

	[Test]
	public static void SetAll_SetsAllBones()
	{
		let mask = scope BoneMask(4, 0.0f);
		mask.SetAll(0.5f);

		Test.Assert(mask.GetWeight(0) == 0.5f);
		Test.Assert(mask.GetWeight(1) == 0.5f);
		Test.Assert(mask.GetWeight(2) == 0.5f);
		Test.Assert(mask.GetWeight(3) == 0.5f);
	}

	[Test]
	public static void SetAll_Clamps()
	{
		let mask = scope BoneMask(2, 0.0f);
		mask.SetAll(5.0f);
		Test.Assert(mask.GetWeight(0) == 1.0f);
	}

	[Test]
	public static void GetWeight_OutOfRange_ReturnsZero()
	{
		let mask = scope BoneMask(2, 1.0f);
		Test.Assert(mask.GetWeight(-1) == 0.0f);
		Test.Assert(mask.GetWeight(5) == 0.0f);
	}

	[Test]
	public static void SetWeight_OutOfRange_DoesNothing()
	{
		let mask = scope BoneMask(2, 0.5f);
		mask.SetWeight(-1, 1.0f);
		mask.SetWeight(10, 1.0f);

		// Original values unchanged
		Test.Assert(mask.GetWeight(0) == 0.5f);
		Test.Assert(mask.GetWeight(1) == 0.5f);
	}

	[Test]
	public static void Weights_Span_MatchesGetWeight()
	{
		let mask = scope BoneMask(3, 0.0f);
		mask.SetWeight(0, 0.1f);
		mask.SetWeight(1, 0.5f);
		mask.SetWeight(2, 0.9f);

		let weights = mask.Weights;
		Test.Assert(weights.Length == 3);
		Test.Assert(weights[0] == 0.1f);
		Test.Assert(weights[1] == 0.5f);
		Test.Assert(weights[2] == 0.9f);
	}
}
