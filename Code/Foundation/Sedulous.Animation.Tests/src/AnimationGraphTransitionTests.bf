namespace Sedulous.Animation.Tests;

using System;
using System.Collections;

class AnimationGraphTransitionTests
{
	[Test]
	public static void SingleCondition_WhenMet_ReturnsTrue()
	{
		let param = new AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.5f;

		let paramList = scope List<AnimationGraphParameter>();
		paramList.Add(param);

		let transition = scope AnimationGraphTransition();
		transition.AddFloatCondition(0, .Greater, 0.1f);

		Test.Assert(transition.EvaluateConditions(paramList) == true);

		delete param;
	}

	[Test]
	public static void SingleCondition_WhenNotMet_ReturnsFalse()
	{
		let param = new AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.0f;

		let paramList = scope List<AnimationGraphParameter>();
		paramList.Add(param);

		let transition = scope AnimationGraphTransition();
		transition.AddFloatCondition(0, .Greater, 0.1f);

		Test.Assert(transition.EvaluateConditions(paramList) == false);

		delete param;
	}

	[Test]
	public static void MultipleConditions_AllMet_ReturnsTrue()
	{
		let speedParam = new AnimationGraphParameter("Speed", .Float);
		speedParam.FloatValue = 1.0f;
		let groundedParam = new AnimationGraphParameter("Grounded", .Bool);
		groundedParam.BoolValue = true;

		let paramList = scope List<AnimationGraphParameter>();
		paramList.Add(speedParam);
		paramList.Add(groundedParam);

		let transition = scope AnimationGraphTransition();
		transition.AddFloatCondition(0, .Greater, 0.1f);
		transition.AddBoolCondition(1, true);

		Test.Assert(transition.EvaluateConditions(paramList) == true);

		delete speedParam;
		delete groundedParam;
	}

	[Test]
	public static void MultipleConditions_OneFails_ReturnsFalse()
	{
		let speedParam = new AnimationGraphParameter("Speed", .Float);
		speedParam.FloatValue = 1.0f;
		let groundedParam = new AnimationGraphParameter("Grounded", .Bool);
		groundedParam.BoolValue = false;

		let paramList = scope List<AnimationGraphParameter>();
		paramList.Add(speedParam);
		paramList.Add(groundedParam);

		let transition = scope AnimationGraphTransition();
		transition.AddFloatCondition(0, .Greater, 0.1f);
		transition.AddBoolCondition(1, true); // expects true, but param is false

		Test.Assert(transition.EvaluateConditions(paramList) == false);

		delete speedParam;
		delete groundedParam;
	}

	[Test]
	public static void NoConditions_ReturnsTrue()
	{
		let paramList = scope List<AnimationGraphParameter>();
		let transition = scope AnimationGraphTransition();

		// Empty conditions list means unconditional
		Test.Assert(transition.EvaluateConditions(paramList) == true);
	}

	[Test]
	public static void InvalidParameterIndex_ReturnsFalse()
	{
		let paramList = scope List<AnimationGraphParameter>();
		let transition = scope AnimationGraphTransition();
		transition.AddFloatCondition(5, .Greater, 0.0f); // index 5 doesn't exist

		Test.Assert(transition.EvaluateConditions(paramList) == false);
	}

	[Test]
	public static void AddBoolCondition_TrueExpected_SetsThresholdAboveHalf()
	{
		let transition = scope AnimationGraphTransition();
		transition.AddBoolCondition(0, true);

		Test.Assert(transition.Conditions.Count == 1);
		Test.Assert(transition.Conditions[0].Threshold == 1.0f);
		Test.Assert(transition.Conditions[0].Op == .Equal);
	}

	[Test]
	public static void AddBoolCondition_FalseExpected_SetsThresholdZero()
	{
		let transition = scope AnimationGraphTransition();
		transition.AddBoolCondition(0, false);

		Test.Assert(transition.Conditions.Count == 1);
		Test.Assert(transition.Conditions[0].Threshold == 0.0f);
	}

	[Test]
	public static void DefaultValues_AreCorrect()
	{
		let transition = scope AnimationGraphTransition();

		Test.Assert(transition.SourceStateIndex == -1); // Any state
		Test.Assert(transition.Duration == 0.25f);
		Test.Assert(transition.HasExitTime == false);
		Test.Assert(transition.ExitTime == 1.0f);
		Test.Assert(transition.Priority == 0);
	}

	[Test]
	public static void TriggerCondition_WhenSet_FiresAndConsumes()
	{
		let triggerParam = new AnimationGraphParameter("Attack", .Trigger);
		triggerParam.BoolValue = true;

		let paramList = scope List<AnimationGraphParameter>();
		paramList.Add(triggerParam);

		let transition = scope AnimationGraphTransition();
		transition.AddBoolCondition(0, true);

		// Should fire
		Test.Assert(transition.EvaluateConditions(paramList) == true);

		// Consume trigger
		triggerParam.ConsumeTrigger();

		// Should no longer fire
		Test.Assert(transition.EvaluateConditions(paramList) == false);

		delete triggerParam;
	}
}
