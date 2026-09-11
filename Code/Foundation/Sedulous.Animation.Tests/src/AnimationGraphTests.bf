using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The graph stack: masks, parameters, conditions, transitions, states, layers, the blend
/// trees, and the player that runs them.
class AnimationGraphTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void ABoneMaskClampsAndRefusesWhatItDoesNotKnow()
	{
		let mask = scope BoneMask(4, 1.0f);
		Test.Assert(mask.BoneCount == 4);
		Test.Assert(mask.GetWeight(0) == 1.0f);

		mask.SetWeight(2, 0.75f);
		Test.Assert(mask.GetWeight(2) == 0.75f);

		mask.SetWeight(0, 2.0f);
		Test.Assert(mask.GetWeight(0) == 1.0f, "clamped high");
		mask.SetWeight(1, -1.0f);
		Test.Assert(mask.GetWeight(1) == 0.0f, "clamped low");

		// A bone outside the mask weighs nothing, so a layer never reaches it.
		Test.Assert(mask.GetWeight(-1) == 0.0f);
		Test.Assert(mask.GetWeight(99) == 0.0f);

		let all = scope BoneMask(2, 0.0f);
		all.SetAll(5.0f);
		Test.Assert(all.GetWeight(0) == 1.0f, "setting them all clamps too");
	}

	/// Masking a bone masks everything BELOW it, which is how a limb is named by its root.
	[Test]
	public static void MaskingABoneChainFollowsTheHierarchy()
	{
		let skeleton = scope Skeleton(3);
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.Bones[2].ParentIndex = 1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();

		let mask = scope BoneMask(3, 0.0f);
		mask.SetBoneChainWeight(skeleton, 0, 1.0f);
		Test.Assert(mask.GetWeight(0) == 1.0f);
		Test.Assert(mask.GetWeight(1) == 1.0f);
		Test.Assert(mask.GetWeight(2) == 1.0f);
	}

	/// A TRIGGER clears itself once seen; a plain bool does not.
	[Test]
	public static void OnlyATriggerConsumesItself()
	{
		let speed = scope AnimationGraphParameter("Speed", .Float);
		Test.Assert(speed.FloatValue == 0.0f);
		Test.Assert(speed.Type == .Float);
		Test.Assert(speed.Name == "Speed");
		speed.FloatValue = 1.5f;
		Test.Assert(speed.FloatValue == 1.5f);

		let trigger = scope AnimationGraphParameter("Fire", .Trigger);
		trigger.BoolValue = true;
		trigger.ConsumeTrigger();
		Test.Assert(!trigger.BoolValue);

		let flag = scope AnimationGraphParameter("Flag", .Bool);
		flag.BoolValue = true;
		flag.ConsumeTrigger();
		Test.Assert(flag.BoolValue, "a bool is the caller's to clear");
	}

	[Test]
	public static void ConditionsCompareEveryParameterKind()
	{
		let speed = scope AnimationGraphParameter("Speed", .Float);
		speed.FloatValue = 0.5f;
		Test.Assert(AnimationGraphCondition(0, .Greater, 0.1f).Evaluate(speed));
		speed.FloatValue = 0.05f;
		Test.Assert(!AnimationGraphCondition(0, .Greater, 0.1f).Evaluate(speed));
		speed.FloatValue = 0.1f;
		Test.Assert(AnimationGraphCondition(0, .LessEqual, 0.1f).Evaluate(speed));
		speed.FloatValue = 1.0f;
		Test.Assert(AnimationGraphCondition(0, .Equal, 1.0f).Evaluate(speed));

		let level = scope AnimationGraphParameter("Level", .Int);
		level.IntValue = 5;
		Test.Assert(AnimationGraphCondition(0, .Greater, 3.0f).Evaluate(level));

		let grounded = scope AnimationGraphParameter("Grounded", .Bool);
		grounded.BoolValue = true;
		Test.Assert(AnimationGraphCondition(0, .Equal, 1.0f).Evaluate(grounded), "is true");
		grounded.BoolValue = false;
		Test.Assert(AnimationGraphCondition(0, .Equal, 0.0f).Evaluate(grounded), "is false");

		// A condition that cannot be evaluated must not let a transition through.
		Test.Assert(!AnimationGraphCondition(0, .Greater, 0.0f).Evaluate(null));
	}

	[Test]
	public static void ATransitionNeedsEveryConditionAndAValidIndex()
	{
		let parameters = scope List<AnimationGraphParameter>();
		parameters.Add(scope:: AnimationGraphParameter("Speed", .Float));
		parameters.Add(scope:: AnimationGraphParameter("Grounded", .Bool));
		parameters[0].FloatValue = 1.0f;
		parameters[1].BoolValue = true;

		let transition = scope AnimationGraphTransition();
		Test.Assert(transition.SourceStateIndex == -1, "any state by default");
		Test.Assert(transition.Duration == 0.25f);
		Test.Assert(transition.EvaluateConditions(parameters), "no conditions is unconditional");

		transition.AddFloatCondition(0, .Greater, 0.1f);
		transition.AddBoolCondition(1, true);
		Test.Assert(transition.EvaluateConditions(parameters), "both hold");

		parameters[1].BoolValue = false;
		Test.Assert(!transition.EvaluateConditions(parameters), "one fails, so all fail");

		let bad = scope AnimationGraphTransition();
		bad.AddFloatCondition(5, .Greater, 0.0f);
		Test.Assert(!bad.EvaluateConditions(parameters), "an index nothing answers to");
	}

	/// A state either OWNS its node or borrows it, and a borrowed one outlives the state.
	[Test]
	public static void AStateOwnsOrBorrowsItsNode()
	{
		let idle = scope AnimationGraphState("Idle", null);
		Test.Assert(idle.Name == "Idle");
		Test.Assert(idle.Node == null);
		Test.Assert(idle.Speed == 1.0f);
		Test.Assert(idle.Loop);
		Test.Assert(!idle.OwnsNode);
		Test.Assert(idle.Duration == 0.0f);

		{
			let owned = scope AnimationGraphState("Owned", new ClipStateNode(null), true);
			Test.Assert(owned.OwnsNode);
		}

		let node = scope ClipStateNode(null);
		{
			let borrow = scope AnimationGraphState("Borrow", node);
			Test.Assert(!borrow.OwnsNode);
		}
		Test.Assert(node.Duration == 0.0f, "it outlived the state that borrowed it");
	}

	[Test]
	public static void ALayerHoldsItsStatesTransitionsAndMask()
	{
		let layer = scope AnimationLayer("Base");
		Test.Assert(layer.Name == "Base");
		Test.Assert(layer.DefaultStateIndex == 0);
		Test.Assert(layer.BlendMode == .Override);
		Test.Assert(layer.Weight == 1.0f);
		Test.Assert(layer.Mask == null);

		Test.Assert(layer.AddState(new AnimationGraphState("Idle", null)) == 0);
		Test.Assert(layer.AddState(new AnimationGraphState("Walk", null)) == 1);
		Test.Assert(layer.States.Count == 2);
		Test.Assert(layer.GetState(1).Name == "Walk");
		Test.Assert(layer.GetState(-1) == null);
		Test.Assert(layer.GetState(99) == null);
		Test.Assert(layer.FindStateIndex("Walk") == 1);

		layer.AddTransition(new AnimationGraphTransition());
		Test.Assert(layer.Transitions.Count == 1);

		layer.SetMask(new BoneMask(4, 0.0f));
		layer.Mask.SetWeight(0, 1.0f);
		Test.Assert(layer.Mask.GetWeight(0) == 1.0f);
		Test.Assert(layer.Mask.GetWeight(1) == 0.0f);
	}

	[Test]
	public static void ABlendTree1DSortsItsEntriesAndSurvivesBeingEmpty()
	{
		let tree = scope BlendTree1D();
		tree.AddEntry(1.0f, null);
		tree.AddEntry(0.0f, null);
		tree.AddEntry(0.5f, null);

		Test.Assert(tree.Entries.Count == 3);
		Test.Assert(tree.Entries[0].Threshold == 0.0f);
		Test.Assert(tree.Entries[1].Threshold == 0.5f);
		Test.Assert(tree.Entries[2].Threshold == 1.0f);
		Test.Assert(tree.Parameter == 0.0f);
		Test.Assert(tree.Duration == 0.0f, "no clips, no duration");

		tree.AddEntry(0.5f, null);
		Test.Assert(tree.Entries.Count == 4, "a repeated threshold is allowed");

		let empty = scope Skeleton(0);
		let poses = scope BoneTransform[4];
		let blank = scope BlendTree1D();
		blank.Evaluate(empty, 0.0f, poses);
	}

	[Test]
	public static void ABlendTree2DKeepsItsEntriesWhereTheyWerePlaced()
	{
		let tree = scope BlendTree2D();
		tree.AddEntry(0.0f, 0.0f, null);
		tree.AddEntry(Float2(1, 0), null);
		tree.AddEntry(-1.0f, 2.5f, null);

		Test.Assert(tree.Entries.Count == 3);
		Test.Assert(tree.Entries[1].Position.X == 1.0f);
		Test.Assert(tree.Entries[2].Position.X == -1.0f);
		Test.Assert(tree.Entries[2].Position.Y == 2.5f);
		Test.Assert(tree.ParameterX == 0.0f);
		Test.Assert(tree.Duration == 0.0f);
	}

	[Test]
	public static void AGraphResolvesItsParametersByNameCaseSensitively()
	{
		let graph = scope AnimationGraph();
		Test.Assert(graph.AddParameter("Speed", .Float) == 0);
		Test.Assert(graph.AddParameter("Grounded", .Bool) == 1);
		Test.Assert(graph.Parameters.Count == 2);
		Test.Assert(graph.FindParameter("Speed") == 0);
		Test.Assert(graph.FindParameter("Missing") == -1);
		Test.Assert(graph.FindParameter("speed") == -1, "case sensitive");
		Test.Assert(graph.GetParameter(0).Type == .Float);
		Test.Assert(graph.GetParameter(-1) == null);

		Test.Assert(graph.AddLayer(new AnimationLayer("Base")) == 0);
		Test.Assert(graph.AddLayer(new AnimationLayer("Upper")) == 1);
		Test.Assert(graph.Layers.Count == 2);
	}

	/// The state machine end to end: a parameter goes true and the layer moves.
	[Test]
	public static void ThePlayerTransitionsOnAParameter()
	{
		let skeleton = scope Skeleton(1);
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();

		// Both clips need a real duration: a state with none does not advance at all.
		let idleClip = scope AnimationClip("idle", 1.0f, true);
		idleClip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
		idleClip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 0, 0));
		let walkClip = scope AnimationClip("walk", 1.0f, true);
		walkClip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
		walkClip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 0, 0));

		let graph = scope AnimationGraph();
		let moving = graph.AddParameter("Moving", .Bool);

		let layer = new AnimationLayer("Base");
		layer.AddState(new AnimationGraphState("Idle", new ClipStateNode(idleClip), true));
		layer.AddState(new AnimationGraphState("Walk", new ClipStateNode(walkClip), true));

		let toWalk = new AnimationGraphTransition();
		toWalk.SourceStateIndex = 0;
		toWalk.DestStateIndex = 1;
		toWalk.Duration = 0.001f;
		toWalk.AddBoolCondition(moving, true);
		layer.AddTransition(toWalk);
		graph.AddLayer(layer);

		let player = scope AnimationGraphPlayer(graph, skeleton);
		Test.Assert(player.GetCurrentStateIndex() == 0, "it starts at the default state");

		player.Update(0.016f);
		Test.Assert(player.GetCurrentStateIndex() == 0, "the condition is false, so it stays");

		player.SetBool(moving, true);
		player.Update(0.016f);
		Test.Assert(player.GetCurrentStateIndex() == 1);

		let skin = player.GetSkinningMatrices();
		Test.Assert(skin.Length == 1);
	}

	/// A blend tree fires its DOMINANT clip's events, once. Two walk clips both carrying a
	/// footstep would otherwise fire it twice for one step.
	[Test]
	public static void ABlendTree1DFiresOnlyTheDominantClipsEvents()
	{
		let walk = scope AnimationClip("walk", 1.0f);
		walk.AddEvent(0.5f, "step.walk");
		let run = scope AnimationClip("run", 1.0f);
		run.AddEvent(0.5f, "step.run");

		let tree = scope BlendTree1D();
		tree.AddEntry(0.0f, walk);
		tree.AddEntry(1.0f, run);

		let fired = scope List<String>();
		defer { ClearAndDeleteItems!(fired); }
		AnimationEventHandler handler = scope (name, time) =>
			{
				fired.Add(new String(name));
			};

		tree.Parameter = 0.2f;
		tree.FireEvents(0.4f, 0.6f, false, handler);
		Test.Assert(fired.Count == 1);
		Test.Assert(fired[0] == "step.walk");

		// The parameter decides WHICH clip's events fire.
		ClearAndDeleteItems!(fired);
		tree.Parameter = 0.9f;
		tree.FireEvents(0.4f, 0.6f, false, handler);
		Test.Assert(fired.Count == 1);
		Test.Assert(fired[0] == "step.run");

		// A wrap fires what sits in the wrapped span, and nothing else.
		ClearAndDeleteItems!(fired);
		tree.FireEvents(0.9f, 0.1f, true, handler);
		Test.Assert(fired.IsEmpty, "half a second is in neither part of the span");

		tree.FireEvents(0.4f, 0.1f, true, handler);
		Test.Assert(fired.Count == 1, "crossed before the wrap");
		Test.Assert(fired[0] == "step.run");

		ClearAndDeleteItems!(fired);
		tree.FireEvents(0.6f, 0.8f, false, handler);
		Test.Assert(fired.IsEmpty, "no crossing, no event");
	}

	[Test]
	public static void ABlendTree2DFiresOnlyTheNearestEntrysEvents()
	{
		let idle = scope AnimationClip("idle", 1.0f);
		idle.AddEvent(0.25f, "breath");
		let strafe = scope AnimationClip("strafe", 1.0f);
		strafe.AddEvent(0.25f, "scuff");

		let tree = scope BlendTree2D();
		tree.AddEntry(0.0f, 0.0f, idle);
		tree.AddEntry(1.0f, 0.0f, strafe);

		let fired = scope List<String>();
		defer { ClearAndDeleteItems!(fired); }
		AnimationEventHandler handler = scope (name, time) =>
			{
				fired.Add(new String(name));
			};

		tree.ParameterX = 0.1f;
		tree.ParameterY = 0.0f;
		tree.FireEvents(0.2f, 0.3f, false, handler);
		Test.Assert(fired.Count == 1, "the dominant one only");
		Test.Assert(fired[0] == "breath");

		ClearAndDeleteItems!(fired);
		tree.ParameterX = 0.9f;
		tree.FireEvents(0.2f, 0.3f, false, handler);
		Test.Assert(fired.Count == 1);
		Test.Assert(fired[0] == "scuff");
	}
}
