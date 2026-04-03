namespace Sedulous.Animation.Tests;

using System;

class BlendTree1DTests
{
	[Test]
	public static void AddEntry_SortsByThreshold()
	{
		let tree = scope BlendTree1D();
		tree.AddEntry(1.0f, null);
		tree.AddEntry(0.0f, null);
		tree.AddEntry(0.5f, null);

		Test.Assert(tree.Entries.Count == 3);
		Test.Assert(tree.Entries[0].Threshold == 0.0f);
		Test.Assert(tree.Entries[1].Threshold == 0.5f);
		Test.Assert(tree.Entries[2].Threshold == 1.0f);
	}

	[Test]
	public static void AddEntry_AppendWhenAlreadySorted()
	{
		let tree = scope BlendTree1D();
		tree.AddEntry(0.0f, null);
		tree.AddEntry(0.5f, null);
		tree.AddEntry(1.0f, null);

		Test.Assert(tree.Entries.Count == 3);
		Test.Assert(tree.Entries[0].Threshold == 0.0f);
		Test.Assert(tree.Entries[1].Threshold == 0.5f);
		Test.Assert(tree.Entries[2].Threshold == 1.0f);
	}

	[Test]
	public static void Duration_EmptyTree_ReturnsZero()
	{
		let tree = scope BlendTree1D();
		Test.Assert(tree.Duration == 0.0f);
	}

	[Test]
	public static void Duration_NullClips_ReturnsZero()
	{
		let tree = scope BlendTree1D();
		tree.AddEntry(0.0f, null);
		tree.AddEntry(1.0f, null);
		Test.Assert(tree.Duration == 0.0f);
	}

	[Test]
	public static void Parameter_DefaultsToZero()
	{
		let tree = scope BlendTree1D();
		Test.Assert(tree.Parameter == 0.0f);
	}

	[Test]
	public static void Parameter_CanBeSet()
	{
		let tree = scope BlendTree1D();
		tree.Parameter = 0.75f;
		Test.Assert(tree.Parameter == 0.75f);
	}

	[Test]
	public static void Evaluate_EmptyTree_DoesNotCrash()
	{
		let tree = scope BlendTree1D();
		BoneTransform[4] poses = .();
		tree.Evaluate(null, 0.0f, poses);
		// Just verifying no crash
	}

	[Test]
	public static void AddEntry_DuplicateThresholds_BothAdded()
	{
		let tree = scope BlendTree1D();
		tree.AddEntry(0.5f, null);
		tree.AddEntry(0.5f, null);

		Test.Assert(tree.Entries.Count == 2);
	}
}
