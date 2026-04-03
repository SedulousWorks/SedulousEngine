namespace Sedulous.Animation.Tests;

using System;

class AnimationGraphStateTests
{
	[Test]
	public static void Constructor_SetsNameAndNode()
	{
		let state = scope AnimationGraphState("Idle", null);
		Test.Assert(StringView.Compare(state.Name, "Idle", false) == 0);
		Test.Assert(state.Node == null);
	}

	[Test]
	public static void DefaultValues_AreCorrect()
	{
		let state = scope AnimationGraphState("Test", null);
		Test.Assert(state.Speed == 1.0f);
		Test.Assert(state.Loop == true);
		Test.Assert(state.OwnsNode == false);
	}

	[Test]
	public static void Duration_NullNode_ReturnsZero()
	{
		let state = scope AnimationGraphState("Empty", null);
		Test.Assert(state.Duration == 0.0f);
	}

	[Test]
	public static void Speed_CanBeAdjusted()
	{
		let state = scope AnimationGraphState("Walk", null);
		state.Speed = 2.0f;
		Test.Assert(state.Speed == 2.0f);
	}

	[Test]
	public static void Loop_CanBeDisabled()
	{
		let state = scope AnimationGraphState("Death", null);
		state.Loop = false;
		Test.Assert(state.Loop == false);
	}

	[Test]
	public static void ClipStateNode_NullClip_DurationZero()
	{
		let node = scope ClipStateNode(null);
		Test.Assert(node.Duration == 0.0f);
	}

	[Test]
	public static void OwnedNode_DeletedOnDestruction()
	{
		// Create a state that owns its node
		let node = new ClipStateNode(null);
		let state = new AnimationGraphState("Test", node, ownsNode: true);
		Test.Assert(state.OwnsNode == true);
		// Deleting state should delete the node without crashing
		delete state;
	}

	[Test]
	public static void NonOwnedNode_NotDeletedOnDestruction()
	{
		// Create a state that does NOT own its node
		let node = scope ClipStateNode(null);
		let state = new AnimationGraphState("Test", node, ownsNode: false);
		delete state;
		// node still valid since state didn't own it
		Test.Assert(node.Duration == 0.0f);
	}
}
