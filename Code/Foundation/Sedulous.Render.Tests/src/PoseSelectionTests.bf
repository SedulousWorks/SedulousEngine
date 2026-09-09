using System;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// How a skinned instance picks its pose out of the shared palettes.
class PoseSelectionTests
{
	[Test]
	public static void SequentialWalksThePalettes()
	{
		for (uint32 i = 0; i < 12; i++)
			Test.Assert(PoseSelection.SelectPose(.Sequential, i, 4, null) == (i % 4));
	}

	/// No palettes at all answers the first one rather than dividing by nothing.
	[Test]
	public static void NoPalettesAnswersZero()
	{
		Test.Assert(PoseSelection.SelectPose(.Sequential, 5, 0, null) == 0);
		Test.Assert(PoseSelection.SelectPose(.Hashed, 5, 0, null) == 0);
		Test.Assert(PoseSelection.SelectPose(.Explicit, 5, 0, null) == 0);
	}

	/// Hashing is deterministic, within range, and NOT the identity: a crowd whose poses
	/// followed the instance order would march in step, which is exactly what it is for.
	[Test]
	public static void HashingScattersWithoutFollowingTheIndex()
	{
		var identical = 0;
		for (uint32 i = 0; i < 64; i++)
		{
			let pose = PoseSelection.SelectPose(.Hashed, i, 8, null);
			Test.Assert(pose < 8);
			Test.Assert(PoseSelection.SelectPose(.Hashed, i, 8, null) == pose, "deterministic");

			if (pose == (i % 8))
				identical++;
		}

		Test.Assert(identical < 40, "it does not track the sequential map");
	}

	[Test]
	public static void ExplicitUsesTheCallersArray()
	{
		var indices = uint32[4](3, 1, 9, 0);

		Test.Assert(PoseSelection.SelectPose(.Explicit, 0, 4, &indices[0]) == 3);
		Test.Assert(PoseSelection.SelectPose(.Explicit, 1, 4, &indices[0]) == 1);
		Test.Assert(PoseSelection.SelectPose(.Explicit, 2, 4, &indices[0]) == 1, "wrapped into range");
		Test.Assert(PoseSelection.SelectPose(.Explicit, 3, 4, &indices[0]) == 0);
	}

	/// An explicit policy with NO array degrades to hashing rather than reading past the end
	/// of one, which is what extraction leaves when the caller's array was the wrong size.
	[Test]
	public static void ExplicitWithoutAnArrayFallsBackToHashing()
	{
		for (uint32 i = 0; i < 16; i++)
		{
			Test.Assert(PoseSelection.SelectPose(.Explicit, i, 6, null)
				== PoseSelection.SelectPose(.Hashed, i, 6, null));
		}
	}

	/// A whole column shares a phase, and the columns step: a formation.
	[Test]
	public static void ColumnPosesAreConstantDownAColumn()
	{
		for (uint32 row = 0; row < 5; row++)
			Test.Assert(PoseSelection.ColumnPose(2, 4) == PoseSelection.ColumnPose(2, 4));

		Test.Assert(PoseSelection.ColumnPose(0, 4) != PoseSelection.ColumnPose(1, 4));
		Test.Assert(PoseSelection.ColumnPose(4, 4) == PoseSelection.ColumnPose(0, 4), "it wraps");
	}

	/// A wave is equal along the anti diagonals and steps across them.
	[Test]
	public static void WavePosesAreEqualAlongAnAntiDiagonal()
	{
		Test.Assert(PoseSelection.WavePose(0, 3, 8) == PoseSelection.WavePose(3, 0, 8));
		Test.Assert(PoseSelection.WavePose(1, 2, 8) == PoseSelection.WavePose(2, 1, 8));
		Test.Assert(PoseSelection.WavePose(0, 0, 8) != PoseSelection.WavePose(1, 0, 8));
	}

	/// A cell shares a phase, and neighbouring cells do not: the crowd clusters rather than
	/// banding.
	[Test]
	public static void ClusterPosesAreConstantWithinACell()
	{
		let inCell = PoseSelection.ClusterPose(0, 0, 4, 8);
		Test.Assert(PoseSelection.ClusterPose(1, 1, 4, 8) == inCell);
		Test.Assert(PoseSelection.ClusterPose(3, 3, 4, 8) == inCell);

		// Every pose stays in range whichever cell it lands in.
		for (uint32 column = 0; column < 16; column++)
		{
			for (uint32 row = 0; row < 16; row++)
				Test.Assert(PoseSelection.ClusterPose(column, row, 4, 8) < 8);
		}
	}
}
