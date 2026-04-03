namespace Sedulous.Animation.Tests;

using System;

class AnimationGraphConditionTests
{
	// ==================== Float Comparisons ====================

	[Test]
	public static void FloatGreater_WhenAbove_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.5f;

		let cond = AnimationGraphCondition(0, .Greater, 0.1f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void FloatGreater_WhenBelow_ReturnsFalse()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.05f;

		let cond = AnimationGraphCondition(0, .Greater, 0.1f);
		Test.Assert(cond.Evaluate(param) == false);
	}

	[Test]
	public static void FloatLessEqual_WhenEqual_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.1f;

		let cond = AnimationGraphCondition(0, .LessEqual, 0.1f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void FloatLessEqual_WhenBelow_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.0f;

		let cond = AnimationGraphCondition(0, .LessEqual, 0.1f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void FloatLess_WhenAbove_ReturnsFalse()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 1.0f;

		let cond = AnimationGraphCondition(0, .Less, 0.5f);
		Test.Assert(cond.Evaluate(param) == false);
	}

	[Test]
	public static void FloatEqual_WithinEpsilon_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 1.0f;

		let cond = AnimationGraphCondition(0, .Equal, 1.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void FloatNotEqual_WhenDifferent_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 2.0f;

		let cond = AnimationGraphCondition(0, .NotEqual, 1.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void FloatGreaterEqual_WhenEqual_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 0.5f;

		let cond = AnimationGraphCondition(0, .GreaterEqual, 0.5f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	// ==================== Int Comparisons ====================

	[Test]
	public static void IntGreater_WhenAbove_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Level", .Int);
		param.IntValue = 5;

		let cond = AnimationGraphCondition(0, .Greater, 3.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void IntEqual_WhenMatches_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("State", .Int);
		param.IntValue = 2;

		let cond = AnimationGraphCondition(0, .Equal, 2.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	// ==================== Bool/Trigger Comparisons ====================

	[Test]
	public static void BoolEqual_True_WhenTrue_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Grounded", .Bool);
		param.BoolValue = true;

		// threshold > 0.5 means "is true"
		let cond = AnimationGraphCondition(0, .Equal, 1.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void BoolEqual_True_WhenFalse_ReturnsFalse()
	{
		let param = scope AnimationGraphParameter("Grounded", .Bool);
		param.BoolValue = false;

		let cond = AnimationGraphCondition(0, .Equal, 1.0f);
		Test.Assert(cond.Evaluate(param) == false);
	}

	[Test]
	public static void BoolEqual_False_WhenFalse_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Grounded", .Bool);
		param.BoolValue = false;

		// threshold <= 0.5 means "is false"
		let cond = AnimationGraphCondition(0, .Equal, 0.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void TriggerEqual_WhenSet_ReturnsTrue()
	{
		let param = scope AnimationGraphParameter("Fire", .Trigger);
		param.BoolValue = true;

		let cond = AnimationGraphCondition(0, .Equal, 1.0f);
		Test.Assert(cond.Evaluate(param) == true);
	}

	[Test]
	public static void NullParameter_ReturnsFalse()
	{
		let cond = AnimationGraphCondition(0, .Greater, 0.0f);
		Test.Assert(cond.Evaluate(null) == false);
	}
}
