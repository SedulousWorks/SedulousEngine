namespace Sedulous.Animation.Tests;

using System;

class AnimationLayerTests
{
	[Test]
	public static void AddState_ReturnsSequentialIndices()
	{
		let layer = scope AnimationLayer("Base");
		let idx0 = layer.AddState(new AnimationGraphState("Idle", null));
		let idx1 = layer.AddState(new AnimationGraphState("Walk", null));
		let idx2 = layer.AddState(new AnimationGraphState("Run", null));

		Test.Assert(idx0 == 0);
		Test.Assert(idx1 == 1);
		Test.Assert(idx2 == 2);
		Test.Assert(layer.States.Count == 3);
	}

	[Test]
	public static void GetState_ValidIndex_ReturnsState()
	{
		let layer = scope AnimationLayer("Base");
		layer.AddState(new AnimationGraphState("Idle", null));
		layer.AddState(new AnimationGraphState("Walk", null));

		let state = layer.GetState(1);
		Test.Assert(state != null);
		Test.Assert(StringView.Compare(state.Name, "Walk", false) == 0);
	}

	[Test]
	public static void GetState_InvalidIndex_ReturnsNull()
	{
		let layer = scope AnimationLayer("Base");
		Test.Assert(layer.GetState(0) == null);
		Test.Assert(layer.GetState(-1) == null);
		Test.Assert(layer.GetState(100) == null);
	}

	[Test]
	public static void AddTransition_IncreasesCount()
	{
		let layer = scope AnimationLayer("Base");
		layer.AddTransition(new AnimationGraphTransition());
		layer.AddTransition(new AnimationGraphTransition());

		Test.Assert(layer.Transitions.Count == 2);
	}

	[Test]
	public static void DefaultValues_AreCorrect()
	{
		let layer = scope AnimationLayer("Test");

		Test.Assert(StringView.Compare(layer.Name, "Test", false) == 0);
		Test.Assert(layer.DefaultStateIndex == 0);
		Test.Assert(layer.BlendMode == .Override);
		Test.Assert(layer.Weight == 1.0f);
		Test.Assert(layer.Mask == null);
		Test.Assert(layer.OwnsMask == false);
	}

	[Test]
	public static void BlendMode_CanBeSetToAdditive()
	{
		let layer = scope AnimationLayer("Overlay");
		layer.BlendMode = .Additive;
		Test.Assert(layer.BlendMode == .Additive);
	}

	[Test]
	public static void Weight_CanBeAdjusted()
	{
		let layer = scope AnimationLayer("Upper");
		layer.Weight = 0.5f;
		Test.Assert(layer.Weight == 0.5f);
	}

	[Test]
	public static void Mask_CanBeAssigned()
	{
		let layer = scope AnimationLayer("Upper");
		let mask = new BoneMask(4, 0.0f);
		mask.SetWeight(0, 1.0f);
		layer.Mask = mask;
		layer.OwnsMask = true;

		Test.Assert(layer.Mask != null);
		Test.Assert(layer.Mask.GetWeight(0) == 1.0f);
		Test.Assert(layer.Mask.GetWeight(1) == 0.0f);
	}
}
