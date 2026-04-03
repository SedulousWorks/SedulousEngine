namespace Sedulous.Animation.Tests;

using System;
using Sedulous.Core.Mathematics;

class BlendTree2DTests
{
	[Test]
	public static void AddEntry_Vector2_IncreasesCount()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(.(0, 0), null);
		tree.AddEntry(.(1, 0), null);
		tree.AddEntry(.(0, 1), null);

		Test.Assert(tree.Entries.Count == 3);
	}

	[Test]
	public static void AddEntry_FloatXY_IncreasesCount()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(0.0f, 0.0f, null);
		tree.AddEntry(1.0f, 0.0f, null);

		Test.Assert(tree.Entries.Count == 2);
		Test.Assert(tree.Entries[0].Position.X == 0.0f);
		Test.Assert(tree.Entries[1].Position.X == 1.0f);
	}

	[Test]
	public static void Parameters_DefaultToZero()
	{
		let tree = scope BlendTree2D();
		Test.Assert(tree.ParameterX == 0.0f);
		Test.Assert(tree.ParameterY == 0.0f);
	}

	[Test]
	public static void Parameters_CanBeSet()
	{
		let tree = scope BlendTree2D();
		tree.ParameterX = 0.5f;
		tree.ParameterY = -0.3f;

		Test.Assert(tree.ParameterX == 0.5f);
		Test.Assert(tree.ParameterY == -0.3f);
	}

	[Test]
	public static void Duration_EmptyTree_ReturnsZero()
	{
		let tree = scope BlendTree2D();
		Test.Assert(tree.Duration == 0.0f);
	}

	[Test]
	public static void Duration_NullClips_ReturnsZero()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(0.0f, 0.0f, null);
		tree.AddEntry(1.0f, 0.0f, null);
		Test.Assert(tree.Duration == 0.0f);
	}

	[Test]
	public static void Evaluate_EmptyTree_DoesNotCrash()
	{
		let tree = scope BlendTree2D();
		BoneTransform[4] poses = .();
		tree.Evaluate(null, 0.0f, poses);
	}

	[Test]
	public static void Evaluate_NullSkeleton_DoesNotCrash()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(0.0f, 0.0f, null);
		BoneTransform[4] poses = .();
		tree.Evaluate(null, 0.0f, poses);
	}

	[Test]
	public static void EntryPositions_StoreCorrectly()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(.(-1.0f, 2.5f), null);

		Test.Assert(tree.Entries[0].Position.X == -1.0f);
		Test.Assert(tree.Entries[0].Position.Y == 2.5f);
	}
}
